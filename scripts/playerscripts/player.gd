class_name Player extends CharacterBody2D

@export var move_speed : float = 500.0
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var state_machine : PlayerStateMachine = $StateMachine

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

	var new_dir : Vector2 = cardinal_direction
	if direction.y == 0:
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN

	if new_dir == cardinal_direction:
		return false

	cardinal_direction = new_dir
	DirectionChanged.emit(new_dir)
	sprite.flip_h = (cardinal_direction == Vector2.LEFT)
	return true

func AnimDirection() -> String:
	if direction.y < 0:
		return "up"
	elif direction.y > 0:
		return "down"
	else:
		return "side"
