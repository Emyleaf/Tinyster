class_name HurtBox extends Area2D

@export var damage : int = 1
## Spinta applicata al bersaglio. Impostata da chi genera il colpo.
@export var knockback_force : float = 50.0

## Impostato da chi genera il colpo. Serve solo alla presentazione (colore del numero).
var is_crit : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_area_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _area_entered(area : Area2D) -> void:
	if area is HitBox:
		area.take_damage(self)
	pass
