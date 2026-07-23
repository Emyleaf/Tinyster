extends Node2D

var doors_to_open : Array[Door] = []

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var door_north: Door = $DoorN
@onready var door_south: Door = $DoorS
@onready var door_east: Door = $DoorE
@onready var trans_east: LevelTransition = $TransE
@onready var spawn_from_west: Marker2D = $SpawnFromWest


func _ready():
	_position_player_on_entry()
	
	if DungeonManager.last_room:
		print("Stanza - Riga: %d, Colonna: %d" % [DungeonManager.last_room.column+1, DungeonManager.last_room.row])


func _position_player_on_entry() -> void:
	var spawn_point: Marker2D = spawn_from_west
			
	if PlayerManager.player == null:
		PlayerManager.player = PlayerManager.PLAYER.instantiate()
		add_sibling(PlayerManager.player)
		if PlayerManager.player.has_node("Camera2D"):
			PlayerManager.player.get_node("Camera2D").queue_free()
	
	PlayerManager.player.global_position = spawn_point.global_position
