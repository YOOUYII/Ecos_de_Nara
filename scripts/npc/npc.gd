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
@export var gesture_sheet: Texture2D

var player_in_range := false

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var npc_sprite: Sprite2D = $NpcSprite
@onready var gesture_sprite: AnimatedSprite2D = $GestureSprite


func _ready() -> void:
	interaction_prompt.hide()
	gesture_sprite.hide()
	if gesture_sheet:
		_configure_gesture()


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


func play_context_gesture() -> void:
	if gesture_sheet == null:
		return
	npc_sprite.hide()
	gesture_sprite.show()
	gesture_sprite.play(&"gesture")


func stop_context_gesture() -> void:
	gesture_sprite.stop()
	gesture_sprite.hide()
	npc_sprite.show()


func _configure_gesture() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"gesture")
	frames.set_animation_speed(&"gesture", 6.0)
	frames.set_animation_loop(&"gesture", true)
	for frame_index in 4:
		var frame := AtlasTexture.new()
		frame.atlas = gesture_sheet
		frame.region = Rect2(frame_index * 32, 0, 32, 48)
		frames.add_frame(&"gesture", frame)
	gesture_sprite.sprite_frames = frames
