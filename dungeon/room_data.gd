# room_data.gd
class_name RoomData extends Resource

enum RoomType { START, COMBAT, ELITE, SHOP, EVENT, TREASURE, REST, BOSS }

@export var id: int
@export var type: RoomType
@export var depth: int
@export var connections: Dictionary = {}
# connections = { "north": 3, "east": 7 }
# il valore è l'id della stanza collegata

var visited: bool = false
var completed: bool = false
