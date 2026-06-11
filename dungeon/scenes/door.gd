class_name Door extends Node2D

var is_open : bool = false
var enemies_alive := 3

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	pass
	
func open_door() -> void:
	animation_player.play("destroy")
	queue_free()
	pass
	
func close_door() -> void:
	pass


func _on_slime_enemy_destroyed(hurt_box: HurtBox) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		await get_tree().create_timer(0.5).timeout
		open_door()
	pass # Replace with function body.
