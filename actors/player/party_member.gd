class_name PartyMember extends RefCounted

enum Slot { SKILL, ULTIMATE }

var data : CharacterData
var current_hp : int
## Slot (EquipmentData.Slot) -> EquipmentData
var equipment : Dictionary = {}
## PartyMember.Slot -> secondi rimanenti di cooldown
var cooldowns : Dictionary = { Slot.SKILL: 0.0, Slot.ULTIMATE: 0.0 }
## Il dash ha un cooldown proprio: non e' una skill, non sta in Slot
var dash_cooldown : float = 0.0
## Bonus ATK temporaneo (es. abilita' post-dash del Warrior)
var atk_buff : int = 0
var atk_buff_time : float = 0.0

func _init(character_data : CharacterData) -> void:
	data = character_data
	current_hp = get_max_hp()

func get_max_hp() -> int:
	return data.max_hp + int(_bonus("bonus_max_hp"))

func get_atk() -> int:
	return data.atk + int(_bonus("bonus_atk")) + atk_buff

func get_crit_rate() -> float:
	return clampf(data.crit_rate + _bonus("bonus_crit_rate"), 0.0, 1.0)

func get_crit_dmg() -> float:
	return maxf(1.0, data.crit_dmg + _bonus("bonus_crit_dmg"))

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
	if dash_cooldown > 0.0:
		dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	if atk_buff_time > 0.0:
		atk_buff_time = maxf(atk_buff_time - delta, 0.0)
		if atk_buff_time == 0.0:
			atk_buff = 0

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

# --- Dash ---------------------------------------------------------------------

func is_dash_ready() -> bool:
	return data.dash != null and dash_cooldown <= 0.0

func start_dash_cooldown() -> void:
	dash_cooldown = data.dash.cooldown

## Non si accumula: una nuova applicazione sostituisce valore e durata.
func apply_atk_buff(amount : int, duration : float) -> void:
	atk_buff = amount
	atk_buff_time = duration

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
