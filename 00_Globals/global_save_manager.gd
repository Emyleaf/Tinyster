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
	var player = get_tree().get_first_node_in_group("Player")
	if current_save.get("game_mode", "") != "dungeon":
		if player:
			player.hp = current_save["player"]["hp"]
			player.max_hp = current_save["player"]["max_hp"]
			player.global_position = Vector2(current_save["player"]["pos_x"], current_save["player"]["pos_y"])
		return  # hub: da implementare in futuro

	var dungeon_data: Dictionary = current_save.get("dungeon", {})
	if dungeon_data.is_empty():
		return

	# 1. Ricostruisce map_data e last_room in DungeonManager
	DungeonManager.load_from_data(dungeon_data)

	# 2. Resetta floors_climbed dal save (load_from_data lo sovrascrive già)
	#    last_room e last_exit_direction sono già impostati da load_from_data

	# 3. Distruggi la room corrente se esiste
	if DungeonManager.current_room_node:
		DungeonManager.current_room_node.queue_free()
		DungeonManager.current_room_node = null

	# 4. Re-entra nella stanza salvata
	#    Usiamo un frame di attesa per dare tempo a queue_free di completarsi
	var room := DungeonManager.last_room
	if room == null:
		return

	DungeonManager.is_transitioning = false
	await get_tree().process_frame
	DungeonManager.enter_room(room)

	await get_tree().create_timer(0.5).timeout
	
	var map := get_tree().get_first_node_in_group("Map") as Mappa
	if map:
		map.sync_visual_to_dungeon_state()
