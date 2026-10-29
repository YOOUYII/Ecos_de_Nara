# Registro de cambios: narrativa A1 progresivo

Los textos originales están en `data/dialogues/legacy/`. Los recursos pendientes están en `ARTE_PENDIENTE.md`.

## Código (campos opcionales y retrocompatibles)

- `dialogue_box.gd` y `dialogue_box.tscn`: texto letra por letra (30 caracteres/s), boca del retrato animada solo mientras escribe, y pictograma flotante (`IconPopup`). El primer `E` completa la línea y el segundo avanza.
- `dialogue_manager.gd`: una línea puede ser un `String` o un objeto `{text, portrait?, icon?, icon_word?, gesture?}`.

## Contenido

| NPC | Archivo | Cambios principales |
|---|---|---|
| Helga (`panadera`) | `pueblo.json` | Líneas de 1 a 4 palabras con pictograma; la variante por defecto enseña también `Brot`. |
| Karl (`guardia`) | `pueblo.json` | `öffne` pasa a `öffnen`; `Dorf` se reemplaza por `Achtung`; añade `Brücke` antes del bosque (corrección §4 del Fragmento II). |
| Leni (`nina`) | `pueblo.json` | `Quelle` pasa a `Brunnen`; flag nuevo `leni_met` para una segunda conversación (`Mitte`). |
| Fritz (`lenador`) | `bosque.json` | 3 beats; `gefährlich` se reemplaza por `Achtung`; gesto distinto por línea. |
| Maren (`pescadora`) | `rio.json` | Revelación en 6 líneas; se quita `Fluss` (máx. 3 palabras objetivo); escena final de 4 líneas. |

## Decisiones y limitaciones

- La clave `hause` se conserva porque `letter.gd` la exige en `required_words` del Fragmento III. La libreta explica que solo existe en "nach Hause".
- Se quitaron del vocabulario `Quelle`, `gefährlich`, `Dorf`, `öffne` y `Fluss`. Las partidas guardadas que los tengan conservarán esas entradas.
- `relationship` es fija en cada escena, por lo que varias variantes "por defecto" no se activaban (por ejemplo, la de Helga). No se modificó.
- Hueco narrativo existente: Helga pide "Brot für Fritz", pero Karl se queda con la cesta y Fritz nunca recibe el pan.
- Los avisos del lintador son anclas visuales pendientes de arte.
- No hay diálogos de alcaldesa, bibliotecario ni anciana en el proyecto.
- `NARRATIVA_Y_DIALOGOS_ECOS_DE_NARA_v2.md` no se generó: el documento original no está en el proyecto.

## Cómo verificar

```text
python tools/lint_dialogos.py
godot --headless --path . --script res://tests/test_dialogue_box.gd
godot --headless --path . --script res://tests/test_npc_flow.gd
```
