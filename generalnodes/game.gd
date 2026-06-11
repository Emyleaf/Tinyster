class_name Run extends Node

const MAP_SCENE := preload("res://dungeon/scenes/map.tscn")
const BATTLE_SCENE := preload("res://dungeon/scenes/room_combat.tscn")

var map_open := false
@onready var map_node = $Map   # cambia il path se necessario

func _unhandled_input(event):
	if event.is_action_pressed("map"):
		map_open = !map_open
		map_node.visible = map_open
