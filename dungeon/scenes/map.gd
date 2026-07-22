class_name Map extends Node2D

signal room_chosen(room: Room)

const SCROLL_SPEED := 15
const MAP_ROOM = preload("res://dungeon/scenes/map_room.tscn")
const MAP_LINE = preload("res://dungeon/scenes/map_line.tscn")

@onready var map : Node2D = $"."
@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D
@onready var player_camera_2d: Camera2D = null
@onready var party_hud := get_tree().get_first_node_in_group("PartyHUD")

var camera_edge_y: float

var is_map_open := false

func _ready() -> void:
	camera_edge_y = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)
	if DungeonManager.map_data.is_empty():
		DungeonManager.generate_new_map()
	create_map()
		
	unlock_floor(0)
	if not PlayerManager.player:
		await get_tree().process_frame  # aspetta un frame, oppure connetti il segnale
	_update_player_camera_reference()

func _unhandled_input(event: InputEvent) -> void:
	pass
	
func generate_new_map() -> void:
	DungeonManager.generate_new_map()
	create_map()
	
func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	DungeonManager.floors_climbed = floors_completed
	DungeonManager.map_data = map
	DungeonManager.last_room = last_room_climbed
	create_map()
	
	if DungeonManager.floors_climbed > 0:
		unlock_next_rooms()
	else:
		unlock_floor()

func create_map() -> void:
	for current_floor: Array in DungeonManager.map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	#posiziona la room Boss nel mezzo
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(DungeonManager.map_data[MapGenerator.FLOORS - 1][middle])

	#posiziona la mappa all'interno dello schermo, senza questo codice andrebbe fuori screen
	var map_width_pixels := (MapGenerator.MAP_WIDTH - 1) * MapGenerator.X_DIST
	visuals.position.y = (get_viewport_rect().size.y - map_width_pixels) * 0.08
	visuals.position.x = get_viewport_rect().size.x * 0.03

func unlock_floor(which_floor: int = DungeonManager.floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true

func unlock_next_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
		if DungeonManager.last_room.next_rooms.has(map_room.room):
			map_room.available = true

func show_map() -> void:
	show()
	camera_2d.enabled = true
	_refresh_party_hud()

func hide_map() -> void:
	hide()
	camera_2d.enabled = false
	_refresh_party_hud()

func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)

	if room.selected and room.row < DungeonManager.floors_climbed:
		new_map_room.show_selected()

func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return

	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		new_map_line.add_point(room.position)
		new_map_line.add_point(next.position)
		lines.add_child(new_map_line)

func _update_player_camera_reference() -> void:
	if PlayerManager.player:
		player_camera_2d = PlayerManager.player.camera_2d_player

func _on_map_room_clicked(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false
			
func _on_map_room_selected(room: Room) -> void:
	DungeonManager.last_room = room
	DungeonManager.floors_climbed += 1
	room_chosen.emit(room)
	
func _refresh_party_hud() -> void:
	if party_hud == null:
		return
	if visible:
		party_hud.hide_party_hud()
	else:
		party_hud.show_party_hud()
