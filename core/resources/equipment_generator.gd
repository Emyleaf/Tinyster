class_name EquipmentGenerator

## Produce istanze di EquipmentData a partire dai template .tres.
## Non e' un autoload: solo funzioni statiche, nessuno stato.

## template_path per slot. Aggiungi qui i .tres man mano che li crei.
const TEMPLATES : Dictionary = {
	EquipmentData.Slot.WEAPON:    ["res://data/equipment/weapon_basic.tres"],
	EquipmentData.Slot.ARMOR:     ["res://data/equipment/armor_basic.tres"],
	EquipmentData.Slot.ACCESSORY: ["res://data/equipment/accessory_basic.tres"],
	EquipmentData.Slot.SIGIL:     ["res://data/equipment/sigil_basic.tres"],
}

## Chiamata alla morte di un nemico. Ritorna null se non droppa nulla.
## `tier` 1-5 (da DungeonData.tier), `enemy_class` = BalanceConfig.CLASS_*
static func roll_drop(tier : int, enemy_class : int) -> EquipmentData:
	var t : int = BalanceConfig.ti(tier)
	var c : int = clampi(enemy_class, 0, 2)

	if randf() > BalanceConfig.DROP_CHANCE[c]:
		return null

	var rarity : int = _weighted_pick(BalanceConfig.DROP_WEIGHTS[t][c])
	if rarity < 0:
		return null

	var slot : int = randi() % EquipmentData.Slot.size()
	var paths : Array = TEMPLATES.get(slot, [])
	if paths.is_empty():
		return null

	return create(paths[randi() % paths.size()], rarity, 1)

## Unico punto in cui nasce un equipaggiamento.
## duplicate() e' OBBLIGATORIO: senza, setup() scriverebbe sulla risorsa
## condivisa e tutti i pezzi dello stesso template avrebbero le stesse stat.
static func create(template_path : String, rarity : int, level : int) -> EquipmentData:
	if not ResourceLoader.exists(template_path):
		push_error("EquipmentGenerator: template mancante %s" % template_path)
		return null

	var template : EquipmentData = load(template_path)
	var item : EquipmentData = template.duplicate()
	item.template_path = template_path
	item.setup(rarity, level)
	return item

# --- Salvataggio --------------------------------------------------------------

static func to_dict(item : EquipmentData) -> Dictionary:
	return {
		"path": item.template_path,
		"rarity": int(item.rarity),
		"level": item.level,
	}

static func from_dict(d : Dictionary) -> EquipmentData:
	return create(d.get("path", ""), int(d.get("rarity", 0)), int(d.get("level", 1)))

# --- Interno ------------------------------------------------------------------

static func _weighted_pick(weights : Array) -> int:
	var total : float = 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return -1

	var roll : float = randf() * total
	var acc : float = 0.0
	for i in weights.size():
		acc += weights[i]
		if roll < acc:
			return i
	return weights.size() - 1
