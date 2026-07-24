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

	var to_spawn : int = mini(enemy_count, valid_cells.size())
	if to_spawn <= 0:
		enemy_count = 0
		return

	# Deciso PRIMA del loop: il loop ha degli await e il player potrebbe
	# uccidere un nemico prima che l'assegnazione avvenga
	var key_index : int = randi_range(0, to_spawn - 1)

	var spawned := 0
	for cell in valid_cells:
		if spawned >= to_spawn:
			break

		var world_pos = tilemap.map_to_local(cell)
		var enemy = enemy_scene.instantiate()
		enemy.has_key = (spawned == key_index)
		# bind: enemy_destroyed passa solo la HurtBox, ci serve anche chi e' morto
		enemy.enemy_destroyed.connect(_on_slime_enemy_destroyed.bind(enemy))
		enemy.global_position = world_pos

		run_node.call_deferred("add_child", enemy)
		enemy.call_deferred("play_start_animation")

		spawned += 1
		await get_tree().create_timer(0.1).timeout

	enemy_count = spawned

func _on_slime_enemy_destroyed(_hurt_box: HurtBox, enemy: Enemy) -> void:
	enemy_count -= 1
	print(enemy_count)

	PartyManager.add_energy(BalanceConfig.ENERGY_PER_KILL)

	if enemy.has_key:
		# self, non enemy: il nemico viene queue_free() a fine animazione destroy
		Pickup.spawn(self, enemy.global_position, Pickup.Kind.KEY)

	if enemy_count <= 0:
		print("STANZA COMPLETA, ENEMY COUNTER %s" % enemy_count)

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
