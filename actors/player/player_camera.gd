class_name PlayerCamera extends Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#LevelManager.tilemap_bounds_changed.connect(update_limits)
	#update_limits(LevelManager.current_tilemap_bounds)
	pass # Replace with function body.


#func update_limits( bounds : Array[Vector2] ) -> void:
	#if bounds == []:
		#return
#
	#var min_bound : Vector2 = bounds[0]
	#var max_bound : Vector2 = bounds[1]
	#
	#limit_left = int(min_bound.x)
	#limit_top = int(min_bound.y)
	#limit_right = int(max_bound.x)
	#limit_bottom = int(max_bound.y)
	#pass
