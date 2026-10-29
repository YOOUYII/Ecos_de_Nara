extends SceneTree

## Recorre la historia completa una vez por cada combinación real de idiomas (aprender, principal)
## y comprueba que la estructura compartida se comporta igual: mismas líneas por conversación, mismas
## misiones, ítems, zonas y banderas, y los tres fragmentos de la carta se pueden traducir.
## Ejecutar: godot --headless --path . --script res://tests/test_target_languages.gd

var _failures := 0
var _dm: Node
var _checked_languages := 0
var _entry_count := -1


func _initialize() -> void:
	_run()


func _run() -> void:
	await create_timer(0.3).timeout
	var lang: Node = root.get_node("Lang")
	for pair in lang.valid_pairs():
		await _flow(pair[0], pair[1])
	_check(_checked_languages == lang.valid_pairs().size() and _checked_languages >= 6, "se recorrieron todas las combinaciones (%d)" % _checked_languages)
	lang.reset()
	print("RESULTADO: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(_failures)


func _flow(target: String, native: String) -> void:
	var lang: Node = root.get_node("Lang")
	var story: Node = root.get_node("StoryProgress")
	var notebook: Node = root.get_node("Notebook")
	var letter: Node = root.get_node("Letter")
	_dm = root.get_node("DialogueManager")
	var tag := "[%s/%s] " % [target, native]

	# Partida nueva en este idioma.
	story.reset()
	notebook.reset()
	lang.unlock()
	_check(lang.set_languages(target, native), tag + "par %s/%s válido" % [target, native])
	lang.lock()
	_checked_languages += 1

	var village: Node = load("res://scenes/world/world_test.tscn").instantiate()
	root.add_child(village)
	await create_timer(0.3).timeout

	# Longitud de cada conversación (igual en todos los idiomas: la estructura es compartida).
	_check(_play(_npc(village, "nina")).size() == 3, tag + "Leni, primera vez: 3 líneas")
	_check(story.has_flag("leni_met"), tag + "Leni activa leni_met")
	_check(_play(_npc(village, "nina")).size() == 1, tag + "Leni, segunda vez: 1 línea")
	_check(_play(_npc(village, "panadera")).size() == 3, tag + "Helga: 3 líneas")
	_check(_play(_npc(village, "guardia")).size() == 4, tag + "Karl bloqueado: 4 líneas")

	story.start_quest("favor_panadera", "Pan", "Cesta")
	story.add_item("cesta_pan")
	_check(_play(_npc(village, "guardia")).size() == 5, tag + "Karl con la cesta: 5 líneas")
	_check(story.can_enter("bosque") and not story.has_item("cesta_pan"), tag + "Karl abre el bosque y retira la cesta")
	_check(story.get_quest_status("favor_panadera") == Quest.Status.COMPLETED, tag + "misión favor_panadera completada")
	_check(_play(_npc(village, "guardia")).size() == 2, tag + "Karl con el camino abierto: 2 líneas")
	village.queue_free()
	await process_frame

	var forest: Node = load("res://scenes/world/world_bosque.tscn").instantiate()
	root.add_child(forest)
	await create_timer(0.3).timeout
	_dm.load_zone_dialogues("bosque")
	_check(_play(_npc(forest, "lenador")).size() == 6, tag + "Fritz: 6 líneas")
	_check(story.has_item("llave_rio") and story.can_enter("rio") and story.has_flag("met_fritz"), tag + "Fritz da la llave y abre el río")
	forest.queue_free()
	await process_frame

	var river: Node = load("res://scenes/world/world_rio.tscn").instantiate()
	root.add_child(river)
	await create_timer(0.3).timeout
	var maren := _npc(river, "pescadora")
	_check(_play(maren).size() == 6, tag + "Maren: 6 líneas")
	_check(story.get_quest_status("favor_lenador") == Quest.Status.COMPLETED and story.has_flag("met_maren"), tag + "Maren completa favor_lenador")

	# Libreta y carta: las palabras del idioma, confirmadas, traducen los tres fragmentos.
	if _entry_count < 0:
		_entry_count = notebook.entries_by_key.size()
	_check(notebook.entries_by_key.size() == _entry_count and _entry_count > 0, tag + "la libreta tiene las mismas entradas que el primer idioma (%d)" % notebook.entries_by_key.size())
	for concept in ["way", "water", "bridge", "key", "answer", "home"]:
		notebook.confirm_entry(lang.word_for(concept))
	for fragment_id in ["fragment_1", "fragment_2", "fragment_3"]:
		_check(story.has_flag(fragment_id + "_translated"), tag + "%s traducido" % fragment_id)
		_check(not letter.get_fragment(fragment_id).target_text.begins_with("["), tag + "%s tiene texto en el idioma" % fragment_id)

	story.set_flag("demo_completed", true)
	_check(_play(maren).size() == 4, tag + "escena final: 4 líneas")
	story.set_flag("demo_completed", false)
	river.queue_free()
	await process_frame


func _npc(world: Node, id: String) -> Npc:
	for n in world.find_children("*", "Npc", true, false):
		if (n as Npc).npc_id == id:
			return n
	push_error("NPC no encontrado: " + id)
	return null


## Reproduce una conversación completa y devuelve el texto de cada línea mostrada.
## Falla si alguna línea quedó sin traducir (marcador "[id]") o vacía.
func _play(npc: Npc) -> Array:
	var shown: Array = []
	if not _dm.start_dialogue(npc):
		return shown
	var box: DialogueBox = _dm.dialogue_box
	while _dm.is_dialogue_open:
		var text: String = box.dialogue_label.text
		_check(not text.is_empty() and not text.begins_with("["), "línea con texto: '%s'" % text)
		shown.append(text)
		_dm.advance_dialogue()
		_dm.advance_dialogue()
	return shown


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("  FAIL - %s" % message)
