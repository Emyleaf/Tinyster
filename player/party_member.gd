class_name PartyMember extends RefCounted

var data : CharacterData
var current_hp : int
## Slot (EquipmentData.Slot) -> EquipmentData
var equipment : Dictionary = {}

func _init(character_data : CharacterData) -> void:
	data = character_data
	current_hp = get_max_hp()

func get_max_hp() -> int:
	return data.max_hp + int(_bonus("bonus_max_hp"))

func get_atk() -> int:
	return data.atk + int(_bonus("bonus_atk"))

func get_speed() -> float:
	return data.speed + _bonus("bonus_speed")

func get_skills() -> Array[SkillData]:
	return data.skills

func is_alive() -> bool:
	return current_hp > 0

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
