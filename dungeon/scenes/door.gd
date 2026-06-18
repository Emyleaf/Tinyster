class_name Door extends Node2D

var is_open : bool = false

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	pass
	
func open_door() -> void:
	animation_player.play("destroy")
	queue_free()
	pass
	
func close_door() -> void:
	pass
