class_name DungeonGenerator

static func generate(depth: int = 10) -> Array[RoomData]:
	var rooms: Array[RoomData] = []
	var id_counter := 0

	# Stanza iniziale fissa
	var start := RoomData.new()
	start.id = id_counter
	start.type = RoomData.RoomType.START
	start.depth = 0
	rooms.append(start)
	id_counter += 1

	# Genera i layer successivi alla Slay the Spire
	var current_layer := [start]

	for d in range(1, depth + 1):
		var next_layer: Array[RoomData] = []
		var branches := randi_range(2, 3)  # 2 o 3 rami per layer

		for _b in range(branches):
			var room := RoomData.new()
			room.id = id_counter
			room.depth = d
			room.type = _pick_type(d, depth)
			rooms.append(room)
			next_layer.append(room)
			id_counter += 1

		# Collega il layer precedente al nuovo
		_connect_layers(current_layer, next_layer)
		current_layer = next_layer

	# Boss finale
	var boss := RoomData.new()
	boss.id = id_counter
	boss.type = RoomData.RoomType.BOSS
	boss.depth = depth + 1
	rooms.append(boss)
	_connect_layers(current_layer, [boss])

	_assign_directions(rooms)
	return rooms

static func _pick_type(depth: int, max_depth: int) -> RoomData.RoomType:
	if depth == max_depth:
		return RoomData.RoomType.BOSS
	var roll := randf()
	if roll < 0.45: return RoomData.RoomType.COMBAT
	elif roll < 0.65: return RoomData.RoomType.EVENT
	elif roll < 0.75: return RoomData.RoomType.SHOP
	elif roll < 0.85: return RoomData.RoomType.TREASURE
	elif roll < 0.92: return RoomData.RoomType.REST
	else: return RoomData.RoomType.ELITE
