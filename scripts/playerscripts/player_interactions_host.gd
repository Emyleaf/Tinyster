class_name PlayerInteractionsHost extends Node2D

@onready var player : Player = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.DirectionChanged.connect(UpdateDirection)
	pass # Replace with function body.

func UpdateDirection(dir : Vector2) -> void:
	match dir:
		Vector2(0,-1):
			rotation_degrees = 0
		Vector2(0,1):
			rotation_degrees = 180
		Vector2(-1,0):
			rotation_degrees = 90
		Vector2(1,0):
			rotation_degrees = -90
		_:
			rotation_degrees = 0
	pass
