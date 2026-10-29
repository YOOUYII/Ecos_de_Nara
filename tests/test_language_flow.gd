extends SceneTree

## Idiomas: bloqueo al empezar, selector, guardado/restauración y carta por conceptos.
## Ejecutar: godot --headless --path . --script res://tests/test_language_flow.gd
## Crea (y borra al terminar) un paquete de idioma de prueba "zz" para probar varias combinaciones.

const ZZ_CONTENT := "res://data/content/zz.json"
const ZZ_GLOSS := "res://data/gloss/zz.json"

var _failures := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await create_timer(0.2).timeout
	var lang: Node = root.get_node("Lang")
	var game: Node = root.get_node("GameManager")
	var saves: Node = root.get_node("SaveManager")
	var letter: Node = root.get_node("Letter")

	# Por defecto de/es. Con glosas en español e inglés hay dos combinaciones: se muestra la selección.
	lang.reset()
	_check(lang.target == "de" and lang.native == "es" and not lang.locked, "por defecto de/es y sin bloquear")
	_check(lang.valid_pairs() == [["de", "es"], ["de", "en"], ["de", "eo"], ["es", "de"], ["es", "en"], ["es", "eo"], ["en", "de"], ["en", "es"], ["en", "eo"], ["eo", "de"], ["eo", "es"], ["eo", "en"]] and lang.needs_selection(), "doce combinaciones reales")

	# Al empezar la partida, los idiomas se fijan y ya no se pueden cambiar.
	_check(game.confirm_languages("de", "es") and lang.locked, "confirm_languages fija y bloquea")
	_check(not lang.set_languages("de", "es"), "bloqueado: set_languages se rechaza aunque el par sea válido")
	lang.reset()
	_check(not lang.locked, "partida nueva (reset) desbloquea")
	_check(not game.confirm_languages("de", "de") and not lang.locked, "par inválido no bloquea")

	# Carta por conceptos, en el par actual.
	_check(letter.fragments.size() == 3, "carta: 3 fragmentos desde data/letter.json")
	var f1: LetterFragment = letter.get_fragment("fragment_1")
	_check(f1.is_discovered() and f1.required_concepts == ["way", "water"], "carta: fragmento I descubierto, requiere way+water")
	_check(f1.target_text.begins_with("Lieber Freund") and f1.native_text.begins_with("Querido amigo"), "carta: textos de/es")
	_check(f1.title == "Fragmento I — El Camino y el Agua", "carta: título en español")
	_check(letter.get_fragment("fragment_3").is_locked(), "carta: fragmento III bloqueado")

	# Varias combinaciones: paquete de prueba "zz".
	_write(ZZ_CONTENT, {"language": "zz", "words": {}, "lines": {}, "letter": {}})
	_write(ZZ_GLOSS, {"language": "zz", "concepts": {}, "contexts": {}, "letter": {}})
	lang._registry["zz"] = {"name": "Zeta", "content": true, "gloss": true}
	_check(lang.valid_pairs().size() == 20, "con zz: 20 combinaciones")

	var screen: Control = load("res://scenes/ui/language_select.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	_check(screen.target_option.item_count == 5, "selector: 5 idiomas para aprender (de, es, en, eo, zz)")
	_check(screen.native_option.item_count == 5, "selector: 'Mi idioma' muestra siempre todos los idiomas (incluido Deutsch)")
	_check(screen.selected_target() == "de" and screen.selected_native() == "es", "selector: por defecto aprende alemán con interfaz en español")
	_check(_item_disabled(screen, "de") and not _item_disabled(screen, "es") and not _item_disabled(screen, "zz"), "selector: con de elegido, Deutsch sale desactivado en 'Mi idioma'")
	screen.target_option.select(4)
	screen._refresh_natives()
	_check(screen.selected_target() == "zz" and screen.selected_native() == "es" and screen.native_option.item_count == 5, "selector: sigue mostrando todos los idiomas al cambiar el idioma a aprender")
	_check(_item_disabled(screen, "zz") and not _item_disabled(screen, "de"), "selector: con zz elegido, Deutsch vuelve a estar disponible y zz queda desactivado")
	# Si el idioma principal elegido pasa a ser el que se aprende, se cambia automáticamente a otro disponible.
	var german_index := _item_index(screen, "de")
	screen.native_option.select(german_index)
	_check(screen.selected_native() == "de", "selector: se puede elegir Deutsch como idioma principal")
	screen.target_option.select(1) # es
	screen._refresh_natives()
	_check(screen.selected_target() == "es" and screen.selected_native() == "de", "selector: aprender español con interfaz en alemán se conserva")
	screen.target_option.select(0) # de
	screen._refresh_natives()
	_check(screen.selected_target() == "de" and screen.selected_native() != "de" and not _item_disabled(screen, screen.selected_native()), "selector: al aprender alemán, el principal cambia solo a otro idioma disponible")
	_check(not screen.start_button.disabled, "selector: se puede continuar con una combinación válida")
	# Aprender español con Deutsch como idioma principal, tal como lo confirma el botón "Continuar".
	screen.target_option.select(1)
	screen._refresh_natives()
	screen.native_option.select(_item_index(screen, "de"))
	_check(game.confirm_languages(screen.selected_target(), screen.selected_native()) and lang.target == "es" and lang.native == "de" and TranslationServer.get_locale().begins_with("de"), "selector: aprender es con Mi idioma = Deutsch fija la interfaz en alemán")
	lang.reset()
	screen.queue_free()

	# El par de idiomas viaja con la partida.
	lang.reset()
	_check(game.confirm_languages("zz", "es"), "confirm_languages zz/es")
	var saved: Dictionary = saves.build_save_dict(Vector2.ZERO)
	_check(saved["language"] == {"target": "zz", "native": "es"}, "guardado incluye el par de idiomas")
	lang.reset()
	saves.apply_language(saved)
	_check(lang.target == "zz" and lang.native == "es" and lang.locked, "cargar restaura el par y lo bloquea")
	_check(letter.get_fragment("fragment_1").target_text == "[fragment_1]", "cargar reconstruye la carta en el par restaurado")
	saves.apply_language({})
	_check(lang.target == "de" and lang.native == "es" and lang.locked, "guardado anterior (sin 'language') usa de/es")
	saves.apply_language({"language": {"target": "xx", "native": "es"}})
	_check(lang.target == "de" and lang.native == "es" and lang.locked, "par guardado no disponible: vuelve a de/es")

	# Inglés como idioma principal (paquete real): la glosa y la interfaz salen en inglés.
	var objective_id := "Habla con los habitantes del pueblo, anota vocabulario (N) y revisa tu carta (C)."
	lang.reset()
	_check(lang.tr("Cerrar") == "Cerrar" and TranslationServer.get_locale().begins_with("es"), "ui: con español como principal se ven los textos originales")
	_check(lang.set_languages("de", "en") and TranslationServer.get_locale().begins_with("en"), "ui: de/en es una combinación válida")
	_check(lang.tr("Cerrar") == "Close" and lang.tr("Panadera") == "Baker", "ui: principal inglés traduce la interfaz")
	_check(lang.tr("Texto sin traducción") == "Texto sin traducción", "ui: un texto sin traducción se muestra tal cual")
	var story: Node = root.get_node("StoryProgress")
	story.set_objective(objective_id)
	_check(story.current_objective == "Talk to the villagers, note down vocabulary (N) and check your letter (C).", "ui: los objetivos se traducen")
	var box: DialogueBox = load("res://scenes/ui/dialogue_box.tscn").instantiate()
	root.add_child(box)
	await process_frame
	box.show_line(lang.tr("Panadera"), "Hallo!", "res://assets/art/portraits/anim/panadera_amable_talk_3f.png", true)
	_check(box.next_button.text == "Close" and box.speaker_label.text == "Baker", "ui: el cuadro de diálogo muestra los textos en inglés")
	box.queue_free()

	# Glosa en inglés: vocabulario, contexto y carta.
	var notebook: Node = root.get_node("Notebook")
	notebook.reset()
	notebook.register_effects([{"type": "vocabulary", "concept": "bread", "context_id": "panadera.v3.bread"}])
	var bread: VocabularyEntry = notebook.entries_by_key.get("brot")
	_check(bread != null and bread.concept == "bread" and bread.spanish_meaning == "bread", "glosa en: 'Brot' significa 'bread'")
	_check(bread != null and bread.context == "The baker offers warm bread while saying the word.", "glosa en: contexto en inglés")
	_check(bread != null and bread.choices.size() == 3 and bread.choices.has("water") and bread.correct_answer == "bread", "glosa en: opciones y respuesta en inglés")
	_check(letter.get_fragment("fragment_1").native_text.begins_with("Dear friend") and letter.get_fragment("fragment_1").title == "Fragment I — The Path and the Water", "glosa en: carta traducida en inglés")
	_check(letter.get_fragment("fragment_1").target_text.begins_with("Lieber Freund"), "glosa en: el texto de la carta sigue en alemán")
	notebook.confirm_entry("Brot")
	notebook.register_effects([{"type": "vocabulary", "concept": "way", "context_id": "guardia.v3.way"}, {"type": "vocabulary", "concept": "water", "context_id": "panadera.v3.water"}])
	notebook.confirm_entry("Weg")
	notebook.confirm_entry("Wasser")
	_check(letter.get_fragment("fragment_1").is_translated(), "glosa en: el fragmento I se traduce al confirmar way+water")
	notebook.reset()
	lang.reset()

	# Segundo cambio de idioma principal: reemplaza la traducción anterior (paquete temporal "ia").
	_write("res://data/gloss/ia.json", {"language": "ia", "concepts": {}, "contexts": {}, "letter": {}, "ui": {"Cerrar": "Clauder"}})
	lang._registry["ia"] = {"name": "ia", "content": false, "gloss": true}
	lang.set_languages("de", "en")
	lang.unlock()
	_check(lang.set_languages("de", "ia") and lang.tr("Cerrar") == "Clauder" and lang.tr("Panadera") == "Panadera", "ui: cambiar de idioma principal sustituye la traducción anterior")
	lang.reset()
	_check(lang.tr("Cerrar") == "Cerrar" and lang.tr("Panadera") == "Panadera", "ui: volver a español quita las traducciones")
	story.set_objective(objective_id)
	_check(story.current_objective == objective_id, "ui: el objetivo vuelve al texto original en español")

	# Limpieza.
	lang.reset()
	lang._registry.erase("zz")
	lang._registry.erase("ia")
	for path in [ZZ_CONTENT, ZZ_GLOSS, "res://data/gloss/ia.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(not FileAccess.file_exists(ZZ_CONTENT) and not FileAccess.file_exists(ZZ_GLOSS) and not FileAccess.file_exists("res://data/gloss/ia.json"), "limpieza: paquetes de prueba borrados")
	_check(FileAccess.file_exists("res://data/gloss/en.json"), "limpieza: la glosa real en.json sigue en su sitio")

	print("RESULTADO: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(_failures)


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok  - %s" % message)
	else:
		_failures += 1
		print("  FAIL - %s" % message)


func _item_index(screen: Control, code: String) -> int:
	for i in screen.native_option.item_count:
		if screen.native_option.get_item_metadata(i) == code:
			return i
	return -1


func _item_disabled(screen: Control, code: String) -> bool:
	var index := _item_index(screen, code)
	return index >= 0 and screen.native_option.is_item_disabled(index)
