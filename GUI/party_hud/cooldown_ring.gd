class_name CooldownRing extends Control

## Anello di ricarica: charge 0.0 = appena usata, 1.0 = pronta.
## Usato sia per l'indicatore ultimate nella lista party sia per i tasti E/Q.

@export var color_ready : Color = Color(1.0, 0.86, 0.42)
@export var color_charging : Color = Color(0.45, 0.78, 1.0)
@export var color_track : Color = Color(0.0, 0.0, 0.0, 0.55)
@export var thickness : float = 5.0

var charge : float = 1.0 :
	set(value):
		value = clampf(value, 0.0, 1.0)
		if is_equal_approx(charge, value):
			return
		charge = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center : Vector2 = size * 0.5
	var radius : float = minf(size.x, size.y) * 0.5 - thickness * 0.5

	# Sfondo scuro dietro l'icona
	draw_circle(center, radius, Color(0.05, 0.07, 0.11, 0.75))
	# Traccia dell'anello
	draw_arc(center, radius, 0.0, TAU, 48, color_track, thickness, true)

	if charge <= 0.0:
		return
	var col : Color = color_ready if charge >= 1.0 else color_charging
	var start : float = -PI * 0.5
	draw_arc(center, radius, start, start + TAU * charge, 64, col, thickness, true)
