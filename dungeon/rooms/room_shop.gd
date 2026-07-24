extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var spawnpoint: Marker2D = $Spawnpoint
@onready var heart: Area2D = $Heart


func _ready():
	_position_player_on_entry()
	heart.body_entered.connect(_on_heart_body_entered)


func _position_player_on_entry() -> void:
	var spawn_point: Marker2D = spawnpoint

	# is_instance_valid e non "== null": a fine stanza il Player viene liberato
	# insieme a tutti i figli di CurrentView, ma il riferimento in PlayerManager
	# resta puntato all'istanza morta e NON risulta uguale a null
	if not is_instance_valid(PlayerManager.player):
		PlayerManager.player = PlayerManager.PLAYER.instantiate()
		add_sibling(PlayerManager.player)
		if PlayerManager.player.has_node("Camera2D"):
			PlayerManager.player.get_node("Camera2D").queue_free()

	PlayerManager.player.global_position = spawn_point.global_position


## Il cuore si raccoglie camminandoci sopra, come la chiave: cura tutto il party
## in percentuale sugli HP massimi e sparisce.
func _on_heart_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	PartyManager.heal_party(BalanceConfig.CAMPFIRE_HEAL_PCT)
	heart.queue_free()
