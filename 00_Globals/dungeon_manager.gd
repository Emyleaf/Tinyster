# dungeon_manager.gd — Autoload chiamato "DungeonManager"
extends Node

var graph: Array[RoomData] = []
var current_room_id: int = 0
var transitioning: bool = false

# Pacchetti scena per tipo (assegna dall'editor o da codice)
var room_scenes := {
	RoomData.RoomType.START:    preload("res://scenes/rooms/room_start.tscn"),
	RoomData.RoomType.COMBAT:   preload("res://scenes/rooms/room_combat.tscn"),
	RoomData.RoomType.SHOP:     preload("res://scenes/rooms/room_shop.tscn"),
	RoomData.RoomType.BOSS:     preload("res://scenes/rooms/room_boss.tscn"),
	# ... etc
}

func start_dungeon() -> void:
	graph = DungeonGenerator.generate(10)
	current_room_id = 0
	_load_room(0, "south")  # Player entra dalla porta sud (viene da sinistra/basso)

func enter_door(direction: String) -> void:
	if transitioning:
		return
	var room := _get_current_room()
	if not room.connections.has(direction):
		return

	transitioning = true
	var next_id: int = room.connections[direction]
	var enter_from := _opposite(direction)

	# Chiudi la porta dietro (non si torna indietro)
	room.connections.erase(_opposite(direction))

	await _transition_flash()
	_load_room(next_id, enter_from)
	transitioning = false

func _load_room(room_id: int, enter_from: String) -> void:
	current_room_id = room_id
	var room_data := graph[room_id]
	room_data.visited = true

	var packed: PackedScene = room_scenes.get(room_data.type, room_scenes[RoomData.RoomType.COMBAT])
	get_tree().change_scene_to_packed(packed)

	# Passiamo i dati alla nuova stanza appena pronta
	await get_tree().node_added  # attende che la scena sia pronta
	var new_room := get_tree().current_scene
	if new_room.has_method("setup"):
		new_room.setup(room_data, enter_from)

func _transition_flash() -> void:
	# ColorRect nero in CanvasLayer che fa fade in/out
	# Segnale emesso quando l'animazione è completata
	EventBus.emit_signal("room_transition_started")
	await EventBus.room_transition_ended

func _opposite(dir: String) -> String:
	return {"north":"south","south":"north","east":"west","west":"east"}[dir]

func _get_current_room() -> RoomData:
	return graph[current_room_id]
