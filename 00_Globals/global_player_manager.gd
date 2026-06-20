extends Node

const PLAYER = preload("res://player/player.tscn")

var player : Player
var player_spawned : bool = false

func _ready() -> void:
	player = PLAYER.instantiate()
	add_child(player)
	player.visible = false
	player.set_physics_process(false)
	player.set_process(false)

func activate(parent: Node, global_pos: Vector2) -> void:
	if player.get_parent() != parent:
		player.get_parent().remove_child(player)
		parent.add_child(player)
	player.global_position = global_pos
	player.visible = true
	player.set_physics_process(true)
	player.set_process(true)
	player_spawned = true
