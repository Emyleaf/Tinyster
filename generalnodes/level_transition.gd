@tool
class_name LevelTransition extends Area2D

@export var current_view_path: NodePath   # percorso al nodo "currentview" da svuotare
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Assicura che la collision shape sia configurata (se serve)
	_update_area()

func _update_area() -> void:
	var new_rect := Vector2(120, 120)
	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")
	collision_shape.shape.size = new_rect
	collision_shape.position = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if DungeonManager.is_transitioning:
		return
	
	DungeonManager.is_transitioning = true
	set_physics_process(false)
	
	# 1. Svuota TUTTO il contenuto del nodo currentview
	var view = get_node_or_null(current_view_path)
	if view:
		for child in view.get_children():
			child.queue_free()
	
	# 2. Riapri la mappa aggiornata (stanza completata, scegli le adiacenti)
	DungeonManager.complete_current_room()    # marca la stanza come completata
	DungeonManager.open_map()                 # torna alla schermata di selezione
	
	# La transizione è finita quando la mappa viene mostrata, quindi puoi resettare
	# il flag dopo un piccolo delay o nella logica di open_map.

#@tool
#class_name LevelTransition extends Area2D
#
#@export var target_transition_area : String = "LevelTransition"
#@onready var collision_shape: CollisionShape2D = $CollisionShape2D
#
#signal entered(body: Node2D)
#
#@export var auto_change_scene := true
#
#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
#
#
#func _update_area() -> void:
	#var new_rect : Vector2 = Vector2 (120,120)
	#var new_position : Vector2 = Vector2.ZERO
		#
	#if collision_shape == null:
		#collision_shape = get_node("CollisionShape2D")
		#
	#collision_shape.shape.size = new_rect
	#collision_shape.position = new_position
		#
	#pass
	#
#
#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("Player"):
		#if DungeonManager.is_transitioning:
			#return
		#set_physics_process(false)    
		#entered.emit(body)
