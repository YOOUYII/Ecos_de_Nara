extends SceneTree

## Prueba de flujo con los diálogos reales (sin ventana).
## Ejecutar: godot --headless --path . --script res://tests/test_npc_flow.gd

var _failures := 0
var _dm: Node
var _gestures: Array = []


func _initialize() -> void:
	_run()


func _run() -> void:
	var world: Node = load("res://scenes/world/world_test.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.3).timeout
	_dm = root.get_node("DialogueManager")
	var story: Node = root.get_node("StoryProgress")

	# Leni: primera conversación -> activa el flag; segunda -> línea distinta.
	var leni := _npc(world, "nina")
	_check(not story.has_flag("leni_met"), "Leni: flag leni_met parte apagado")
	var first := _play(leni)
	_check(first == ["Hallo! Ich bin Leni.", "Der Brunnen.", "Der Brunnen ist schön."], "Leni 1ª vez: %s" % [first])
	_check(story.has_flag("leni_met"), "Leni: leni_met activo tras la primera conversación")
	var second := _play(leni)
	_check(second == ["Der Brunnen ist in der Mitte."], "Leni 2ª vez: %s" % [second])

	# Helga (friendly) y Karl (wary): conservan su flujo base.
	var helga := _play(_npc(world, "panadera"))
	_check(helga == ["Guten Morgen!", "Das ist Brot.", "Das ist Wasser."], "Helga: %s" % [helga])
	var karl := _play(_npc(world, "guardia"))
	_check(karl == ["Halt!", "Wer bist du?", "Wald? Nein.", "Der Weg ist zu."], "Karl bloqueado: %s" % [karl])

	# Karl con la cesta: abre el bosque y completa la misión (misma lógica de efectos que antes).
	story.start_quest("favor_panadera", "Pan", "Lleva la cesta")
	story.add_item("cesta_pan")
	var karl_ok := _play(_npc(world, "guardia"))
	_check(karl_ok == ["Halt! Brot? Von Helga?", "Gut.", "Ich öffne den Weg.", "Achtung im Wald!", "Die Brücke."], "Karl con cesta: %s" % [karl_ok])
	_check(story.can_enter("bosque"), "Karl: bosque desbloqueado")
	_check(not story.has_item("cesta_pan"), "Karl: cesta retirada")
	_check(story.get_quest_status("favor_panadera") == Quest.Status.COMPLETED, "Karl: misión completada")
	var karl_open := _play(_npc(world, "guardia"))
	_check(karl_open == ["Der Weg ist offen.", "Achtung im Wald!"], "Karl con camino abierto: %s" % [karl_open])

	# Fritz (escena del bosque): conversación, gesto por línea y efectos intactos.
	world.queue_free()
	await process_frame
	var forest: Node = load("res://scenes/world/world_bosque.tscn").instantiate()
	root.add_child(forest)
	await create_timer(0.3).timeout
	_dm.load_zone_dialogues("bosque")
	var fritz := _npc(forest, "lenador")
	var fritz_lines := _play(fritz)
	_check(fritz_lines == ["Hallo! Ich bin Fritz.", "Das ist Holz.", "Die Brücke.", "Achtung!", "Der Schlüssel.", "Frag Maren."], "Fritz 1ª vez: %s" % [fritz_lines])
	_check(_gestures[0].ends_with("npc_lenador_gesto_cortar.png"), "Fritz: empieza cortando")
	_check(_gestures[4].ends_with("npc_lenador_gesto_entregar.png"), "Fritz: entrega la llave con el gesto 'entregar'")
	_check(story.has_item("llave_rio"), "Fritz: da la llave del río")
	_check(story.can_enter("rio"), "Fritz: río desbloqueado")
	_check(story.has_flag("met_fritz"), "Fritz: met_fritz activo")
	_check(story.get_quest_status("favor_lenador") == Quest.Status.ACTIVE, "Fritz: misión favor_lenador activa")
	var notebook: Node = root.get_node("Notebook")
	var keys: Dictionary = notebook.entries_by_key
	_check(keys.has("holz") and keys.has("schlüssel") and keys.has("brücke") and not keys.has("gefährlich"), "Fritz: libreta con Holz, Brücke y Schlüssel, sin gefährlich")
	var fritz_again := _play(fritz)
	_check(fritz_again == ["Frag Maren.", "Die Brücke."], "Fritz misión activa: %s" % [fritz_again])

	# Maren (escena del río): revelación, fragmento III traducible y escena final.
	forest.queue_free()
	await process_frame
	var river: Node = load("res://scenes/world/world_rio.tscn").instantiate()
	root.add_child(river)
	await create_timer(0.3).timeout
	var maren := _npc(river, "pescadora")
	var letter: Node = root.get_node("Letter")
	var maren_lines := _play(maren)
	_check(maren_lines == ["Wer bist du?", "Fritz? Gut. Ich bin Maren.", "Fisch.", "Unter der Brücke.", "Die Antwort.", "Geh nach Hause."], "Maren revelación: %s" % [maren_lines])
	_check(story.get_quest_status("favor_lenador") == Quest.Status.COMPLETED, "Maren: misión favor_lenador completada")
	_check(story.has_flag("met_maren"), "Maren: met_maren activo")
	_check(keys.has("antwort") and keys.has("hause") and keys.has("fisch") and not keys.has("fluss"), "Maren: libreta con Antwort, Hause y Fisch")

	# Las palabras clave de cada fragmento siguen existiendo y se pueden confirmar -> los 3 fragmentos se traducen.
	for word in ["Weg", "Wasser", "Brücke", "Schlüssel", "Antwort", "Hause"]:
		notebook.confirm_entry(word)
	for frag_id in ["fragment_1", "fragment_2", "fragment_3"]:
		_check(story.has_flag(frag_id + "_translated"), "Carta: %s traducido con el vocabulario reescrito" % frag_id)

	story.set_flag("demo_completed", true)
	var maren_final := _play(maren)
	_check(maren_final == ["Das Amulett!", "Du bist gut.", "Danke, Freund!", "Gute Reise!"], "Escena final: %s" % [maren_final])
	story.set_flag("demo_completed", false)
	var maren_done := _play(maren)
	_check(maren_done == ["Fisch.", "Unter der Brücke.", "Die Antwort."], "Maren misión completada: %s" % [maren_done])

	print("RESULTADO: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(_failures)


func _npc(world: Node, id: String) -> Npc:
	for n in world.find_children("*", "Npc", true, false):
		if (n as Npc).npc_id == id:
			return n
	push_error("NPC no encontrado: " + id)
	return null


## Reproduce una conversación completa y devuelve el texto de cada línea mostrada.
func _play(npc: Npc) -> Array:
	var shown: Array = []
	_gestures.clear()
	if not _dm.start_dialogue(npc):
		return shown
	var box: DialogueBox = _dm.dialogue_box
	while _dm.is_dialogue_open:
		shown.append(box.dialogue_label.text)
		_gestures.append(npc.gesture_sheet.resource_path if npc.gesture_sheet else "")
		_dm.advance_dialogue() # completa la línea
		_dm.advance_dialogue() # pasa a la siguiente / cierra
	return shown


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok  - %s" % message)
	else:
		_failures += 1
		print("  FAIL - %s" % message)
