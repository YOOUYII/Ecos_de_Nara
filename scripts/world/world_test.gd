extends Node2D

## Controla únicamente el estado temporal de los accesos del pueblo.
## La composición visual del mapa permanece editable en world_test.tscn.
@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer


func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_PUEBLO
	notice_panel.hide()


func _on_forest_access_body_entered(body: Node2D) -> void:
	if body is Player and not StoryProgress.can_enter(StoryProgress.ZONE_BOSQUE):
		show_access_notice("El guardia bloquea el camino al bosque.\nNecesitas ganarte la confianza del pueblo.")


func _on_river_access_body_entered(body: Node2D) -> void:
	if body is Player and not StoryProgress.can_enter(StoryProgress.ZONE_RIO):
		show_access_notice("La ruta del río está cerrada.\nPrimero debes conseguir autorización.")


func show_access_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
