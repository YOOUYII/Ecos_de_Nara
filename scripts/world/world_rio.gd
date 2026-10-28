extends Node2D

## Controla la zona del río: NPCs, transiciones, interacción con el puente y notificaciones.

@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer
@onready var prompt_puente: Label = $Props/PuenteInteraccion/Prompt
@onready var amuleto_sprite: Sprite2D = $Props/PuenteInteraccion/AmuletoSprite

var player_near_bridge := false


func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_RIO
	DialogueManager.load_zone_dialogues("rio")
	notice_panel.hide()
	prompt_puente.hide()
	
	if StoryProgress.has_flag("demo_completed"):
		amuleto_sprite.show()
	else:
		amuleto_sprite.hide()

	Letter.fragment_translated.connect(_on_fragment_translated)
	Letter.fragment_unlocked.connect(_on_fragment_unlocked)


func _unhandled_input(event: InputEvent) -> void:
	if player_near_bridge and event.is_action_pressed("interact") and not event.is_echo():
		if DialogueManager.is_dialogue_open or Notebook.is_open or Letter.is_open:
			return
		_inspect_bridge()
		get_viewport().set_input_as_handled()


func _inspect_bridge() -> void:
	if not StoryProgress.has_flag("fragment_3_translated"):
		_show_notice("El agua corre bajo el puente de madera.\nDebes traducir el Fragmento III de la carta primero.")
		return

	if StoryProgress.has_flag("demo_completed"):
		_show_notice("Bajo el puente las aguas del río fluyen en paz.\nYa tienes el Amuleto de Nara.")
		return

	# Descubrimiento del secreto bajo el puente y cierre de la historia de la demo
	StoryProgress.set_flag("demo_completed", true)
	StoryProgress.add_item("amuleto_nara")
	StoryProgress.set_objective("¡Misterio completado! Has descifrado la carta y encontrado el Amuleto de Nara.")
	if is_instance_valid(amuleto_sprite):
		amuleto_sprite.show()
	_show_notice("¡Has encontrado el Amuleto de Nara bajo el puente!\n«Bajo el puente está la respuesta. Ve a casa.»\n¡Felicidades, has completado el misterio de la demo!")


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


func _on_npc_interaction_requested(npc: Npc) -> void:
	DialogueManager.start_dialogue(npc)


func _on_npc_interaction_cancelled(npc: Npc) -> void:
	if DialogueManager.is_dialogue_open and DialogueManager.current_npc == npc:
		DialogueManager.close_dialogue()


func _on_fragment_translated(fragment: LetterFragment) -> void:
	_show_notice("¡Has traducido el %s!\nRevisa tu carta con [C]." % fragment.title)


func _on_fragment_unlocked(fragment: LetterFragment) -> void:
	_show_notice("¡Nuevo fragmento en la carta!\nPúlsa [C] para examinarlo.")


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
