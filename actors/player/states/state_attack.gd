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
## Pausa forzata dopo l'ultimo colpo della catena: impedisce lo spam a raffica
@export_range(0.0, 2.0, 0.05) var attack_cooldown : float = 0.25

## 0 = primo colpo, 1 = secondo colpo
var combo_index : int = 0
var _last_attack_end_msec : int = -999999
## Input premuto durante l'animazione: viene ricordato invece che perso
var _buffered_attack : bool = false

@onready var animation_player : AnimationPlayer = $"../../AnimationPlayer"
@onready var walk : State = $"../Walk"
@onready var idle  : State = $"../Idle"
@onready var sprite = $"../../Sprite2D"
@onready var audio : AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"

@onready var hurt_box : HurtBox = $"../../Interactions/HurtBox"

func enter() -> void:
	var projectile : PackedScene = player.get_current_member().data.projectile

	# Se sono ancora nella finestra, questo e' il colpo 2 (solo melee, vedi _in_combo_window)
	combo_index = 1 if _in_combo_window() else 0

	# Il dado del critico si tira una volta sola, alla pressione del tasto
	var is_crit : bool = randf() < player.get_crit_rate()

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
			_shoot(projectile, is_crit)
		else:
			hurt_box.damage = _damage_for(is_crit)
			hurt_box.is_crit = is_crit
			hurt_box.monitoring = true
	pass
	
func exit() -> void:
	animation_player.animation_finished.disconnect( end_attack )
	attacking = false
	hurt_box.monitoring = false
	_buffered_attack = false
	# Il combo timer parte da qui: il "cooldown" e' stata l'animazione stessa
	_last_attack_end_msec = Time.get_ticks_msec()
	pass
	
func process(_delta: float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	
	if attacking == false:
		# L'input bufferizzato ha priorita' sul ritorno a idle/walk
		if _buffered_attack:
			_restart_attack()
			return null
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	return null
	
func physics(_delta:float) -> State:
	return null
	
func handle_input(_event: InputEvent) -> State:
	# Si bufferizza SOLO il 2o colpo della combo melee: una pressione, un colpo in coda.
	# Senza questo vincolo la catena enter()/exit() non finirebbe mai.
	if _event.is_action_pressed("attack") and combo_index == 0 and not _is_ranged():
		_buffered_attack = true
	return null
	
func end_attack( _newAnimName : String) -> void:
	attacking = false

## Rientra in Attack senza passare dallo state machine
## (change_state() scarta le transizioni verso lo stato corrente)
func _restart_attack() -> void:
	_buffered_attack = false
	exit()
	enter()

## Chiamata da Idle/Walk prima di entrare qui.
## Il 2o colpo resta immediato, il recupero scatta solo a fine catena.
func can_attack() -> bool:
	if _in_combo_window():
		return true
	return (Time.get_ticks_msec() - _last_attack_end_msec) >= int(attack_cooldown * 1000.0)

## Ho gia' fatto il colpo 2, o sono a distanza? Allora si riparte dal colpo 1
func _in_combo_window() -> bool:
	if combo_index == 1 or _is_ranged():
		return false
	return (Time.get_ticks_msec() - _last_attack_end_msec) <= int(combo_window * 1000.0)

func _is_ranged() -> bool:
	return player.get_current_member().data.projectile != null

func _damage_for(is_crit : bool) -> int:
	var dmg : float = float(player.get_atk())
	if combo_index == 1:
		dmg *= combo_damage_mult
	if is_crit:
		dmg *= player.get_crit_dmg()
	return maxi(1, roundi(dmg))

func _shoot(projectile : PackedScene, is_crit : bool) -> void:
	var arrow : Arrow = projectile.instantiate()
	arrow.setup(player.global_position + muzzle_offset, aim_direction, _damage_for(is_crit), is_crit)
	player.get_parent().add_child.call_deferred(arrow)
