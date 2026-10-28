extends Node

## Autoload de la Carta Misteriosa (Letter).
## Gestiona los fragmentos de texto en alemán que el jugador debe traducir
## asociando palabras confirmadas de su libreta para desbloquear progreso narrativo.

signal fragment_translated(fragment: LetterFragment)
signal fragment_unlocked(fragment: LetterFragment)
signal letter_opened
signal letter_closed

const LETTER_PANEL_SCENE := preload("res://scenes/ui/letter_panel.tscn")

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


func _init_fragments() -> void:
	fragments.clear()

	# Fragmento 1: Descubierto desde el inicio. Requiere "Weg" (camino) y "Wasser" (agua)
	var frag1 := LetterFragment.new(
		"fragment_1",
		"Fragmento I — El Camino y el Agua",
		"Lieber Freund, du musst den Weg zum Fluss finden. Das Wasser zeigt die Wahrheit.",
		"Querido amigo, debes encontrar el camino al río. El agua muestra la verdad.",
		["weg", "wasser"],
		LetterFragment.Status.DISCOVERED,
		"La panadera y el guardia conocen los caminos. Habla con ellos y averigua cómo llegar al río."
	)
	fragments.append(frag1)

	# Fragmento 2: Bloqueado (Sección 8/9, en el bosque)
	var frag2 := LetterFragment.new(
		"fragment_2",
		"Fragmento II — El Leñador y el Puente",
		"Der Holzfäller kennt die Brücke. Frage nach dem Schlüssel.",
		"El leñador conoce el puente. Pregunta por la llave.",
		["brücke", "schlüssel"],
		LetterFragment.Status.LOCKED,
		"Explora el bosque y busca al leñador."
	)
	fragments.append(frag2)

	# Fragmento 3: Bloqueado (Sección 9, en el río)
	var frag3 := LetterFragment.new(
		"fragment_3",
		"Fragmento III — La Respuesta en el Río",
		"Unter der Brücke liegt die Antwort. Geh nach Hause.",
		"Bajo el puente está la respuesta. Ve a casa.",
		["antwort", "hause"],
		LetterFragment.Status.LOCKED,
		"Acércate a la orilla del río y encuentra lo que hay bajo el puente."
	)
	fragments.append(frag3)


func _on_vocabulary_changed() -> void:
	var confirmed_words := Notebook.get_confirmed_words()
	for fragment in fragments:
		if fragment.is_discovered():
			var was_translated := fragment.is_translated()
			if fragment.check_translation(confirmed_words) and not was_translated:
				_on_fragment_translated(fragment)

	if is_open:
		letter_panel.show_letter(fragments, confirmed_words)


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
	letter_panel.show_letter(fragments, Notebook.get_confirmed_words())
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
