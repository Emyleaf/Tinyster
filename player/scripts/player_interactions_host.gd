class_name PlayerInteractionsHost extends Node2D

@onready var player : Player = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.direction_changed.connect(update_direction)
	pass # Replace with function body.

func update_direction(dir : Vector2) -> void:
	match dir:
		Vector2.LEFT:
			position.x = -10
		Vector2.RIGHT:
			position.x = 10
	pass
