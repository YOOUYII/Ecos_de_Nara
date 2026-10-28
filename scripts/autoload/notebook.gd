extends Node

## Libreta de la partida actual. El guardado persistente se incorporará después.
const NOTEBOOK_PANEL_SCENE := preload("res://scenes/ui/notebook_panel.tscn")

signal vocabulary_changed

var is_open := false
var entries_by_key: Dictionary = {}
var notebook_panel: NotebookPanel
var last_feedback := ""
var _entry_sequence := 0


func _ready() -> void:
	notebook_panel = NOTEBOOK_PANEL_SCENE.instantiate()
	add_child(notebook_panel)
	notebook_panel.close_requested.connect(close_notebook)
	notebook_panel.guess_requested.connect(try_confirm_entry)


func add_or_update_entry(
	word: String,
	meaning: String,
	context: String,
	confirmed := false,
	choices: Array[String] = [],
	correct_answer := ""
) -> void:
	var key := word.to_lower().strip_edges()
	if key.is_empty():
		return
	if entries_by_key.has(key):
		(entries_by_key[key] as VocabularyEntry).update(meaning, context, confirmed, choices, correct_answer)
	else:
		_entry_sequence += 1
		var new_entry := VocabularyEntry.new(word, meaning, context, confirmed, choices, correct_answer)
		new_entry.order_index = _entry_sequence
		entries_by_key[key] = new_entry
	vocabulary_changed.emit()
	if is_open:
		notebook_panel.show_notebook(get_entries(), last_feedback)


func register_effects(effects: Array) -> void:
	for effect in effects:
		if effect is Dictionary and effect.get("type", "vocabulary") == "vocabulary":
			var choices: Array[String] = []
			for choice in effect.get("choices", []):
				choices.append(str(choice))
			add_or_update_entry(
				str(effect.get("word", "")),
				str(effect.get("meaning", "")),
				str(effect.get("context", "")),
				bool(effect.get("confirmed", false)),
				choices,
				str(effect.get("answer", ""))
			)


func get_entries() -> Array[VocabularyEntry]:
	var entries: Array[VocabularyEntry] = []
	for entry in entries_by_key.values():
		entries.append(entry as VocabularyEntry)
	entries.sort_custom(func(first: VocabularyEntry, second: VocabularyEntry) -> bool: return first.order_index > second.order_index)
	return entries


func get_confirmed_words() -> Array[String]:
	var confirmed: Array[String] = []
	for entry in entries_by_key.values():
		var voc := entry as VocabularyEntry
		if voc and voc.is_confirmed:
			confirmed.append(voc.german.to_lower().strip_edges())
	return confirmed


func confirm_entry(word: String) -> void:
	var entry := entries_by_key.get(word.to_lower().strip_edges()) as VocabularyEntry
	if entry:
		entry.is_confirmed = true
		vocabulary_changed.emit()


func try_confirm_entry(word: String, guess: String) -> void:
	var entry := entries_by_key.get(word.to_lower().strip_edges()) as VocabularyEntry
	if entry == null:
		return
	if entry.try_confirm(guess):
		last_feedback = "¡Correcto! %s significa %s." % [entry.german, entry.spanish_meaning]
	else:
		last_feedback = "Esa hipótesis no encaja todavía. Observa de nuevo el contexto."
	vocabulary_changed.emit()
	if is_open:
		notebook_panel.show_notebook(get_entries(), last_feedback)


func open_notebook() -> void:
	if DialogueManager.is_dialogue_open or Letter.is_open:
		return
	is_open = true
	last_feedback = ""
	notebook_panel.show_notebook(get_entries(), last_feedback)


func close_notebook() -> void:
	is_open = false
	notebook_panel.hide_notebook()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("notebook") and not event.is_echo() and not DialogueManager.is_dialogue_open and not Letter.is_open:
		if is_open:
			close_notebook()
		else:
			open_notebook()
		get_viewport().set_input_as_handled()
