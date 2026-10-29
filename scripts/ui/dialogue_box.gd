class_name DialogueBox
extends CanvasLayer

signal advance_requested

## Velocidad del texto letra por letra.
const CHARS_PER_SECOND := 30.0

@onready var panel: PanelContainer = $DialogueRoot/Panel
@onready var speaker_label: Label = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/SpeakerLabel
@onready var dialogue_label: Label = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/DialogueLabel
@onready var portrait: TextureRect = $DialogueRoot/Panel/MarginContainer/Content/Portrait
@onready var next_button: Button = $DialogueRoot/Panel/MarginContainer/Content/TextColumn/NextButton
@onready var icon_popup: TextureRect = $DialogueRoot/IconPopup

var _anim_timer: Timer
var _talk_frames: Array[AtlasTexture] = []
var _current_frame_idx := 0
var _anim_sequence := [0, 1, 2, 1]
var _typing := false
var _type_tween: Tween
var _icon_reveal_at := 0


func _ready() -> void:
	_setup_anim_timer()
	hide_dialogue()
	next_button.pressed.connect(func() -> void: advance_requested.emit())


func _setup_anim_timer() -> void:
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.12 # ~8 FPS para animación de habla
	_anim_timer.timeout.connect(_on_anim_tick)
	add_child(_anim_timer)


## `extras` es opcional: "icon" (ruta a un pictograma) e "icon_word" (palabra tras la
## cual aparece; si falta, aparece al terminar la línea).
func show_line(speaker: String, line: String, portrait_path: String, is_last_line: bool, extras: Dictionary = {}) -> void:
	speaker_label.text = speaker
	dialogue_label.text = line
	next_button.text = "Cerrar" if is_last_line else "Continuar  [E]"
	_load_portrait(portrait_path)
	_prepare_icon(line, extras)
	panel.show()
	_start_typing(line.length())


func hide_dialogue() -> void:
	_cancel_typing()
	_stop_portrait_animation()
	icon_popup.hide()
	panel.hide()


func is_typing() -> bool:
	return _typing


## Muestra la línea completa al instante (primer E mientras se escribe).
func finish_typing() -> void:
	if not _typing:
		return
	_cancel_typing()
	_on_typing_finished()


func _start_typing(char_count: int) -> void:
	_cancel_typing()
	dialogue_label.visible_characters = 0
	if char_count == 0:
		_on_typing_finished()
		return
	_typing = true
	if not _talk_frames.is_empty():
		_anim_timer.start()
	_type_tween = create_tween()
	_type_tween.tween_method(_on_char_progress, 0, char_count, char_count / CHARS_PER_SECOND)
	_type_tween.finished.connect(_on_typing_finished)


func _cancel_typing() -> void:
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = null
	_typing = false


func _on_char_progress(count: int) -> void:
	dialogue_label.visible_characters = count
	if icon_popup.texture != null and not icon_popup.visible and count >= _icon_reveal_at:
		icon_popup.show()


func _on_typing_finished() -> void:
	_typing = false
	dialogue_label.visible_characters = -1
	if icon_popup.texture != null:
		icon_popup.show()
	_stop_portrait_animation()


func _prepare_icon(line: String, extras: Dictionary) -> void:
	icon_popup.hide()
	icon_popup.texture = null
	var icon_path := str(extras.get("icon", ""))
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return
	icon_popup.texture = load(icon_path) as Texture2D
	_icon_reveal_at = line.length()
	var word := str(extras.get("icon_word", ""))
	if not word.is_empty():
		var idx := line.find(word)
		if idx >= 0:
			_icon_reveal_at = idx + word.length()


func _load_portrait(portrait_path: String) -> void:
	_stop_portrait_animation()
	_talk_frames.clear()

	var tex := load(portrait_path) as Texture2D
	if tex == null:
		return

	# Si es un spritesheet de retrato animado (ancho = 3 veces el alto, ej 768x256)
	if tex.get_width() >= tex.get_height() * 3:
		var frame_size: int = tex.get_height()
		for i in 3:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_size, 0, frame_size, frame_size)
			_talk_frames.append(atlas)
		portrait.texture = _talk_frames[0]
		_current_frame_idx = 0
	else:
		# Retrato estático clásico
		portrait.texture = tex


func _on_anim_tick() -> void:
	if _talk_frames.size() < 3 or not _typing:
		_stop_portrait_animation()
		return
	_current_frame_idx = (_current_frame_idx + 1) % _anim_sequence.size()
	portrait.texture = _talk_frames[_anim_sequence[_current_frame_idx]]


func _stop_portrait_animation() -> void:
	if _anim_timer and _anim_timer.is_inside_tree():
		_anim_timer.stop()
	if not _talk_frames.is_empty():
		portrait.texture = _talk_frames[0]
