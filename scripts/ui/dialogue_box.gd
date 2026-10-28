class_name DialogueBox
extends CanvasLayer

signal advance_requested

@onready var panel: PanelContainer = $DialogueRoot/Panel
@onready var speaker_label: Label = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/SpeakerLabel
@onready var dialogue_label: Label = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/DialogueLabel
@onready var portrait: TextureRect = $DialogueRoot/Panel/MarginContainer/Content/Portrait
@onready var next_button: Button = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/NextButton

var _anim_timer: Timer
var _talk_frames: Array[AtlasTexture] = []
var _current_frame_idx := 0
var _anim_sequence := [0, 1, 2, 1]
var _talk_cycles_left := 0


func _ready() -> void:
	_setup_anim_timer()
	hide_dialogue()
	next_button.pressed.connect(func() -> void: advance_requested.emit())


func _setup_anim_timer() -> void:
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.12 # ~8 FPS para animación de habla
	_anim_timer.timeout.connect(_on_anim_tick)
	add_child(_anim_timer)


func show_line(speaker: String, line: String, portrait_path: String, is_last_line: bool) -> void:
	speaker_label.text = speaker
	dialogue_label.text = line
	next_button.text = "Cerrar" if is_last_line else "Continuar  [E]"
	_load_and_play_portrait(portrait_path)
	panel.show()


func hide_dialogue() -> void:
	_stop_portrait_animation()
	panel.hide()


func _load_and_play_portrait(portrait_path: String) -> void:
	_stop_portrait_animation()
	_talk_frames.clear()

	var tex := load(portrait_path) as Texture2D
	if tex == null:
		return

	# Si es un spritesheet de retrato animado (ancho = 3 veces el alto, ej 768x256)
	if tex.get_width() >= tex.get_height() * 3:
		var frame_w: int = tex.get_height()
		var frame_h: int = tex.get_height()
		for i in 3:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
			_talk_frames.append(atlas)

		portrait.texture = _talk_frames[0]
		_current_frame_idx = 0
		# Reproduce ~4 ciclos de habla (alrededor de 2 segundos)
		_talk_cycles_left = 16
		_anim_timer.start()
	else:
		# Retrato estático clásico
		portrait.texture = tex


func _on_anim_tick() -> void:
	if _talk_frames.size() < 3:
		_stop_portrait_animation()
		return

	_talk_cycles_left -= 1
	if _talk_cycles_left <= 0:
		_stop_portrait_animation()
		return

	_current_frame_idx = (_current_frame_idx + 1) % _anim_sequence.size()
	var frame_num: int = _anim_sequence[_current_frame_idx]
	portrait.texture = _talk_frames[frame_num]


func _stop_portrait_animation() -> void:
	if _anim_timer and _anim_timer.is_inside_tree():
		_anim_timer.stop()
	if not _talk_frames.is_empty():
		portrait.texture = _talk_frames[0]
