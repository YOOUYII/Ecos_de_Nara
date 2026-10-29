# i18n: idioma a aprender e idioma principal selectables

Objetivo: dos ejes independientes: idioma a aprender (de, en, eo, es) e idioma principal (es, de, en, eo). Rama: sin git. Estrategia de entrega: sin commits (decisión del usuario). Runner de pruebas: Godot headless (`tests/*.gd`) y `tools/lint_dialogos.py`.

## Specs

- S1: "Perfecto, puedes empezar a implementar el plan?" (plan de dos ejes: 4 paquetes de contenido + 4 paquetes de glosa).
- S2: Alemán con glosa en español debe quedar idéntico a hoy antes de añadir idiomas (punto de control del plan).
- S3: Los IDs de misión, bandera e ítem no cambian; los guardados viejos siguen cargando (campos nuevos opcionales).
- S4: "haz que el idioma se tenga que elegir solo desde el inicio, que no se pueda cambiar cuando ya se inició la partida". Los dos idiomas (aprender y principal) se eligen una sola vez al empezar una partida nueva, quedan bloqueados, se guardan con la partida y se restauran al cargarla. (Reemplaza el supuesto anterior de "idioma principal como ajuste libre".)
- S5: Cualquier texto nuevo pasa por el sistema de traducción desde el primer día.

## Tasks

| ID | Specs | Ruta | Estado |
|---|---|---|---|
| T1 | S2,S3 | inline | HECHO y verificado: estructura compartida, `Lang`, content `de`, gloss `es` (vocabulario, contextos y líneas). Script de equivalencia: 20 variantes, 59 líneas, 27 efectos, 0 diferencias. Pruebas headless OK. Sin commit. |
| T2 | S2,S3 | inline | HECHO y verificado: carta en `data/letter.json` + texto en content + traducción/título/pista en gloss; `required_concepts`; `Notebook.get_confirmed_concepts()`. Los 3 fragmentos se siguen traduciendo (prueba de flujo). |
| T3 | S5 | inline | HECHO y verificado: interfaz, avisos, objetivos y misiones traducibles. Identificador = texto original en español; la sección `ui` de `gloss/<código>.json` lo traduce (`Lang` instala una `Translation` y fija el locale). 71 textos de interfaz. Escenas sin tocar (Label/Button traducen solos); scripts con `tr()` donde hay formato. Cambio visible: "(En alemán)" pasa a "(Sin traducir)" (ya no puede nombrar un idioma fijo). |
| T4 | S4,S3 | inline | HECHO y verificado: `Lang.lock/unlock/reset`, registro `data/languages.json`, pantalla `language_select` (solo si hay >1 combinación), `GameManager.confirm_languages`, par de idiomas en el guardado (`SaveManager.apply_language`). Sin prefijar claves de la libreta: cada partida tiene un único par. Pendiente: un único hueco de guardado compartido entre pares de idiomas. |
| T5 | S2 | inline | PARCIAL: lintador con `--lang` (hecho) y `tools/check_paquetes.py` (verifica líneas, palabras, contextos, carta y `ui` por idioma; hecho). HECHO también: pruebas de flujo parametrizadas (`tests/test_target_languages.gd`, una vez por cada combinación real). |
| T6 | S1 | inline | EN CURSO. HECHO: glosa `en` (idioma principal inglés: 22 conceptos, 27 contextos, carta y 71 textos de interfaz; pendiente de revisión humana). Verificado con pruebas y capturas reales (menú, selección de personaje, introducción, diálogo, libreta y carta en inglés). Con esto aparece la pantalla de selección (de/es y de/en). HECHO: contenido `en` como idioma a aprender (59 líneas, 22 palabras, 3 fragmentos; léxico `lexicon_en.json`; lintador `--lang en` con 0 errores; pendiente de revisión humana). Contextos con sobrescritura por idioma (`<id>@de`). Prueba `tests/test_target_languages.gd` recorre la historia completa en cada idioma a aprender. HECHO: contenido `eo` como idioma a aprender (59 líneas, 22 palabras, 3 fragmentos; `lexicon_eo.json`; lintador `--lang eo` 0 errores; diacríticos ĉ ŝ ĝ se dibujan bien en la fuente por defecto; sin revisión humana). Los diálogos evitan el acusativo -n salvo frases fijas (Dankon, Bonan matenon, Bonan vojaĝon) y los adverbios direccionales norden/hejmen; la carta sí usa acusativo (vojon, veron). HECHO: contenido `es` como idioma a aprender (59 líneas, 22 palabras, 3 fragmentos; `lexicon_es.json`; lintador `--lang es` 0 errores; solo combinable con una interfaz que no sea español; sin revisión humana). Combinaciones reales (6): de/es, de/en, es/en, en/es, eo/es, eo/en. Guía v2 actualizada (arquitectura de dos ejes, líneas por ID, cómo añadir idiomas; en Descargas). HECHO: glosa `de` (idioma principal alemán: 22 conceptos, 27 contextos, carta y 71 textos de interfaz; verificada con capturas en alemán; sin revisión humana); combinaciones reales: 9; `test_target_languages` recorre las 9. HECHO: glosa `eo` (idioma principal esperanto; 71 textos de interfaz verificados con capturas; sin revisión humana). Combinaciones reales: 12 (los cuatro idiomas a aprender × los otros tres como principal), todas recorridas por `test_target_languages`. IMPLEMENTACIÓN TÉCNICA COMPLETA. PENDIENTE (humano): revisión de todo el texto nuevo por hablantes, prueba con personas, hueco de guardado por par y `nach Hause` en vez de `Hause` (decisiones abiertas). |

## Log

- L1: "Perfecto, puedes empezar a implementar el plan?" (2026-10-28)
- Decisiones de B0 asumidas por defecto (recomendadas y no objetadas): nombres de NPC conservados; el idioma principal se cambia sin perder progreso; solo escritura latina; interfaz inicial en español.
- L2: "Bien, continua, pero haz que el idioma se tenga que elegir solo desde el inicio, que no se pueda cambiar cuando ya se inició la partida" (2026-10-28)
- Riesgo: ítem 1 (formato de guardado persistido). Se añaden campos opcionales y se prueba la carga de un guardado en formato viejo.
