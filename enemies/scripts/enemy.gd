class_name Enemy extends CharacterBody2D

signal direction_changed(new_direction : Vector2)
signal enemy_damaged(hurt_box : HurtBox)
signal enemy_destroyed(hurt_box : HurtBox)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@export var max_hp : int = 3
@export var current_hp : int = max_hp

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var player : Player
var invulnerable : bool = false

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var state_machine : EnemyStateMachine = $EnemyStateMachine
@onready var hit_box : HitBox = $HitBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_physics_process(false)
	player = PlayerManager.player
	hit_box.damaged.connect(_take_damage)
	pass
	
func play_start_animation():
	invulnerable = true
	animation_player.play("spawn")
	await animation_player.animation_finished
	
	invulnerable = false
	state_machine.initialize(self)        # inizializza la macchina a stati
	set_physics_process(true)             # riattiva move_and_slide

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	move_and_slide()
	pass

func _physics_process(_delta: float) -> void:
	move_and_slide()

func set_direction(_new_direction: Vector2) -> bool:
	direction = _new_direction.normalized()
	if direction == Vector2.ZERO:
		return false

	var direction_id : int = int(round((direction + cardinal_direction * 0.1).angle()/ TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]

	if new_dir == cardinal_direction:
		return false

	cardinal_direction = new_dir
	direction_changed.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func update_animation(state : String) -> void:
	animation_player.play(state+ "_" + anim_direction())
	pass

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

func _take_damage(hurt_box : HurtBox) -> void:
	if invulnerable:
		return
	current_hp -= hurt_box.damage
	if current_hp <= 0:
		enemy_destroyed.emit(hurt_box)
	else:
		enemy_damaged.emit(hurt_box)
