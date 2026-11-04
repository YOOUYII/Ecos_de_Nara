class_name EchoBattle
extends CanvasLayer

## Combate de vocabulario. Cada acierto esquiva un golpe y debilita al Eco;
## cada error deja que el Eco alcance al personaje.

signal victory
signal defeat

const PLAYER_MAX_HEALTH := 3
const ECHO_MAX_HEALTH := 5
const ROUND_DELAY := 1.1

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

var player_health := PLAYER_MAX_HEALTH
var echo_health := ECHO_MAX_HEALTH
var words: Array[String] = []
var current_concept := ""
var accepting_answer := false

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
		words = ["bread", "basket", "wood", "key", "answer", "home"]
	while words.size() < ECHO_MAX_HEALTH:
		words.append_array(words.duplicate())
	status_label.text = tr("El Eco copia tus dudas. Esquiva el golpe escogiendo la traducción correcta.")
	_next_round()


func _build_interface() -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)

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
	player_sprite.position = Vector2(380, 290)
	player_sprite.scale = Vector2(3.0, 3.0)
	player_sprite.sprite_frames = _make_frames({"idle": _frames(_player_idle(), 32, 48, 2), "dodge": _frames(_player_dodge(), 32, 48, 4)}, "idle")
	player_sprite.play("idle")
	layer.add_child(player_sprite)

	echo_sprite = AnimatedSprite2D.new()
	echo_sprite.position = Vector2(900, 290)
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

	player_health_label = _label(Vector2(180, 95), Vector2(320, 30), 20)
	echo_health_label = _label(Vector2(780, 95), Vector2(320, 30), 20)
	layer.add_child(player_health_label)
	layer.add_child(echo_health_label)

	question_label = _label(Vector2(260, 405), Vector2(760, 42), 24)
	layer.add_child(question_label)
	for index in 3:
		var button := Button.new()
		button.position = Vector2(330 + index * 215, 465)
		button.size = Vector2(195, 68)
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_stylebox_override("normal", _nine_slice("res://assets/art/ui/ui_combate_opcion_normal_9slice.png"))
		button.add_theme_stylebox_override("hover", _nine_slice("res://assets/art/ui/ui_combate_opcion_correcta_9slice.png"))
		button.add_theme_stylebox_override("pressed", _nine_slice("res://assets/art/ui/ui_combate_opcion_incorrecta_9slice.png"))
		button.pressed.connect(_answer.bind(index))
		layer.add_child(button)
		option_buttons.append(button)

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
	accepting_answer = true
	current_concept = words.pick_random()
	question_label.text = tr("¿Qué significa “%s”?" ) % Lang.word_for(current_concept)
	var choices := _choices_for(current_concept)
	for index in option_buttons.size():
		option_buttons[index].text = choices[index]
		option_buttons[index].disabled = false


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
	if not accepting_answer:
		return
	accepting_answer = false
	for button in option_buttons:
		button.disabled = true
	var correct := option_buttons[index].text == _gloss_answer(current_concept)
	if correct:
		status_label.text = tr("¡Esquivaste el golpe! El Eco se debilita.")
		player_sprite.play("dodge")
		_show_effect("dodge")
		echo_sprite.play("hurt")
		echo_health -= 1
	else:
		status_label.text = tr("El golpe te alcanzó. Mira tu libreta y vuelve a intentarlo.")
		echo_sprite.play("attack")
		_show_effect("hit")
		player_health -= 1
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
	player_health_label.text = tr("FORASTERO/A  %s") % _hearts(player_health, PLAYER_MAX_HEALTH)
	echo_health_label.text = tr("ECO  %s") % _hearts(echo_health, ECHO_MAX_HEALTH)


func _hearts(current: int, maximum: int) -> String:
	return "●".repeat(current) + "○".repeat(maximum - current)


func _win() -> void:
	# Esconder botones y deshabilitar interacción
	for button in option_buttons:
		button.hide()
	question_label.text = tr("El Eco ya no puede sostenerse.")
	status_label.text = ""

	# 1. Animación de desvanecimiento del Eco
	echo_sprite.play("fade")
	await echo_sprite.animation_finished

	# 2. Fade-out de toda la pantalla de combate
	await get_tree().create_timer(0.6).timeout
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

	# Botón "Continuar"
	var cont_btn := Button.new()
	cont_btn.text = tr("Continuar →")
	cont_btn.position = Vector2(490, 560)
	cont_btn.size = Vector2(300, 56)
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


## Crea un Label centrado con fade-in para la pantalla de victoria.
func _make_vscreen_label(text: String, font_size: int, color: Color, offset: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_top = offset.y
	label.offset_bottom = offset.y + font_size * 3
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
	var title := _make_vscreen_label("Ecos de Nara", 54, Color(0.95, 0.82, 0.38, 1.0), Vector2(0, 100))
	title.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(title)

	var subtitle := _make_vscreen_label(tr("Demo — Versión 1.0"), 20, Color(0.65, 0.65, 0.65, 1.0), Vector2(0, 190))
	subtitle.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(subtitle)

	var thanks := _make_vscreen_label(
		tr("Gracias por jugar la demo.\nEspero que hayas disfrutado\naprender tus primeras palabras en alemán."),
		24, Color(0.92, 0.92, 0.92, 1.0), Vector2(0, 280)
	)
	thanks.modulate = Color(1, 1, 1, 0)
	vscreen.add_child(thanks)

	# Fade-in secuencial
	for lbl in [title, subtitle, thanks]:
		await _fade_in_label(lbl, 1.0)
		await get_tree().create_timer(0.3).timeout

	# Botón volver al menú
	var menu_btn := Button.new()
	menu_btn.text = tr("Volver al menú principal")
	menu_btn.position = Vector2(440, 590)
	menu_btn.size = Vector2(400, 54)
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
	question_label.text = tr("El espejo se rompe a tu alrededor.")
	status_label.text = tr("La duda no termina aquí. El portal sigue esperándote junto al río: revisa tus anotaciones y vuelve cuando quieras.")
	for button in option_buttons:
		button.hide()
	await get_tree().create_timer(2.5).timeout
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
