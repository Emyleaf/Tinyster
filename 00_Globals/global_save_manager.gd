extends Node

const SAVE_PATH := "user://"
const SAVE_FILE := "save.sav"

signal game_loaded
signal game_saved

var current_save: Dictionary = {
	"game_mode": "hub",        # "hub" o "dungeon"
	"player": {
		"hp": 6,
		"max_hp": 6,
		"pos_x": 0.0,
		"pos_y": 0.0,
		"inventory": [],      # array di ID oggetti o risorse
		"equipment": {},
		# ... altre stats
	},
	"hub": {
		"quests_completed": [],
		"upgrades": {},
		# ... dati permanenti dell'hub
	},
	"dungeon": {
		"seed": 12345,                       # opzionale, se rigeneri da seed
		"floors_climbed": 2,
		"map_data": [],                      # array di stanze serializzate
		"last_room_index": -1,               # per ritrovare la stanza attuale
		"rooms_cleared": [],                 # indici o coordinate
		"persistent_items": [],              # oggetti ottenuti durante il run
		# ... tutto ciò che serve a riprendere il run esattamente
	}
}

func save_game() -> void:
	update_save_data()
	var file := FileAccess.open( SAVE_PATH.path_join(SAVE_FILE), FileAccess.WRITE)
	var save_json = JSON.stringify( current_save )
	file.store_line( save_json )
	game_saved.emit()
	pass
	
func load_game() -> void:
	var file := FileAccess.open( SAVE_PATH + "save.sav", FileAccess.READ)
	var json := JSON.new()
	json.parse( file.get_line() )
	var save_dict : Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	
	apply_loaded_data()
	game_loaded.emit()
	pass

func update_save_data() -> void:
	# Modalità gioco
	if DungeonManager.current_room_node != null:
		current_save["game_mode"] = "dungeon"
		current_save["dungeon"] = DungeonManager.get_save_data()
	else:
		current_save["game_mode"] = "hub"
		# eventualmente salva dati specifici dell'hub
	
	# Dati giocatore
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		current_save["player"]["hp"] = player.hp
		current_save["player"]["max_hp"] = player.max_hp
		current_save["player"]["pos_x"] = player.global_position.x
		current_save["player"]["pos_y"] = player.global_position.y
		# inventory, etc.
	
func apply_loaded_data() -> void:
	# Posiziona il giocatore (se è nella scena)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.hp = current_save["player"]["hp"]
		player.max_hp = current_save["player"]["max_hp"]
		player.global_position = Vector2(current_save["player"]["pos_x"], current_save["player"]["pos_y"])
		# aggiorna HUD, etc.
	
	# Carica la scena corretta in base alla modalità
	if current_save["game_mode"] == "dungeon":
		# Carica la scena del dungeon (es. "main.tscn" o una scena base)
		# e poi applica lo stato del dungeon
		DungeonManager.load_from_data(current_save["dungeon"])
		# Devi anche spawnare la stanza attuale e i nemici rimanenti...
		# Questo dipende dalla tua implementazione della transizione tra stanze.
	else:
		# Carica la scena dell'HUB
		pass
