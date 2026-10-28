extends Node2D

## Controla el estado del pueblo y las notificaciones de eventos narrativos.
@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer

func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_PUEBLO
	notice_panel.hide()
	Letter.fragment_translated.connect(_on_fragment_translated)
	Letter.fragment_unlocked.connect(_on_fragment_unlocked)


func _on_forest_access_body_entered(body: Node2D) -> void:
	if body is Player and not StoryProgress.can_enter(StoryProgress.ZONE_BOSQUE):
		show_access_notice("El guardia bloquea el camino al bosque.\nNecesitas ganarte la confianza del pueblo.")


func _on_river_access_body_entered(body: Node2D) -> void:
	if body is Player and not StoryProgress.can_enter(StoryProgress.ZONE_RIO):
		show_access_notice("La ruta del río está cerrada.\nPrimero debes conseguir autorización.")


func _on_npc_interaction_requested(npc: Npc) -> void:
	DialogueManager.start_dialogue(npc)


func _on_npc_interaction_cancelled(npc: Npc) -> void:
	if DialogueManager.is_dialogue_open and DialogueManager.current_npc == npc:
		DialogueManager.close_dialogue()


func _on_fragment_translated(fragment: LetterFragment) -> void:
	show_access_notice("¡Has traducido el %s!\nRevisa tu carta con [C] para consultar tu nuevo objetivo." % fragment.title)


func _on_fragment_unlocked(fragment: LetterFragment) -> void:
	show_access_notice("¡Has descubierto un nuevo fragmento en la carta!\nPúlsala con [C] para examinarlo.")


func show_access_notice(message: String) -> void:
	_show_notice(message)


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
