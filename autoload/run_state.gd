extends Node

## Stato che vive quanto una singola run e muore con essa.
## Fonte unica per oro, chiavi, oggetti non equipaggiati e contatori di fine run.
## Gli HP e l'equipaggiamento indossato NON stanno qui: sono di PartyManager.

signal gold_changed(amount : int)
signal keys_changed(amount : int)
signal inventory_changed()

var gold : int = 0
var keys : int = 0
var inventory : Array[EquipmentData] = []
var enemies_killed : int = 0
var rooms_cleared : int = 0


func new_game() -> void:
	gold = 0
	keys = 0
	inventory.clear()
	enemies_killed = 0
	rooms_cleared = 0
	gold_changed.emit(gold)
	keys_changed.emit(keys)
	inventory_changed.emit()

# --- Oro ----------------------------------------------------------------------

func add_gold(amount : int) -> void:
	gold = maxi(gold + amount, 0)
	gold_changed.emit(gold)

## Unico punto in cui l'oro viene speso. False se non basta.
func try_spend(amount : int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# --- Chiavi -------------------------------------------------------------------

func add_key(amount : int = 1) -> void:
	keys = maxi(keys + amount, 0)
	keys_changed.emit(keys)

## Unico punto in cui una chiave viene consumata. False se non basta.
func try_spend_key(amount : int = 1) -> bool:
	if amount > keys:
		return false
	keys -= amount
	keys_changed.emit(keys)
	return true

# --- Inventario ---------------------------------------------------------------

func add_item(item : EquipmentData) -> void:
	inventory.append(item)
	inventory_changed.emit()

func remove_item(item : EquipmentData) -> void:
	inventory.erase(item)
	inventory_changed.emit()

# --- Save / Load --------------------------------------------------------------

func get_save_data() -> Dictionary:
	var paths : Array = []
	for item in inventory:
		paths.append(item.resource_path)
	return {
		"gold": gold,
		"keys": keys,
		"inventory": paths,
		"enemies_killed": enemies_killed,
		"rooms_cleared": rooms_cleared,
	}

func load_from_data(data : Dictionary) -> void:
	new_game()
	gold = int(data.get("gold", 0))
	keys = int(data.get("keys", 0))
	enemies_killed = int(data.get("enemies_killed", 0))
	rooms_cleared = int(data.get("rooms_cleared", 0))

	for path : String in data.get("inventory", []):
		if ResourceLoader.exists(path):
			inventory.append(load(path))
		else:
			push_warning("Item del salvataggio non trovato: %s" % path)

	gold_changed.emit(gold)
	keys_changed.emit(keys)
	inventory_changed.emit()
