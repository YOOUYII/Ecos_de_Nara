extends CanvasLayer

## Animación de logro a pantalla completa (por ejemplo, al conseguir el Amuleto de Nara):
## destello, rayos de luz que giran, el ícono con rebote, una explosión de chispas y un cartel que baja
## desde arriba. Pausa el juego mientras dura; se puede saltar con E, Enter o un clic pasado un instante.
## Los textos llegan ya traducidos (quien llama usa tr()).

signal finished

const MIN_SKIPPABLE_TIME := 1.3 # antes de esto no se puede saltar, para que se vea el efecto
const HOLD_TIME := 4.0
const FADE_OUT_TIME := 0.5
const ICON_CENTER_OFFSET_Y := -40.0 # el ícono queda algo por encima del centro, por debajo del cartel
const BANNER_WIDTH := 620.0
const BANNER_REST_Y := 56.0
const GOLD := Color(0.96, 0.79, 0.37, 1.0)
const CREAM := Color(0.96, 0.95, 0.9, 1.0)

var _root: Control
var _dim: ColorRect
var _rays: LightRays
var _flash: ColorRect
var _icon: TextureRect
var _banner: PanelContainer
var _title_label: Label
var _name_label: Label
var _sub_label: Label
var _hint_label: Label
var _burst: CPUParticles2D
var _sparkles: CPUParticles2D
var _tween: Tween
var _bob_tween: Tween
var _elapsed := 0.0
var _playing := false
var _fading := false
var _paused_before := false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS # sigue activo con el juego en pausa
	visible = false
	_build_ui()


func is_playing() -> bool:
	return _playing


## Reproduce la animación. `icon` es el ícono (se amplía sin suavizado); los textos ya vienen traducidos.
func play(icon: Texture2D, title: String, item_name: String, subtitle: String) -> void:
	if _playing:
		return
	_playing = true
	_fading = false
	_elapsed = 0.0
	_title_label.text = title
	_name_label.text = item_name
	_sub_label.text = subtitle
	_hint_label.text = tr("Continuar  [E]")
	_icon.texture = icon
	_banner.size = Vector2(BANNER_WIDTH, 0.0) # recalcula la altura con los textos nuevos
	_banner.reset_size()
	_paused_before = get_tree().paused
	get_tree().paused = true
	visible = true
	_reset_state()
	_start_timeline()


## Salta la animación (con el efecto ya visible). Devuelve false si todavía no se puede saltar.
func skip() -> bool:
	if not _playing or _fading or _elapsed < MIN_SKIPPABLE_TIME:
		return false
	_begin_fade_out()
	return true


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	if not _fading and _elapsed >= HOLD_TIME:
		_begin_fade_out()


func _input(event: InputEvent) -> void:
	if not _playing:
		return
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	var clicked := false
	if event is InputEventMouseButton:
		clicked = (event as InputEventMouseButton).pressed
	if (pressed or clicked) and not event.is_echo():
		skip()
		get_viewport().set_input_as_handled() # el aviso no debe llegar al juego ni reabrir nada


func _reset_state() -> void:
	var size := _viewport_size()
	_root.modulate.a = 1.0
	_dim.color.a = 0.0
	_rays.modulate.a = 0.0
	_rays.scale = Vector2(0.5, 0.5)
	_rays.rotation = 0.0
	_flash.color.a = 0.0
	_icon.scale = Vector2.ZERO
	_icon.position = Vector2(size.x * 0.5 - _icon.size.x * 0.5, size.y * 0.5 + ICON_CENTER_OFFSET_Y - _icon.size.y * 0.5)
	_banner.position = Vector2((size.x - BANNER_WIDTH) * 0.5, -240.0)
	_hint_label.modulate.a = 0.0
	_burst.emitting = false
	_sparkles.emitting = false


func _start_timeline() -> void:
	var size := _viewport_size()
	var center := Vector2(size.x * 0.5, size.y * 0.5 + ICON_CENTER_OFFSET_Y)
	_rays.position = center - _rays.size * 0.5
	_burst.position = center
	_sparkles.position = center

	_kill_tweens()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_dim, "color:a", 0.62, 0.35)
	_tween.tween_property(_rays, "modulate:a", 0.9, 0.6)
	_tween.tween_property(_rays, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# destello blanco al aparecer el amuleto
	_tween.tween_property(_flash, "color:a", 0.85, 0.08).set_delay(0.15)
	_tween.tween_property(_flash, "color:a", 0.0, 0.45).set_delay(0.23)
	# el amuleto crece con rebote
	_tween.tween_property(_icon, "scale", Vector2.ONE, 0.7).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_emit_particles).set_delay(0.45)
	_tween.tween_callback(_start_bobbing).set_delay(0.95)
	# el cartel baja desde arriba con rebote
	_tween.tween_property(_banner, "position:y", BANNER_REST_Y, 0.65).set_delay(0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_hint_label, "modulate:a", 0.85, 0.4).set_delay(MIN_SKIPPABLE_TIME)


func _emit_particles() -> void:
	_burst.restart()
	_burst.emitting = true
	_sparkles.emitting = true


## El amuleto flota suavemente arriba y abajo mientras dura el cartel.
func _start_bobbing() -> void:
	if _bob_tween != null and _bob_tween.is_valid():
		_bob_tween.kill()
	var rest_y := _icon.position.y
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_icon, "position:y", rest_y - 7.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_icon, "position:y", rest_y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _begin_fade_out() -> void:
	_fading = true
	_kill_tweens()
	_sparkles.emitting = false
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", 0.0, FADE_OUT_TIME)
	_tween.tween_callback(_finish)


func _finish() -> void:
	_kill_tweens()
	_burst.emitting = false
	_sparkles.emitting = false
	visible = false
	_playing = false
	_fading = false
	get_tree().paused = _paused_before
	finished.emit()


func _kill_tweens() -> void:
	for tween in [_tween, _bob_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_tween = null
	_bob_tween = null


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP # evita clics sobre el juego
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.05, 0.0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	_rays = LightRays.new()
	_rays.size = Vector2(1500, 1500)
	_root.add_child(_rays)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(192, 192)
	_icon.size = Vector2(192, 192)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.pivot_offset = Vector2(96, 96)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_icon)

	_burst = _make_particles(true)
	_burst.amount = 56
	_burst.lifetime = 1.5
	_burst.explosiveness = 1.0
	_burst.direction = Vector2.UP
	_burst.spread = 180.0
	_burst.initial_velocity_min = 150.0
	_burst.initial_velocity_max = 380.0
	_burst.gravity = Vector2(0, 180)
	_burst.damping_min = 40.0
	_burst.damping_max = 80.0
	_burst.scale_amount_min = 3.0
	_burst.scale_amount_max = 6.0
	_root.add_child(_burst)

	_sparkles = _make_particles(false)
	_sparkles.amount = 28
	_sparkles.lifetime = 1.6
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_sparkles.emission_sphere_radius = 110.0
	_sparkles.direction = Vector2.UP
	_sparkles.spread = 20.0
	_sparkles.initial_velocity_min = 12.0
	_sparkles.initial_velocity_max = 30.0
	_sparkles.gravity = Vector2(0, -10)
	_sparkles.scale_amount_min = 2.0
	_sparkles.scale_amount_max = 4.0
	_root.add_child(_sparkles)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

	_banner = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.11, 0.96)
	style.set_border_width_all(3)
	style.border_color = Color(0.82, 0.68, 0.32, 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	_banner.add_theme_stylebox_override("panel", style)
	_banner.custom_minimum_size = Vector2(BANNER_WIDTH, 0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_banner)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_banner.add_child(column)
	_title_label = _make_label(20, GOLD)
	_name_label = _make_label(38, CREAM)
	_sub_label = _make_label(16, Color(0.72, 0.69, 0.64, 1.0))
	column.add_child(_title_label)
	column.add_child(_name_label)
	column.add_child(_sub_label)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.9, 0.85))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_label.offset_left = -200
	_hint_label.offset_right = 200
	_hint_label.offset_top = -64
	_hint_label.offset_bottom = -34
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint_label)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Partículas de CPU (rinden bien en Web). Cuadraditos dorados que se desvanecen.
func _make_particles(one_shot_mode: bool) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = one_shot_mode
	particles.local_coords = false
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.93, 0.6, 1.0))
	fade.set_color(1, Color(1.0, 0.75, 0.3, 0.0))
	particles.color_ramp = fade
	return particles
