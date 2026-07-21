extends TextureProgressBar

@export var player : Player

func _ready() -> void:
	# Assicurati che il Player emetta segnali con nomi analoghi
	player.player_damaged.connect(_on_player_damaged)
	update_health_bar()

func update_health_bar():
	if PlayerManager.max_hp > 0:
		value = PlayerManager.current_hp * 100.0 / PlayerManager.max_hp
	else:
		value = 0

func _on_player_damaged(_hurt_box : HurtBox):
	update_health_bar()
