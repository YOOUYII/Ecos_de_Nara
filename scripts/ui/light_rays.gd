class_name LightRays
extends Control

## Abanico de rayos de luz dorados que giran despacio, con degradado del centro hacia afuera.
## Se usa detrás del ícono en la animación de logro.

const RAY_COUNT := 14
const RAY_WIDTH := 0.45 # fracción del ángulo de cada rayo que se pinta (el resto queda vacío)
const INNER := Color(1.0, 0.86, 0.45, 0.42)
const OUTER := Color(1.0, 0.86, 0.45, 0.0)
const TURN_SPEED := 0.3 # radianes por segundo


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _process(delta: float) -> void:
	rotation += TURN_SPEED * delta


func _draw() -> void:
	var center := size * 0.5
	var radius := size.x * 0.5
	var step := TAU / RAY_COUNT
	for i in RAY_COUNT:
		var start := step * i
		var points := PackedVector2Array([
			center,
			center + Vector2(radius, 0.0).rotated(start),
			center + Vector2(radius, 0.0).rotated(start + step * RAY_WIDTH),
		])
		draw_polygon(points, PackedColorArray([INNER, OUTER, OUTER]))
