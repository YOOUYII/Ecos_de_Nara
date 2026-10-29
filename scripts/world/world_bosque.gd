extends Node2D

## Controla la zona del bosque: NPCs, transiciones y notificaciones.

@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer


func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_BOSQUE
	DialogueManager.load_zone_dialogues("bosque")
	notice_panel.hide()

	Letter.fragment_translated.connect(_on_fragment_translated)
	Letter.fragment_unlocked.connect(_on_fragment_unlocked)
	StoryProgress.zone_unlocked.connect(_on_zone_unlocked)


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
		_show_notice(tr("¡Camino al río desbloqueado!\nFritz te ha dado la llave para continuar al este."))


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
