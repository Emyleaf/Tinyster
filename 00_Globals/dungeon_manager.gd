# DungeonManager.gd
extends Node

var map_data: Array[Array] = []
var floors_climbed: int = 0
var last_room: Room = null

# Riferimento al generatore (puoi anche istanziarlo qui)
var map_generator: MapGenerator

func _ready() -> void:
	map_generator = MapGenerator.new()

func generate_new_map() -> void:
	map_data = map_generator.generate_map()
	floors_climbed = 0
	last_room = null
