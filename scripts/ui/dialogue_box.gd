class_name DialogueBox
extends CanvasLayer

signal advance_requested

@onready var panel: PanelContainer = $DialogueRoot/Panel
@onready var speaker_label: Label = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/SpeakerLabel
@onready var dialogue_label: Label = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/DialogueLabel
@onready var portrait: TextureRect = $DialogueRoot/Panel/MarginContainer/Content/Portrait
@onready var next_button: Button = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/NextButton


func _ready() -> void:
	hide_dialogue()
	next_button.pressed.connect(func() -> void: advance_requested.emit())


func show_line(speaker: String, line: String, portrait_path: String, is_last_line: bool) -> void:
	speaker_label.text = speaker
	dialogue_label.text = line
	next_button.text = "Cerrar" if is_last_line else "Continuar  [E]"
	portrait.texture = _create_portrait_texture(portrait_path)
	panel.show()


func hide_dialogue() -> void:
	panel.hide()


func _create_portrait_texture(portrait_path: String) -> AtlasTexture:
	var portrait_texture := AtlasTexture.new()
	portrait_texture.atlas = load(portrait_path)
	# Los sprites provisionales usan una primera celda de 32 x 48 px.
	portrait_texture.region = Rect2(0, 0, 32, 48)
	return portrait_texture
