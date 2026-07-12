class_name Run extends Node2D

# Man mano che avrai le altre stanze pronte, aggiungi qui le entry (TREASURE, EVENT, BOSS...)
const ROOM_SCENES := {
	Room.Type.MONSTER: preload("res://dungeon/scenes/room_monster.tscn"),
	Room.Type.SHOP: preload("res://dungeon/scenes/room_shop.tscn"),
	Room.Type.CAMPFIRE: preload("res://dungeon/scenes/room_campfire.tscn"),
}

@onready var map: Mappa = $Map
@onready var current_view: Node = $CurrentView

var current_room_node: Node2D = null
var is_transitioning: bool = false


func _ready() -> void:
	GameManager.current_run = self
	map.room_chosen.connect(_on_room_chosen)


func _on_room_chosen(room: Room) -> void:
	if is_transitioning:
		return
	_enter_room(room)


func _enter_room(room: Room) -> void:
	is_transitioning = true

	var scene: PackedScene = ROOM_SCENES.get(room.type)
	if scene == null:
		push_warning("Nessuna scena assegnata al tipo di stanza %s" % Room.Type.keys()[room.type])
		is_transitioning = false
		return

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

#func switch_to_map():
	## Disabilita la stanza e i suoi abitanti
	#current_view.process_mode = Node.PROCESS_MODE_DISABLED
	#current_view.visible = false
	## Attiva la mappa
	#map.process_mode = Node.PROCESS_MODE_INHERIT
	#map.visible = true
	## Qui puoi anche chiamare $Map.aggiorna_scelte() se serve
	#
#func switch_to_room(room_scene: PackedScene):
	## Disabilita la mappa
	#map.process_mode = Node.PROCESS_MODE_DISABLED
	#map.visible = false
	## Carica la nuova stanza
	#var new_room = room_scene.instantiate()
	#current_view.add_child(new_room)
	## Riabilita CurrentView
	#current_view.process_mode = Node.PROCESS_MODE_INHERIT
	#current_view.visible = true
	## Il Player è già dentro la scena Room? Se sì, eredita il process_mode.
