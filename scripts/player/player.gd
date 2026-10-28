class_name Player
extends CharacterBody2D

@export var speed := 180.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const FORASTERO_SHEET := preload("res://assets/art/characters/player/forastero_sheet.png")
const FORASTERA_SHEET := preload("res://assets/art/characters/player/forastera_sheet.png")

func _ready() -> void:
	var character_sheet := FORASTERO_SHEET if GameManager.selected_character == GameManager.CHARACTER_FORASTERO else FORASTERA_SHEET
	for animation_name in animated_sprite.sprite_frames.get_animation_names():
		for frame_index in range(animated_sprite.sprite_frames.get_frame_count(animation_name)):
			var frame_texture := animated_sprite.sprite_frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
			if frame_texture:
				frame_texture.atlas = character_sheet

	# Posicionar al jugador en el punto de spawn si viene de otra zona
	if GameManager.spawn_position != Vector2.ZERO:
		global_position = GameManager.spawn_position
		GameManager.spawn_position = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if DialogueManager.is_dialogue_open or Notebook.is_open or Letter.is_open:
		velocity = Vector2.ZERO
		_update_visual(Vector2.ZERO)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	_update_visual(direction)

func _update_visual(direction: Vector2) -> void:
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
