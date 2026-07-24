class_name State_Walk extends State

@onready var idle : State = $"../Idle"
@onready var attack : State_Attack = $"../Attack"
@onready var skill : State = $"../Skill"
@onready var dodge : State_Dodge = $"../Dodge"

func enter() -> void:
	player.update_animation("walk_side")

func exit() -> void:
	pass

func process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle

	player.velocity = player.direction * player.get_speed()

	if player.set_direction():
		player.update_animation("walk_side")

	return null

func physics(_delta:float) -> State:
	return null

func handle_input(_event: InputEvent) -> State:
	if _event.is_action_pressed("dodge") and dodge.try_dash():
		return dodge
	if _event.is_action_pressed("attack") and attack.can_attack():
		return attack
	if _event.is_action_pressed("skill") and skill.try_cast(PartyMember.Slot.SKILL):
		return skill
	if _event.is_action_pressed("ultimate") and skill.try_cast(PartyMember.Slot.ULTIMATE):
		return skill
	return null
