extends Node

## Libreta de la partida actual. Registra vocabulario e hipótesis.
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
	Lang.language_changed.connect(refresh_gloss)


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


## Un efecto con `concept` toma la palabra del paquete de contenido y el significado, las opciones y el
## contexto del paquete de glosa. Un efecto con `word` y `meaning` incrustados se sigue aceptando.
func _register_concept_effect(effect: Dictionary) -> void:
	var concept := str(effect.get("concept", ""))
	var word := Lang.word_for(concept)
	var gloss := Lang.concept_gloss(concept)
	if word.is_empty() or gloss.is_empty():
		push_warning("Concepto sin palabra o sin glosa (%s/%s): %s" % [Lang.target, Lang.native, concept])
		return
	var meaning := str(gloss.get("meaning", ""))
	var context_id := str(effect.get("context_id", ""))
	add_or_update_entry(
		word,
		meaning,
		Lang.context_text(context_id),
		bool(effect.get("confirmed", false)),
		_to_string_array(gloss.get("choices", [])),
		str(gloss.get("answer", meaning))
	)
	var entry := entries_by_key.get(word.to_lower().strip_edges()) as VocabularyEntry
	if entry:
		entry.concept = concept
		entry.context_id = context_id


## Reaplica la glosa del idioma principal actual a las entradas que tienen concepto.
func refresh_gloss() -> void:
	for entry in entries_by_key.values():
		var voc := entry as VocabularyEntry
		if voc == null or voc.concept.is_empty():
			continue
		var gloss := Lang.concept_gloss(voc.concept)
		if gloss.is_empty():
			continue
		var meaning := str(gloss.get("meaning", ""))
		voc.update(
			meaning,
			Lang.context_text(voc.context_id),
			false,
			_to_string_array(gloss.get("choices", [])),
			str(gloss.get("answer", meaning))
		)
	vocabulary_changed.emit()
	if is_open:
		notebook_panel.show_notebook(get_entries(), last_feedback)


func _to_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(str(value))
	return out


func register_effects(effects: Array) -> void:
	for effect in effects:
		if effect is Dictionary and effect.has("concept") and effect.get("type", "vocabulary") == "vocabulary":
			_register_concept_effect(effect)
		elif effect is Dictionary and effect.get("type", "vocabulary") == "vocabulary":
			var choices: Array[String] = []
			for choice in effect.get("choices", []):
				choices.append(str(choice))
			var is_confirmed_val: bool = bool(effect.get("confirmed", false)) or (str(effect.get("status", "")) == "confirmed")
			var answer_val := str(effect.get("answer", ""))
			if answer_val.is_empty():
				answer_val = str(effect.get("meaning", ""))
			add_or_update_entry(
				str(effect.get("word", "")),
				str(effect.get("meaning", "")),
				str(effect.get("context", "")),
				is_confirmed_val,
				choices,
				answer_val
			)


func get_entries() -> Array[VocabularyEntry]:
	var entries: Array[VocabularyEntry] = []
	for entry in entries_by_key.values():
		entries.append(entry as VocabularyEntry)
	entries.sort_custom(func(first: VocabularyEntry, second: VocabularyEntry) -> bool: return first.order_index > second.order_index)
	return entries


## Conceptos cuya palabra el jugador ya confirmó (independiente del idioma que se aprende).
func get_confirmed_concepts() -> Array[String]:
	var confirmed: Array[String] = []
	for entry in entries_by_key.values():
		var voc := entry as VocabularyEntry
		if voc and voc.is_confirmed and not voc.concept.is_empty() and not confirmed.has(voc.concept):
			confirmed.append(voc.concept)
	return confirmed


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
		last_feedback = tr("¡Correcto! %s significa %s.") % [entry.german, entry.spanish_meaning]
	else:
		last_feedback = tr("Esa hipótesis no encaja todavía. Observa de nuevo el contexto.")
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


# --- Serialización y Persistencia (Sección 10) ---

func serialize() -> Dictionary:
	var list: Array[Dictionary] = []
	for key in entries_by_key:
		var entry: VocabularyEntry = entries_by_key[key]
		if entry:
			list.append({
				"word": entry.german,
				"meaning": entry.spanish_meaning,
				"context": entry.context,
				"is_confirmed": entry.is_confirmed,
				"choices": entry.choices.duplicate(),
				"correct_answer": entry.correct_answer,
				"order_index": entry.order_index,
				"concept": entry.concept,
				"context_id": entry.context_id
			})
	return {
		"entry_sequence": _entry_sequence,
		"entries": list
	}


func deserialize(data: Dictionary) -> void:
	entries_by_key.clear()
	_entry_sequence = int(data.get("entry_sequence", 0))
	last_feedback = ""
	for item in data.get("entries", []):
		if item is Dictionary:
			var choices: Array[String] = []
			for c in item.get("choices", []):
				choices.append(str(c))
			var entry := VocabularyEntry.new(
				str(item.get("word", "")),
				str(item.get("meaning", "")),
				str(item.get("context", "")),
				bool(item.get("is_confirmed", false)),
				choices,
				str(item.get("correct_answer", ""))
			)
			entry.order_index = int(item.get("order_index", 0))
			entry.concept = str(item.get("concept", ""))
			entry.context_id = str(item.get("context_id", ""))
			# Guardados anteriores no traen concepto: se deduce de la palabra.
			if entry.concept.is_empty():
				entry.concept = Lang.concept_for_word(entry.german)
			var key := entry.german.to_lower().strip_edges()
			entries_by_key[key] = entry
	refresh_gloss()


func reset() -> void:
	entries_by_key.clear()
	_entry_sequence = 0
	last_feedback = ""
	vocabulary_changed.emit()
