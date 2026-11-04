extends Node2D

## Controla la zona del río: NPCs, transiciones, interacción con el puente y notificaciones.

@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer
@onready var prompt_puente: Label = $Props/PuenteInteraccion/Prompt
@onready var amuleto_sprite: Sprite2D = $Props/PuenteInteraccion/AmuletoSprite

var player_near_bridge := false
var player_near_portal := false
var portal_sprite: AnimatedSprite2D
var portal_area: Area2D
var portal_prompt: Label


func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_RIO
	DialogueManager.load_zone_dialogues("rio")
	notice_panel.hide()
	prompt_puente.hide()
	
	if StoryProgress.has_flag("amulet_obtained") or StoryProgress.has_flag("demo_completed"):
		amuleto_sprite.show()
	else:
		amuleto_sprite.hide()
	_create_portal()
	if StoryProgress.has_flag("portal_opened") or StoryProgress.has_flag("demo_completed"):
		_show_portal(false)

	Letter.fragment_translated.connect(_on_fragment_translated)
	Letter.fragment_unlocked.connect(_on_fragment_unlocked)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		if DialogueManager.is_dialogue_open or Notebook.is_open or Letter.is_open:
			return
		if player_near_portal:
			_enter_portal()
		elif player_near_bridge:
			_inspect_bridge()
		get_viewport().set_input_as_handled()


func _inspect_bridge() -> void:
	if not StoryProgress.has_flag("fragment_3_translated"):
		_show_notice(tr("El agua corre bajo el puente de madera.\nDebes traducir el Fragmento III de la carta primero."))
		return

	if StoryProgress.has_flag("amulet_obtained"):
		_show_notice(tr("El Amuleto de Nara vibra hacia el este.\nBusca la puerta que apareció sobre el agua."))
		return

	# El amuleto ya no cierra la demo: despierta el portal hacia el enfrentamiento final.
	StoryProgress.set_flag("amulet_obtained", true)
	StoryProgress.add_item("amuleto_nara")
	StoryProgress.set_objective("El Amuleto de Nara reacciona. Algo te espera al este del puente.")
	if is_instance_valid(amuleto_sprite):
		amuleto_sprite.show()
	# Animación de logro; al terminar se muestra el aviso con la pista final.
	if is_instance_valid(amuleto_sprite) and not AchievementBanner.is_playing():
		AchievementBanner.finished.connect(_activate_portal, CONNECT_ONE_SHOT)
		AchievementBanner.play(
			amuleto_sprite.texture,
			tr("¡Logro desbloqueado!"),
			tr("Amuleto de Nara"),
			tr("El amuleto despierta una puerta sobre el agua.")
		)
	else:
		_activate_portal()


func _activate_portal() -> void:
	_show_portal(true)
	_show_notice(tr("El Amuleto abrió una puerta en el agua, al este del puente.\nAcércate y pulsa [E] para cruzarla."))


## Transición oeste → bosque
func _on_bosque_transition_body_entered(body: Node2D) -> void:
	if body is Player:
		GameManager.change_zone("bosque", Vector2(1200, 360), "left")


func _on_puente_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player_near_bridge = true
		prompt_puente.show()


func _on_puente_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_near_bridge = false
		prompt_puente.hide()


func _create_portal() -> void:
	portal_sprite = AnimatedSprite2D.new()
	portal_sprite.name = "PortalNara"
	portal_sprite.position = Vector2(930, 360)
	portal_sprite.z_index = 4
	portal_sprite.sprite_frames = _portal_frames()
	portal_sprite.hide()
	$Props.add_child(portal_sprite)

	portal_area = Area2D.new()
	portal_area.name = "PortalInteraccion"
	portal_area.position = Vector2(885, 360)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 58.0
	collision.shape = shape
	portal_area.add_child(collision)
	portal_prompt = Label.new()
	portal_prompt.position = Vector2(-92, -82)
	portal_prompt.size = Vector2(184, 30)
	portal_prompt.text = tr("E - Cruzar portal")
	portal_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portal_prompt.add_theme_font_size_override("font_size", 16)
	portal_prompt.add_theme_color_override("font_color", Color("9cecff"))
	portal_prompt.add_theme_color_override("font_outline_color", Color("10172c"))
	portal_prompt.add_theme_constant_override("outline_size", 4)
	portal_area.add_child(portal_prompt)
	portal_prompt.hide()
	portal_area.body_entered.connect(_on_portal_body_entered)
	portal_area.body_exited.connect(_on_portal_body_exited)
	portal_area.set_deferred("monitoring", false)
	$Props.add_child(portal_area)


func _show_portal(animated: bool) -> void:
	if not is_instance_valid(portal_sprite):
		return
	portal_sprite.show()
	if animated:
		portal_sprite.play("open")
		await portal_sprite.animation_finished
	portal_sprite.play("idle")
	portal_area.set_deferred("monitoring", true)
	StoryProgress.set_flag("portal_opened", true)


func _enter_portal() -> void:
	if not StoryProgress.has_flag("amulet_obtained") and not StoryProgress.has_flag("demo_completed"):
		return
	GameManager.change_zone("dimension", Vector2(400, 330), "right")


func _on_portal_body_entered(body: Node2D) -> void:
	if body is Player:
		player_near_portal = true
		portal_prompt.show()


func _on_portal_body_exited(body: Node2D) -> void:
	if body is Player:
		player_near_portal = false
		portal_prompt.hide()


func _portal_frames() -> SpriteFrames:
	var closed := load("res://assets/art/props/portal_nara_cerrado.png") as Texture2D
	var opening := load("res://assets/art/props/portal_nara_abrir_6f.png") as Texture2D
	var opened := load("res://assets/art/props/portal_nara_abierto_4f.png") as Texture2D
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("closed")
	frames.add_frame("closed", closed)
	frames.add_animation("open")
	frames.set_animation_speed("open", 8.0)
	frames.set_animation_loop("open", false)
	for index in 6:
		var atlas := AtlasTexture.new()
		atlas.atlas = opening
		atlas.region = Rect2(index * 96, 0, 96, 128)
		frames.add_frame("open", atlas)
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 5.0)
	frames.set_animation_loop("idle", true)
	for index in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = opened
		atlas.region = Rect2(index * 96, 0, 96, 128)
		frames.add_frame("idle", atlas)
	return frames


func _on_npc_interaction_requested(npc: Npc) -> void:
	DialogueManager.start_dialogue(npc)


func _on_npc_interaction_cancelled(npc: Npc) -> void:
	if DialogueManager.is_dialogue_open and DialogueManager.current_npc == npc:
		DialogueManager.close_dialogue()


func _on_fragment_translated(fragment: LetterFragment) -> void:
	_show_notice(tr("¡Has traducido el %s!\nRevisa tu carta con [C].") % fragment.title)


func _on_fragment_unlocked(fragment: LetterFragment) -> void:
	_show_notice(tr("¡Nuevo fragmento en la carta!\nPúlsa [C] para examinarlo."))


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
