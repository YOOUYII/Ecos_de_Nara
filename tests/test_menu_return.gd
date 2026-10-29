extends SceneTree

## Tecla R: aviso para volver al menú de inicio.
## Ejecutar: godot --headless --path . --script res://tests/test_menu_return.gd
## Con personaje elegido el autoguardado escribe user://savegame.json: esta prueba no cambia misiones,
## zonas ni fragmentos, y abre diálogo/libreta poniendo sus banderas a mano, para no tocar la partida real.

var _failures := 0


func _initialize() -> void:
	_run()


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _run() -> void:
	await create_timer(0.3).timeout
	var game: Node = root.get_node("GameManager")
	var story: Node = root.get_node("StoryProgress")
	var lang: Node = root.get_node("Lang")
	var dialogue: Node = root.get_node("DialogueManager")
	var notebook: Node = root.get_node("Notebook")
	var menu: Node = root.get_node("MenuReturn")

	game.reset_all_data()
	_check(not menu.is_open(), "el aviso empieza cerrado")

	# Sin partida iniciada no se ofrece.
	var world: Node = load("res://scenes/world/world_test.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	menu._input(_key(KEY_R))
	_check(not menu.is_open() and not paused, "sin partida iniciada, R no hace nada")

	# Partida iniciada, en el mundo: R abre el aviso y pausa el juego.
	_check(game.confirm_languages("de", "en"), "idiomas de/en")
	game.select_character("forastero")
	story.set_flag("marca_de_prueba", true)
	menu._input(_key(KEY_R))
	_check(menu.is_open() and paused, "R abre el aviso y pausa el juego")
	_check(menu.message_label.text.begins_with("Are you sure you want to go back to the main menu?"), "el aviso se muestra en el idioma principal (inglés)")
	_check(menu.cancel_button.text == "Cancel" and menu.confirm_button.text == "Back to menu", "los botones se traducen")
	_check(menu.cancel_button.has_focus(), "el botón seguro (Cancelar) tiene el foco")

	# R con el aviso abierto no hace nada; Esc lo cierra y reanuda el juego.
	menu._input(_key(KEY_R))
	_check(menu.is_open(), "R con el aviso abierto no lo cierra")
	menu._input(_key(KEY_ESCAPE))
	_check(not menu.is_open() and not paused, "Esc cierra el aviso y reanuda el juego")

	# Cancelar conserva la partida.
	menu._input(_key(KEY_R))
	menu.cancel_button.pressed.emit()
	_check(not menu.is_open() and not paused, "Cancelar cierra el aviso")
	_check(game.has_selected_character() and story.has_flag("marca_de_prueba") and lang.locked, "Cancelar conserva la partida y los idiomas bloqueados")

	# Con diálogo, libreta o carta abiertos no se ofrece.
	dialogue.is_dialogue_open = true
	menu._input(_key(KEY_R))
	_check(not menu.is_open(), "con un diálogo abierto, R no hace nada")
	dialogue.is_dialogue_open = false
	notebook.is_open = true
	menu._input(_key(KEY_R))
	_check(not menu.is_open(), "con la libreta abierta, R no hace nada")
	notebook.is_open = false

	# Fuera del mundo (por ejemplo, en el menú) no se ofrece.
	var menu_scene: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu_scene)
	current_scene = menu_scene
	menu._input(_key(KEY_R))
	_check(not menu.is_open(), "fuera del mundo, R no hace nada")
	menu_scene.queue_free()
	current_scene = world

	# Confirmar descarta la partida y vuelve al menú.
	menu._input(_key(KEY_R))
	menu.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	_check(not menu.is_open() and not paused, "Confirmar cierra el aviso y reanuda el juego")
	_check(not game.has_selected_character() and not story.has_flag("marca_de_prueba"), "Confirmar descarta la partida en curso")
	_check(not lang.locked and lang.target == "de" and lang.native == "es", "Confirmar libera los idiomas (vuelven a los de por defecto)")
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "Confirmar lleva al menú de inicio")

	print("RESULTADO: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok  - %s" % message)
	else:
		_failures += 1
		print("  FAIL - %s" % message)
