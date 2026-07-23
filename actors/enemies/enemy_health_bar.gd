extends TextureProgressBar

@export var enemy : Enemy

func _ready() -> void:
	# Connetti entrambi i segnali per aggiornare la barra
	enemy.enemy_damaged.connect(_on_enemy_damaged)
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	update_health_bar()

func update_health_bar():
	# Assicurati che max_hp non sia 0 per evitare divisioni per zero
	if enemy.stats.max_hp > 0:
		value = enemy.current_hp * 100.0 / enemy.stats.max_hp
	else:
		value = 0

func _on_enemy_damaged(_hurt_box : HurtBox):
	update_health_bar()

func _on_enemy_destroyed(_hurt_box : HurtBox):
	value = 0
