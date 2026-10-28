extends Node

## Lee el contenido desde JSON y controla una conversación activa.
## No contiene traducciones: el significado se registrará en la libreta (Sección 6).
signal dialogue_closed

const DIALOGUE_BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")
const DIALOGUE_DATA_PATH := "res://data/dialogues/pueblo.json"

var is_dialogue_open := false
var current_npc: Npc
var current_lines: Array = []
var current_line_index := 0
var current_portrait_path := ""
var dialogue_data: Dictionary = {}
var dialogue_box: DialogueBox


func _ready() -> void:
	_load_dialogue_data()
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)
	dialogue_box.advance_requested.connect(advance_dialogue)


func start_dialogue(npc: Npc) -> bool:
	if is_dialogue_open:
		return false
	var variant := _get_matching_variant(npc)
	if variant.is_empty():
		return false

	current_npc = npc
	# duplicate() evita vaciar las líneas guardadas en dialogue_data al cerrar.
	current_lines = (variant.get("lines", []) as Array).duplicate()
	current_portrait_path = variant.get("portrait", "")
	current_line_index = 0
	if current_lines.is_empty() or current_portrait_path.is_empty():
		return false

	is_dialogue_open = true
	_show_current_line()
	return true


func advance_dialogue() -> void:
	if not is_dialogue_open:
		return
	current_line_index += 1
	if current_line_index >= current_lines.size():
		close_dialogue()
		return
	_show_current_line()


func close_dialogue() -> void:
	if not is_dialogue_open:
		return
	is_dialogue_open = false
	current_npc = null
	current_lines.clear()
	dialogue_box.hide_dialogue()
	dialogue_closed.emit()


func _input(event: InputEvent) -> void:
	if is_dialogue_open and event.is_action_pressed("interact") and not event.is_echo():
		advance_dialogue()
		get_viewport().set_input_as_handled()


func _show_current_line() -> void:
	dialogue_box.show_line(
		current_npc.display_name,
		str(current_lines[current_line_index]),
		current_portrait_path,
		current_line_index == current_lines.size() - 1
	)


func _load_dialogue_data() -> void:
	var file := FileAccess.open(DIALOGUE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("No se encontró el archivo de diálogos: %s" % DIALOGUE_DATA_PATH)
		return
	var parsed_data = JSON.parse_string(file.get_as_text())
	if parsed_data is Dictionary:
		dialogue_data = parsed_data
	else:
		push_error("El archivo de diálogos no contiene un objeto JSON válido.")


func _get_matching_variant(npc: Npc) -> Dictionary:
	var npc_data: Dictionary = dialogue_data.get("dialogues", {}).get(npc.npc_id, {})
	for variant in npc_data.get("variants", []):
		if _condition_matches(variant.get("condition", {}), npc):
			return variant
	return {}


func _condition_matches(condition: Dictionary, npc: Npc) -> bool:
	var required_relationship := str(condition.get("relationship", ""))
	if not required_relationship.is_empty() and required_relationship != _relationship_name(npc.relationship):
		return false
	var required_flag := str(condition.get("progress_flag", ""))
	return required_flag.is_empty() or StoryProgress.has_flag(required_flag)


func _relationship_name(value: Npc.Relationship) -> String:
	match value:
		Npc.Relationship.FRIENDLY:
			return "friendly"
		Npc.Relationship.WARY:
			return "wary"
		_:
			return "neutral"
