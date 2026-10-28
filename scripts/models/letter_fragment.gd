class_name LetterFragment
extends RefCounted

## Representa un fragmento de la carta misteriosa.
## La traducción requiere que el jugador haya confirmado en su libreta
## todas las palabras en alemán requeridas por el fragmento.

enum Status {
	LOCKED,       ## Aún no descubierto
	DISCOVERED,   ## Descubierto en la carta, texto en alemán pero sin traducir
	TRANSLATED,   ## Traducido al español tras confirmar el vocabulario necesario
}

var id := ""
var title := ""
var german_text := ""
var spanish_text := ""
var required_words: Array[String] = []
var status := Status.LOCKED
var objective_hint := ""


func _init(
	fragment_id: String = "",
	fragment_title: String = "",
	german: String = "",
	spanish: String = "",
	words: Array[String] = [],
	initial_status: Status = Status.LOCKED,
	hint: String = ""
) -> void:
	id = fragment_id
	title = fragment_title
	german_text = german
	spanish_text = spanish
	required_words = words
	status = initial_status
	objective_hint = hint


func is_translated() -> bool:
	return status == Status.TRANSLATED


func is_discovered() -> bool:
	return status == Status.DISCOVERED


func is_locked() -> bool:
	return status == Status.LOCKED


func check_translation(confirmed_words: Array[String]) -> bool:
	if status == Status.TRANSLATED:
		return true
	if status == Status.LOCKED:
		return false
	for word in required_words:
		if not confirmed_words.has(word.to_lower().strip_edges()):
			return false
	status = Status.TRANSLATED
	return true


func get_missing_words(confirmed_words: Array[String]) -> Array[String]:
	var missing: Array[String] = []
	for word in required_words:
		if not confirmed_words.has(word.to_lower().strip_edges()):
			missing.append(word)
	return missing
