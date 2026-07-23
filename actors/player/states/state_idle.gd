class_name State_Idle extends State

@onready var walk : State = $"../Walk"
@onready var sprite = $"../../Sprite2D"
@onready var attack : State_Attack = $"../Attack"
@onready var skill : State = $"../Skill"

func enter() -> void:
	player.update_animation("idle")

func exit() -> void:
	pass

func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null

func physics(_delta:float) -> State:
	return null

func handle_input(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack") and attack.can_attack():
		return attack
	if _event.is_action_pressed("skill") and skill.try_cast(PartyMember.Slot.SKILL):
		return skill
	if _event.is_action_pressed("ultimate") and skill.try_cast(PartyMember.Slot.ULTIMATE):
		return skill
	return null
