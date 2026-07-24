class_name EquipmentData extends Resource

## Un .tres di equipaggiamento e' un TEMPLATE: definisce nome, icona e slot,
## mai rarita' o livello. L'istanza vera la produce EquipmentGenerator,
## che duplica il template e chiama setup().
##
## I campi bonus_* NON sono @export: sono derivati da (rarity, level) tramite
## _refresh(). Hanno gli stessi nomi di RunBuff, cosi' PartyMember._bonus()
## continua a sommarli senza sapere da dove arrivano: nessuna modifica li'.

enum Slot { WEAPON, ARMOR, ACCESSORY, SIGIL }
enum Rarity { BASE, UNCOMMON, RARE, EPIC, LEGENDARY }

# --- Template (nei .tres) -----------------------------------------------------

@export var item_name : String = ""
@export var icon : Texture2D
@export var slot : Slot = Slot.WEAPON

# --- Istanza (a runtime) ------------------------------------------------------

## Path del .tres da cui e' stato generato. duplicate() azzera resource_path,
## quindi il salvataggio ha bisogno di questo campo per ricostruire il pezzo.
var template_path : String = ""
var rarity : Rarity = Rarity.BASE
var level : int = 1

# --- Derivati -----------------------------------------------------------------

var bonus_atk : int = 0
var bonus_max_hp : int = 0
var bonus_speed : float = 0.0
var bonus_crit_rate : float = 0.0
var bonus_crit_dmg : float = 0.0
var energy_recharge : float = 0.0

# --- API ----------------------------------------------------------------------

func setup(new_rarity : Rarity, new_level : int) -> void:
	rarity = new_rarity
	level = clampi(new_level, 1, max_level())
	_refresh()

func max_level() -> int:
	return BalanceConfig.RARITY_CAP[rarity]

func can_upgrade() -> bool:
	return level < max_level()

## Non paga nulla: il costo lo gestisce Economy.upgrade_item()
func upgrade() -> void:
	if not can_upgrade():
		return
	level += 1
	_refresh()

func get_display_name() -> String:
	return "%s (%s lv%d/%d)" % [item_name, BalanceConfig.RARITY_NAMES[rarity],
		level, max_level()]

# --- Calcolo ------------------------------------------------------------------

## Posizione dentro la banda: 0.0 a lv1, 1.0 a livello massimo
func _t() -> float:
	var cap : int = max_level()
	if cap <= 1:
		return 1.0
	return float(level - 1) / float(cap - 1)

## Una sola stat per slot. Tutte le altre restano a zero: il budget della
## curva nemici assume UNA sola fonte di ATK e UNA sola di HP.
func _refresh() -> void:
	bonus_atk = 0
	bonus_max_hp = 0
	bonus_speed = 0.0
	bonus_crit_rate = 0.0
	bonus_crit_dmg = 0.0
	energy_recharge = 0.0

	var t : float = _t()
	match slot:
		Slot.WEAPON:
			var b : Vector2i = BalanceConfig.BAND_ATK[rarity]
			bonus_atk = roundi(lerpf(b.x, b.y, t))
		Slot.ARMOR:
			var b : Vector2i = BalanceConfig.BAND_HP[rarity]
			bonus_max_hp = roundi(lerpf(b.x, b.y, t))
		Slot.ACCESSORY:
			var b : Vector2 = BalanceConfig.BAND_CRIT[rarity]
			bonus_crit_rate = lerpf(b.x, b.y, t)
		Slot.SIGIL:
			var b : Vector2 = BalanceConfig.BAND_RECHARGE[rarity]
			energy_recharge = lerpf(b.x, b.y, t)
