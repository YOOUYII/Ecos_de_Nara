extends Node2D

## Arena del Espejo: contiene el combate final y devuelve al jugador al río si pierde.

@onready var battle: EchoBattle = $EchoBattle


func _ready() -> void:
	StoryProgress.current_zone = "dimension"
	battle.victory.connect(_on_victory)
	battle.defeat.connect(_on_defeat)
	battle.start_battle()


func _on_defeat() -> void:
	StoryProgress.set_objective("El Eco te expulsó de la dimensión. Puedes volver al portal y reintentarlo.")
	GameManager.change_zone("rio", Vector2(850, 470), "up")


func _on_victory() -> void:
	StoryProgress.set_flag("demo_completed", true)
	StoryProgress.set_objective(tr("Has vencido al Eco. ¡Gracias por jugar!"))
	# La pantalla épica de reflexión y agradecimiento ya fue mostrada por EchoBattle.
	# Al terminar, volvemos al menú principal para un cierre limpio de la demo.
	GameManager.return_to_menu()
