class_name LetterFragment
extends RefCounted

## Representa un fragmento de la carta misteriosa.
## La traducción requiere que el jugador haya confirmado en su libreta
## todos los conceptos requeridos por el fragmento.

enum Status {
	LOCKED,       ## Aún no descubierto
	DISCOVERED,   ## Descubierto en la carta, texto en el idioma que se aprende pero sin traducir
	TRANSLATED,   ## Traducido al idioma principal tras confirmar el vocabulario necesario
}

var id := ""
var title := ""
var target_text := ""
var native_text := ""
var required_concepts: Array[String] = []
var status := Status.LOCKED
var objective_hint := ""


func _init(
	fragment_id: String = "",
	fragment_title: String = "",
	target: String = "",
	native: String = "",
	concepts: Array[String] = [],
	initial_status: Status = Status.LOCKED,
	hint: String = ""
) -> void:
	id = fragment_id
	title = fragment_title
	target_text = target
	native_text = native
	required_concepts = concepts
	status = initial_status
	objective_hint = hint


func is_translated() -> bool:
	return status == Status.TRANSLATED


func is_discovered() -> bool:
	return status == Status.DISCOVERED


func is_locked() -> bool:
	return status == Status.LOCKED


func check_translation(confirmed_concepts: Array[String]) -> bool:
	if status == Status.TRANSLATED:
		return true
	if status == Status.LOCKED:
		return false
	for concept in required_concepts:
		if not confirmed_concepts.has(concept):
			return false
	status = Status.TRANSLATED
	return true


func get_missing_concepts(confirmed_concepts: Array[String]) -> Array[String]:
	var missing: Array[String] = []
	for concept in required_concepts:
		if not confirmed_concepts.has(concept):
			missing.append(concept)
	return missing
