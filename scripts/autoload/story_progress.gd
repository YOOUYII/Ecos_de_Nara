extends Node

## Estado de la historia, zonas, misiones y progreso narrativo.
## Conecta el aprendizaje de la carta con objetivos claros y favores del pueblo.

signal flag_changed(flag_name: String, value: bool)
signal objective_changed(new_objective: String)
signal zone_unlocked(zone_name: String)
signal quest_updated(quest_id: String, status: Quest.Status)
signal item_received(item_id: String)
signal item_removed(item_id: String)

const ZONE_PUEBLO := "pueblo"
const ZONE_BOSQUE := "bosque"
const ZONE_RIO := "rio"

const DEFAULT_OBJECTIVE := "Habla con los habitantes del pueblo, anota vocabulario (N) y revisa tu carta (C)."

var current_zone := ZONE_PUEBLO
var unlocked_zones := {
	ZONE_PUEBLO: true,
	ZONE_BOSQUE: false,
	ZONE_RIO: false,
}
var flags: Dictionary = {}
var current_objective := DEFAULT_OBJECTIVE

var quests: Dictionary = {}
var items: Array[String] = []


func can_enter(zone: String) -> bool:
	return unlocked_zones.get(zone, false)


func unlock_zone(zone: String) -> void:
	if unlocked_zones.has(zone) and not unlocked_zones[zone]:
		unlocked_zones[zone] = true
		zone_unlocked.emit(zone)


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String, value := true) -> void:
	var old_value: bool = flags.get(flag, false)
	flags[flag] = value
	if old_value != value:
		flag_changed.emit(flag, value)


func set_objective(objective: String) -> void:
	current_objective = objective
	objective_changed.emit(objective)


# --- Sistema de Misiones / Favores ---

func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id, null)


func get_quest_status(quest_id: String) -> Quest.Status:
	var q := get_quest(quest_id)
	if q:
		return q.status
	return Quest.Status.NOT_STARTED


func start_quest(quest_id: String, title: String = "", desc: String = "") -> void:
	var q := get_quest(quest_id)
	if q == null:
		q = Quest.new(quest_id, title, desc, Quest.Status.ACTIVE)
		quests[quest_id] = q
	else:
		q.status = Quest.Status.ACTIVE
	quest_updated.emit(quest_id, Quest.Status.ACTIVE)


func complete_quest(quest_id: String) -> void:
	var q := get_quest(quest_id)
	if q:
		q.status = Quest.Status.COMPLETED
		quest_updated.emit(quest_id, Quest.Status.COMPLETED)


# --- Sistema de Objetos de Misión ---

func has_item(item_id: String) -> bool:
	return items.has(item_id.to_lower().strip_edges())


func add_item(item_id: String) -> void:
	var clean_id := item_id.to_lower().strip_edges()
	if not items.has(clean_id):
		items.append(clean_id)
		item_received.emit(clean_id)


func remove_item(item_id: String) -> void:
	var clean_id := item_id.to_lower().strip_edges()
	if items.has(clean_id):
		items.erase(clean_id)
		item_removed.emit(clean_id)


# --- Serialización y Persistencia (Sección 10) ---

func serialize() -> Dictionary:
	var serialized_quests := {}
	for q_id in quests:
		var q: Quest = quests[q_id]
		if q:
			serialized_quests[q_id] = {
				"id": q.id,
				"title": q.title,
				"description": q.description,
				"status": int(q.status)
			}

	return {
		"current_zone": current_zone,
		"unlocked_zones": unlocked_zones.duplicate(),
		"flags": flags.duplicate(),
		"current_objective": current_objective,
		"quests": serialized_quests,
		"items": items.duplicate()
	}


func deserialize(data: Dictionary) -> void:
	current_zone = str(data.get("current_zone", ZONE_PUEBLO))
	unlocked_zones = {
		ZONE_PUEBLO: bool(data.get("unlocked_zones", {}).get(ZONE_PUEBLO, true)),
		ZONE_BOSQUE: bool(data.get("unlocked_zones", {}).get(ZONE_BOSQUE, false)),
		ZONE_RIO: bool(data.get("unlocked_zones", {}).get(ZONE_RIO, false)),
	}
	flags = (data.get("flags", {}) as Dictionary).duplicate()
	current_objective = str(data.get("current_objective", DEFAULT_OBJECTIVE))

	quests.clear()
	var raw_quests: Dictionary = data.get("quests", {})
	for q_id in raw_quests:
		var q_data: Dictionary = raw_quests[q_id]
		var status_val = int(q_data.get("status", 0))
		var q := Quest.new(
			str(q_data.get("id", q_id)),
			str(q_data.get("title", "")),
			str(q_data.get("description", "")),
			status_val as Quest.Status
		)
		quests[q_id] = q

	items.clear()
	for it in data.get("items", []):
		items.append(str(it))


func reset() -> void:
	current_zone = ZONE_PUEBLO
	unlocked_zones = {
		ZONE_PUEBLO: true,
		ZONE_BOSQUE: false,
		ZONE_RIO: false,
	}
	flags.clear()
	current_objective = DEFAULT_OBJECTIVE
	quests.clear()
	items.clear()
