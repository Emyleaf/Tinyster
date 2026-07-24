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
## Energia accumulata per la ultimate. Parte da 0 a inizio dungeon.
var energy : float = 0.0

func _init(character_data : CharacterData) -> void:
	data = character_data
	current_hp = get_max_hp()

func get_max_hp() -> int:
	var flat : float = data.max_hp + _bonus("bonus_max_hp")
	return maxi(1, roundi(flat * (1.0 + _buff_sum("pct_max_hp"))))

func get_atk() -> int:
	var flat : float = data.atk + _bonus("bonus_atk") + atk_buff
	return maxi(1, roundi(flat * (1.0 + _buff_sum("pct_atk"))))

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
	if get_skill_data(slot) == null:
		return false
	if cooldowns[slot] > 0.0:
		return false
	# La ultimate ha un secondo gate: l'energia deve essere piena
	if slot == Slot.ULTIMATE:
		return energy >= get_energy_cost()
	return true

## Unico punto in cui una skill viene "pagata": cooldown e, per la ultimate,
## l'energia accumulata che torna a zero.
func consume(slot : Slot) -> void:
	var skill := get_skill_data(slot)
	if skill == null:
		return
	cooldowns[slot] = skill.cooldown
	if slot == Slot.ULTIMATE:
		energy = 0.0

## Riempimento dell'anello nella HUD.
## SKILL: avanzamento del cooldown. ULTIMATE: energia accumulata.
func get_charge(slot : Slot) -> float:
	if slot == Slot.ULTIMATE:
		return get_energy_ratio()
	var skill := get_skill_data(slot)
	if skill == null or skill.cooldown <= 0.0:
		return 1.0
	return 1.0 - cooldowns[slot] / skill.cooldown

# --- Energia ultimate ---------------------------------------------------------

func get_energy_cost() -> float:
	var ult := get_skill_data(Slot.ULTIMATE)
	return ult.energy_cost if ult else 0.0

## 0.0 = vuota, 1.0 = ultimate carica
func get_energy_ratio() -> float:
	var cost : float = get_energy_cost()
	if cost <= 0.0:
		return 1.0
	return clampf(energy / cost, 0.0, 1.0)

func get_energy_recharge() -> float:
	return maxf(0.0, 1.0 + _buff_sum("energy_recharge"))

func add_energy(amount : float) -> void:
	if amount <= 0.0:
		return
	energy = minf(energy + amount * get_energy_recharge(), get_energy_cost())

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

## Bonus piatti: equip indossato + buff della run (stessi nomi di campo)
func _bonus(field : String) -> float:
	var total : float = 0.0
	for item in equipment.values():
		total += item.get(field)
	for buff in RunState.buffs:
		total += buff.get(field)
	return total

## Campi che esistono solo sui buff (percentuali, ricarica energia)
func _buff_sum(field : String) -> float:
	var total : float = 0.0
	for buff in RunState.buffs:
		total += buff.get(field)
	return total
