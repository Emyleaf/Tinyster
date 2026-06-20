class_name Run extends Node2D

const MAP_SCENE := preload("res://dungeon/scenes/map.tscn")
const ROOM_SCENES := {
	Room.Type.MONSTER: preload("res://dungeon/scenes/room_monster.tscn"),
	Room.Type.SHOP: preload("res://dungeon/scenes/room_shop.tscn")
}

@onready var map: Map = $Map
var current_room_node: Node2D

func _ready() -> void:
	GameManager.current_run = self
	self.y_sort_enabled = true
	#PlayerManager.set_as_parent(self)
	map.show_map()
	map.room_selected_to_enter.connect(_on_room_selected_to_enter)

func _on_room_selected_to_enter(room: Room) -> void:
	if current_room_node:
		current_room_node.queue_free()

	var scene: PackedScene = ROOM_SCENES.get(room.type)
	if scene == null:
		push_warning("Nessuna scena per il tipo: %s" % Room.Type.keys()[room.type])
		return

	current_room_node = scene.instantiate()
	add_child.call_deferred(current_room_node)
	map.hide_map()
