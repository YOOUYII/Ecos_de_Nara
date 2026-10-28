extends Node2D

## Controla el estado del pueblo, las notificaciones y el desbloqueo físico de zonas.
@onready var notice_panel: PanelContainer = $HUD/NoticePanel
@onready var notice_label: Label = $HUD/NoticePanel/MarginContainer/NoticeLabel
@onready var notice_timer: Timer = $HUD/NoticeTimer

@onready var barrera_bosque: Sprite2D = $Props/BarreraBosque
@onready var colision_barrera: CollisionShape2D = $Colisiones/StaticBody2D/CollisionShape2D
@onready var acceso_bosque: CollisionShape2D = $Accesos/BosqueBloqueado/CollisionShape2D

func _ready() -> void:
	StoryProgress.current_zone = StoryProgress.ZONE_PUEBLO
	DialogueManager.load_zone_dialogues("pueblo")
	notice_panel.hide()

	Letter.fragment_translated.connect(_on_fragment_translated)
	Letter.fragment_unlocked.connect(_on_fragment_unlocked)
	StoryProgress.zone_unlocked.connect(_on_zone_unlocked)

	# Si el bosque ya fue desbloqueado previamente, reflejarlo en la escena
	if StoryProgress.can_enter(StoryProgress.ZONE_BOSQUE):
		_open_forest_path(false)


func _on_forest_access_body_entered(body: Node2D) -> void:
	if body is Player and not StoryProgress.can_enter(StoryProgress.ZONE_BOSQUE):
		show_access_notice("El guardia bloquea el camino al bosque.\nNecesitas ganarte la confianza del pueblo.")


func _on_river_access_body_entered(body: Node2D) -> void:
	if body is Player and not StoryProgress.can_enter(StoryProgress.ZONE_RIO):
		show_access_notice("La ruta del río está cerrada.\nPrimero debes conseguir autorización.")


## Transición al bosque cuando el jugador cruza al norte
func _on_bosque_transition_body_entered(body: Node2D) -> void:
	if body is Player and StoryProgress.can_enter(StoryProgress.ZONE_BOSQUE):
		GameManager.change_zone("bosque", Vector2(640, 640), "up")


func _on_npc_interaction_requested(npc: Npc) -> void:
	DialogueManager.start_dialogue(npc)


func _on_npc_interaction_cancelled(npc: Npc) -> void:
	if DialogueManager.is_dialogue_open and DialogueManager.current_npc == npc:
		DialogueManager.close_dialogue()


func _on_fragment_translated(fragment: LetterFragment) -> void:
	show_access_notice("¡Has traducido el %s!\nRevisa tu carta con [C] para consultar tu nuevo objetivo." % fragment.title)


func _on_fragment_unlocked(fragment: LetterFragment) -> void:
	show_access_notice("¡Has descubierto un nuevo fragmento en la carta!\nPúlsala con [C] para examinarlo.")


func _on_zone_unlocked(zone_name: String) -> void:
	if zone_name == StoryProgress.ZONE_BOSQUE:
		_open_forest_path(true)


func _open_forest_path(animate: bool = true) -> void:
	if is_instance_valid(colision_barrera):
		colision_barrera.set_deferred("disabled", true)
	if is_instance_valid(acceso_bosque):
		acceso_bosque.set_deferred("disabled", true)

	if is_instance_valid(barrera_bosque):
		if animate:
			var tween := create_tween()
			tween.tween_property(barrera_bosque, "position:x", 585.0, 0.6)
			tween.parallel().tween_property(barrera_bosque, "modulate:a", 0.5, 0.6)
		else:
			barrera_bosque.position.x = 585.0
			barrera_bosque.modulate.a = 0.5

	if animate:
		show_access_notice("¡El camino hacia el bosque está abierto!\nEl guardia Karl te ha concedido el paso al norte.")


func show_access_notice(message: String) -> void:
	_show_notice(message)


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_panel.show()
	notice_timer.start()


func _on_notice_timer_timeout() -> void:
	notice_panel.hide()
