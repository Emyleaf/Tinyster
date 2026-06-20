@tool
class_name LevelTransition extends Area2D

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }

@export_file("*.tscn") var level
@export var target_transition_area : String = "LevelTransition"

@export_file("*.tscn") var target_scene: String = "res://generalnodes/game.tscn"

@export_category("Collision Area Settings")

@export_range(1, 12, 1, "or_greater") var size : int = 2 :
	set (_v):
		size = _v
		_update_area()

@export var side : SIDE = SIDE.LEFT :
	set (_v):
		side = _v
		_update_area()

@export var snap_to_grid : bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal entered(body: Node2D)

@export var auto_change_scene := true

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _update_area() -> void:
	var new_rect : Vector2 = Vector2 (120,120)
	var new_position : Vector2 = Vector2.ZERO
	
	if side == SIDE.TOP:
		new_rect.x *= size
		new_position.y -= 60
	elif side == SIDE.BOTTOM:
		new_rect.x *= size
		new_position.y += 60
	elif side == SIDE.LEFT:
		new_rect.y *= size
		new_position.x -= 60
	elif side == SIDE.RIGHT:
		new_rect.y *= size
		new_position.x += 60
		
	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")
		
	collision_shape.shape.size = new_rect
	collision_shape.position = new_position
		
	pass
	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		entered.emit(body)
		if auto_change_scene:
			get_tree().change_scene_to_file(target_scene)
