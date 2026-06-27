extends Node

const PLAYER = preload("res://player/player.tscn")

var player : Player
var player_spawned : bool = false

func set_health(hp:int, max_hp:int) -> void:
	player.max_hp = max_hp
	player.hp = hp
	player.update_hp(0)
