class_name Player
extends CharacterBody2D

@export var speed := 180.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	_update_visual(direction, delta)

func _update_visual(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		var animation_name := _get_walk_animation(direction)
		if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
			animated_sprite.play(animation_name)
	else:
		animated_sprite.pause()
		animated_sprite.frame = 0

func _get_walk_animation(direction: Vector2) -> StringName:
	if abs(direction.x) > abs(direction.y):
		return &"walk_right" if direction.x > 0.0 else &"walk_left"
	return &"walk_down" if direction.y > 0.0 else &"walk_up"
