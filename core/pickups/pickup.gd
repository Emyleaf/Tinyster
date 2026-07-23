class_name Pickup extends Node2D

## Oggetto droppato a terra. Fa lo stesso bounce dei DamageNumber,
## poi si lascia raccogliere automaticamente quando il player entra nel raggio.

enum Kind { KEY }

## <<< CAMBIA QUESTO PATH con la tua icona della chiave >>>
const KEY_TEXTURE : Texture2D = preload("res://props/pickups/art/key.png")

const BOUNCE_DURATION : float = 0.5
const RISE : float = 26.0      ## quanto sale nella prima meta'
const FALL : float = 10.0      ## quanto ricade nella seconda
const DRIFT : float = 10.0     ## deriva orizzontale random, evita sovrapposizioni

## Distanza entro cui il player raccoglie automaticamente
const PICKUP_RADIUS : float = 40.0

var _kind : Kind = Kind.KEY
var _spawn_pos : Vector2 = Vector2.ZERO
var _collectable : bool = false

## Unico punto di ingresso. parent deve essere un nodo persistente della stanza,
## NON il nemico (che viene queue_free() sul colpo letale).
static func spawn(parent : Node, world_pos : Vector2, kind : Kind) -> void:
	var p := Pickup.new()
	p._kind = kind
	p._spawn_pos = world_pos
	# call_deferred: siamo dentro la catena di callback fisiche di HurtBox
	parent.add_child.call_deferred(p)

func _ready() -> void:
	z_index = 50
	global_position = _spawn_pos + Vector2(randf_range(-DRIFT, DRIFT), 0)

	var sprite := Sprite2D.new()
	sprite.texture = _texture_for(_kind)
	add_child(sprite)

	_play_bounce()

func _process(_delta : float) -> void:
	if not _collectable:
		return
	var player : Player = PlayerManager.player
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) <= PICKUP_RADIUS:
		_collect()

func _collect() -> void:
	_collectable = false
	match _kind:
		Kind.KEY:
			RunState.add_key(1)
	queue_free()

func _play_bounce() -> void:
	var start : Vector2 = position
	var top : Vector2 = start + Vector2(0, -RISE)
	var landing : Vector2 = top + Vector2(0, FALL)

	var t := create_tween()
	t.tween_property(self, "position", top, BOUNCE_DURATION * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position", landing, BOUNCE_DURATION * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Raccoglibile solo a bounce finito: cosi' l'animazione si vede sempre,
	# anche se il nemico muore addosso al player
	t.tween_callback(func() -> void: _collectable = true)

func _texture_for(kind : Kind) -> Texture2D:
	match kind:
		Kind.KEY:
			return KEY_TEXTURE
	return null
