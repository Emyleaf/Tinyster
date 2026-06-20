class_name Run extends Node2D

const MAP = preload("res://dungeon/scenes/map.tscn")

@onready var map = null

func _ready():
	map = MAP.instantiate()
	add_child(map)
	map.show_map()
	map.room_selected_to_enter.connect(_on_room_selected)

func _on_room_selected(room: Room):
	map.room_selected_to_enter.disconnect(_on_room_selected)

	# Comunica a DungeonManager di entrare nella stanza
	DungeonManager.enter_room(room)
	map.hide_map()
	
	var child_node = get_child(1)
	if child_node.get_parent():	
		child_node.get_parent().remove_child(child_node)
		GameManager.main_scene.add_child(child_node)

	queue_free()
