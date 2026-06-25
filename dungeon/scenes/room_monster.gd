extends Node2D

var enemy_scene = preload("res://enemies/slime/slime.tscn")
var player_mask_radius = 200
var enemy_count : int = 0
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
	randomize()
	enemy_count = randi_range(3, 6)

	_setup_doors_to_open()
	_position_player_on_entry()
	
	if DungeonManager.last_room:
		print("Stanza - Riga: %d, Colonna: %d" % [DungeonManager.last_room.column+1, DungeonManager.last_room.row])
	
	trans_north.entered.connect(func(_b): _on_transition(Room.Direction.NORTH))
	trans_south.entered.connect(func(_b): _on_transition(Room.Direction.SOUTH))
	trans_east.entered.connect(func(_b): _on_transition(Room.Direction.FORWARD))

	await get_tree().create_timer(1.0).timeout
	spawn_enemies()


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

func spawn_enemies():
	var all_cells = tilemap.get_used_cells()
	var valid_cells = []

	for cell in all_cells:
		var world_pos = tilemap.map_to_local(cell)
		if cell.y == 0 or cell.x == 0 or cell.x == 1 or cell.y == 1 or cell.y == 6 or cell.x == 12 or cell.x == 11:
			pass
		elif PlayerManager.player.global_position.distance_to(world_pos) > player_mask_radius:
			valid_cells.append(cell)

	if valid_cells.is_empty():
		return

	valid_cells.shuffle()
	
	var run_node = get_parent()

	for i in enemy_count:
		var world_pos = tilemap.map_to_local(valid_cells[i])
		var enemy = enemy_scene.instantiate() 
		enemy.enemy_destroyed.connect(_on_slime_enemy_destroyed)
		enemy.global_position = world_pos
		
		run_node.call_deferred("add_child", enemy)

		enemy.call_deferred("play_start_animation")
		await get_tree().create_timer(0.1).timeout



func _on_slime_enemy_destroyed(hurt_box: HurtBox) -> void:
	enemy_count -= 1
	print(enemy_count)
	if enemy_count <= 0:
		print("STANZA COMPLETA, ENEMY COUNTER %s" % enemy_count)
		
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
	var previous := DungeonManager.last_room 
	DungeonManager.enter_room(next_room, direction)
	
	var map := get_tree().get_first_node_in_group("Map") as Map
	if map:
		map._update_visual_selection(next_room, previous)
