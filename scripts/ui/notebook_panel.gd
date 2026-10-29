class_name NotebookPanel
extends CanvasLayer

signal close_requested
signal guess_requested(word: String, guess: String)

@onready var panel: PanelContainer = $NotebookRoot/Panel
@onready var entries_container: VBoxContainer = $NotebookRoot/Panel/MarginContainer/Content/EntriesScroll/EntriesContainer
@onready var close_button: Button = $NotebookRoot/Panel/MarginContainer/Content/CloseButton
@onready var feedback_label: Label = $NotebookRoot/Panel/MarginContainer/Content/FeedbackLabel

@export var entry_style: StyleBox


func _ready() -> void:
	hide_notebook()
	close_button.pressed.connect(func() -> void: close_requested.emit())


func show_notebook(entries: Array[VocabularyEntry], feedback := "") -> void:
	_clear_entries()
	feedback_label.text = feedback
	if entries.is_empty():
		_add_text_card(tr("Aún no has anotado palabras. Habla con los habitantes del pueblo."))
	else:
		for entry in entries:
			_add_vocabulary_card(entry)
	panel.show()


func hide_notebook() -> void:
	panel.hide()


func _clear_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()


func _add_text_card(content: String) -> void:
	var card := _create_card()
	var margins := card.get_child(0) as MarginContainer
	var entry_label := Label.new()
	entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry_label.add_theme_font_size_override("font_size", 18)
	entry_label.add_theme_color_override("font_color", Color(0.16, 0.12, 0.08, 1.0))
	entry_label.add_theme_constant_override("outline_size", 0)
	entry_label.text = content
	margins.add_child(entry_label)
	entries_container.add_child(card)


func _add_vocabulary_card(entry: VocabularyEntry) -> void:
	var card := _create_card()
	var margins := card.get_child(0) as MarginContainer
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margins.add_child(content)

	var word_label := Label.new()
	word_label.text = entry.german
	word_label.add_theme_font_size_override("font_size", 23)
	word_label.add_theme_color_override("font_color", Color(0.23, 0.12, 0.05, 1.0))
	content.add_child(word_label)

	var context_label := Label.new()
	context_label.text = tr("Pista visual: %s") % entry.context
	context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_label.add_theme_font_size_override("font_size", 16)
	context_label.add_theme_color_override("font_color", Color(0.28, 0.18, 0.1, 1.0))
	content.add_child(context_label)

	if entry.is_confirmed:
		var confirmed_label := Label.new()
		confirmed_label.text = tr("Confirmada: %s") % entry.spanish_meaning
		confirmed_label.add_theme_font_size_override("font_size", 18)
		confirmed_label.add_theme_color_override("font_color", Color(0.12, 0.36, 0.2, 1.0))
		content.add_child(confirmed_label)
	else:
		var hypothesis_label := Label.new()
		hypothesis_label.text = tr("Hipótesis: ¿qué significa?")
		hypothesis_label.add_theme_font_size_override("font_size", 17)
		hypothesis_label.add_theme_color_override("font_color", Color(0.48, 0.26, 0.08, 1.0))
		content.add_child(hypothesis_label)
		var choices_row := HBoxContainer.new()
		choices_row.add_theme_constant_override("separation", 8)
		for choice in entry.choices:
			var choice_button := Button.new()
			choice_button.text = choice
			choice_button.pressed.connect(func() -> void: guess_requested.emit(entry.german, choice))
			choices_row.add_child(choice_button)
		content.add_child(choices_row)
	entries_container.add_child(card)


func _create_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 104)
	if entry_style:
		card.add_theme_stylebox_override("panel", entry_style)
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_top", 10)
	margins.add_theme_constant_override("margin_right", 14)
	margins.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margins)
	return card
