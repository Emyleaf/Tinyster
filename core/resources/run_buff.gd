class_name RunBuff extends RefCounted

## Buff scelto a fine stanza. Vive quanto la run: sta in RunState.buffs.
## I campi bonus_* hanno gli stessi nomi di EquipmentData, cosi'
## PartyMember._bonus() somma equip e buff nello stesso ciclo.

var id : String = ""
var buff_name : String = ""
var description : String = ""

var bonus_max_hp : int = 0
var bonus_atk : int = 0
var bonus_speed : float = 0.0
var bonus_crit_rate : float = 0.0
var bonus_crit_dmg : float = 0.0

## Percentuali, applicate DOPO i flat. 0.15 = +15%
var pct_max_hp : float = 0.0
var pct_atk : float = 0.0
## Moltiplicatore sull'energia guadagnata. 0.25 = +25%
var energy_recharge : float = 0.0

func _init(d : Dictionary = {}) -> void:
	id = d.get("id", "")
	buff_name = d.get("buff_name", "")
	description = d.get("description", "")
	bonus_max_hp = d.get("bonus_max_hp", 0)
	bonus_atk = d.get("bonus_atk", 0)
	bonus_speed = d.get("bonus_speed", 0.0)
	bonus_crit_rate = d.get("bonus_crit_rate", 0.0)
	bonus_crit_dmg = d.get("bonus_crit_dmg", 0.0)
	pct_max_hp = d.get("pct_max_hp", 0.0)
	pct_atk = d.get("pct_atk", 0.0)
	energy_recharge = d.get("energy_recharge", 0.0)
