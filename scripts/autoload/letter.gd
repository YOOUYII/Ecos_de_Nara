extends Node

## Autoload de la Carta Misteriosa (Letter).
## Gestiona los fragmentos de texto en el idioma que se aprende que el jugador debe traducir
## asociando conceptos confirmados de su libreta para desbloquear progreso narrativo.

signal fragment_translated(fragment: LetterFragment)
signal fragment_unlocked(fragment: LetterFragment)
signal letter_opened
signal letter_closed

const LETTER_PANEL_SCENE := preload("res://scenes/ui/letter_panel.tscn")
const LETTER_DATA_PATH := "res://data/letter.json"

var is_open := false
var letter_panel: LetterPanel
var fragments: Array[LetterFragment] = []


func _ready() -> void:
	_init_fragments()
	letter_panel = LETTER_PANEL_SCENE.instantiate()
	add_child(letter_panel)
	letter_panel.close_requested.connect(close_letter)

	# Se conecta a la libreta para evaluar automáticamente si se pueden traducir fragmentos
	Notebook.vocabulary_changed.connect(_on_vocabulary_changed)
	# Al elegir o restaurar los idiomas de una partida, los fragmentos se reconstruyen en ellos.
	Lang.language_changed.connect(_init_fragments)


## Reconstruye los fragmentos: estructura en data/letter.json (IDs, estado inicial y conceptos
## requeridos), texto en el idioma que se aprende y título, traducción y pista en el principal.
## Solo se llama al empezar una partida o al cargarla, nunca con la partida en curso (los idiomas están bloqueados).
func _init_fragments() -> void:
	fragments.clear()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LETTER_DATA_PATH))
	if not (data is Dictionary):
		push_error("No se pudo leer la estructura de la carta: %s" % LETTER_DATA_PATH)
		return
	for item in (data as Dictionary).get("fragments", []):
		var fragment_id := str(item.get("id", ""))
		var gloss := Lang.letter_gloss(fragment_id)
		var concepts: Array[String] = []
		for concept in item.get("required_concepts", []):
			concepts.append(str(concept))
		var initial := LetterFragment.Status.LOCKED
		if str(item.get("initial_status", "locked")) == "discovered":
			initial = LetterFragment.Status.DISCOVERED
		fragments.append(LetterFragment.new(
			fragment_id,
			str(gloss.get("title", fragment_id)),
			Lang.letter_text(fragment_id),
			str(gloss.get("translation", "")),
			concepts,
			initial,
			str(gloss.get("hint", ""))
		))


func _on_vocabulary_changed() -> void:
	var confirmed := Notebook.get_confirmed_concepts()
	for fragment in fragments:
		if fragment.is_discovered():
			var was_translated := fragment.is_translated()
			if fragment.check_translation(confirmed) and not was_translated:
				_on_fragment_translated(fragment)

	if is_open:
		letter_panel.show_letter(fragments, confirmed)


func _on_fragment_translated(fragment: LetterFragment) -> void:
	StoryProgress.set_flag("%s_translated" % fragment.id, true)
	StoryProgress.set_objective(fragment.objective_hint)
	fragment_translated.emit(fragment)


func get_fragment(id: String) -> LetterFragment:
	for fragment in fragments:
		if fragment.id == id:
			return fragment
	return null


func unlock_fragment(id: String) -> void:
	var fragment := get_fragment(id)
	if fragment and fragment.is_locked():
		fragment.status = LetterFragment.Status.DISCOVERED
		fragment_unlocked.emit(fragment)
		# Evalúa si ya tenía las palabras
		_on_vocabulary_changed()


func open_letter() -> void:
	if DialogueManager.is_dialogue_open or Notebook.is_open:
		return
	is_open = true
	letter_panel.show_letter(fragments, Notebook.get_confirmed_concepts())
	letter_opened.emit()


func close_letter() -> void:
	is_open = false
	letter_panel.hide_letter()
	letter_closed.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("letter") and not event.is_echo():
		if DialogueManager.is_dialogue_open or Notebook.is_open:
			return
		if is_open:
			close_letter()
		else:
			open_letter()
		get_viewport().set_input_as_handled()


# --- Serialización y Persistencia (Sección 10) ---

func serialize() -> Dictionary:
	var list: Array[Dictionary] = []
	for frag in fragments:
		list.append({
			"id": frag.id,
			"status": int(frag.status)
		})
	return { "fragments": list }


func deserialize(data: Dictionary) -> void:
	var frag_map := {}
	for f in data.get("fragments", []):
		if f is Dictionary:
			frag_map[str(f.get("id", ""))] = int(f.get("status", 0))
	for frag in fragments:
		if frag_map.has(frag.id):
			var status_val = frag_map[frag.id]
			frag.status = status_val as LetterFragment.Status


func reset() -> void:
	_init_fragments()
