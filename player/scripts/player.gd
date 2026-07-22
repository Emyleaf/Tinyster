class_name Player extends CharacterBody2D

signal direction_changed(new_direction : Vector2)
signal player_damaged(hurt_box : HurtBox)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var direction : Vector2 = Vector2.ZERO
var cardinal_direction : Vector2 = Vector2.DOWN

var invulnerable : bool = false
var facing_right : bool = true

var current_member : PartyMember

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var effect_animation_player : AnimationPlayer = $EffectAnimationPlayer
@onready var hit_box : HitBox = $HitBox
@onready var sprite : Sprite2D = $Sprite2D
@onready var state_machine : PlayerStateMachine = $StateMachine
@onready var camera_2d_player : Camera2D = $Camera2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

func _ready():
	PlayerManager.player = self
	state_machine.Initialize(self)
	hit_box.damaged.connect(_take_damage)
	PartyManager.member_changed.connect(_on_member_changed)
	PartyManager.party_wiped.connect(_on_party_wiped)
	var active := PartyManager.get_active()
	if active:
		_on_member_changed(PartyManager.active_index, active)

func _on_member_changed(_index : int, member : PartyMember) -> void:
	current_member = member
	sprite.texture = member.data.sprite_sheet
	# Annulla l'attacco in corso e ricarica l'animazione del nuovo personaggio
	state_machine.reset_to_idle()

## Le stat vengono SEMPRE dal membro attivo
func get_speed() -> float:
	return current_member.get_speed() if current_member else 200.0

func get_atk() -> int:
	return current_member.get_atk() if current_member else 1

func get_current_member() -> PartyMember:
	return current_member

func _process(_delta: float) -> void:
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

func _physics_process(_delta: float) -> void:
	move_and_slide()

## state = "idle", "walk_side", "attack_side", "stun"
func update_animation(state : String) -> void:
	if current_member == null:
		return
	animation_player.play(current_member.data.char_name + "/" + state)

func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false
	if direction.x != 0:
		facing_right = direction.x > 0
		sprite.flip_h = not facing_right
		direction_changed.emit(direction)
	return true

func _take_damage(hurt_box : HurtBox) -> void:
	if invulnerable == true:
		return
	PartyManager.damage_active(hurt_box.damage)
	player_damaged.emit(hurt_box)

func _on_party_wiped() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func make_invulnerable(_duration : float) -> void:
	invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer(_duration).timeout
	invulnerable = false
	hit_box.monitoring = true
