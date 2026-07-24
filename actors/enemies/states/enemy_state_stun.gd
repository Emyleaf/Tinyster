class_name EnemyStateStun extends EnemyState

@export var anim_name : String = "stun"
@export var decelerate_speed : float = 10.0
## Durata degli i-frame. Deve restare sotto la lunghezza dell'animazione di attacco
## del player (0.3s), altrimenti il 2o colpo di combo viene assorbito.
@export var invulnerable_time : float = 0.15
## Sopra questa soglia il colpo e' "pesante": il nemico viene allontanato e non avanza
@export var heavy_threshold : float = 150.0
## Con quale velocita' il nemico riprende ad avanzare durante uno stun leggero
@export var advance_speed : float = 20.0

@export_category("AI")
@export var next_state : EnemyState
## Se il player e' visibile si torna qui invece che a next_state
@export var chase_state : EnemyState

var _damage_position : Vector2
var _direction : Vector2
var _knockback_force : float = 0.0
var _animation_finished : bool = false
var _invulnerable_timer : float = 0.0


func init() -> void:
	enemy.enemy_damaged.connect(_on_enemy_damaaged)
	pass # Replace with function body.

func enter() -> void: 
	enemy.invulnerable = true
	_invulnerable_timer = invulnerable_time
	_animation_finished = false

	_direction = enemy.global_position.direction_to(_damage_position)

	enemy.set_direction(_direction)
	enemy.velocity = _direction * -_knockback_force

	enemy.update_animation(anim_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	pass
	
func exit() -> void:
	enemy.invulnerable = false
	enemy.animation_player.animation_finished.disconnect(_on_animation_finished)
	pass
	
func process(_delta: float) -> EnemyState:
	# Gli i-frame scadono prima dell'animazione: lo stun resta visibile,
	# ma il nemico torna colpibile in tempo per il colpo successivo
	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= _delta
		if _invulnerable_timer <= 0.0:
			enemy.invulnerable = false
	if _animation_finished == true:
		if chase_state != null and enemy.can_see_player:
			return chase_state
		return next_state
	if _knockback_force < heavy_threshold and is_instance_valid(enemy.player):
		# Colpo leggero: la spinta si esaurisce e il nemico riparte verso il player
		var advance : Vector2 = enemy.global_position.direction_to(enemy.player.global_position) * advance_speed
		enemy.velocity = enemy.velocity.lerp(advance, decelerate_speed * _delta)
	else:
		enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null
	
func physics(_delta:float) -> EnemyState:
	return null

func _on_enemy_damaaged(hurt_box : HurtBox) -> void:
	_damage_position = hurt_box.global_position
	_knockback_force = hurt_box.knockback_force
	# Colpo ricevuto mentre lo stun e' gia' in corso: change_state() scarterebbe
	# la transizione verso lo stato corrente, quindi si rientra a mano
	if state_machine.current_state == self:
		exit()
		enter()
		return
	state_machine.change_state(self)

func _on_animation_finished(_anim_name : String) -> void:
	_animation_finished = true
