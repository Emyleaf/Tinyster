class_name Map extends Node2D

const SCROLL_SPEED := 15
const MAP_ROOM = preload("res://dungeon/scenes/map_room.tscn")
const MAP_LINE = preload("res://dungeon/scenes/map_line.tscn")

@export var player_camera_path: NodePath

@onready var map : Node2D = $"."
@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D
@onready var player_camera_2d: Camera2D = null

var camera_edge_y: float

var is_map_open := false
		
func _open_map():
	is_map_open = true
	get_tree().paused = true
	set_physics_process(false)
	map.show()
	
func _close_map():
	is_map_open = false
	get_tree().paused = false
	map.hide()
	set_physics_process(true)

func _ready() -> void:
	camera_edge_y = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)
	if DungeonManager.map_data.is_empty():
		DungeonManager.generate_new_map()
	create_map()
	unlock_floor(0)
	if not PlayerManager.player:
		await get_tree().process_frame  # aspetta un frame, oppure connetti il segnale
	_update_player_camera_reference()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("map"):
		if map.visible: 
			_close_map()
		else:
			_open_map()
	
	if map.visible and event.is_action_pressed("scroll_up"):
		camera_2d.position.x += SCROLL_SPEED
	elif map.visible and event.is_action_pressed("scroll_down"):
		camera_2d.position.x -= SCROLL_SPEED

	camera_2d.position.x = clamp(camera_2d.position.x, 0, camera_edge_y)

func generate_new_map() -> void:
	DungeonManager.generate_new_map()
	create_map()

func create_map() -> void:
	for current_floor: Array in DungeonManager.map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(DungeonManager.map_data[MapGenerator.FLOORS - 1][middle])

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

func hide_map() -> void:
	hide()

func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
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

signal room_selected_to_enter(room: Room)

func _update_player_camera_reference() -> void:
	if PlayerManager.player:
		player_camera_2d = PlayerManager.player.camera_2d_player

func enter_room(room: Room, exit_direction: Room.Direction = Room.Direction.FORWARD) -> void:
	var previous_room := DungeonManager.last_room
	
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false
		if map_room.room == room:
			room.selected = true
			map_room.show_selected()
		elif previous_room and map_room.room == previous_room:
			previous_room.selected = false
			map_room.hide_selected()

	DungeonManager.last_room = room
	DungeonManager.last_exit_direction = exit_direction
	DungeonManager.floors_climbed += 1
	room_selected_to_enter.emit(room)
	

func _on_map_room_selected(room: Room) -> void:
	enter_room(room)
