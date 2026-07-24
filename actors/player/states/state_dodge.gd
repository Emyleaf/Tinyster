class_name State_Dodge extends State

## Dash direzionale con i-frame su una finestra precisa (stile Dark Souls):
## startup vulnerabile -> finestra invulnerabile -> recupero vulnerabile.
## I parametri sono per personaggio, in CharacterData.dash (DashData).

var _dash : DashData
var _dir : Vector2 = Vector2.RIGHT
var _elapsed : float = 0.0
var _iframes : bool = false
var _prev_invulnerable : bool = false

@onready var idle : State = $"../Idle"
@onready var walk : State = $"../Walk"

## Chiamato da Idle/Walk PRIMA di restituire questo stato.
## Consuma il cooldown solo se il dash e' effettivamente eseguibile.
func try_dash() -> bool:
	var member := player.get_current_member()
	if member == null or not PartyManager.try_dash():
		return false
	_dash = member.data.dash
	return true

func enter() -> void:
	_elapsed = 0.0
	_iframes = false

	# La direzione si congela qui: player.direction viene riscritta ogni frame
	if player.direction != Vector2.ZERO:
		_dir = player.direction
	else:
		_dir = Vector2.RIGHT if player.facing_right else Vector2.LEFT
	player.face_towards(_dir)

	# Non esiste un'animazione di dash dedicata: si riusa walk_side accelerata
	player.update_animation("walk_side")
	player.animation_player.speed_scale = _dash.anim_speed

func exit() -> void:
	player.animation_player.speed_scale = 1.0
	player.sprite.modulate.a = 1.0
	if _iframes:
		player.invulnerable = _prev_invulnerable
		_iframes = false

func process(_delta : float) -> State:
	_elapsed += _delta

	# Slancio pieno all'inizio, decelerazione verso la fine
	var t : float = clampf(_elapsed / _dash.duration, 0.0, 1.0)
	player.velocity = _dir * _dash.speed * (1.0 - t * t)

	_update_iframes()

	if _elapsed < _dash.duration:
		return null

	_on_dash_finished()
	return idle if player.direction == Vector2.ZERO else walk

func physics(_delta : float) -> State:
	return null

## Nessun cancel durante il dash: l'input viene ignorato fino alla fine
func handle_input(_event : InputEvent) -> State:
	return null

## Invulnerabile SOLO dentro [iframe_start, iframe_start + iframe_duration].
## Salva/ripristina il valore precedente per non annullare l'invulnerabilita'
## di uno Stun ancora in corso.
func _update_iframes() -> void:
	var active : bool = _elapsed >= _dash.iframe_start \
		and _elapsed < _dash.iframe_start + _dash.iframe_duration
	if active == _iframes:
		return

	_iframes = active
	if active:
		_prev_invulnerable = player.invulnerable
		player.invulnerable = true
	else:
		player.invulnerable = _prev_invulnerable
	player.sprite.modulate.a = 0.45 if active else 1.0

## Abilita' speciale del personaggio a fine dash (es. Warrior: +2 ATK)
func _on_dash_finished() -> void:
	if _dash.buff_atk != 0 and _dash.buff_duration > 0.0:
		player.get_current_member().apply_atk_buff(_dash.buff_atk, _dash.buff_duration)
