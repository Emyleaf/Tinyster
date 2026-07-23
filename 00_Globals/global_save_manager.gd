extends Node

## Salvataggio del run in JSON (niente Resource, per motivi di sicurezza).
## L'autosave scatta quando esci da una stanza:
##   DungeonManager.complete_room() -> _finish_transition() -> save_game()
## Il Load NON rientra nella stanza: riprendi dalla mappa, esattamente dove
## avevi lasciato (stanze completate + prossime sbloccate + HP correnti del party).

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

signal game_saved
signal game_loaded

## Impostato da load_game(): dice a Map._ready() di ricostruire la mappa salvata
## invece di generarne una nuova. Viene riazzerato da Map._ready() dopo l'uso.
var pending_load : bool = false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Serializza lo stato corrente del run (mappa + progressi + party) su file JSON.
func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"dungeon": DungeonManager.get_save_data(),
		"party": PartyManager.get_save_data(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Salvataggio fallito: %s" % error_string(FileAccess.get_open_error()))
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	game_saved.emit()


## Carica i dati dal file nei manager. Ritorna false se il salvataggio manca
## o è corrotto. Non tocca la scena: sarà la MainMenu a cambiare scena e sarà
## Map._ready() (grazie a pending_load) a ricostruire la mappa.
func load_game() -> bool:
	if not has_save():
		push_warning("Nessun salvataggio da caricare.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Caricamento fallito: %s" % error_string(FileAccess.get_open_error()))
		return false

	var text := file.get_as_text()
	file.close()

	var parsed : Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Salvataggio corrotto o non valido.")
		return false

	var data : Dictionary = parsed
	DungeonManager.load_from_data(data.get("dungeon", {}))
	PartyManager.load_from_data(data.get("party", {}))

	pending_load = true
	game_loaded.emit()
	return true


## Nuova partita: resetta mappa e party allo stato iniziale (party full HP).
func new_game() -> void:
	pending_load = false
	DungeonManager.map_data.clear()
	DungeonManager.floors_climbed = 0
	DungeonManager.last_room = null
	PartyManager.new_game()
