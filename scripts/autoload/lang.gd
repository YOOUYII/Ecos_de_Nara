extends Node

## Idiomas del juego, en dos ejes independientes:
## - target: idioma que se aprende. Paquete de contenido: data/content/<código>.json
##   (palabra de cada concepto, texto de cada línea de diálogo y textos de la carta).
## - native: idioma del jugador. Paquete de glosa: data/gloss/<código>.json
##   (significados, opciones de verificación, contextos y traducción de la carta).
##
## Los idiomas se eligen solo al empezar una partida nueva y quedan bloqueados (`lock`):
## forman parte de la partida y se guardan y restauran con ella.

signal language_changed

const DEFAULT_TARGET := "de"
const DEFAULT_NATIVE := "es"
const CONTENT_PATH := "res://data/content/%s.json"
const GLOSS_PATH := "res://data/gloss/%s.json"
const REGISTRY_PATH := "res://data/languages.json"

var target := DEFAULT_TARGET
var native := DEFAULT_NATIVE
## Con la partida iniciada, los idiomas no se pueden cambiar.
var locked := false

var _registry: Dictionary = {}
var _content: Dictionary = {}
var _gloss: Dictionary = {}
var _concept_by_word: Dictionary = {}
var _ui_translation: Translation


func _ready() -> void:
	_registry = _read_json(REGISTRY_PATH)
	_reload()


## Cambia los idiomas. Devuelve false (sin cambios) si están bloqueados, coinciden o falta algún paquete.
func set_languages(new_target: String, new_native: String) -> bool:
	if locked:
		push_warning("Los idiomas no se pueden cambiar con la partida iniciada.")
		return false
	if new_target == new_native or not is_pair_available(new_target, new_native):
		return false
	target = new_target
	native = new_native
	_reload()
	language_changed.emit()
	return true


func lock() -> void:
	locked = true


func unlock() -> void:
	locked = false


## Vuelve a los idiomas por defecto y desbloquea (partida nueva).
func reset() -> void:
	locked = false
	set_languages(DEFAULT_TARGET, DEFAULT_NATIVE)


func is_pair_available(new_target: String, new_native: String) -> bool:
	return new_target in available_targets() and new_native in available_natives()


func available_targets() -> Array[String]:
	return _codes_with("content", CONTENT_PATH)


func available_natives() -> Array[String]:
	return _codes_with("gloss", GLOSS_PATH)


## Todas las combinaciones (aprender, principal) posibles; el idioma a aprender nunca es el principal.
func valid_pairs() -> Array:
	var pairs: Array = []
	for t in available_targets():
		for n in available_natives():
			if t != n:
				pairs.append([t, n])
	return pairs


## Solo hace falta pantalla de selección si hay más de una combinación posible.
func needs_selection() -> bool:
	return valid_pairs().size() > 1


func display_name(code: String) -> String:
	return str((_registry.get(code, {}) as Dictionary).get("name", code))


func has_line(line_id: String) -> bool:
	return (_content.get("lines", {}) as Dictionary).has(line_id)


## Convierte una línea del JSON (ID, String literal o Dictionary) en un Dictionary
## {text, icon_word?, icon?, gesture?, portrait?}. Un String que no es un ID se usa como texto literal.
func resolve_line(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		var out: Dictionary = (raw as Dictionary).duplicate()
		var line_id := str(out.get("id", ""))
		if not line_id.is_empty() and has_line(line_id):
			var entry := _entry_to_dict(line_id)
			for key in entry:
				if not out.has(key):
					out[key] = entry[key]
		elif not out.has("text"):
			out["text"] = "[%s]" % line_id
		return out
	var line := str(raw)
	if has_line(line):
		return _entry_to_dict(line)
	return {"text": line}


func word_for(concept: String) -> String:
	return str((_content.get("words", {}) as Dictionary).get(concept, ""))


## Concepto cuya palabra (en el idioma que se aprende) es `word`; "" si no existe.
func concept_for_word(word: String) -> String:
	return str(_concept_by_word.get(word.to_lower().strip_edges(), ""))


## {meaning, choices, answer} en el idioma principal; vacío si falta.
func concept_gloss(concept: String) -> Dictionary:
	return (_gloss.get("concepts", {}) as Dictionary).get(concept, {})


## Contexto de una palabra en el idioma principal. Un contexto "<id>@<idioma>" sustituye al "<id>"
## cuando se aprende ese idioma (para notas que citan palabras concretas de él).
func context_text(context_id: String) -> String:
	var contexts: Dictionary = _gloss.get("contexts", {})
	return str(contexts.get("%s@%s" % [context_id, target], contexts.get(context_id, "")))


## Texto de un fragmento de la carta en el idioma que se aprende.
func letter_text(fragment_id: String) -> String:
	return str((_content.get("letter", {}) as Dictionary).get(fragment_id, "[%s]" % fragment_id))


## {title, translation, hint} de un fragmento en el idioma principal.
func letter_gloss(fragment_id: String) -> Dictionary:
	return (_gloss.get("letter", {}) as Dictionary).get(fragment_id, {})


func _codes_with(kind: String, path_format: String) -> Array[String]:
	var codes: Array[String] = []
	for code in _registry:
		if bool((_registry[code] as Dictionary).get(kind, false)) and FileAccess.file_exists(path_format % code):
			codes.append(str(code))
	return codes


func _entry_to_dict(line_id: String) -> Dictionary:
	var entry: Variant = (_content["lines"] as Dictionary)[line_id]
	if entry is Dictionary:
		return (entry as Dictionary).duplicate()
	return {"text": str(entry)}


func _reload() -> void:
	_content = _read_json(CONTENT_PATH % target)
	_gloss = _read_json(GLOSS_PATH % native)
	_concept_by_word.clear()
	var words: Dictionary = _content.get("words", {})
	for concept in words:
		_concept_by_word[str(words[concept]).to_lower().strip_edges()] = concept
	_install_ui_translation()


## Textos de la interfaz: el identificador es el texto original en español (lo que está escrito en las
## escenas y en `tr("...")`); la sección "ui" del paquete de glosa lo traduce al idioma principal.
## Con el principal = español no hay traducciones y se muestran los textos originales.
func _install_ui_translation() -> void:
	if _ui_translation != null:
		TranslationServer.remove_translation(_ui_translation)
		_ui_translation = null
	TranslationServer.set_locale(native)
	var ui: Dictionary = _gloss.get("ui", {})
	if not ui.is_empty():
		_ui_translation = Translation.new()
		_ui_translation.locale = native
		for message_id in ui:
			_ui_translation.add_message(message_id, str(ui[message_id]))
		TranslationServer.add_translation(_ui_translation)
	# Los paneles que ya existen (libreta, carta, diálogo) se crearon antes de elegir idioma y Godot no
	# les avisa al añadir una traducción: se notifica a todo el árbol para que se actualicen.
	if is_inside_tree():
		get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se encontró el paquete de idioma: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("El paquete de idioma no es un objeto JSON válido: %s" % path)
	return {}
