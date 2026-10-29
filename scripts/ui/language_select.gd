extends Control

## Elección de idiomas al empezar una partida nueva. La elección queda bloqueada durante la partida.
## Los rótulos se muestran en todos los idiomas principales disponibles, porque aún no se ha elegido uno.

const LABELS := {
	"learn": {"es": "Quiero aprender", "en": "I want to learn", "de": "Ich möchte lernen", "eo": "Mi volas lerni"},
	"native": {"es": "Mi idioma", "en": "My language", "de": "Meine Sprache", "eo": "Mia lingvo"},
	"warning": {
		"es": "Esta elección no se puede cambiar durante la partida.",
		"en": "This choice cannot be changed during the game.",
		"de": "Diese Wahl kann während des Spiels nicht geändert werden.",
		"eo": "Ĉi tiu elekto ne povas esti ŝanĝita dum la ludo.",
	},
	"start": {"es": "Continuar", "en": "Continue", "de": "Weiter", "eo": "Daŭrigi"},
}

var target_option: OptionButton
var native_option: OptionButton
var start_button: Button


func _ready() -> void:
	_build_ui()
	_fill_targets()
	_refresh_natives()
	target_option.grab_focus()


func selected_target() -> String:
	return str(target_option.get_item_metadata(target_option.selected)) if target_option.item_count > 0 else ""


func selected_native() -> String:
	return str(native_option.get_item_metadata(native_option.selected)) if native_option.item_count > 0 else ""


func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/art/ui/ui_menu_fondo.png")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.07, 0.1, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(520, 0)
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)

	column.add_child(_label(_all_languages_text("learn"), 22))
	target_option = OptionButton.new()
	target_option.item_selected.connect(func(_index: int) -> void: _refresh_natives())
	column.add_child(target_option)

	column.add_child(_label(_all_languages_text("native"), 22))
	native_option = OptionButton.new()
	column.add_child(native_option)

	var warning := _label(_all_languages_text("warning"), 15)
	warning.add_theme_color_override("font_color", Color(0.96, 0.79, 0.37, 1))
	column.add_child(warning)

	start_button = Button.new()
	start_button.text = _all_languages_text("start", " / ")
	start_button.custom_minimum_size = Vector2(0, 40)
	start_button.pressed.connect(_on_start_pressed)
	column.add_child(start_button)


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.9, 1))
	return label


## Texto del rótulo en cada idioma principal disponible, unidos por "  /  ".
func _all_languages_text(key: String, separator := "  /  ") -> String:
	var parts: Array[String] = []
	for code in Lang.available_natives():
		parts.append(str((LABELS[key] as Dictionary).get(code, code)))
	return separator.join(parts)


func _fill_targets() -> void:
	target_option.clear()
	for code in Lang.available_targets():
		target_option.add_item(Lang.display_name(code))
		target_option.set_item_metadata(target_option.item_count - 1, code)


## Todos los idiomas aparecen siempre en "Mi idioma". El que se está aprendiendo no se puede elegir como
## principal: sale desactivado (y se elige otro) al cambiar el idioma a aprender.
func _refresh_natives() -> void:
	var previous := selected_native()
	native_option.clear()
	var first_enabled := -1
	var previous_index := -1
	for code in Lang.available_natives():
		native_option.add_item(Lang.display_name(code))
		var index := native_option.item_count - 1
		native_option.set_item_metadata(index, code)
		if code == selected_target():
			native_option.set_item_disabled(index, true)
			continue
		if first_enabled < 0:
			first_enabled = index
		if code == previous:
			previous_index = index
	var chosen := previous_index if previous_index >= 0 else first_enabled
	if chosen >= 0:
		native_option.select(chosen)
	start_button.disabled = chosen < 0 or target_option.item_count == 0


func _on_start_pressed() -> void:
	if GameManager.confirm_languages(selected_target(), selected_native()):
		GameManager.show_character_select()
