extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var spawnpoint: Marker2D = $Spawnpoint


func _ready():
	_position_player_on_entry()


func _position_player_on_entry() -> void:
	var spawn_point: Marker2D = spawnpoint
			
	if PlayerManager.player == null:
		PlayerManager.player = PlayerManager.PLAYER.instantiate()
		add_sibling(PlayerManager.player)
		if PlayerManager.player.has_node("Camera2D"):
			PlayerManager.player.get_node("Camera2D").queue_free()
	
	PlayerManager.player.global_position = spawn_point.global_position
