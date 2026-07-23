extends Node2D

@export var door_scene: PackedScene = preload("res://dungeon/rooms/door.tscn")

var enemy_scene = preload("res://actors/enemies/slime/slime.tscn")
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
