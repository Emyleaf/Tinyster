# DungeonManager.gd
extends Node

var map_data: Array[Array] = []
var floors_climbed: int = 0
var last_room: Room = null
var last_exit_direction: Room.Direction = Room.Direction.FORWARD
var current_room_node: Node2D = null  # riferimento alla stanza attuale nel World

const MAP_SCENE := preload("res://dungeon/scenes/map.tscn")
const ROOM_SCENES := {
	Room.Type.MONSTER: preload("res://dungeon/scenes/room_monster.tscn"),
	Room.Type.SHOP: preload("res://dungeon/scenes/room_shop.tscn")
}

# Riferimento al generatore (puoi anche istanziarlo qui)
var map_generator: MapGenerator

func _ready() -> void:
	map_generator = MapGenerator.new()

func generate_new_map() -> void:
	map_data = map_generator.generate_map()
	floors_climbed = 0
	last_room = null
	last_exit_direction = Room.Direction.FORWARD
	
func enter_room(room: Room, exit_direction: Room.Direction = Room.Direction.FORWARD):
	last_room = room
	last_exit_direction = exit_direction
	floors_climbed += 1
	
	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null

	var scene = ROOM_SCENES.get(room.type)
	if scene:
		current_room_node = scene.instantiate()
		
		var main = get_node("/root/Main")
		main.add_child(current_room_node)
		var map = get_node("/root/Map")
		main.add_child(map)
