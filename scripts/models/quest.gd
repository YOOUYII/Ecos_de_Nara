class_name Quest
extends RefCounted

## Modelo de misión narrativa simple para Ecos de Nara.

enum Status {
	NOT_STARTED,
	ACTIVE,
	COMPLETED
}

var id := ""
var title := ""
var description := ""
var status := Status.NOT_STARTED


func _init(quest_id: String = "", quest_title: String = "", quest_desc: String = "", initial_status: Status = Status.NOT_STARTED) -> void:
	id = quest_id
	title = quest_title
	description = quest_desc
	status = initial_status


func is_not_started() -> bool:
	return status == Status.NOT_STARTED


func is_active() -> bool:
	return status == Status.ACTIVE


func is_completed() -> bool:
	return status == Status.COMPLETED
