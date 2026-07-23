class_name EquipmentData extends Resource

enum Slot { WEAPON, ARMOR, ACCESSORY }

@export var item_name : String = ""
@export var icon : Texture2D
@export var slot : Slot = Slot.WEAPON
@export var bonus_max_hp : int = 0
@export var bonus_atk : int = 0
@export var bonus_speed : float = 0.0
