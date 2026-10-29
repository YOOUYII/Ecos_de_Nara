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

## Idiomas (i18n, en curso; ver `odd/tasks/i18n-idiomas.md`)

- Dos ejes: **idioma a aprender** (`data/content/<código>.json`: palabra de cada concepto y texto de cada línea) e **idioma principal** (`data/gloss/<código>.json`: significados, opciones y contextos de la libreta).
- `data/dialogues/*.json` conserva solo la estructura (condiciones, efectos y metadatos de ícono, gesto y retrato). Las líneas son IDs (`panadera.v0.l1`) y los efectos de vocabulario llevan `concept` y `context_id`.
- Autoload `Lang` (`scripts/autoload/lang.gd`): resuelve líneas, palabras y glosas; `set_languages(target, native)` cambia los idiomas.
- Los guardados anteriores siguen cargando: el concepto se deduce de la palabra.
- Estado previo a la migración en `data/dialogues/legacy/pre_i18n/`.
- La carta vive en `data/letter.json` (estructura y conceptos requeridos); su texto está en `content/<código>.json` y su traducción, título y pista en `gloss/<código>.json`.
- **Los idiomas se eligen solo al empezar una partida nueva y quedan bloqueados** (`Lang.lock()`); se guardan con la partida (`"language"`) y se restauran al cargarla. Con una sola combinación posible no se muestra la pantalla de selección. Los idiomas disponibles se declaran en `data/languages.json`.
- **Interfaz traducible:** el identificador de cada texto es el original en español (escenas y `tr("...")` en scripts, más los textos de objetivos y misiones de los diálogos). La sección `ui` de `gloss/<código>.json` los traduce al idioma principal; con español no hace falta. Todo texto nuevo de interfaz debe escribirse así.
- `tools/check_paquetes.py` comprueba que cada paquete de idioma esté completo (`--list` muestra los textos de interfaz traducibles).
- **Idioma principal inglés** (`data/gloss/en.json`, registrado en `data/languages.json`): vocabulario, contextos, carta e interfaz. Escrito por IA y **sin revisar por una persona**. La pantalla de selección de idioma ya aparece al empezar una partida nueva (alemán con glosa en español o en inglés).
- Al elegir idioma, `Lang` notifica al árbol (`NOTIFICATION_TRANSLATION_CHANGED`); sin eso, la libreta y la carta (creadas al arrancar) conservaban sus títulos en español.
- **Inglés como idioma a aprender** (`data/content/en.json` y `data/lexicon_en.json`): mismas líneas, misiones y flujo que el alemán (la estructura es compartida). Escrito por IA y **sin revisar por una persona**. Comprobar con `python tools/lint_dialogos.py --lang en`.
- Los contextos de la glosa pueden tener una versión por idioma a aprender: `"<id>@de"` sustituye a `"<id>"` cuando se aprende alemán (se usa para notas que citan palabras alemanas concretas).
- `tests/test_target_languages.gd` recorre la historia completa una vez por cada idioma a aprender.
- **Esperanto como idioma a aprender** (`data/content/eo.json` y `data/lexicon_eo.json`): los diálogos evitan el acusativo `-n` salvo frases fijas (`Dankon`, `Bonan matenon`, `Bonan vojaĝon`) y los adverbios direccionales `norden` y `hejmen`; la carta sí lo usa. Escrito por IA y **sin revisar por una persona**. Comprobar con `python tools/lint_dialogos.py --lang eo`.
- Combinaciones disponibles: alemán/español, alemán/inglés, inglés/español, esperanto/español y esperanto/inglés.
- **Español como idioma a aprender** (`data/content/es.json` y `data/lexicon_es.json`): solo se puede combinar con una interfaz en otro idioma (hoy, inglés). Escrito por IA y **sin revisar por una persona**. Comprobar con `python tools/lint_dialogos.py --lang es`.
- Combinaciones disponibles (6): alemán/español, alemán/inglés, español/inglés, inglés/español, esperanto/español y esperanto/inglés.
- **Idioma principal alemán** (`data/gloss/de.json`): vocabulario, contextos, carta e interfaz. Escrito por IA y **sin revisar por una persona**. Con él, las combinaciones disponibles son 9 (alemán/español, alemán/inglés, español/alemán, español/inglés, inglés/alemán, inglés/español, esperanto/alemán, esperanto/español y esperanto/inglés).
- **Idioma principal esperanto** (`data/gloss/eo.json`): vocabulario, contextos, carta e interfaz. Escrito por IA y **sin revisar por una persona**. Con él, las combinaciones disponibles son 12: cada uno de los cuatro idiomas (alemán, español, inglés y esperanto) se puede aprender con cualquiera de los otros tres como idioma principal.
- **Pantalla de idiomas:** "Mi idioma" muestra siempre todos los idiomas (Deutsch, Español, English, Esperanto). El que se está aprendiendo sale desactivado y no se puede elegir como principal; al cambiar el idioma a aprender, el principal se ajusta solo si hace falta. Antes la pantalla ocultaba Deutsch mientras estaba elegido en "Quiero aprender" (la opción por defecto), aunque el alemán ya funcionaba como idioma principal.
- **Tecla R: volver al menú de inicio** (`scripts/autoload/menu_return.gd`, acción `return_to_menu`). Solo dentro del mundo y sin diálogo, libreta ni carta abiertos. Pausa el juego y pregunta "¿Seguro que quieres volver al menú de inicio? (Tu progreso se perderá si no lo has guardado)"; Esc o Cancelar la cierran y no cambian nada. Al confirmar se descarta la partida en curso y se vuelve al menú (`GameManager.return_to_menu()`); "Continuar" carga lo guardado. Sus 3 textos están traducidos en las glosas `en`, `de` y `eo`. La barra de ayuda de las tres zonas incluye `[R] Menú` y su panel se ajusta al contenido (ya no tiene ancho fijo), para que quepa en cualquier idioma.
- Pendiente: revisión humana de todo el texto nuevo (inglés, esperanto, español y alemán, tanto como contenido como interfaz) y la prueba con personas.

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
