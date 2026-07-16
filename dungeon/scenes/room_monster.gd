extends Node2D

@export var door_scene: PackedScene = preload("res://dungeon/scenes/door.tscn")

var enemy_scene = preload("res://enemies/slime/slime.tscn")
var player_mask_radius = 600
var enemy_count : int = 0

@onready var generator: WalkerGenerator = $WalkerGenerator
@onready var tilemap: TileMapLayer = $Ground

var door_instance: Door

func _ready() -> void:
	generator.spawn_ready.connect(_on_spawn_ready)
	generator.exit_ready.connect(_on_exit_ready)
	generator.generate_map()
	generator.place_spawn_and_exit()
	
	randomize()
	enemy_count = randi_range(10, 15)

	#_position_player_on_entry()
	
	await get_tree().create_timer(1.0).timeout
	spawn_enemies()
	
func spawn_enemies() -> void:
	var run_node = get_parent()

	var valid_cells: Array[Vector2i] = generator.floor_cells.duplicate()

	var spawn_cell: Vector2i = tilemap.local_to_map(PlayerManager.player.global_position)
	var exit_cell: Vector2i = spawn_cell
	if door_instance != null:
		exit_cell = tilemap.local_to_map(door_instance.global_position) #qui da modificare e mettere tile stairs anziché istanziare una porta sec me

	valid_cells = valid_cells.filter(func(c): return c != spawn_cell and c != exit_cell)
	valid_cells.shuffle()

	var spawned := 0
	for cell in valid_cells:
		if spawned >= enemy_count:
			break

		var world_pos = tilemap.map_to_local(cell)
		var enemy = enemy_scene.instantiate()
		enemy.enemy_destroyed.connect(_on_slime_enemy_destroyed)
		enemy.global_position = world_pos

		run_node.call_deferred("add_child", enemy)
		enemy.call_deferred("play_start_animation")

		spawned += 1
		await get_tree().create_timer(0.1).timeout

	enemy_count = spawned
	
func _on_slime_enemy_destroyed(hurt_box: HurtBox) -> void:
	enemy_count -= 1
	print(enemy_count)
	if enemy_count <= 0:
		print("STANZA COMPLETA, ENEMY COUNTER %s" % enemy_count)
		await get_tree().create_timer(0.5).timeout
		

func _on_spawn_ready(world_pos: Vector2) -> void:
	print("Spawn ricevuto: ", world_pos)
	_spawn_player(world_pos)

func _on_exit_ready(world_pos: Vector2) -> void:
	print("Exit ricevuto: ", world_pos)
	_spawn_door(world_pos)

func _spawn_player(world_pos: Vector2) -> void:
	if PlayerManager.player == null:
		PlayerManager.player = PlayerManager.PLAYER.instantiate()
		add_sibling(PlayerManager.player)
		#add_child(PlayerManager.player)

	PlayerManager.player.global_position = world_pos
	#PlayerManager.player.get_node("Camera2D").reset_smoothing()

func _spawn_door(world_pos: Vector2) -> void:
	door_instance = door_scene.instantiate()
	add_child(door_instance)
	door_instance.global_position = world_pos


#extends Node2D
#
#var enemy_scene = preload("res://enemies/slime/slime.tscn")
#var player_mask_radius = 200
#var enemy_count : int = 0
#var doors_to_open : Array[Door] = []
#
#signal room_completed
#signal room_exited
#
#@onready var tilemap: TileMapLayer = $Ground
#
#
#func _ready():
	#pass
	#randomize()
	#enemy_count = randi_range(3, 6)
#
	##_position_player_on_entry()
	#
	#await get_tree().create_timer(1.0).timeout
	#spawn_enemies()

#func spawn_enemies():
	#var all_cells = tilemap.get_used_cells()
	#var valid_cells = []
#
	#for cell in all_cells:
		#var world_pos = tilemap.map_to_local(cell)
		#if cell.y == 0 or cell.x == 0 or cell.x == 1 or cell.y == 1 or cell.y == 6 or cell.x == 12 or cell.x == 11:
			#pass
		#elif PlayerManager.player.global_position.distance_to(world_pos) > player_mask_radius:
			#valid_cells.append(cell)
#
	#if valid_cells.is_empty():
		#return
#
	#valid_cells.shuffle()
	#
	#var run_node = get_parent()
#
	#for i in enemy_count:
		#var world_pos = tilemap.map_to_local(valid_cells[i])
		#var enemy = enemy_scene.instantiate() 
		#enemy.enemy_destroyed.connect(_on_slime_enemy_destroyed)
		#enemy.global_position = world_pos
		#
		#run_node.call_deferred("add_child", enemy)
#
		#enemy.call_deferred("play_start_animation")
		#await get_tree().create_timer(0.1).timeout
#
#func _on_slime_enemy_destroyed(hurt_box: HurtBox) -> void:
	#enemy_count -= 1
	#print(enemy_count)
	#if enemy_count <= 0:
		#print("STANZA COMPLETA, ENEMY COUNTER %s" % enemy_count)
		#await get_tree().create_timer(0.5).timeout
		#
#func _on_trans_east_entered(_body: Node2D) -> void:
	#if enemy_count <= 0:
		#room_exited.emit()

#func _position_player_on_entry() -> void:
	#if PlayerManager.player == null:
		#PlayerManager.player = PlayerManager.PLAYER.instantiate()
		#add_sibling(PlayerManager.player)
		#if PlayerManager.player.has_node("Camera2D"):
			#PlayerManager.player.get_node("Camera2D").queue_free()
	#
	#PlayerManager.player.global_position = spawn_point.global_position
