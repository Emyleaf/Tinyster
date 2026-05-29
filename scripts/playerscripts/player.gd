class_name Player extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var state_machine : PlayerStateMachine = $StateMachine

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var direction : Vector2 = Vector2.ZERO
var cardinal_direction : Vector2 = Vector2.ZERO

signal DirectionChanged(new_direction : Vector2)

func _ready():
	state_machine.Initialize(self)

func _process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _physics_process(_delta: float) -> void:
	move_and_slide()

func UpdateAnimation(state : String) -> void:
	animation_player.play(state)
	pass

func SetDirection() -> bool:
	if direction == Vector2.ZERO:
		return false

	var direction_id : int = int(round((direction + cardinal_direction * 0.1).angle()/ TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]

	if new_dir == cardinal_direction:
		return false

	cardinal_direction = new_dir
	DirectionChanged.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true


func AnimDirection() -> String:
	if direction.y < 0:
		return "up"
	elif direction.y > 0:
		return "down"
	else:
		return "side"
