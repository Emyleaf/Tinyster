extends Node

## Autoload. Unico posto in cui esistono le due valute.
##
## GOLD  : vive quanto la run, si spende dentro il dungeon, perso alla morte.
## SHARD : permanente, si spende a Serendipity per potenziare l'equip.
##
## NOTA ARCHITETTURALE: il gold e' dato di run e in teoria apparterrebbe a
## RunState. Sta qui perche' avere le due valute in due posti rende la UI del
## portafoglio dipendente da due sorgenti. Se preferisci spostarlo in
## RunState, l'unica cosa da garantire e' che resti una sola autorita'.

signal gold_changed(value : int)
signal shards_changed(value : int)

var gold : int = 0
var shards : int = 0

## Id dei dungeon gia' completati almeno una volta. Serve al bonus primo clear
## ed e' anche l'informazione da cui la mappa del mondo ricava cosa e' sbloccato.
var cleared_dungeons : Array[String] = []

# --- Ciclo della run ----------------------------------------------------------

## Chiamata all'ingresso di un dungeon
func start_run() -> void:
	gold = 0
	gold_changed.emit(gold)

## Chiamata a fine dungeon, sia in caso di clear che di morte.
## Il gold viene azzerato in ogni caso, gli shard restano.
func end_run(dungeon : DungeonData, rooms_cleared : int, boss_killed : bool,
		heat : int = 0) -> int:
	var first : bool = boss_killed and not cleared_dungeons.has(dungeon.id)
	var earned : int = BalanceConfig.run_shard_reward(
		dungeon.tier, rooms_cleared, boss_killed, heat, first)
	add_shards(earned)

	if first:
		cleared_dungeons.append(dungeon.id)

	gold = 0
	gold_changed.emit(gold)
	return earned

func is_cleared(dungeon_id : String) -> bool:
	return cleared_dungeons.has(dungeon_id)

# --- Gold ---------------------------------------------------------------------

func add_gold(amount : int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit(gold)

func spend_gold(amount : int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# --- Shard --------------------------------------------------------------------

func add_shards(amount : int) -> void:
	shards = maxi(0, shards + amount)
	shards_changed.emit(shards)

func spend_shards(amount : int) -> bool:
	if amount > shards:
		return false
	shards -= amount
	shards_changed.emit(shards)
	return true

# --- Potenziamento ------------------------------------------------------------

## Sale di un livello se ci sono abbastanza shard. Ritorna false se non
## e' stato possibile (cap raggiunto o shard insufficienti).
func upgrade_item(item : EquipmentData) -> bool:
	if item == null or not item.can_upgrade():
		return false
	if not spend_shards(BalanceConfig.upgrade_cost(item.level)):
		return false
	item.upgrade()
	return true

## Distrugge il pezzo e restituisce il 75% degli shard investiti.
## Chi chiama deve rimuoverlo dall'inventario / dallo slot.
func dismantle_item(item : EquipmentData) -> int:
	if item == null:
		return 0
	var refund : int = BalanceConfig.dismantle_value(item.level)
	add_shards(refund)
	return refund

# --- Save / Load --------------------------------------------------------------

func get_save_data() -> Dictionary:
	return {
		"shards": shards,
		"cleared_dungeons": cleared_dungeons,
	}

func load_from_data(data : Dictionary) -> void:
	shards = int(data.get("shards", 0))
	cleared_dungeons.assign(data.get("cleared_dungeons", []))
	gold = 0
	shards_changed.emit(shards)
	gold_changed.emit(gold)
