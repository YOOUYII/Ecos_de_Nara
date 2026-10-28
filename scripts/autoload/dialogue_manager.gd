extends Node

## Autoload del sistema de diálogo.
## Lee los datos desde JSON, evalúa variantes por relación, flags, misiones e items,
## y aplica efectos narrativos y de vocabulario al cerrar.

signal dialogue_opened(npc: Npc)
signal dialogue_closed

const DIALOGUE_DATA_PATH := "res://data/dialogues/pueblo.json"
const DIALOGUE_BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")

var is_dialogue_open := false
var current_npc: Npc
var current_lines: Array = []
var current_effects: Array = []
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
	if is_dialogue_open or Notebook.is_open or Letter.is_open:
		return false
	var variant := _get_matching_variant(npc)
	if variant.is_empty():
		return false

	current_npc = npc
	current_lines = (variant.get("lines", []) as Array).duplicate()
	current_effects = (variant.get("effects", []) as Array).duplicate(true)
	current_portrait_path = variant.get("portrait", "")
	current_line_index = 0
	if current_lines.is_empty() or current_portrait_path.is_empty():
		return false

	# Si la variante define un gesto especial (ej. guardia aprobando paso)
	var gesture_override := str(variant.get("gesture", ""))
	if not gesture_override.is_empty():
		var g_tex := load(gesture_override) as Texture2D
		if g_tex:
			current_npc.set_gesture_sheet(g_tex)

	is_dialogue_open = true
	current_npc.play_context_gesture()
	_show_current_line()
	dialogue_opened.emit(current_npc)
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
	current_npc.stop_context_gesture()
	_process_dialogue_effects(current_effects)
	current_npc = null
	current_lines.clear()
	current_effects.clear()
	dialogue_box.hide_dialogue()
	dialogue_closed.emit()


func _process_dialogue_effects(effects: Array) -> void:
	Notebook.register_effects(effects)
	for effect_data in effects:
		if not (effect_data is Dictionary):
			continue
		var eff: Dictionary = effect_data
		var effect_type := str(eff.get("type", ""))
		match effect_type:
			"start_quest":
				var q_id := str(eff.get("quest_id", ""))
				StoryProgress.start_quest(q_id, str(eff.get("title", "")), str(eff.get("desc", "")))
			"complete_quest":
				var q_id := str(eff.get("quest_id", ""))
				StoryProgress.complete_quest(q_id)
			"give_item":
				var it_id := str(eff.get("item_id", ""))
				StoryProgress.add_item(it_id)
			"take_item":
				var it_id := str(eff.get("item_id", ""))
				StoryProgress.remove_item(it_id)
			"unlock_zone":
				var z_id := str(eff.get("zone", ""))
				StoryProgress.unlock_zone(z_id)
			"unlock_fragment":
				var f_id := str(eff.get("fragment_id", ""))
				Letter.unlock_fragment(f_id)
			"set_flag":
				var fl := str(eff.get("flag", ""))
				StoryProgress.set_flag(fl, eff.get("value", true))
			"set_objective":
				var obj := str(eff.get("objective", ""))
				StoryProgress.set_objective(obj)


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
	if condition.is_empty():
		return true

	# 1. Relación con el NPC
	var required_relationship := str(condition.get("relationship", ""))
	if not required_relationship.is_empty() and required_relationship != _relationship_name(npc.relationship):
		return false

	# 2. Flag narrativo
	var required_flag := str(condition.get("flag", condition.get("progress_flag", "")))
	if not required_flag.is_empty() and not StoryProgress.has_flag(required_flag):
		return false

	# 3. Estado de misión
	var quest_id := str(condition.get("quest", ""))
	if not quest_id.is_empty():
		var expected_status := str(condition.get("quest_status", "active")).to_lower()
		var actual_status := StoryProgress.get_quest_status(quest_id)
		match expected_status:
			"not_started":
				if actual_status != Quest.Status.NOT_STARTED:
					return false
			"active":
				if actual_status != Quest.Status.ACTIVE:
					return false
			"completed":
				if actual_status != Quest.Status.COMPLETED:
					return false

	# 4. Item en posesión
	var required_item := str(condition.get("item", ""))
	if not required_item.is_empty() and not StoryProgress.has_item(required_item):
		return false

	# 5. Zona desbloqueada
	var required_zone := str(condition.get("zone_unlocked", ""))
	if not required_zone.is_empty() and not StoryProgress.can_enter(required_zone):
		return false

	return true


func _relationship_name(value: Npc.Relationship) -> String:
	match value:
		Npc.Relationship.FRIENDLY:
			return "friendly"
		Npc.Relationship.WARY:
			return "wary"
		_:
			return "neutral"
