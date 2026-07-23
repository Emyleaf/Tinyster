class_name EquipmentData extends Resource

enum Slot { WEAPON, ARMOR, ACCESSORY }

@export var item_name : String = ""
@export var icon : Texture2D
@export var slot : Slot = Slot.WEAPON
@export var bonus_max_hp : int = 0
@export var bonus_atk : int = 0
@export var bonus_speed : float = 0.0
## Sommato al crit_rate del personaggio. 0.1 = +10% di probabilita'
@export_range(0.0, 1.0, 0.01) var bonus_crit_rate : float = 0.0
## Sommato al crit_dmg del personaggio. 0.2 = +20% di danno critico
@export_range(0.0, 3.0, 0.05) var bonus_crit_dmg : float = 0.0
