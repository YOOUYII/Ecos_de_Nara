class_name LetterPanel
extends CanvasLayer

signal close_requested

@onready var panel: PanelContainer = $LetterRoot/Panel
@onready var fragments_container: VBoxContainer = $LetterRoot/Panel/MarginContainer/Content/FragmentsScroll/FragmentsContainer
@onready var close_button: Button = $LetterRoot/Panel/MarginContainer/Content/CloseButton

const TEX_SLOT_PARCHMENT := preload("res://assets/art/ui/ui_libreta_slot_entrada_9slice.png")
const TEX_SLOT_LOCKED := preload("res://assets/art/ui/ui_seleccion_tarjeta_9slice.png")
const ICON_CHECK := preload("res://assets/art/ui/ui_icono_check.png")
const ICON_LOCK := preload("res://assets/art/ui/ui_icono_candado.png")
const ICON_LETTER := preload("res://assets/art/ui/ui_icono_carta.png")


func _ready() -> void:
	hide_letter()
	close_button.pressed.connect(func() -> void: close_requested.emit())


func show_letter(fragments: Array[LetterFragment], confirmed_words: Array[String]) -> void:
	_clear_fragments()
	for fragment in fragments:
		_add_fragment_card(fragment, confirmed_words)
	panel.show()


func hide_letter() -> void:
	panel.hide()


func _clear_fragments() -> void:
	for child in fragments_container.get_children():
		child.queue_free()


func _add_fragment_card(fragment: LetterFragment, confirmed_words: Array[String]) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var style := StyleBoxTexture.new()
	if fragment.is_locked():
		style.texture = TEX_SLOT_LOCKED
		style.texture_margin_left = 10.0
		style.texture_margin_top = 10.0
		style.texture_margin_right = 10.0
		style.texture_margin_bottom = 10.0
	else:
		style.texture = TEX_SLOT_PARCHMENT
		style.texture_margin_left = 6.0
		style.texture_margin_top = 6.0
		style.texture_margin_right = 6.0
		style.texture_margin_bottom = 6.0
	card.add_theme_stylebox_override("panel", style)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 16)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_right", 16)
	margins.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margins.add_child(content)

	# Fila superior: Título del fragmento + Icono de estado
	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_child(header_row)

	var title_lbl := Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 17)
	header_row.add_child(title_lbl)

	var status_icon := TextureRect.new()
	status_icon.custom_minimum_size = Vector2(24, 24)
	status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_row.add_child(status_icon)

	if fragment.is_locked():
		title_lbl.text = fragment.title
		title_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.7, 0.9))
		status_icon.texture = ICON_LOCK

		var locked_lbl := Label.new()
		locked_lbl.text = "Fragmento aún no descubierto. Explora el mundo para encontrarlo."
		locked_lbl.add_theme_font_size_override("font_size", 14)
		locked_lbl.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55, 0.8))
		locked_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(locked_lbl)

	elif fragment.is_discovered():
		title_lbl.text = "%s  (En alemán)" % fragment.title
		title_lbl.add_theme_color_override("font_color", Color(0.28, 0.16, 0.08, 1.0))
		status_icon.texture = ICON_LETTER

		var german_lbl := Label.new()
		german_lbl.text = "\"%s\"" % fragment.german_text
		german_lbl.add_theme_font_size_override("font_size", 16)
		german_lbl.add_theme_color_override("font_color", Color(0.2, 0.12, 0.06, 1.0))
		german_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(german_lbl)

		var words_status_lbl := Label.new()
		var parts: Array[String] = []
		for word in fragment.required_words:
			var is_confirmed: bool = confirmed_words.has(word.to_lower().strip_edges())
			if is_confirmed:
				parts.append("[✓ %s]" % word)
			else:
				parts.append("[⏳ %s]" % word)
		words_status_lbl.text = "Palabras necesarias en tu libreta: %s" % ", ".join(parts)
		words_status_lbl.add_theme_font_size_override("font_size", 14)
		words_status_lbl.add_theme_color_override("font_color", Color(0.48, 0.25, 0.08, 1.0))
		content.add_child(words_status_lbl)

	else: # TRANSLATED
		title_lbl.text = "%s  (Traducido)" % fragment.title
		title_lbl.add_theme_color_override("font_color", Color(0.12, 0.42, 0.2, 1.0))
		status_icon.texture = ICON_CHECK

		var german_sub := Label.new()
		german_sub.text = "\"%s\"" % fragment.german_text
		german_sub.add_theme_font_size_override("font_size", 13)
		german_sub.add_theme_color_override("font_color", Color(0.45, 0.35, 0.25, 0.85))
		german_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(german_sub)

		var translation_lbl := Label.new()
		translation_lbl.text = "«%s»" % fragment.spanish_text
		translation_lbl.add_theme_font_size_override("font_size", 16)
		translation_lbl.add_theme_color_override("font_color", Color(0.16, 0.11, 0.05, 1.0))
		translation_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(translation_lbl)

		if not fragment.objective_hint.is_empty():
			var hint_lbl := Label.new()
			hint_lbl.text = "🎯 Siguiente paso: %s" % fragment.objective_hint
			hint_lbl.add_theme_font_size_override("font_size", 14)
			hint_lbl.add_theme_color_override("font_color", Color(0.1, 0.38, 0.45, 1.0))
			hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(hint_lbl)

	fragments_container.add_child(card)
