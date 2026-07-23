class_name State_Attack extends State

var attacking : bool = false
var aim_direction : Vector2 = Vector2.RIGHT

@export var attack_sound : AudioStream
@export_range(1,20,0.5) var decelerate_speed : float = 5.0
## Da dove parte il proiettile, relativo all'origine del player (che e' ai piedi)
@export var muzzle_offset : Vector2 = Vector2(0, -16)

## Finestra (in secondi) dopo la fine dell'attacco in cui il 2o colpo e' disponibile
@export_range(0.0, 1.5, 0.05) var combo_window : float = 0.4
## Moltiplicatore di danno del 2o colpo
@export_range(1.0, 3.0, 0.1) var combo_damage_mult : float = 1.5

## 0 = primo colpo, 1 = secondo colpo
var combo_index : int = 0
var _last_attack_end_msec : int = -999999

@onready var animation_player : AnimationPlayer = $"../../AnimationPlayer"
@onready var walk : State = $"../Walk"
@onready var idle  : State = $"../Idle"
@onready var sprite = $"../../Sprite2D"
@onready var audio : AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"

@onready var hurt_box : HurtBox = $"../../Interactions/HurtBox"

func enter() -> void:
	var projectile : PackedScene = player.get_current_member().data.projectile

	# Combo solo per i melee: se sono ancora nella finestra, questo e' il colpo 2
	combo_index = 1 if (projectile == null and _in_combo_window()) else 0

	# Mira fissata alla pressione del tasto: flip e freccia restano coerenti
	if projectile:
		aim_direction = player.global_position.direction_to(player.get_global_mouse_position())
		player.face_towards(aim_direction)

	player.update_animation("attack_side2" if combo_index == 1 else "attack_side")
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
			hurt_box.damage = _current_damage()
			hurt_box.monitoring = true
	pass
	
func exit() -> void:
	animation_player.animation_finished.disconnect( end_attack )
	attacking = false
	hurt_box.monitoring = false
	# Il combo timer parte da qui: il "cooldown" e' stata l'animazione stessa
	_last_attack_end_msec = Time.get_ticks_msec()
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

## Ho gia' fatto il colpo 2? Allora si riparte dal colpo 1
func _in_combo_window() -> bool:
	if combo_index == 1:
		return false
	return (Time.get_ticks_msec() - _last_attack_end_msec) <= int(combo_window * 1000.0)

func _current_damage() -> int:
	if combo_index == 1:
		return roundi(player.get_atk() * combo_damage_mult)
	return player.get_atk()

func _shoot(projectile : PackedScene) -> void:
	var arrow : Arrow = projectile.instantiate()
	arrow.setup(player.global_position + muzzle_offset, aim_direction, player.get_atk())
	player.get_parent().add_child.call_deferred(arrow)
