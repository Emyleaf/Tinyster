# room_data.gd
class_name Room extends Resource

enum Type { NOT_ASSIGNED, MONSTER, CAMPFIRE, SHOP, TREASURE, BOSS }
enum Direction { NORTH, FORWARD, SOUTH }

@export var type: Type
@export var row: int
@export var column: int
@export var position: Vector2
@export var next_rooms: Array[Room]
@export var selected := false

func get_direction_to(next_room: Room) -> Direction:
	if next_room.column < column:
		return Direction.NORTH
	elif next_room.column > column:
		return Direction.SOUTH
	return Direction.FORWARD

func _to_string() -> String:
	return "%s (%s)" % [column, Type.keys()[type][0]]
