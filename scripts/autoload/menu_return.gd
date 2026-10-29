extends CanvasLayer

## Tecla R: pregunta si se quiere volver al menú de inicio. Con el aviso en pantalla el juego queda en pausa.
## Solo se ofrece dentro del mundo y sin otro panel abierto (diálogo, libreta o carta).
## Al confirmar se descarta la partida en curso: el progreso no guardado se pierde.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var message_label: Label
var confirm_button: Button
var cancel_button: Button


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS # sigue activo con el juego en pausa
	visible = false
	_build_ui()


func is_open() -> bool:
	return visible


## Solo dentro de una zona del mundo con partida iniciada y sin diálogo, libreta ni carta abiertos.
func can_open() -> bool:
	var scene := get_tree().current_scene
	if scene == null or not GameManager.has_selected_character():
		return false
	if not GameManager.ZONE_SCENES.values().has(scene.scene_file_path):
		return false
	return not (DialogueManager.is_dialogue_open or Notebook.is_open or Letter.is_open)


func open() -> void:
	message_label.text = tr("¿Seguro que quieres volver al menú de inicio?\n(Tu progreso se perderá si no lo has guardado)")
	confirm_button.text = tr("Volver al menú")
	cancel_button.text = tr("Cancelar")
	visible = true
	get_tree().paused = true
	cancel_button.grab_focus() # el botón seguro es el predeterminado


func close() -> void:
	visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("return_to_menu") and not event.is_echo() and can_open():
		open()
		get_viewport().set_input_as_handled()


func _on_confirm_pressed() -> void:
	close()
	GameManager.return_to_menu()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP # evita clics sobre el juego
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.11, 0.97)
	style.set_border_width_all(3)
	style.border_color = Color(0.82, 0.68, 0.32, 1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.9, 1))
	column.add_child(message_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)

	cancel_button = Button.new()
	cancel_button.custom_minimum_size = Vector2(200, 40)
	cancel_button.pressed.connect(close)
	buttons.add_child(cancel_button)

	confirm_button = Button.new()
	confirm_button.custom_minimum_size = Vector2(200, 40)
	confirm_button.pressed.connect(_on_confirm_pressed)
	buttons.add_child(confirm_button)
