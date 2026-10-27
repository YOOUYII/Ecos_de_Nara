extends Control

@onready var introduction_label: Label = %IntroductionLabel

func _ready() -> void:
	var title := "forastero" if GameManager.selected_character == GameManager.CHARACTER_FORASTERO else "forastera"
	introduction_label.text = "Despiertas sin recuerdos.\n\nEl pueblo guarda silencio mientras te observa. Solo llevas una libreta y una carta que no puedes comprender.\n\nDebes descubrir quién eres, qué dice la carta y cómo salir de Nara, %s." % title

func _on_continue_button_pressed() -> void:
	GameManager.begin_world()
