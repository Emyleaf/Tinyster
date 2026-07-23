class_name State_Attack extends State

var attacking : bool = false
var aim_direction : Vector2 = Vector2.RIGHT

@export var attack_sound : AudioStream
@export_range(1,20,0.5) var decelerate_speed : float = 5.0
## Da dove parte il proiettile, relativo all'origine del player (che e' ai piedi)
@export var muzzle_offset : Vector2 = Vector2(0, -16)

@onready var animation_player : AnimationPlayer = $"../../AnimationPlayer"
@onready var walk : State = $"../Walk"
@onready var idle  : State = $"../Idle"
@onready var sprite = $"../../Sprite2D"
@onready var audio : AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"

@onready var hurt_box : HurtBox = $"../../Interactions/HurtBox"

func enter() -> void:
	var projectile : PackedScene = player.get_current_member().data.projectile

	# Mira fissata alla pressione del tasto: flip e freccia restano coerenti
	if projectile:
		aim_direction = player.global_position.direction_to(player.get_global_mouse_position())
		player.face_towards(aim_direction)

	player.update_animation("attack_side")
	animation_player.animation_finished.connect( end_attack )
	
	audio.stream = attack_sound
	audio.pitch_scale = randf_range(0.9,1.1)
	audio.play()
	attacking = true

	await get_tree().create_timer(0.075).timeout
	if attacking == true:
		if projectile:
			_shoot(projectile)
		else:
			hurt_box.damage = player.get_atk()
			hurt_box.monitoring = true
	pass
	
func exit() -> void:
	animation_player.animation_finished.disconnect( end_attack )
	attacking = false
	hurt_box.monitoring = false
	pass
	
func process(_delta: float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	
	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	return null
	
func physics(_delta:float) -> State:
	return null
	
func handle_input(_event: InputEvent) -> State:
	return null
	
func end_attack( _newAnimName : String) -> void:
	attacking = false

func _shoot(projectile : PackedScene) -> void:
	var arrow : Arrow = projectile.instantiate()
	arrow.setup(player.global_position + muzzle_offset, aim_direction, player.get_atk())
	player.get_parent().add_child.call_deferred(arrow)
