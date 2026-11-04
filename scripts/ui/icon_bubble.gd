class_name IconBubble
extends Control

## Burbuja con el pictograma de una palabra clave: fondo redondeado con borde dorado y una cola que apunta al
## cuadro de diálogo. Aparece con un rebote y después late suavemente mientras se muestra.

const RADIUS := 44.0
const ICON_SIZE := 64.0
const BORDER := 3.0
const FILL := Color(0.06, 0.08, 0.11, 0.96)
const EDGE := Color(0.82, 0.68, 0.32, 1.0)
const POP_TIME := 0.38
const PULSE_SCALE := 1.07
const PULSE_TIME := 0.7

var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # el pictograma se ve nítido al ampliarlo
	pivot_offset = Vector2(RADIUS, RADIUS) # crece y late desde el centro del círculo


## Muestra la burbuja con un rebote y, al terminar, un latido suave.
func pop() -> void:
	stop_animation()
	show()
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, POP_TIME * 0.4)
	_tween.chain().tween_callback(_start_pulse)


func stop_animation() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	scale = Vector2.ONE
	modulate.a = 1.0


func is_animating() -> bool:
	return _tween != null and _tween.is_valid()


func _start_pulse() -> void:
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "scale", Vector2.ONE * PULSE_SCALE, PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _draw() -> void:
	var center := Vector2(RADIUS, RADIUS)
	# cola: primero el borde dorado y encima el relleno, para que el contorno continúe el del círculo
	var tail_y := 2.0 * RADIUS - 6.0
	draw_colored_polygon(PackedVector2Array([Vector2(RADIUS - 12.0, tail_y), Vector2(RADIUS + 12.0, tail_y), Vector2(RADIUS, 2.0 * RADIUS + 12.0)]), EDGE)
	draw_circle(center, RADIUS, EDGE)
	draw_colored_polygon(PackedVector2Array([Vector2(RADIUS - 9.0, tail_y), Vector2(RADIUS + 9.0, tail_y), Vector2(RADIUS, 2.0 * RADIUS + 7.0)]), FILL)
	draw_circle(center, RADIUS - BORDER, FILL)
	if texture != null:
		draw_texture_rect(texture, Rect2(center - Vector2(ICON_SIZE, ICON_SIZE) * 0.5, Vector2(ICON_SIZE, ICON_SIZE)), false)
