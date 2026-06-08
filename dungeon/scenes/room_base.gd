# room_base.gd
extends Node2D

@onready var door_north: Area2D = $Doors/DoorNorth
@onready var door_south: Area2D = $Doors/DoorSouth
@onready var door_east:  Area2D = $Doors/DoorEast
@onready var door_west:  Area2D = $Doors/DoorWest
@onready var player_spawns := {
	"north": $Spawns/SpawnSouth,  # entra da nord → spawn in basso
	"south": $Spawns/SpawnNorth,
	"east":  $Spawns/SpawnWest,
	"west":  $Spawns/SpawnEast,
}

var room_data: RoomData
var enter_from: String

func setup(data: RoomData, from: String) -> void:
	room_data = data
	enter_from = from
	_configure_doors()
	_spawn_player()

func _configure_doors() -> void:
	# Mostra solo le porte che esistono nella RoomData
	door_north.visible = room_data.connections.has("north")
	door_south.visible = room_data.connections.has("south")
	door_east.visible  = room_data.connections.has("east")
	door_west.visible  = room_data.connections.has("west")

	# La porta da cui siamo entrati si chiude subito
	_close_door(enter_from)

	# Le porte in avanti sono bloccate finché la stanza non è completata
	_lock_forward_doors()

func _close_door(direction: String) -> void:
	# Rendi la porta non attraversabile (cambia collisione o sprite)
	match direction:
		"north": door_north.get_node("CollisionShape2D").disabled = false
		"south": door_south.get_node("CollisionShape2D").disabled = false
		# etc.

func _lock_forward_doors() -> void:
	# Blocca tutte le porte tranne quella da cui siamo venuti
	# Si sbloccano quando room_data.completed = true
	pass

func _spawn_player() -> void:
	var spawn_pos: Node2D = player_spawns.get(enter_from)
	if spawn_pos:
		get_tree().current_scene.get_node("Player").global_position = spawn_pos.global_position

func room_completed() -> void:
	room_data.completed = true
	_unlock_forward_doors()

func _on_door_north_body_entered(body: Node2D) -> void:
	if body is Player:
		DungeonManager.enter_door("north")
