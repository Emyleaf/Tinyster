class_name Player extends CharacterBody2D

signal direction_changed(new_direction : Vector2)
signal player_damaged(hurt_box : HurtBox)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var direction : Vector2 = Vector2.ZERO
var cardinal_direction : Vector2 = Vector2.DOWN

var invulnerable : bool = false

var facing_right : bool = true

var current_member: PartyMember

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
	var active = PartyManager.get_active()
	if active:
		_on_member_changed(PartyManager.active_index, active)
	pass

func _on_member_changed(index: int, member: PartyMember):
	current_member = member
	apply_character_visuals(member.data)
	
func apply_character_visuals(data: CharacterData):
	PlayerManager.char_name = data.char_name
	# Cambia animazioni
	if sprite.texture != data.sprite_sheet:
		sprite.texture = data.sprite_sheet
		animation_player.play(PlayerManager.char_name + "/idle")
		
func apply_character_data(data: CharacterData) -> void:
	PlayerManager.speed = data.speed
	sprite.texture = data.sprite_sheet
	pass

## Metodo utile per la State Machine o altri sistemi
func get_current_speed() -> float:
	if current_member:
		return current_member.data.speed
	return 300.0

func get_current_member() -> PartyMember:
	return current_member

func _process(_delta: float) -> void:
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	pass

func _physics_process(_delta: float) -> void:
	move_and_slide()

func update_animation(state : String) -> void:
	animation_player.play(state)
	pass
	
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
	update_hp(-hurt_box.damage)
	if PlayerManager.current_hp > 0:
		player_damaged.emit(hurt_box)
	else:
		player_damaged.emit(hurt_box)
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
	pass

func update_hp( delta : int) -> void:
	PlayerManager.current_hp = clamp(PlayerManager.current_hp + delta, 0, PlayerManager.max_hp)
	pass

func make_invulnerable(_duration : float) -> void:
	invulnerable = true
	hit_box.monitoring = false
	
	await get_tree().create_timer(_duration).timeout
	invulnerable = false
	hit_box.monitoring = true
	pass
