class_name EnemyStateChase extends EnemyState

@export var anim_name: String = "walk"
@export var chase_speed: float = 20.0
@export var stop_distance: float = 30.0
@export var give_up_time: float = 2.0

# Prossimo stato dopo aver perso di vista il giocatore
@export var next_state: EnemyState   # di solito EnemyStateIdle

var _time_since_seen: float = 0.0

func enter() -> void:
	# Inizia a inseguire l'ultima posizione nota (già aggiornata da enemy)
	_time_since_seen = 0.0
	enemy.update_animation(anim_name)

func exit() -> void:
	pass

func process(delta: float) -> EnemyState:
	# 1. Se vediamo il player, azzeriamo il timer e puntiamo alla sua posizione attuale
	if enemy.can_see_player:
		_time_since_seen = 0.0
		# last_seen_player_position è già aggiornato da enemy in _process, lo usiamo
	else:
		_time_since_seen += delta
		# Se non lo vediamo da troppo tempo, rinuncia e torna allo stato specificato
		if _time_since_seen > give_up_time:
			return next_state

	# 2. Calcola la direzione verso il target (ultima posizione nota)
	var target = enemy.last_seen_player_position
	var direction = (target - enemy.global_position).normalized()
	var distance = enemy.global_position.distance_to(target)

	# 3. Se siamo sufficientemente vicini e non vediamo il player, torna indietro
	if distance < stop_distance and not enemy.can_see_player:
		return next_state

	# 4. Muoviti
	enemy.velocity = direction * chase_speed
	enemy.set_direction(direction)
	enemy.update_animation(anim_name)

	return null

func physics(delta: float) -> EnemyState:
	enemy.move_and_slide()
	return null
