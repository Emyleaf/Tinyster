class_name Run extends Node2D

# Man mano che avrai le altre stanze pronte, aggiungi qui le entry (TREASURE, EVENT, BOSS...)
const ROOM_SCENES := {
	Room.Type.MONSTER: preload("res://dungeon/rooms/room_monster.tscn"),
	Room.Type.SHOP: preload("res://dungeon/rooms/room_shop.tscn"),
	Room.Type.CAMPFIRE: preload("res://dungeon/rooms/room_campfire.tscn"),
	Room.Type.TREASURE: preload("res://dungeon/rooms/room_monster.tscn"), #placeholder
	Room.Type.BOSS: preload("res://dungeon/rooms/room_monster.tscn"), #placeholder
	Room.Type.EVENT: preload("res://dungeon/rooms/room_monster.tscn"), #placeholder
}

@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var party_hud := get_tree().get_first_node_in_group("PartyHUD")

var current_room_node: Node2D = null
var is_transitioning: bool = false


func _ready() -> void:
	GameManager.current_run = self
	map.room_chosen.connect(_on_room_chosen)
	current_view.add_to_group("CurrentView")


func _on_room_chosen(room: Room) -> void:
	if is_transitioning:
		return
	_enter_room(room)


func _enter_room(room: Room) -> void:
	is_transitioning = true
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished

	var scene: PackedScene = ROOM_SCENES.get(room.type)

	map.hide_map()

	current_room_node = scene.instantiate()
	current_view.add_child(current_room_node)

	if current_room_node.has_signal("room_exited"):
		current_room_node.room_exited.connect(_on_room_exited)

	is_transitioning = false


func _on_room_exited() -> void:
	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null

	SaveManager.save_game()

	map.show_map()
	map.unlock_next_rooms()
