class_name PartyMember extends RefCounted

enum Slot { SKILL, ULTIMATE }

const CRIT_MULT : float = 1.5

var data : CharacterData
var current_hp : int
## Slot (EquipmentData.Slot) -> EquipmentData
var equipment : Dictionary = {}
## PartyMember.Slot -> secondi rimanenti di cooldown
var cooldowns : Dictionary = { Slot.SKILL: 0.0, Slot.ULTIMATE: 0.0 }

func _init(character_data : CharacterData) -> void:
	data = character_data
	current_hp = get_max_hp()

func get_max_hp() -> int:
	return data.max_hp + int(_bonus("bonus_max_hp"))

func get_atk() -> int:
	return data.atk + int(_bonus("bonus_atk"))

func get_crit_rate() -> float:
	return data.crit_rate

func get_speed() -> float:
	return data.speed + _bonus("bonus_speed")

func is_alive() -> bool:
	return current_hp > 0

# --- Skill / Ultimate ---------------------------------------------------------

func get_skill_data(slot : Slot) -> SkillData:
	return data.skill if slot == Slot.SKILL else data.ultimate

## Scorre anche mentre il membro e' fuori campo (chiamato da PartyManager)
func tick_cooldowns(delta : float) -> void:
	for s in cooldowns:
		if cooldowns[s] > 0.0:
			cooldowns[s] = maxf(cooldowns[s] - delta, 0.0)

func is_ready(slot : Slot) -> bool:
	return get_skill_data(slot) != null and cooldowns[slot] <= 0.0

func start_cooldown(slot : Slot) -> void:
	var skill := get_skill_data(slot)
	if skill:
		cooldowns[slot] = skill.cooldown

## 0.0 = appena usata, 1.0 = pronta. Usato dalla HUD per riempire l'anello.
func get_charge(slot : Slot) -> float:
	var skill := get_skill_data(slot)
	if skill == null or skill.cooldown <= 0.0:
		return 1.0
	return 1.0 - cooldowns[slot] / skill.cooldown

# --- Equipaggiamento ----------------------------------------------------------

func equip(item : EquipmentData) -> void:
	equipment[item.slot] = item
	current_hp = clampi(current_hp, 0, get_max_hp())

func unequip(slot : EquipmentData.Slot) -> void:
	equipment.erase(slot)
	current_hp = clampi(current_hp, 0, get_max_hp())

func _bonus(field : String) -> float:
	var total : float = 0.0
	for item in equipment.values():
		total += item.get(field)
	return total
