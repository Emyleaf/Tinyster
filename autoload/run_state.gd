extends Node

## Stato che vive quanto una singola run e muore con essa.
## Fonte unica per oro, oggetti non equipaggiati e contatori di fine run.
## Gli HP e l'equipaggiamento indossato NON stanno qui: sono di PartyManager.

signal gold_changed(amount : int)
signal inventory_changed()

var gold : int = 0
var inventory : Array[EquipmentData] = []
var enemies_killed : int = 0
var rooms_cleared : int = 0


func new_game() -> void:
	gold = 0
	inventory.clear()
	enemies_killed = 0
	rooms_cleared = 0
	gold_changed.emit(gold)
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
		"inventory": paths,
		"enemies_killed": enemies_killed,
		"rooms_cleared": rooms_cleared,
	}

func load_from_data(data : Dictionary) -> void:
	new_game()
	gold = int(data.get("gold", 0))
	enemies_killed = int(data.get("enemies_killed", 0))
	rooms_cleared = int(data.get("rooms_cleared", 0))

	for path : String in data.get("inventory", []):
		if ResourceLoader.exists(path):
			inventory.append(load(path))
		else:
			push_warning("Item del salvataggio non trovato: %s" % path)

	gold_changed.emit(gold)
	inventory_changed.emit()
