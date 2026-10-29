#!/usr/bin/env python3
"""Verifica que los paquetes de idioma estén completos.

- Contenido (data/content/<código>.json): texto de cada línea de diálogo, palabra de cada concepto y
  texto de cada fragmento de la carta.
- Glosa (data/gloss/<código>.json): concepto, contexto y carta (título, traducción y pista) usados por los
  diálogos y la carta, y sección "ui" con la traducción de cada texto de interfaz.

El español es el idioma original de la interfaz (sus textos son los identificadores), así que su
sección "ui" no es obligatoria.

Uso: python tools/check_paquetes.py [--list]   (desde la raíz del proyecto Godot)
  --list  imprime los textos de interfaz traducibles y termina.
Código de salida: 0 sin errores, 1 con errores.
"""
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
SOURCE_UI_LANGUAGE = "es"
STRING = r'"((?:[^"\\]|\\.)*)"'


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def unescape(raw):
    return json.loads(f'"{raw}"')


def ui_message_ids():
    """Textos de interfaz originales: escenas (text, display_name...), tr("...") en scripts y textos de efectos."""
    found = {}

    def add(text, origin):
        if text.strip():
            found.setdefault(text, origin)

    for scene in sorted((ROOT / "scenes").rglob("*.tscn")):
        for line in scene.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(rf"(?:text|placeholder_text|tooltip_text|display_name) = {STRING}$", line)
            if m:
                add(unescape(m.group(1)), scene.relative_to(ROOT).as_posix())
    for script in sorted((ROOT / "scripts").rglob("*.gd")):
        text = script.read_text(encoding="utf-8")
        for m in re.finditer(rf"\btr\({STRING}\)", text):
            add(unescape(m.group(1)), script.relative_to(ROOT).as_posix())
    for dlg in sorted((ROOT / "data" / "dialogues").glob("*.json")):
        for npc in load(dlg)["dialogues"].values():
            for variant in npc["variants"]:
                for eff in variant.get("effects", []):
                    for key in ("objective", "title", "desc"):
                        if eff.get(key):
                            add(eff[key], dlg.relative_to(ROOT).as_posix())
    # Textos que se traducen desde código sin literal en tr(): nombres de personaje, avisos del guardado.
    for text in ("forastero", "forastera", "Partida guardada", "Partida cargada",
                 StoryDefault()):
        add(text, "scripts")
    return found


def StoryDefault():
    text = (ROOT / "scripts" / "autoload" / "story_progress.gd").read_text(encoding="utf-8")
    m = re.search(rf"const DEFAULT_OBJECTIVE := {STRING}", text)
    return unescape(m.group(1)) if m else ""


def structure():
    """Líneas, conceptos y contextos que la estructura (diálogos y carta) exige a cada paquete."""
    lines, concepts, contexts = set(), set(), set()
    for dlg in sorted((ROOT / "data" / "dialogues").glob("*.json")):
        for npc in load(dlg)["dialogues"].values():
            for variant in npc["variants"]:
                for raw in variant.get("lines", []):
                    lines.add(raw if isinstance(raw, str) else raw["id"])
                for eff in variant.get("effects", []):
                    if eff.get("type") == "vocabulary" and eff.get("concept"):
                        concepts.add(eff["concept"])
                        if eff.get("context_id"):
                            contexts.add(eff["context_id"])
    letter = load(ROOT / "data" / "letter.json")["fragments"]
    fragments = [f["id"] for f in letter]
    for f in letter:
        concepts.update(f.get("required_concepts", []))
    return lines, concepts, contexts, fragments


def main():
    ids = ui_message_ids()
    if "--list" in sys.argv:
        for text, origin in ids.items():
            print(f"{origin}: {text!r}")
        print(f"{len(ids)} textos de interfaz")
        return 0

    lines, concepts, contexts, fragments = structure()
    registry = load(ROOT / "data" / "languages.json")
    errors, warnings = [], []

    for code, info in registry.items():
        if info.get("content"):
            pack = load(ROOT / "data" / "content" / f"{code}.json")
            for lid in sorted(lines - set(pack.get("lines", {}))):
                errors.append(f"content/{code}: falta la línea '{lid}'")
            for c in sorted(concepts - set(pack.get("words", {}))):
                errors.append(f"content/{code}: falta la palabra del concepto '{c}'")
            for fid in fragments:
                if fid not in pack.get("letter", {}):
                    errors.append(f"content/{code}: falta el texto de la carta '{fid}'")
            for lid in sorted(set(pack.get("lines", {})) - lines):
                warnings.append(f"content/{code}: línea sin uso '{lid}'")
        if info.get("gloss"):
            pack = load(ROOT / "data" / "gloss" / f"{code}.json")
            for c in sorted(concepts - set(pack.get("concepts", {}))):
                errors.append(f"gloss/{code}: falta la glosa del concepto '{c}'")
            for cid in sorted(contexts - set(pack.get("contexts", {}))):
                errors.append(f"gloss/{code}: falta el contexto '{cid}'")
            # Sobrescrituras "<id>@<idioma>": el contexto base debe existir y el idioma estar registrado.
            for key in pack.get("contexts", {}):
                if "@" in key:
                    base, _, lang_code = key.partition("@")
                    if base not in contexts or lang_code not in registry:
                        errors.append(f"gloss/{code}: sobrescritura inválida '{key}'")
            for fid in fragments:
                entry = pack.get("letter", {}).get(fid, {})
                for key in ("title", "translation", "hint"):
                    if not entry.get(key):
                        errors.append(f"gloss/{code}: falta '{key}' de la carta '{fid}'")
            if code != SOURCE_UI_LANGUAGE:
                ui = pack.get("ui", {})
                for text in ids:
                    if text not in ui:
                        errors.append(f"gloss/{code}: falta traducir {text!r}")
                for text in ui:
                    if text not in ids:
                        warnings.append(f"gloss/{code}: traducción sin uso {text!r}")

    for w in warnings:
        print("AVISO ", w)
    for e in errors:
        print("ERROR ", e)
    pending = [c for c, i in registry.items() if i.get("gloss") and c != SOURCE_UI_LANGUAGE]
    print(f"Paquetes: {len(registry)} idiomas, {len(ids)} textos de interfaz, "
          f"{len(lines)} líneas, {len(concepts)} conceptos; "
          f"{len(errors)} errores, {len(warnings)} avisos"
          + ("" if pending else " (sin glosas distintas del español: la interfaz aún no se puede comprobar)"))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
