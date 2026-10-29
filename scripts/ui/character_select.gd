extends Control

@onready var forastero_button: Button = %ForasteroButton
@onready var forastera_button: Button = %ForasteraButton
@onready var begin_button: Button = %BeginButton
@onready var selection_label: Label = %SelectionLabel

func _ready() -> void:
	forastero_button.pressed.connect(_select.bind(GameManager.CHARACTER_FORASTERO))
	forastera_button.pressed.connect(_select.bind(GameManager.CHARACTER_FORASTERA))
	begin_button.pressed.connect(GameManager.show_intro)
	begin_button.disabled = true
	forastero_button.grab_focus()

func _select(character_type: String) -> void:
	GameManager.select_character(character_type)
	begin_button.disabled = false
	begin_button.grab_focus()
	if character_type == GameManager.CHARACTER_FORASTERO:
		selection_label.text = tr("Has elegido al forastero.")
	else:
		selection_label.text = tr("Has elegido a la forastera.")
