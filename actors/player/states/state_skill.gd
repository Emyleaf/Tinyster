class_name State_Skill extends State

## Stato unico per skill (E) e ultimate (Q): cambia solo il SkillData usato.

@export var windup : float = 0.075
@export_range(1, 20, 0.5) var decelerate_speed : float = 8.0
## La HurtBox e' condivisa con Attack: va riscritta a ogni cast
@export_range(0.0, 400.0, 10.0) var knockback_force : float = 200.0

var slot : PartyMember.Slot = PartyMember.Slot.SKILL
var casting : bool = false

@onready var idle : State = $"../Idle"
@onready var walk : State = $"../Walk"
@onready var hurt_box : HurtBox = $"../../Interactions/HurtBox"

## Chiamato da Idle/Walk PRIMA di restituire questo stato.
## Consuma il cooldown solo se la skill e' effettivamente lanciabile.
func try_cast(_slot : PartyMember.Slot) -> bool:
	if not PartyManager.try_use_skill(_slot):
		return false
	slot = _slot
	return true

func enter() -> void:
	var member := player.get_current_member()
	var skill := member.get_skill_data(slot)
	casting = true

	player.update_animation(skill.anim_name)

	var is_crit : bool = randf() < player.get_crit_rate()
	var dmg : float = member.get_atk() * skill.damage_mult
	if is_crit:
		dmg *= player.get_crit_dmg()
	hurt_box.damage = maxi(1, roundi(dmg))
	hurt_box.is_crit = is_crit
	hurt_box.knockback_force = knockback_force
	hurt_box.scale = Vector2.ONE * skill.hitbox_scale

	await get_tree().create_timer(windup).timeout
	if casting:
		hurt_box.monitoring = true

	await get_tree().create_timer(skill.cast_time).timeout
	casting = false

func exit() -> void:
	casting = false
	hurt_box.monitoring = false
	hurt_box.scale = Vector2.ONE

func process(_delta : float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	if casting:
		return null
	return idle if player.direction == Vector2.ZERO else walk

func physics(_delta : float) -> State:
	return null

func handle_input(_event : InputEvent) -> State:
	return null
