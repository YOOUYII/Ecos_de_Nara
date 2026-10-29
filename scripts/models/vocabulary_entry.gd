class_name VocabularyEntry
extends RefCounted

## Una palabra o expresión descubierta durante una conversación.
var german := ""
var spanish_meaning := ""
var context := ""
var is_confirmed := false
var choices: Array[String] = []
var correct_answer := ""
var order_index: int = 0
## Concepto del paquete de idiomas y ID del contexto; vacíos en entradas antiguas.
## `spanish_meaning` es el significado en el idioma principal (hoy español).
var concept := ""
var context_id := ""


func _init(
	word: String = "",
	meaning: String = "",
	word_context: String = "",
	confirmed := false,
	word_choices: Array[String] = [],
	answer := ""
) -> void:
	german = word
	spanish_meaning = meaning
	context = word_context
	is_confirmed = confirmed
	choices = word_choices.duplicate()
	choices.shuffle()
	correct_answer = answer


func update(meaning: String, word_context: String, confirmed: bool, word_choices: Array[String], answer: String) -> void:
	if not meaning.is_empty():
		spanish_meaning = meaning
	if not word_context.is_empty():
		context = word_context
	is_confirmed = is_confirmed or confirmed
	if not word_choices.is_empty():
		choices = word_choices.duplicate()
		choices.shuffle()
	if not answer.is_empty():
		correct_answer = answer


func try_confirm(guess: String) -> bool:
	if guess.nocasecmp_to(correct_answer) == 0:
		is_confirmed = true
		return true
	return false
