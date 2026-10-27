extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	# El guardado se implementará en la Sección 10.
	continue_button.disabled = true
	new_game_button.pressed.connect(GameManager.start_new_game)
	exit_button.pressed.connect(get_tree().quit)
	new_game_button.grab_focus()
