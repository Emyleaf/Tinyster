class_name Arrow extends HurtBox

@export var speed : float = 500.0
## Dopo quanti secondi la freccia sparisce se non colpisce nulla
@export var lifetime : float = 2.0

var direction : Vector2 = Vector2.RIGHT
var _spawn_position : Vector2

## Va chiamata PRIMA di add_child: i valori vengono applicati in _ready()
func setup(spawn_position : Vector2, aim_direction : Vector2, arrow_damage : int, crit : bool) -> void:
	_spawn_position = spawn_position
	direction = aim_direction
	damage = arrow_damage
	is_crit = crit
	
func _ready() -> void:
	super()
	global_position = _spawn_position
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta : float) -> void:
	global_position += direction * speed * delta

## Nemico colpito: HurtBox applica il danno, poi la freccia sparisce
func _area_entered(area : Area2D) -> void:
	super(area)
	if area is HitBox:
		queue_free()

## Muro
func _on_body_entered(_body : Node2D) -> void:
	queue_free()
