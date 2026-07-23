class_name DamageNumber extends Node2D

const DURATION : float = 0.5
const RISE : float = 26.0      ## quanto sale nella prima meta'
const FALL : float = 10.0      ## quanto ricade nella seconda
const DRIFT : float = 10.0     ## deriva orizzontale random, evita sovrapposizioni

## Sotto questa soglia: bianco, scala 1.0
const SMALL_DAMAGE : float = 10.0
## Sopra questa soglia: rosso, scala MAX_SCALE
const BIG_DAMAGE : float = 50.0
const MAX_SCALE : float = 1.8

const FONT_SIZE : int = 16
const OUTLINE_SIZE : int = 4

## Palette normale: bianco -> giallo -> rosso
const COL_LOW := Color.WHITE
const COL_MID := Color.YELLOW
const COL_HIGH := Color(1.0, 0.25, 0.15)
## Palette critico: azzurro chiaro -> blu scuro
const COL_CRIT_LOW := Color(0.0, 0.577, 0.773, 1.0)
const COL_CRIT_HIGH := Color(0.075, 0.157, 0.722, 1.0)

var _amount : int = 0
var _is_crit : bool = false
var _spawn_pos : Vector2 = Vector2.ZERO

## Unico punto di ingresso. parent deve essere un nodo persistente della stanza,
## NON il nemico (che viene queue_free() sul colpo letale).
static func spawn(parent : Node, world_pos : Vector2, amount : int, is_crit : bool = false) -> void:
	var dn := DamageNumber.new()
	dn._amount = amount
	dn._is_crit = is_crit
	dn._spawn_pos = world_pos
	# call_deferred: siamo dentro la catena di callback fisiche di HurtBox
	parent.add_child.call_deferred(dn)

func _ready() -> void:
	z_index = 100
	global_position = _spawn_pos + Vector2(randf_range(-DRIFT, DRIFT), 0)

	var t : float = clampf(inverse_lerp(SMALL_DAMAGE, BIG_DAMAGE, float(_amount)), 0.0, 1.0)

	var label := Label.new()
	label.text = str(_amount)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", _color_for(t))
	# Outline chiaro sui crit: il blu scuro sparirebbe su sfondo scuro
	label.add_theme_color_override("font_outline_color",
		Color(0.9, 0.97, 1.0) if _is_crit else Color.BLACK)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	add_child(label)
	label.reset_size()
	label.position = -label.size * 0.5   # centra il testo sull'origine del Node2D

	scale = Vector2.ONE * lerpf(1.0, MAX_SCALE, t)

	_play_bounce()

func _play_bounce() -> void:
	var start : Vector2 = position
	var top : Vector2 = start + Vector2(0, -RISE)
	var landing : Vector2 = top + Vector2(0, FALL)

	var move := create_tween()
	move.tween_property(self, "position", top, DURATION * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move.tween_property(self, "position", landing, DURATION * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var fade := create_tween()
	fade.tween_interval(DURATION * 0.55)
	fade.tween_property(self, "modulate:a", 0.0, DURATION * 0.45)
	fade.tween_callback(queue_free)

## crit: azzurro -> blu scuro. normale: bianco -> giallo -> rosso
func _color_for(t : float) -> Color:
	if _is_crit:
		return COL_CRIT_LOW.lerp(COL_CRIT_HIGH, t)
	if t < 0.5:
		return Color.WHITE.lerp(Color.YELLOW, t * 2.0)
	return Color.YELLOW.lerp(Color(1.0, 0.25, 0.15), (t - 0.5) * 2.0)
