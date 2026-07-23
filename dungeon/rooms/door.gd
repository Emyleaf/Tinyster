class_name Door extends Node2D

var is_open : bool = false

@onready var sprite : Sprite2D = $Sprite2D
@onready var static_body : StaticBody2D = $StaticBody2D

func _ready() -> void:
	RunState.keys_changed.connect(_on_keys_changed)
	# Il player potrebbe gia' avere una chiave entrando nella stanza
	_on_keys_changed(RunState.keys)

func _on_keys_changed(amount : int) -> void:
	if is_open or amount <= 0:
		return
	# Una chiave = una porta
	if RunState.try_spend_key(1):
		open_door()

func open_door() -> void:
	if is_open:
		return
	is_open = true
	sprite.frame = 0
	static_body.queue_free()

func close_door() -> void:
	pass
