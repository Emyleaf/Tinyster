@tool
class_name LevelTransition extends Area2D

@export var target_transition_area : String = "LevelTransition"
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal entered(body: Node2D)

@export var auto_change_scene := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _update_area() -> void:
	var new_rect : Vector2 = Vector2(120, 120)
	var new_position : Vector2 = Vector2.ZERO

	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")

	collision_shape.shape.size = new_rect
	collision_shape.position = new_position
	pass

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if DungeonManager.is_transitioning:
		return

	set_physics_process(false)
	entered.emit(body)

	# stanza completata: pulisce CurrentView e riapre la mappa aggiornata
	DungeonManager.complete_room()
