extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	var can_continue: bool = SaveManager.has_save()
	continue_button.disabled = not can_continue
	if can_continue:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

	new_game_button.pressed.connect(GameManager.start_new_game)
	exit_button.pressed.connect(get_tree().quit)


func _on_continue_pressed() -> void:
	SaveManager.load_game()
