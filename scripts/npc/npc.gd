class_name Npc
extends Area2D

## Base reutilizable para cualquier habitante interactuable.
## La conversación completa se conectará en la siguiente sección mediante DialogueManager.
signal interaction_requested(npc: Npc)
signal interaction_cancelled(npc: Npc)

enum Relationship {
	FRIENDLY,
	NEUTRAL,
	WARY,
}

@export var npc_id := ""
@export var display_name := "Habitante"
@export var relationship := Relationship.NEUTRAL

var player_in_range := false

@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	interaction_prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not event.is_echo():
		interaction_requested.emit(self)
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		interaction_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		var was_in_range := player_in_range
		player_in_range = false
		interaction_prompt.hide()
		if was_in_range:
			interaction_cancelled.emit(self)
