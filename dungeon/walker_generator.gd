@tool
extends Node
class_name WalkerGenerator

const TILE_DATA : Dictionary = {
	"floor": {
		"source_id": 1,
		"atlas_coords": Vector2i(1, 1),
	},
	"empty": {
		"source_id": 1,
		"atlas_coords": Vector2i(6, 4),
	},
	"ceil": {
		"source_id": 1,
		"atlas_coords": Vector2i(1, 1),
	},
	"wall": {
		"source_id": 1,
		"atlas_coords": Vector2i(1, 3),
	},
}

signal spawn_ready(world_pos: Vector2)
signal exit_ready(world_pos: Vector2)

@export var gen_seed : int = 0
@export var randomize_seed : bool = true
@export var map_dimensions : Vector2i = Vector2i(40, 40)
@export var total_steps : int = 600 #indica quanti passi fa il walker quindi la grandezza della mappa
@export var boundary_padding : int = 4
@export_tool_button("Generate Map") var map_gen_button = generate_map
@export var floor_tiles : TileMapLayer
@export var wall_tiles : TileMapLayer

var floor_cells : Array[Vector2i] = []

func _ready() -> void:
	pass  # niente auto-generate: la chiama chi possiede la stanza (room_walker.gd)

func generate_map() -> void:

	if randomize_seed:
		gen_seed = randi()
	seed(gen_seed)

	floor_tiles.clear()
	wall_tiles.clear()
	draw_tile_rect(map_dimensions, TILE_DATA.wall.source_id, TILE_DATA.wall.atlas_coords)
	floor_cells = _walk_and_collect(map_dimensions, boundary_padding)

	for cell in floor_cells:
		floor_tiles.set_cell(cell, TILE_DATA.floor.source_id, TILE_DATA.floor.atlas_coords)
	
	draw_tile_rect2(map_dimensions, TILE_DATA.ceil.source_id, TILE_DATA.ceil.atlas_coords)

	for cell in floor_cells:
		wall_tiles.erase_cell(cell)

func draw_tile_rect(dimensions: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			floor_tiles.set_cell(Vector2i(x, y), source_id, atlas_coords)
			
func draw_tile_rect2(dimensions: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			wall_tiles.set_cell(Vector2i(x, y), source_id, atlas_coords)

func _walk_and_collect(dimensions: Vector2i, padding: int) -> Array[Vector2i]:
	var directions: Array = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var cur_pos := Vector2i(dimensions.x / 2, dimensions.y / 2) #inizio da centro mappa
	var bounds := Rect2i(0, 0, dimensions.x, dimensions.y) #per non generare al limite mappa
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		bounds = bounds.grow_side(side, -padding)

	var visited: Dictionary = {}
	for i in range(total_steps):
		if bounds.has_point(cur_pos):
			visited[cur_pos] = true

		var move_dir: Vector2i = directions.pick_random()
		var next_pos := cur_pos + move_dir
		if bounds.has_point(next_pos):
			cur_pos = next_pos
		else:
			directions.shuffle()
			for d in directions:
				if bounds.has_point(cur_pos + d):
					cur_pos += d
					break

	var result: Array[Vector2i] = []
	for cell in visited.keys():
		result.append(cell)
	return result

func place_spawn_and_exit() -> void:

	var spawn_cell: Vector2i = floor_cells[0]
	var exit_cell: Vector2i = _find_farthest_cell(spawn_cell)

	spawn_ready.emit(floor_tiles.map_to_local(spawn_cell))
	exit_ready.emit(floor_tiles.map_to_local(exit_cell))

func _find_farthest_cell(from: Vector2i) -> Vector2i:
	var floor_set: Dictionary = {}
	for c in floor_cells:
		floor_set[c] = true

	var visited: Dictionary = {from: 0}
	var queue: Array[Vector2i] = [from]
	var farthest := from
	var max_dist := 0

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var dist: int = visited[current]
		if dist > max_dist:
			max_dist = dist
			farthest = current

		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor : Vector2i = current + d
			if floor_set.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = dist + 1
				queue.append(neighbor)

	return farthest
	


#@tool
#extends Node
#class_name WalkerGenerator
#
#const TILE_DATA : Dictionary = {
	#"floor": {
		#"source_id": 1,
		#"atlas_coords": Vector2i(1, 1),
	#},
	#"wall": {
		#"source_id": 0,
		#"atlas_coords": Vector2i(0, 0),
	#},
#}
#
#@export var gen_seed : int = 0
#@export var randomize_seed : bool = true
#@export var map_dimensions : Vector2i = Vector2i(40,40)
#@export var total_steps : int = 600
#@export var boundary_padding : int = 4
#@export_tool_button("Generate Map") var map_gen_button = generate_map
#@export var tilemap_layer : TileMapLayer
#
#func _ready() -> void:
	#generate_map()
	#
#func generate_map() -> void:
	#if randomize_seed:
		#gen_seed = randi()
	#seed(gen_seed)
#
	#tilemap_layer.clear()
#
	#draw_tile_rect(map_dimensions, TILE_DATA.wall.source_id, TILE_DATA.wall.atlas_coords)
	#draw_walker_generation(map_dimensions, boundary_padding, TILE_DATA.floor.source_id, TILE_DATA.floor.atlas_coords)
#
#func draw_tile_rect(dimensions: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	#for x in range(dimensions.x):
		#for y in range(dimensions.y):
			#tilemap_layer.set_cell(Vector2(x, y), source_id, atlas_coords)
#
#func draw_walker_generation(dimensions: Vector2i, padding: int, source_id: int, atlas_coords: Vector2i) -> void:
	#var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	#var cur_pos: Vector2i = Vector2i(
		#floor(dimensions.x / 2.0),
		#floor(dimensions.y / 2.0))
	#var bounds: Rect2i = Rect2i(0,0, dimensions.x, dimensions.y)
#
	#for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		#bounds = bounds.grow_side(side, -padding)
#
	#for i in range(total_steps):
		#if bounds.has_point(cur_pos):
			#tilemap_layer.set_cell(cur_pos, source_id, atlas_coords)
#
		#var move_dir: Vector2i = directions.pick_random()
		#var next_pos: Vector2i = cur_pos + move_dir
#
		#if bounds.has_point(next_pos):
			#cur_pos = next_pos
		#else:
			#directions.shuffle()
			#for d in directions:
				#if bounds.has_point(cur_pos + d):
					#cur_pos += d
					#break
					#
#signal spawn_ready(world_pos: Vector2)
#signal exit_ready(world_pos: Vector2)
#
#var floor_cells: Array[Vector2i] = []
#
#func place_spawn_and_exit() -> void:
	#if floor_cells.is_empty():
		#return
#
	#var spawn_cell: Vector2i = floor_cells[0] # il centro, primo punto del walker
	#var exit_cell: Vector2i = _find_farthest_cell(spawn_cell)
#
	#spawn_ready.emit(tilemap_layer.map_to_local(spawn_cell))
	#exit_ready.emit(tilemap_layer.map_to_local(exit_cell))
#
#func _find_farthest_cell(from: Vector2i) -> Vector2i:
	#var floor_set: Dictionary = {}
	#for c in floor_cells:
		#floor_set[c] = true
#
	#var visited: Dictionary = {from: 0}
	#var queue: Array[Vector2i] = [from]
	#var farthest := from
	#var max_dist := 0
#
	#while not queue.is_empty():
		#var current: Vector2i = queue.pop_front()
		#var dist: int = visited[current]
		#if dist > max_dist:
			#max_dist = dist
			#farthest = current
#
		#for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			#var neighbor : Vector2i = current + d
			#if floor_set.has(neighbor) and not visited.has(neighbor):
				#visited[neighbor] = dist + 1
				#queue.append(neighbor)
#
	#return farthest
