class_name Slime extends Enemy

func _setup_enemy():
	stats.attack_damage = 30.0

func _on_death():
	print("Slime squishato!")
