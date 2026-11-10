class_name EchoBattle
extends CanvasLayer

## Combate de vocabulario. Cada acierto esquiva un golpe y debilita al Eco;
## cada error deja que el Eco alcance al personaje.

signal victory
signal defeat

const PLAYER_MAX_HEALTH := 3
const ECHO_MAX_HEALTH := 5
const ROUND_DELAY := 1.4
const QUESTION_TIME := 10.0
const DANGER_SECONDS := 3
## Máximo de rondas posibles: el Eco cae tras 5 aciertos y el jugador tras 3 fallos.
const MAX_ROUNDS := PLAYER_MAX_HEALTH + ECHO_MAX_HEALTH - 1
## Conceptos presentes en los glosarios de los cuatro idiomas; deben ser al menos MAX_ROUNDS.
const FALLBACK_CONCEPTS: Array[String] = [
	"bread", "basket", "wood", "key", "answer", "home",
	"water", "way", "bridge", "fish", "forest", "fountain",
]

const PLAYER_BASE := Vector2(380, 290)
const ECHO_BASE := Vector2(900, 290)
const GEM_SIZE := 48.0
const GEM_GAP := 8.0
const TIMER_BAR_WIDTH := 232.0

const COLOR_TIME_OK := Color("3c8a8c")
const COLOR_TIME_WARN := Color("e1b15e")
const COLOR_TIME_DANGER := Color("af5f4b")

const MALE_IDLE := preload("res://assets/art/characters/enemigos/eco_inmovil_idle.png")
const MALE_HIT := preload("res://assets/art/characters/enemigos/eco_inmovil_golpe_4f.png")
const MALE_HURT := preload("res://assets/art/characters/enemigos/eco_inmovil_daño_4f.png")
const MALE_FADE := preload("res://assets/art/characters/enemigos/eco_inmovil_desvanecer_6f.png")
const FEMALE_IDLE := preload("res://assets/art/characters/enemigos/eco_forastera_idle.png")
const FEMALE_HIT := preload("res://assets/art/characters/enemigos/eco_forastera_golpe_4f.png")
const FEMALE_HURT := preload("res://assets/art/characters/enemigos/eco_forastera_daño_4f.png")
const FEMALE_FADE := preload("res://assets/art/characters/enemigos/eco_forastera_desvanecer_6f.png")
const DODGE_MALE := preload("res://assets/art/characters/player/forastero_esquive_4f.png")
const DODGE_FEMALE := preload("res://assets/art/characters/player/forastera_esquive_4f.png")
const FX_HIT := preload("res://assets/art/effects/fx_golpe_sombra_3f.png")
const FX_DODGE := preload("res://assets/art/effects/fx_esquive_brillo_4f.png")
const FX_DANGER := preload("res://assets/art/effects/fx_peligro_vineta.png")
const GEM_PLAYER := preload("res://assets/art/ui/ui_energia_jugador.png")
const GEM_ECHO := preload("res://assets/art/ui/ui_energia_eco.png")
const GEM_EMPTY := preload("res://assets/art/ui/ui_energia_vacia.png")
const GEM_BREAK := preload("res://assets/art/ui/ui_energia_rompe_4f.png")
const ICON_CLOCK := preload("res://assets/art/ui/ui_icono_reloj.png")
const ICON_CHECK := preload("res://assets/art/ui/ui_icono_check.png")
const ICON_CROSS := preload("res://assets/art/ui/ui_icono_cruz.png")
const OPTION_NORMAL := "res://assets/art/ui/ui_combate_opcion_normal_9slice.png"
const OPTION_CORRECT := "res://assets/art/ui/ui_combate_opcion_correcta_9slice.png"
const OPTION_WRONG := "res://assets/art/ui/ui_combate_opcion_incorrecta_9slice.png"
const TIMER_FRAME := "res://assets/art/ui/ui_temporizador_marco_9slice.png"

var player_health := PLAYER_MAX_HEALTH
var echo_health := ECHO_MAX_HEALTH
var words: Array[String] = []
var deck: Array[String] = []
var results: Array[Dictionary] = []
var current_concept := ""
var accepting_answer := false
var time_left := QUESTION_TIME
var _last_second := -1
var _in_danger := false
var _battle_over := false
var _shake_tweens := {}
var _danger_tween: Tween
var _pulse_tweens := {}
var _root: Control
var player_gems: Array[TextureRect] = []
var echo_gems: Array[TextureRect] = []
var button_base: Array[Vector2] = []
var clock_icon: TextureRect
var seconds_label: Label
var timer_fill: ColorRect
var vignette: TextureRect

var question_label: Label
var status_label: Label
var player_health_label: Label
var echo_health_label: Label
var option_buttons: Array[Button] = []
var echo_sprite: AnimatedSprite2D
var player_sprite: AnimatedSprite2D
var effect_sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("echo_battle_active")
	_build_interface()


func start_battle() -> void:
	words = Notebook.get_confirmed_concepts()
	if words.is_empty():
		# Es un respaldo para partidas antiguas: normalmente el Fragmento III exige vocabulario confirmado.
		words = FALLBACK_CONCEPTS.duplicate()
	deck = build_deck(words, MAX_ROUNDS, FALLBACK_CONCEPTS)
	status_label.text = tr("El Eco copia tus dudas. Esquiva el golpe escogiendo la traducción correcta.")
	_next_round()


## Mazo de preguntas sin repetir: conceptos confirmados barajados y, si no alcanzan para
## las rondas posibles, completados con conceptos de respaldo que aún no estén en el mazo.
static func build_deck(confirmed: Array, needed: int, fallback: Array) -> Array[String]:
	var result: Array[String] = []
	for concept in confirmed:
		if not result.has(str(concept)):
			result.append(str(concept))
	result.shuffle()
	var extra: Array = fallback.duplicate()
	extra.shuffle()
	for concept in extra:
		if result.size() >= needed:
			break
		if not result.has(str(concept)):
			result.append(str(concept))
	return result


func _build_interface() -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	_root = layer

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.08, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)

	var panel := Panel.new()
	panel.position = Vector2(155, 78)
	panel.size = Vector2(970, 555)
	panel.add_theme_stylebox_override("panel", _nine_slice("res://assets/art/ui/ui_combate_panel_9slice.png"))
	layer.add_child(panel)

	var title := Label.new()
	title.text = tr("EL ECO DEL ESPEJO")
	title.position = Vector2(420, 22)
	title.size = Vector2(440, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("91e6ff"))
	layer.add_child(title)

	player_sprite = AnimatedSprite2D.new()
	player_sprite.position = PLAYER_BASE
	player_sprite.scale = Vector2(3.0, 3.0)
	player_sprite.sprite_frames = _make_frames({"idle": _frames(_player_idle(), 32, 48, 2), "dodge": _frames(_player_dodge(), 32, 48, 4)}, "idle")
	player_sprite.play("idle")
	layer.add_child(player_sprite)

	echo_sprite = AnimatedSprite2D.new()
	echo_sprite.position = ECHO_BASE
	echo_sprite.scale = Vector2(3.0, 3.0)
	var enemy := _enemy_textures()
	echo_sprite.sprite_frames = _make_frames({"idle": _frames(enemy.idle, 32, 48, 2), "attack": _frames(enemy.hit, 32, 48, 4), "hurt": _frames(enemy.hurt, 32, 48, 4), "fade": _frames(enemy.fade, 32, 48, 6)}, "idle")
	echo_sprite.play("idle")
	layer.add_child(echo_sprite)

	effect_sprite = AnimatedSprite2D.new()
	effect_sprite.position = Vector2(640, 290)
	effect_sprite.scale = Vector2(2.5, 2.5)
	effect_sprite.sprite_frames = _make_frames({"hit": _frames(FX_HIT, 32, 32, 3), "dodge": _frames(FX_DODGE, 32, 32, 4)}, "hit", false)
	effect_sprite.hide()
	layer.add_child(effect_sprite)

	player_health_label = _label(Vector2(PLAYER_BASE.x - 160, 100), Vector2(320, 30), 20)
	echo_health_label = _label(Vector2(ECHO_BASE.x - 160, 100), Vector2(320, 30), 20)
	layer.add_child(player_health_label)
	layer.add_child(echo_health_label)
	player_gems = _build_gems(layer, PLAYER_BASE.x, PLAYER_MAX_HEALTH, GEM_PLAYER)
	echo_gems = _build_gems(layer, ECHO_BASE.x, ECHO_MAX_HEALTH, GEM_ECHO)
	_build_timer(layer)

	vignette = TextureRect.new()
	vignette.texture = FX_DANGER
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.hide()
	layer.add_child(vignette)

	question_label = _label(Vector2(260, 405), Vector2(760, 42), 24)
	layer.add_child(question_label)
	for index in 3:
		var button := Button.new()
		var base := Vector2(330 + index * 215, 465)
		button.position = base
		button.size = Vector2(195, 68)
		button.add_theme_font_size_override("font_size", 18)
		_set_button_state(button, "normal")
		button.pressed.connect(_answer.bind(index))
		layer.add_child(button)
		option_buttons.append(button)
		button_base.append(base)

	status_label = _label(Vector2(180, 565), Vector2(920, 54), 16)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(status_label)
	_update_health()


func _label(pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("161b32"))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _nine_slice(path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.texture_margin_left = 12.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 12.0
	style.texture_margin_bottom = 12.0
	style.expand_margin_left = 4.0
	style.expand_margin_top = 4.0
	style.expand_margin_right = 4.0
	style.expand_margin_bottom = 4.0
	return style


func _next_round() -> void:
	if deck.is_empty():
		# Solo ocurre si el idioma no tiene conceptos suficientes: se rebaraja como último recurso.
		deck = build_deck(words, MAX_ROUNDS, FALLBACK_CONCEPTS)
	current_concept = deck.pop_front()
	question_label.text = tr("¿Qué significa “%s”?" ) % Lang.word_for(current_concept)
	question_label.position = Vector2(260, 405)
	var choices := _choices_for(current_concept)
	for index in option_buttons.size():
		var button := option_buttons[index]
		_kill_shake(button)
		button.position = button_base[index]
		button.text = choices[index]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_button_state(button, "normal")
	_exit_danger()
	time_left = QUESTION_TIME
	_last_second = -1
	_update_timer_ui()
	accepting_answer = true


## Devuelve el texto de la respuesta correcta (campo "answer" del glosario).
func _gloss_answer(concept: String) -> String:
	var gloss := Lang.concept_gloss(concept)
	if gloss.is_empty():
		return concept
	return str(gloss.get("answer", gloss.get("meaning", concept)))


func _choices_for(correct_concept: String) -> Array[String]:
	var pool := words.duplicate()
	for fallback in ["bread", "basket", "wood", "key", "answer", "home"]:
		if not pool.has(fallback):
			pool.append(fallback)
	pool.shuffle()
	# Siempre incluimos el concepto correcto y dos distractores distintos
	var chosen: Array[String] = [correct_concept]
	for concept in pool:
		if concept != correct_concept and not chosen.has(concept):
			chosen.append(concept)
		if chosen.size() == 3:
			break
	chosen.shuffle()
	# Convertimos los conceptos a su texto en el idioma nativo del jugador
	var translated: Array[String] = []
	for concept in chosen:
		translated.append(_gloss_answer(concept))
	return translated


func _answer(index: int) -> void:
	_resolve(index)


## Resuelve la ronda. index < 0 significa que se acabó el tiempo.
func _resolve(index: int) -> void:
	if not accepting_answer:
		return
	accepting_answer = false
	_exit_danger()
	var timed_out := index < 0
	var correct := not timed_out and option_buttons[index].text == _gloss_answer(current_concept)
	results.append({"concept": current_concept, "correct": correct, "timeout": timed_out})

	# Opciones: todas tiemblan suave; la elegida, más fuerte y con su color (verde o rojo).
	for button_index in option_buttons.size():
		var button := option_buttons[button_index]
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if timed_out:
			_set_button_state(button, "wrong")
			_shake(button, button_base[button_index], 10.0, 0.5)
		elif button_index == index:
			_set_button_state(button, "correct" if correct else "wrong")
			_shake(button, button_base[button_index], 12.0, 0.45)
		else:
			_shake(button, button_base[button_index], 4.0, 0.3)

	if correct:
		status_label.text = tr("¡Esquivaste el golpe! El Eco se debilita.")
		player_sprite.play("dodge")
		_show_effect("dodge")
		echo_sprite.play("hurt")
		echo_health -= 1
		_damage_feedback(false)
	else:
		if timed_out:
			status_label.text = tr("¡Se acabó el tiempo! El Eco te alcanzó.")
		else:
			status_label.text = tr("El golpe te alcanzó. Mira tu libreta y vuelve a intentarlo.")
		echo_sprite.play("attack")
		_show_effect("hit")
		player_health -= 1
		_damage_feedback(true)
	_update_health()
	await get_tree().create_timer(ROUND_DELAY).timeout
	if echo_health <= 0:
		_win()
	elif player_health <= 0:
		_lose()
	else:
		echo_sprite.play("idle")
		player_sprite.play("idle")
		_next_round()


func _show_effect(animation: String) -> void:
	effect_sprite.play(animation)
	effect_sprite.show()
	await effect_sprite.animation_finished
	effect_sprite.hide()


func _update_health() -> void:
	player_health_label.text = tr("FORASTERO/A  %d/%d") % [player_health, PLAYER_MAX_HEALTH]
	echo_health_label.text = tr("ECO  %d/%d") % [echo_health, ECHO_MAX_HEALTH]


# ------------------------------------------------------------------ vida

func _build_gems(parent: Control, center_x: float, count: int, texture: Texture2D) -> Array[TextureRect]:
	var gems: Array[TextureRect] = []
	var total := count * GEM_SIZE + (count - 1) * GEM_GAP
	for index in count:
		var gem := TextureRect.new()
		gem.texture = texture
		gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gem.stretch_mode = TextureRect.STRETCH_SCALE
		gem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		gem.size = Vector2(GEM_SIZE, GEM_SIZE)
		gem.pivot_offset = gem.size / 2.0
		gem.position = Vector2(center_x - total / 2.0 + index * (GEM_SIZE + GEM_GAP), 138)
		gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(gem)
		gems.append(gem)
	return gems


## Anima la pérdida de una gema, el golpe en el sprite y el "-1" flotante.
func _damage_feedback(on_player: bool) -> void:
	var gems := player_gems if on_player else echo_gems
	var remaining := player_health if on_player else echo_health
	var sprite := player_sprite if on_player else echo_sprite
	var base := PLAYER_BASE if on_player else ECHO_BASE
	if remaining >= 0 and remaining < gems.size():
		_break_gem(gems[remaining])
	_flash_sprite(sprite)
	_shake(sprite, base, 9.0, 0.4)
	_float_text("-1", base + Vector2(0, -100))
	if remaining == 1:
		_pulse_gem(gems[0], "player" if on_player else "echo")


func _break_gem(gem: TextureRect) -> void:
	var tween := create_tween()
	tween.tween_property(gem, "scale", Vector2(1.35, 1.35), 0.08)
	for frame in _frames(GEM_BREAK, 24, 24, 4):
		tween.tween_callback(gem.set_texture.bind(frame))
		tween.tween_interval(0.07)
	tween.tween_callback(gem.set_texture.bind(GEM_EMPTY))
	tween.tween_property(gem, "scale", Vector2.ONE, 0.1)


## La última gema latiendo en rojo avisa de que queda una sola vida.
func _pulse_gem(gem: TextureRect, key: String) -> void:
	if _pulse_tweens.has(key) and is_instance_valid(_pulse_tweens[key]):
		_pulse_tweens[key].kill()
	var tween := create_tween().set_loops()
	tween.tween_property(gem, "modulate", Color(1.9, 0.55, 0.5), 0.35)
	tween.tween_property(gem, "modulate", Color.WHITE, 0.35)
	_pulse_tweens[key] = tween


func _flash_sprite(sprite: AnimatedSprite2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 0.45, 0.45), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _float_text(text_value: String, at: Vector2) -> void:
	var label := _label(at - Vector2(60, 20), Vector2(120, 40), 36)
	label.text = text_value
	label.add_theme_color_override("font_color", Color("f0c064"))
	label.pivot_offset = Vector2(60, 20)
	_root.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


# ------------------------------------------------------------------ temporizador

func _build_timer(parent: Control) -> void:
	clock_icon = TextureRect.new()
	clock_icon.texture = ICON_CLOCK
	clock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock_icon.stretch_mode = TextureRect.STRETCH_SCALE
	clock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clock_icon.size = Vector2(48, 48)
	clock_icon.position = Vector2(575, 96)
	clock_icon.pivot_offset = Vector2(24, 24)
	clock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(clock_icon)

	seconds_label = _label(Vector2(628, 96), Vector2(80, 48), 36)
	seconds_label.pivot_offset = Vector2(40, 24)
	parent.add_child(seconds_label)

	var frame := Panel.new()
	frame.position = Vector2(520, 150)
	frame.size = Vector2(TIMER_BAR_WIDTH + 8.0, 26)
	var style := _nine_slice(TIMER_FRAME)
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	style.expand_margin_left = 0.0
	style.expand_margin_top = 0.0
	style.expand_margin_right = 0.0
	style.expand_margin_bottom = 0.0
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)

	timer_fill = ColorRect.new()
	timer_fill.position = Vector2(524, 154)
	timer_fill.size = Vector2(TIMER_BAR_WIDTH, 18)
	timer_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(timer_fill)


func _process(delta: float) -> void:
	if not accepting_answer or _battle_over:
		return
	if Notebook.is_open or Letter.is_open:
		return # consultar la libreta no gasta tiempo
	time_left = maxf(0.0, time_left - delta)
	_update_timer_ui()
	var second := int(ceil(time_left))
	if second != _last_second:
		_last_second = second
		_on_tick(second)
	if time_left <= 0.0:
		_resolve(-1)


func _update_timer_ui() -> void:
	var ratio := clampf(time_left / QUESTION_TIME, 0.0, 1.0)
	timer_fill.size.x = TIMER_BAR_WIDTH * ratio
	if ratio > 0.5:
		timer_fill.color = COLOR_TIME_OK
	elif ratio > 0.25:
		timer_fill.color = COLOR_TIME_WARN
	else:
		timer_fill.color = COLOR_TIME_DANGER
	seconds_label.text = str(int(ceil(time_left)))


func _on_tick(second: int) -> void:
	# Cada segundo el reloj y la cifra "laten".
	clock_icon.scale = Vector2(1.3, 1.3)
	seconds_label.scale = Vector2(1.25, 1.25)
	var pop := create_tween().set_parallel(true)
	pop.tween_property(clock_icon, "scale", Vector2.ONE, 0.25)
	pop.tween_property(seconds_label, "scale", Vector2.ONE, 0.25)
	if second > 0 and second <= DANGER_SECONDS:
		_enter_danger()
		# Cuanto menos tiempo, más tiembla la pregunta.
		_shake(question_label, Vector2(260, 405), 2.0 + float(DANGER_SECONDS - second) * 1.5, 0.3)


func _enter_danger() -> void:
	if _in_danger:
		return
	_in_danger = true
	seconds_label.add_theme_color_override("font_color", Color("f0b0a0"))
	clock_icon.modulate = Color(1.0, 0.7, 0.65)
	vignette.modulate.a = 0.0
	vignette.show()
	_danger_tween = create_tween().set_loops()
	_danger_tween.tween_property(vignette, "modulate:a", 1.0, 0.3)
	_danger_tween.tween_property(vignette, "modulate:a", 0.35, 0.3)


func _exit_danger() -> void:
	if is_instance_valid(_danger_tween):
		_danger_tween.kill()
	_in_danger = false
	if vignette:
		vignette.hide()
	if clock_icon:
		clock_icon.modulate = Color.WHITE
		clock_icon.scale = Vector2.ONE
	if seconds_label:
		seconds_label.add_theme_color_override("font_color", Color.WHITE)
		seconds_label.scale = Vector2.ONE


# ------------------------------------------------------------------ opciones (shake y color)

func _set_button_state(button: Button, state: String) -> void:
	var font_color := Color.WHITE if state in ["correct", "wrong"] else Color("2a202e")
	for slot in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(slot, font_color)
	match state:
		"correct", "wrong":
			var style := _nine_slice(OPTION_CORRECT if state == "correct" else OPTION_WRONG)
			for slot in ["normal", "hover", "pressed", "disabled", "focus"]:
				button.add_theme_stylebox_override(slot, style)
		_:
			button.add_theme_color_override("font_hover_color", Color.WHITE)
			button.add_theme_color_override("font_pressed_color", Color.WHITE)
			button.add_theme_stylebox_override("normal", _nine_slice(OPTION_NORMAL))
			button.add_theme_stylebox_override("hover", _nine_slice(OPTION_CORRECT))
			button.add_theme_stylebox_override("pressed", _nine_slice(OPTION_WRONG))
			button.remove_theme_stylebox_override("disabled")
			button.remove_theme_stylebox_override("focus")


func _kill_shake(node: Node) -> void:
	var key := node.get_instance_id()
	if _shake_tweens.has(key) and is_instance_valid(_shake_tweens[key]):
		_shake_tweens[key].kill()
	_shake_tweens.erase(key)


## Sacude un nodo alrededor de su posición base; la amplitud decae hasta volver a ella.
func _shake(node: Node, base: Vector2, amplitude: float, duration: float) -> void:
	_kill_shake(node)
	node.position = base
	var tween := create_tween()
	_shake_tweens[node.get_instance_id()] = tween
	var steps := 10
	for step in steps:
		var falloff := 1.0 - float(step) / float(steps)
		var offset := Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude) * 0.5) * falloff
		tween.tween_property(node, "position", base + offset, duration / float(steps))
	tween.tween_property(node, "position", base, 0.02)


# ------------------------------------------------------------------ resumen

## Panel rápido con las palabras acertadas y las falladas. Espera a que se pulse "Continuar".
func _show_summary() -> void:
	question_label.hide()
	status_label.hide()
	var panel := Panel.new()
	panel.position = Vector2(240, 110)
	panel.size = Vector2(800, 470)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("2a202e")
	panel_style.border_color = Color("e1b15e")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(panel)

	var heading := _label(Vector2(0, 18), Vector2(800, 40), 28)
	heading.text = tr("Resumen del combate")
	panel.add_child(heading)

	var right: Array[Dictionary] = []
	var wrong: Array[Dictionary] = []
	for entry in results:
		if entry["correct"]:
			right.append(entry)
		else:
			wrong.append(entry)
	_summary_column(panel, 40.0, tr("Acertadas"), ICON_CHECK, right)
	_summary_column(panel, 420.0, tr("Falladas"), ICON_CROSS, wrong)

	var button := Button.new()
	button.text = tr("Continuar")
	button.position = Vector2(320, 400)
	button.size = Vector2(160, 48)
	button.add_theme_font_size_override("font_size", 20)
	_set_button_state(button, "normal")
	panel.add_child(button)
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.25)
	await button.pressed
	panel.queue_free()
	status_label.show()


func _summary_column(panel: Panel, x: float, title_text: String, icon: Texture2D, entries: Array[Dictionary]) -> void:
	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.size = Vector2(36, 36)
	icon_rect.position = Vector2(x, 78)
	panel.add_child(icon_rect)
	var title_label := _label(Vector2(x + 44, 78), Vector2(300, 36), 22)
	title_label.text = "%s (%d)" % [title_text, entries.size()]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(title_label)
	if entries.is_empty():
		var none := _label(Vector2(x, 130), Vector2(340, 32), 20)
		none.text = "—"
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(none)
		return
	for index in entries.size():
		var concept: String = entries[index]["concept"]
		var row := _label(Vector2(x, 126 + index * 38), Vector2(350, 34), 20)
		row.text = "%s  →  %s" % [Lang.word_for(concept), _gloss_answer(concept)]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(row)


func _win() -> void:
	# Esconder botones y deshabilitar interacción
	for button in option_buttons:
		button.hide()
	question_label.text = tr("El Eco ya no puede sostenerse.")
	status_label.text = ""

	_battle_over = true
	_exit_danger()

	# 1. Animación de desvanecimiento del Eco
	echo_sprite.play("fade")
	await echo_sprite.animation_finished

	# 1b. Resumen rápido de palabras acertadas y falladas
	await get_tree().create_timer(0.4).timeout
	await _show_summary()

	# 2. Fade-out de toda la pantalla de combate
	await get_tree().create_timer(0.3).timeout
	var fade_layer := get_node_or_null(".") as CanvasLayer
	# Oscurecemos el contenedor raíz del combate
	var root_control := get_child(0) as Control
	if is_instance_valid(root_control):
		var tween := create_tween()
		tween.tween_property(root_control, "modulate:a", 0.0, 1.2)
		await tween.finished

	# 3. Pantalla épica de reflexión
	_show_victory_screen()


## Construye y muestra la pantalla de reflexión final a pantalla completa.
func _show_victory_screen() -> void:
	var vscreen := CanvasLayer.new()
	vscreen.layer = 128
	get_tree().root.add_child(vscreen)

	# Fondo completamente negro
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vscreen.add_child(bg)

	# Partículas doradas de fondo
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 60
	particles.lifetime = 4.0
	particles.one_shot = false
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 360)
	particles.position = Vector2(640, 360)
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2(0, -8)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	var fade_grad := Gradient.new()
	fade_grad.set_color(0, Color(0.95, 0.80, 0.35, 0.9))
	fade_grad.set_color(1, Color(0.60, 0.42, 0.10, 0.0))
	particles.color_ramp = fade_grad
	vscreen.add_child(particles)

	# Fade-in del fondo
	var tween_in := create_tween()
	tween_in.tween_property(bg, "color:a", 0.96, 1.4)
	await tween_in.finished

	# Línea 1: texto impactante (grande, dorado)
	var line1 := _make_vscreen_label(
		tr("No venciste a un enemigo."),
		36, Color(0.95, 0.82, 0.38, 1.0),
		Vector2(0, 170)
	)
	vscreen.add_child(line1)
	await _fade_in_label(line1, 1.0)
	await get_tree().create_timer(0.5).timeout

	# Línea 2: revelación (mediana, blanca)
	var line2 := _make_vscreen_label(
		tr("Venciste la parte de ti que esperaba\nel momento perfecto para comenzar."),
		26, Color(0.92, 0.92, 0.92, 1.0),
		Vector2(0, 290)
	)
	vscreen.add_child(line2)
	await _fade_in_label(line2, 1.2)
	await get_tree().create_timer(0.6).timeout

	# Línea 3: cierre esperanzador (pequeña, azul tenue)
	var line3 := _make_vscreen_label(
		tr("Aprender un idioma empieza\ncuando aceptas equivocarte y sigues adelante."),
		20, Color(0.56, 0.84, 1.0, 1.0),
		Vector2(0, 430)
	)
	vscreen.add_child(line3)
	await _fade_in_label(line3, 1.3)
	await get_tree().create_timer(1.5).timeout

	# Botón "Continuar" — centrado con anclas
	var cont_btn := Button.new()
	cont_btn.text = tr("Continuar →")
	cont_btn.anchor_left = 0.5
	cont_btn.anchor_right = 0.5
	cont_btn.anchor_top = 0.0
	cont_btn.anchor_bottom = 0.0
	cont_btn.offset_left = -150.0
	cont_btn.offset_right = 150.0
	cont_btn.offset_top = 560.0
	cont_btn.offset_bottom = 618.0
	cont_btn.add_theme_font_size_override("font_size", 22)
	cont_btn.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(cont_btn)
	var tween_btn := create_tween()
	tween_btn.tween_property(cont_btn, "modulate:a", 1.0, 0.8)
	await tween_btn.finished

	# Al pulsar, mostrar pantalla de agradecimiento
	cont_btn.pressed.connect(func():
		cont_btn.disabled = true
		_show_thanks_screen(vscreen)
	)


## Devuelve el nombre legible del idioma que se está aprendiendo.
func _target_language_name() -> String:
	var names := {
		"de": tr("alemán"), "en": tr("inglés"),
		"eo": tr("esperanto"), "fr": tr("francés"),
		"it": tr("italiano"), "pt": tr("portugués"),
	}
	return names.get(Lang.target, Lang.target)


## Crea un Label de ancho completo posicionado por coordenadas Y absolutas.
func _make_vscreen_label(text: String, font_size: int, color: Color, offset: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Anclas solo horizontales (full width); verticalmente usamos offset absoluto desde el tope.
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 0.0
	label.offset_left = 40.0
	label.offset_right = -40.0
	label.offset_top = offset.y
	label.offset_bottom = offset.y + font_size * 4
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.modulate = Color(1, 1, 1, 0)
	return label


func _fade_in_label(label: Label, duration: float) -> void:
	var t := create_tween()
	t.tween_property(label, "modulate:a", 1.0, duration)
	await t.finished


## Pantalla de agradecimiento final de la demo.
func _show_thanks_screen(vscreen: CanvasLayer) -> void:
	# Fade-out de todo lo anterior
	for child in vscreen.get_children():
		var t := create_tween()
		t.tween_property(child, "modulate:a", 0.0, 0.8)
	await get_tree().create_timer(0.9).timeout
	for child in vscreen.get_children():
		child.queue_free()

	# Fondo negro liso
	var bg2 := ColorRect.new()
	bg2.color = Color(0.03, 0.04, 0.07, 1.0)
	bg2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vscreen.add_child(bg2)

	# Logo / título del juego
	var title := _make_vscreen_label("Ecos de Nara", 54, Color(0.95, 0.82, 0.38, 1.0), Vector2(0, 120))
	title.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(title)

	var subtitle := _make_vscreen_label(tr("Demo — Versión 1.0"), 20, Color(0.65, 0.65, 0.65, 1.0), Vector2(0, 215))
	subtitle.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(subtitle)

	# Texto de gracias con idioma dinámico
	var lang_name := _target_language_name()
	var thanks := _make_vscreen_label(
		tr("Gracias por jugar la demo.\nEspero que hayas disfrutado\naprender tus primeras palabras en %s.") % lang_name,
		24, Color(0.92, 0.92, 0.92, 1.0), Vector2(0, 295)
	)
	thanks.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(thanks)

	# Fade-in secuencial
	for lbl in [title, subtitle, thanks]:
		await _fade_in_label(lbl, 1.0)
		await get_tree().create_timer(0.3).timeout

	# Botón volver al menú — centrado horizontalmente
	var menu_btn := Button.new()
	menu_btn.text = tr("Volver al menú principal")
	menu_btn.anchor_left = 0.5
	menu_btn.anchor_right = 0.5
	menu_btn.anchor_top = 0.0
	menu_btn.anchor_bottom = 0.0
	menu_btn.offset_left = -200.0
	menu_btn.offset_right = 200.0
	menu_btn.offset_top = 510.0
	menu_btn.offset_bottom = 566.0
	menu_btn.add_theme_font_size_override("font_size", 20)
	menu_btn.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(menu_btn)
	var tb := create_tween()
	tb.tween_property(menu_btn, "modulate:a", 1.0, 0.8)
	await tb.finished

	menu_btn.pressed.connect(func():
		vscreen.queue_free()
		victory.emit()
	)



func _lose() -> void:
	_battle_over = true
	_exit_danger()
	question_label.text = tr("El espejo se rompe a tu alrededor.")
	status_label.text = tr("La duda no termina aquí. El portal sigue esperándote junto al río: revisa tus anotaciones y vuelve cuando quieras.")
	for button in option_buttons:
		button.hide()
	await get_tree().create_timer(1.5).timeout
	await _show_summary()
	defeat.emit()


func _enemy_textures() -> Dictionary:
	if GameManager.selected_character == GameManager.CHARACTER_FORASTERA:
		return {"idle": FEMALE_IDLE, "hit": FEMALE_HIT, "hurt": FEMALE_HURT, "fade": FEMALE_FADE}
	return {"idle": MALE_IDLE, "hit": MALE_HIT, "hurt": MALE_HURT, "fade": MALE_FADE}


func _player_idle() -> Texture2D:
	return load("res://assets/art/characters/player/forastera_sheet.png") if GameManager.selected_character == GameManager.CHARACTER_FORASTERA else load("res://assets/art/characters/player/forastero_sheet.png")


func _player_dodge() -> Texture2D:
	return DODGE_FEMALE if GameManager.selected_character == GameManager.CHARACTER_FORASTERA else DODGE_MALE


func _frames(texture: Texture2D, width: int, height: int, count: int) -> Array[AtlasTexture]:
	var result: Array[AtlasTexture] = []
	for index in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * width, 0, width, height)
		result.append(atlas)
	return result


func _make_frames(animations: Dictionary, default_animation: String, loop := true) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in animations:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 9.0)
		frames.set_animation_loop(animation_name, loop if animation_name == default_animation else false)
		for texture in animations[animation_name]:
			frames.add_frame(animation_name, texture)
	return frames
