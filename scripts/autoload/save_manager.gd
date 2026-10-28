extends Node

## Autoload del Sistema de Guardado y Carga Local (SaveManager).
## Serializa y deserializa el estado completo en user://savegame.json.
## Soporta guardado automático en eventos clave y guardado manual con F5.

signal game_saved(success: bool)
signal game_loaded(success: bool)

const SAVE_FILE_PATH := "user://savegame.json"

var _save_toast_layer: CanvasLayer
var _save_toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	_create_toast_ui()
	# Auto-guardado en eventos importantes
	StoryProgress.zone_unlocked.connect(func(_z): _on_auto_save_trigger())
	StoryProgress.quest_updated.connect(func(_q, _s): _on_auto_save_trigger())
	Letter.fragment_translated.connect(func(_f): _on_auto_save_trigger())


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


func delete_save() -> bool:
	if has_save():
		var dir := DirAccess.open("user://")
		if dir:
			return dir.remove("savegame.json") == OK
	return false


func save_game(position_override: Vector2 = Vector2.ZERO, show_toast: bool = true) -> bool:
	# No guardar en menús iniciales
	if not GameManager.has_selected_character():
		return false

	var player_pos := position_override
	if player_pos == Vector2.ZERO:
		var current_scene := get_tree().current_scene
		if current_scene:
			var player_node := current_scene.find_child("Player", true, false)
			if player_node is CharacterBody2D:
				player_pos = player_node.global_position

	if player_pos == Vector2.ZERO:
		player_pos = Vector2(640, 360)

	var save_dict := {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"game": {
			"character": GameManager.selected_character,
			"zone": StoryProgress.current_zone,
			"pos_x": player_pos.x,
			"pos_y": player_pos.y,
			"direction": GameManager.spawn_direction
		},
		"story": StoryProgress.serialize(),
		"notebook": Notebook.serialize(),
		"letter": Letter.serialize()
	}

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Error al abrir archivo para guardar: %s" % SAVE_FILE_PATH)
		game_saved.emit(false)
		return false

	var json_str := JSON.stringify(save_dict, "\t")
	file.store_string(json_str)
	file.close()

	if show_toast:
		show_save_notification("Partida guardada")

	game_saved.emit(true)
	return true


func load_game() -> bool:
	if not has_save():
		push_warning("No existe archivo de guardado.")
		game_loaded.emit(false)
		return false

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo leer el archivo de guardado.")
		game_loaded.emit(false)
		return false

	var raw_content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw_content)
	if not (parsed is Dictionary):
		push_error("El archivo de guardado no tiene formato JSON válido.")
		game_loaded.emit(false)
		return false

	var save_data: Dictionary = parsed
	var game_info: Dictionary = save_data.get("game", {})

	# Restaurar datos de subsistemas
	var char_type := str(game_info.get("character", "forastero"))
	GameManager.select_character(char_type)

	var zone: String = str(game_info.get("zone", "pueblo"))
	var spawn_pos := Vector2(
		float(game_info.get("pos_x", 640.0)),
		float(game_info.get("pos_y", 360.0))
	)
	var dir: String = str(game_info.get("direction", "down"))

	StoryProgress.deserialize(save_data.get("story", {}))
	Notebook.deserialize(save_data.get("notebook", {}))
	Letter.deserialize(save_data.get("letter", {}))

	# Reanudar en la escena correspondiente
	GameManager.resume_saved_game(zone, spawn_pos, dir)
	show_save_notification("Partida cargada")
	game_loaded.emit(true)
	return true


func _on_auto_save_trigger() -> void:
	if GameManager.has_selected_character():
		save_game(Vector2.ZERO, false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save") and not event.is_echo():
		if GameManager.has_selected_character() and not DialogueManager.is_dialogue_open:
			save_game()
			get_viewport().set_input_as_handled()


func show_save_notification(text: String) -> void:
	if not is_instance_valid(_save_toast_label):
		return
	_save_toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_save_toast_layer.visible = true
	_save_toast_label.modulate.a = 0.0
	_toast_tween.tween_property(_save_toast_label, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_save_toast_label, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): _save_toast_layer.visible = false)


func _create_toast_ui() -> void:
	_save_toast_layer = CanvasLayer.new()
	_save_toast_layer.layer = 100
	_save_toast_layer.visible = false
	add_child(_save_toast_layer)

	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -220
	panel.offset_top = 20
	panel.offset_right = -20
	panel.offset_bottom = 58

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.18, 0.92)
	style.border_color = Color(0.85, 0.72, 0.38, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	_save_toast_label = Label.new()
	_save_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_save_toast_label.add_theme_color_override("font_color", Color(1, 0.94, 0.77, 1))
	_save_toast_label.add_theme_font_size_override("font_size", 14)
	_save_toast_label.text = "Partida guardada"

	panel.add_child(_save_toast_label)
	_save_toast_layer.add_child(panel)
