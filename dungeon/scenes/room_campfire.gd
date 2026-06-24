extends Node2D

var doors_to_open : Array[Door] = []

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var door_north: Door = $DoorN
@onready var door_south: Door = $DoorS
@onready var door_east: Door = $DoorE
@onready var trans_north: LevelTransition = $TransN
@onready var trans_south: LevelTransition = $TransS
@onready var trans_east: LevelTransition = $TransE
@onready var spawn_from_west: Marker2D = $SpawnFromWest
@onready var spawn_from_north: Marker2D = $SpawnFromNorth
@onready var spawn_from_south: Marker2D = $SpawnFromSouth


func _ready():
	_setup_doors_to_open()
	_position_player_on_entry()
	
	if DungeonManager.last_room:
		print("Stanza - Riga: %d, Colonna: %d" % [DungeonManager.last_room.column+1, DungeonManager.last_room.row])
	
	trans_north.entered.connect(func(_b): _on_transition(Room.Direction.NORTH))
	trans_south.entered.connect(func(_b): _on_transition(Room.Direction.SOUTH))
	trans_east.entered.connect(func(_b): _on_transition(Room.Direction.FORWARD))


func _setup_doors_to_open() -> void:
	var current_room := DungeonManager.last_room
	if current_room == null:
		return
	for next_room: Room in current_room.next_rooms:
		match current_room.get_direction_to(next_room):
			Room.Direction.NORTH:
				doors_to_open.append(door_north)
			Room.Direction.SOUTH:
				doors_to_open.append(door_south)
			Room.Direction.FORWARD:
				doors_to_open.append(door_east)
		
	await get_tree().create_timer(0.5).timeout
	for door in doors_to_open:
		door.open_door()

func _position_player_on_entry() -> void:
	var spawn_point: Marker2D = spawn_from_west
	match DungeonManager.last_exit_direction:
		Room.Direction.NORTH:
			spawn_point = spawn_from_south
		Room.Direction.SOUTH:
			spawn_point = spawn_from_north
			
	if PlayerManager.player == null:
		PlayerManager.player = PlayerManager.PLAYER.instantiate()
		add_sibling(PlayerManager.player)
		if PlayerManager.player.has_node("Camera2D"):
			PlayerManager.player.get_node("Camera2D").queue_free()
	
	PlayerManager.player.global_position = spawn_point.global_position
	
func _on_transition(direction: Room.Direction) -> void:
	if DungeonManager.is_transitioning:
		return
	var next_room := DungeonManager.last_room.get_next_room_in_direction(direction)
	if next_room == null:
		return
	DungeonManager.enter_room(next_room, direction)
