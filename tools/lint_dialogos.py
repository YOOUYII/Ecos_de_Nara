#!/usr/bin/env python3
"""Lintador de diálogos A1 progresivo.

Revisa solo los NPC listados en `rewritten_npcs` de data/lexicon_a1.json.
Uso: python tools/lint_dialogos.py [--lang de]   (desde la raíz del proyecto Godot)
Código de salida: 0 sin errores, 1 con errores. Los avisos no fallan.
"""
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
TOKEN = re.compile(r"[^\W\d_]+", re.UNICODE)


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def line_parts(raw, content, errors, where):
    """Devuelve (texto, icono, palabra_icono) de una línea (ID, String literal o Dictionary)."""
    meta = raw if isinstance(raw, dict) else {}
    line_id = meta.get("id") if meta else (raw if isinstance(raw, str) and raw in content["lines"] else None)
    entry = content["lines"].get(line_id) if line_id else None
    if line_id and entry is None:
        errors.append(f"{where}: la línea '{line_id}' no tiene texto en content/{content['language']}.json")
    base = {} if entry is None else ({"text": entry} if isinstance(entry, str) else entry)
    text = str(meta.get("text", base.get("text", raw if isinstance(raw, str) and not line_id else "")))
    return text, str(meta.get("icon", "")), str(meta.get("icon_word", base.get("icon_word", "")))


def tokens(text):
    return [t.lower() for t in TOKEN.findall(text)]


def res_to_path(res):
    return ROOT / res.replace("res://", "")


def lint(lang="de"):
    lex_path = ROOT / "data" / ("lexicon_a1.json" if lang == "de" else f"lexicon_{lang}.json")
    lex = load(lex_path)
    content = load(ROOT / "data" / "content" / f"{lang}.json")
    words = lex["words"]
    limits = lex["limits"]
    banned = set(lex.get("banned_tokens", []))
    errors, warnings = [], []

    for dlg_file in sorted((ROOT / "data" / "dialogues").glob("*.json")):
        data = load(dlg_file)
        for npc, npc_data in data.get("dialogues", {}).items():
            if npc not in lex["rewritten_npcs"]:
                continue
            for vi, variant in enumerate(npc_data.get("variants", [])):
                where = f"{dlg_file.name}:{npc}[{vi}]"
                lines = [line_parts(r, content, errors, where) for r in variant.get("lines", [])]
                effects = [e for e in variant.get("effects", []) if e.get("type") == "vocabulary"]

                if len(effects) > limits["max_target_words_per_variant"]:
                    errors.append(f"{where}: {len(effects)} palabras objetivo (máx {limits['max_target_words_per_variant']})")

                for li, (text, icon, icon_word) in enumerate(lines):
                    toks = tokens(text)
                    loc = f"{where} línea {li + 1} '{text}'"
                    if len(toks) > limits["max_words_per_line"]:
                        errors.append(f"{loc}: {len(toks)} palabras (máx {limits['max_words_per_line']})")
                    for t in toks:
                        if t in banned:
                            errors.append(f"{loc}: token prohibido '{t}'")
                        elif t not in words:
                            errors.append(f"{loc}: palabra fuera del léxico '{t}'")
                    if icon:
                        if not res_to_path(icon).exists():
                            errors.append(f"{loc}: el icono no existe: {icon}")
                        if icon_word and icon_word not in text:
                            errors.append(f"{loc}: icon_word '{icon_word}' no está en el texto")

                # Cada palabra objetivo necesita ancla: una línea que la contenga con icono (o gesto de la variante).
                for eff in effects:
                    word = content["words"].get(eff.get("concept", ""), "") if eff.get("concept") else str(eff.get("word", ""))
                    if not word:
                        errors.append(f"{where}: el concepto '{eff.get('concept')}' no tiene palabra en content/{lang}.json")
                        continue
                    entry = next(
                        (e for e in words.values() if e.get("kind") == "target" and e.get("lemma", "").lower() == word.lower()),
                        None,
                    )
                    if entry is None:
                        errors.append(f"{where}: efecto '{word}' no es palabra objetivo del léxico")
                        continue
                    forms = set(entry.get("forms", []))
                    lines_with_word = [(t, i, w) for t, i, w in lines if forms & set(tokens(t))]
                    if not lines_with_word:
                        errors.append(f"{where}: la palabra objetivo '{word}' no aparece en ninguna línea")
                        continue
                    # El ícono ancla solo esta palabra si su icon_word es una de sus formas.
                    # Un gesto de la variante o de la línea ancla la palabra solo si su ancla no depende de arte pendiente.
                    line_gesture = any(isinstance(r, dict) and r.get("gesture") for r in variant.get("lines", []))
                    anchored = any(i and set(tokens(w)) & forms for _, i, w in lines_with_word) or (
                        (bool(variant.get("gesture")) or line_gesture) and not entry.get("anchor_pending")
                    )
                    if not anchored:
                        msg = f"{where}: '{word}' sin ancla visual en su línea"
                        (warnings if entry.get("anchor_pending") else errors).append(
                            msg + (" (arte pendiente)" if entry.get("anchor_pending") else "")
                        )

    for w in warnings:
        print("AVISO ", w)
    for e in errors:
        print("ERROR ", e)
    print(f"Lint: {len(errors)} errores, {len(warnings)} avisos")
    return 1 if errors else 0


if __name__ == "__main__":
    lang_arg = sys.argv[sys.argv.index("--lang") + 1] if "--lang" in sys.argv else "de"
    sys.exit(lint(lang_arg))
