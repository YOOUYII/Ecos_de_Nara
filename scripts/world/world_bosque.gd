extends Node2D

## Controla la zona del bosque: NPCs, transiciones y notificaciones.

@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer

var river_gate: AnimatedSprite2D
var river_gate_collision: CollisionShape2D


func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_BOSQUE
	DialogueManager.load_zone_dialogues("bosque")
	notice_panel.hide()

	Letter.fragment_translated.connect(_on_fragment_translated)
	Letter.fragment_unlocked.connect(_on_fragment_unlocked)
	StoryProgress.zone_unlocked.connect(_on_zone_unlocked)
	_create_river_gate()
	if StoryProgress.can_enter(StoryProgress.ZONE_RIO):
		_open_river_gate(false)


## Transición sur → pueblo
func _on_pueblo_transition_body_entered(body: Node2D) -> void:
	if body is Player:
		GameManager.change_zone("pueblo", Vector2(640, 110), "down")


## Transición este → río
func _on_rio_transition_body_entered(body: Node2D) -> void:
	if body is Player:
		if StoryProgress.can_enter(StoryProgress.ZONE_RIO):
			GameManager.change_zone("rio", Vector2(80, 360), "right")
		else:
			_show_notice(tr("El camino al río está cerrado.\nEl leñador Fritz podría ayudarte."))


func _on_npc_interaction_requested(npc: Npc) -> void:
	DialogueManager.start_dialogue(npc)


func _on_npc_interaction_cancelled(npc: Npc) -> void:
	if DialogueManager.is_dialogue_open and DialogueManager.current_npc == npc:
		DialogueManager.close_dialogue()


func _on_fragment_translated(fragment: LetterFragment) -> void:
	_show_notice(tr("¡Has traducido el %s!\nRevisa tu carta con [C].") % fragment.title)


func _on_fragment_unlocked(fragment: LetterFragment) -> void:
	_show_notice(tr("¡Nuevo fragmento en la carta!\nPúlsa [C] para examinarlo."))


func _on_zone_unlocked(zone_name: String) -> void:
	if zone_name == StoryProgress.ZONE_RIO:
		_open_river_gate(true)
		_show_notice(tr("¡Camino al río desbloqueado!\nFritz te ha dado la llave para continuar al este."))


## La puerta es un objeto físico mientras el río está bloqueado. Al recibir la llave
## reproduce el sprite de apertura y deja libre la transición que ya existía.
func _create_river_gate() -> void:
	river_gate = AnimatedSprite2D.new()
	river_gate.name = "PuertaRio"
	river_gate.position = Vector2(1210, 360)
	river_gate.z_index = 3
	river_gate.sprite_frames = _gate_frames()
	river_gate.play("closed")
	add_child(river_gate)

	var body := StaticBody2D.new()
	body.name = "ColisionPuertaRio"
	body.position = river_gate.position
	river_gate_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 180)
	river_gate_collision.shape = shape
	body.add_child(river_gate_collision)
	add_child(body)


func _open_river_gate(animated: bool) -> void:
	if not is_instance_valid(river_gate):
		return
	if is_instance_valid(river_gate_collision):
		river_gate_collision.set_deferred("disabled", true)
	if animated:
		river_gate.play("open")
		await river_gate.animation_finished
	river_gate.hide()


func _gate_frames() -> SpriteFrames:
	var closed := load("res://assets/art/props/puerta_rio_cerrada.png") as Texture2D
	var opening := load("res://assets/art/props/puerta_rio_abrir_4f.png") as Texture2D
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("closed")
	frames.set_animation_loop("closed", true)
	frames.add_frame("closed", closed)
	frames.add_animation("open")
	frames.set_animation_speed("open", 7.0)
	frames.set_animation_loop("open", false)
	for index in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = opening
		atlas.region = Rect2(index * 96, 0, 96, 64)
		frames.add_frame("open", atlas)
	return frames


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
