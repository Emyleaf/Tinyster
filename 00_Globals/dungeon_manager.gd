# DungeonManager.gd
extends Node

var map_data: Array[Array] = []
var floors_climbed: int = 0
var last_room: Room = null
var last_exit_direction: Room.Direction = Room.Direction.FORWARD
var current_room_node: Node2D = null  # riferimento alla stanza attuale nel World

var is_transitioning: bool = false

const MAP_SCENE := preload("res://dungeon/scenes/map.tscn")
const ROOM_SCENES := {
	Room.Type.MONSTER: preload("res://dungeon/scenes/room_monster.tscn"),
	Room.Type.SHOP: preload("res://dungeon/scenes/room_shop.tscn"),
	Room.Type.CAMPFIRE: preload("res://dungeon/scenes/room_campfire.tscn")
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
	if is_transitioning:
		return
	
	is_transitioning = true
	
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
		main.call_deferred("add_child", current_room_node)

	call_deferred("_finish_transition")
	
func _finish_transition() -> void:
	await get_tree().create_timer(0.3).timeout   # piccolo buffer prima di riabilitare
	is_transitioning = false

# dungeon_manager.gd
func get_save_data() -> Dictionary:
	var rooms_data: Array = []
	for floor in map_data:
		var floor_rooms: Array = []
		for room in floor:
			var room_dict = {
				"type": room.type,
				"row": room.row,
				"column": room.column,
				"position": {"x": room.position.x, "y": room.position.y},
				"next_rooms": []   # indici (colonna, riga) delle stanze collegate
			}
			for next_room in room.next_rooms:
				room_dict["next_rooms"].append({"col": next_room.column, "row": next_room.row})
			floor_rooms.append(room_dict)
		rooms_data.append(floor_rooms)
	
	return {
		"floors_climbed": floors_climbed,
		"last_room": null if last_room == null else {"col": last_room.column, "row": last_room.row},
		"last_exit_direction": last_exit_direction,
		"map_data": rooms_data
	}

#func load_from_data(data: Dictionary) -> void:
	#floors_climbed = data["floors_climbed"]
	#last_exit_direction = data["last_exit_direction"]
	#
	## Ricostruisci le stanze
	#map_data.clear()
	#for floor_rooms_data in data["map_data"]:
		#var floor: Array[Room] = []
		#for room_dict in floor_rooms_data:
			#var room = Room.new()
			#room.type = room_dict["type"]
			#room.row = int(room_dict["row"])
			#room.column = int(room_dict["column"])
			#room.position = Vector2(float(room_dict["position"]["x"]), float(room_dict["position"]["y"]))
			## next_rooms verrà ricostruito dopo che tutte le stanze sono create
			#floor.append(room)
		#map_data.append(floor)
	#
	## Ora collega i next_rooms usando indici
	#for i in range(data["map_data"].size()):
		#var floor_data = data["map_data"][i]
		#for j in range(floor_data.size()):
			#var room = map_data[i][j]
			#for conn in floor_data[j]["next_rooms"]:
				#var target_floor: int = int(conn["col"])  # ← cast esplicito
				#var target_room: int = int(conn["row"])   # ← cast esplicito
				#room.next_rooms.append(map_data[target_floor][target_room])
	#
	## Recupera last_room
	#var lr = data["last_room"]
	#if lr != null:
		#var col: int = int(lr["col"])
		#var row: int = int(lr["row"])
		#last_room = map_data[col][row]
	#else:
		#last_room = null
		
		
func load_from_data(data: Dictionary) -> void:
	floors_climbed = int(data["floors_climbed"])
	last_exit_direction = data["last_exit_direction"]

	# 1. Ricostruisci tutte le stanze e crea un dizionario (colonna, riga) → Room
	map_data.clear()
	var room_lookup: Dictionary = {}   # chiave: Vector2i(column, row)

	for floor_rooms_data in data["map_data"]:
		var floor: Array[Room] = []
		for room_dict in floor_rooms_data:
			var room = Room.new()
			room.type = room_dict["type"]
			room.row = int(room_dict["row"])
			room.column = int(room_dict["column"])
			room.position = Vector2(
				float(room_dict["position"]["x"]),
				float(room_dict["position"]["y"])
			)
			floor.append(room)
			room_lookup[Vector2i(room.column, room.row)] = room
		map_data.append(floor)

	# 2. Collega i next_rooms usando il lookup
	for floor_rooms_data in data["map_data"]:
		for room_dict in floor_rooms_data:
			var col = int(room_dict["column"])
			var row = int(room_dict["row"])
			var current_room = room_lookup[Vector2i(col, row)]
			
			for conn in room_dict["next_rooms"]:
				var target_col = int(conn["col"])
				var target_row = int(conn["row"])
				var target_key = Vector2i(target_col, target_row)
				if room_lookup.has(target_key):
					current_room.next_rooms.append(room_lookup[target_key])
				else:
					# Se proprio non esiste, ignora senza crash
					push_warning("Connessione a stanza inesistente ignorata: %d,%d" % [target_col, target_row])

	# 3. Recupera last_room
	var lr = data["last_room"]
	if lr != null:
		var col = int(lr["col"])
		var row = int(lr["row"])
		var key = Vector2i(col, row)
		if room_lookup.has(key):
			last_room = room_lookup[key]
		else:
			last_room = null
			push_warning("last_room non trovata nel salvataggio")
	else:
		last_room = null
