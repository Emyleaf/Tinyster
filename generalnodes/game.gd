class_name Run extends Node2D

const MAP_SCENE := preload("res://dungeon/scenes/map.tscn")
const BATTLE_SCENE := preload("res://dungeon/scenes/room_base_forest.tscn")

func _ready() -> void:
	GameManager.current_run = self
	self.y_sort_enabled = true
	PlayerManager.set_as_parent(self)
