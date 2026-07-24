# DungeonManager.gd
extends Node

var map_data: Array[Array] = []
var floors_climbed: int = 0
var last_room: Room = null
var current_room_node: Node2D = null  # riferimento alla stanza attuale nel World

var is_transitioning: bool = false

@onready var party_hud := get_tree().get_first_node_in_group("PartyHUD")

const MAP_SCENE := preload("res://dungeon/map/map.tscn")

# Riferimento al generatore (puoi anche istanziarlo qui)
var map_generator: MapGenerator

func _ready() -> void:
	map_generator = MapGenerator.new()

func generate_new_map() -> void:
	map_data = map_generator.generate_map()
	floors_climbed = 0
	last_room = null
	
func _finish_transition() -> void:
	await get_tree().create_timer(0.3).timeout   # piccolo buffer prima di riabilitare
	is_transitioning = false
	SaveManager.save_game()

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
				"selected": room.selected,
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
		"map_data": rooms_data
	}

		
func load_from_data(data: Dictionary) -> void:
	floors_climbed = int(data.get("floors_climbed", 0))

	# 1. Ricostruisci tutte le stanze e crea un dizionario (colonna, riga) → Room
	map_data.clear()
	var room_lookup: Dictionary = {}   # chiave: Vector2i(column, row)

	for floor_rooms_data in data.get("map_data", []):
		var floor: Array[Room] = []
		for room_dict in floor_rooms_data:
			var room = Room.new()
			room.type = int(room_dict["type"])
			room.row = int(room_dict["row"])
			room.column = int(room_dict["column"])
			room.selected = room_dict.get("selected", false)
			room.position = Vector2(
				float(room_dict["position"]["x"]),
				float(room_dict["position"]["y"])
			)
			floor.append(room)
			room_lookup[Vector2i(room.column, room.row)] = room
		map_data.append(floor)

	# 2. Collega i next_rooms usando il lookup
	for floor_rooms_data in data.get("map_data", []):
		for room_dict in floor_rooms_data:
			var col = int(room_dict["column"])
			var row = int(room_dict["row"])
			var current_room = room_lookup[Vector2i(col, row)]
			
			for conn in room_dict.get("next_rooms", []):
				var target_col = int(conn["col"])
				var target_row = int(conn["row"])
				var target_key = Vector2i(target_col, target_row)
				if room_lookup.has(target_key):
					current_room.next_rooms.append(room_lookup[target_key])
				else:
					# Se proprio non esiste, ignora senza crash
					push_warning("Connessione a stanza inesistente ignorata: %d,%d" % [target_col, target_row])

	# 3. Recupera last_room
	var lr = data.get("last_room", null)
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

func complete_room() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished

	# 1. Svuota completamente la CurrentView (stanza + eventuali residui, es. nemici
	#    che vengono aggiunti come figli di CurrentView e non della Room stessa)
	var current_view := get_tree().get_first_node_in_group("CurrentView")
	if current_view:
		for child in current_view.get_children():
			child.queue_free()

	# ripulisci anche il vecchio riferimento legacy, se mai usato
	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null

	# 2. Tre carte buff: si sceglie prima di rivedere la mappa.
	#    La stanza falo' non le da': la sua ricompensa e' la cura del cuore.
	if last_room == null or last_room.type != Room.Type.CAMPFIRE:
		var cards : Array[RunBuff] = BalanceConfig.roll_buffs(BalanceConfig.BUFF_CARDS)
		var buff : RunBuff = await BuffSelect.open(get_tree().root, cards)
		RunState.add_buff(buff)

	# 3. Riapri la mappa e sblocca le stanze adiacenti a quella appena completata
	#    (last_room è già quella giusta: viene settato in map.gd al momento della
	#    SELEZIONE, non dell'uscita, quindi non va incrementato floors_climbed qui)
	var map := get_tree().get_first_node_in_group("Map") as Map
	if map:
		map.show_map()
		map.unlock_next_rooms()

	call_deferred("_finish_transition")   # resetta is_transitioning + salva, dopo un piccolo buffer
