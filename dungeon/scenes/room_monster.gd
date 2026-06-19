extends Node2D

var enemy_scene = preload("res://enemies/slime/slime.tscn")
var player_mask_radius = 200
var enemy_count : int = 0

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var door = $Door


func _ready():
	randomize()
	enemy_count = randi_range(3, 6)
	await get_tree().create_timer(1.0).timeout
	spawn_enemies()

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
	if enemy_count <= 0:
		await get_tree().create_timer(0.5).timeout
		door.open_door()
