class_name Pickup extends RigidBody2D

## Drop fisico. Il nemico lo sputa fuori con un impulso, rimbalza sui muri,
## si ferma per attrito e resta a terra finche' il player non ci passa sopra.
##
## Top-down: la gravita' e' 0, il corpo si muove sul piano del pavimento.
## La "caduta" verticale e' finta: e' un salto animato sullo Sprite2D figlio.

enum Kind { KEY }

const KEY_TEXTURE : Texture2D = preload("res://props/pickups/art/key.png")

## --- Lancio (la tile e' 64px) -------------------------------------------------
const IMPULSE : float = 150.0     ## velocita' iniziale in px/s
const DAMP : float = 5.0          ## frenata: distanza percorsa ~= IMPULSE / DAMP
const BOUNCE : float = 0.6        ## rimbalzo sui muri, 0 = si incolla
const BODY_RADIUS : float = 4.0   ## piccolo: non si incastra negli angoli

## --- Salto visivo -------------------------------------------------------------
const HOP_HEIGHT : float = 18.0
const HOP_DURATION : float = 0.45

## --- Raccolta -----------------------------------------------------------------
const PICKUP_RADIUS : float = 14.0

## Layer fisici, vedi project.godot
const LAYER_PLAYER : int = 1      ## layer 1 "Player"
const LAYER_WALLS : int = 16      ## layer 5 "Walls"

var _kind : Kind = Kind.KEY
var _spawn_pos : Vector2 = Vector2.ZERO
var _collectable : bool = false

var _sprite : Sprite2D
var _pickup_area : Area2D


## Unico punto di ingresso. parent deve essere un nodo persistente della stanza,
## NON il nemico (che viene queue_free() sul colpo letale).
static func spawn(parent : Node, world_pos : Vector2, kind : Kind) -> void:
	var p := Pickup.new()
	p._kind = kind
	p._spawn_pos = world_pos
	# call_deferred: siamo dentro la catena di callback fisiche di HurtBox
	parent.add_child.call_deferred(p)


func _ready() -> void:
	z_index = 1
	global_position = _spawn_pos

	_setup_body()
	_setup_sprite()
	_setup_pickup_area()

	# Sputato fuori in una direzione casuale
	apply_central_impulse(Vector2.RIGHT.rotated(randf() * TAU) * IMPULSE)
	_play_hop()


# --- Costruzione ---------------------------------------------------------------

func _setup_body() -> void:
	gravity_scale = 0.0            # top-down: nessuna gravita', ci pensa _play_hop()
	linear_damp = DAMP
	lock_rotation = true           # l'icona non deve girare su se stessa
	collision_layer = 0            # nessuno deve rilevare il corpo del drop
	collision_mask = LAYER_WALLS   # rimbalza solo sui muri

	var mat := PhysicsMaterial.new()
	mat.bounce = BOUNCE
	mat.friction = 0.0
	physics_material_override = mat

	var circle := CircleShape2D.new()
	circle.radius = BODY_RADIUS
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)


func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _texture_for(_kind)
	add_child(_sprite)


func _setup_pickup_area() -> void:
	var circle := CircleShape2D.new()
	circle.radius = PICKUP_RADIUS
	var shape := CollisionShape2D.new()
	shape.shape = circle

	_pickup_area = Area2D.new()
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = LAYER_PLAYER
	_pickup_area.body_entered.connect(_on_body_entered)
	_pickup_area.add_child(shape)
	add_child(_pickup_area)


# --- Caduta e raccolta ---------------------------------------------------------

## Il corpo si muove sul pavimento, lo sprite fa il salto verticale.
func _play_hop() -> void:
	var t := create_tween()
	t.tween_property(_sprite, "position:y", -HOP_HEIGHT, HOP_DURATION * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "position:y", 0.0, HOP_DURATION * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Raccoglibile solo dopo l'atterraggio: cosi' il drop si vede sempre,
	# anche se il nemico muore addosso al player
	t.tween_callback(_land)


func _land() -> void:
	_collectable = true
	# Se il player era gia' fermo sopra al drop, body_entered non scattera' mai
	for body in _pickup_area.get_overlapping_bodies():
		if body is Player:
			_collect()
			return


func _on_body_entered(body : Node2D) -> void:
	if body is Player:
		_collect()


func _collect() -> void:
	if not _collectable:
		return
	_collectable = false
	match _kind:
		Kind.KEY:
			RunState.add_key(1)
	queue_free()


func _texture_for(kind : Kind) -> Texture2D:
	match kind:
		Kind.KEY:
			return KEY_TEXTURE
	return null
