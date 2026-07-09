class_name Run extends Node2D

const BATTLE_SCENE := preload("res://dungeon/scenes/room_monster.tscn")
const CAMPFIRE_SCENE := preload("res://dungeon/scenes/room_campfire.tscn")
const SHOP_SCENE := preload("res://dungeon/scenes/room_shop.tscn")
const TREASURE_SCENE = preload("res://dungeon/scenes/room_monster.tscn")
#const WIN_SCREEN_SCENE := preload("res://scenes/win_screen/win_screen.tscn")
#const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"

#@export var run_startup: RunStartup

@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var pause_menu: PauseMenu = $PauseMenu

#var stats: RunStats
#var character: CharacterStats
#var save_data: SaveGame

func _ready() -> void:
	pass
	#if not run_startup:
		#return
	#
	#pause_menu.save_and_quit.connect(
		#func(): 
			#get_tree().change_scene_to_file(MAIN_MENU_PATH)
	#)
	
	#match run_startup.type:
		#RunStartup.Type.NEW_RUN:
			#character = run_startup.picked_character.create_instance()
			#_start_run()
		#RunStartup.Type.CONTINUED_RUN:
			#_load_run()


#func _start_run() -> void:
	#stats = RunStats.new()
	#
	#_setup_event_connections()
	#_setup_top_bar()
	#
	#map.generate_new_map()
	#map.unlock_floor(0)
	#
	#save_data = SaveGame.new()
	#_save_run(true)


#func _save_run(was_on_map: bool) -> void:
	#save_data.rng_seed = RNG.instance.seed
	#save_data.rng_state = RNG.instance.state
	#save_data.run_stats = stats
	#save_data.char_stats = character
	#save_data.current_deck = character.deck
	#save_data.current_health = character.health
	#save_data.relics = relic_handler.get_all_relics()
	#save_data.last_room = map.last_room
	#save_data.map_data = map.map_data.duplicate()
	#save_data.floors_climbed = map.floors_climbed
	#save_data.was_on_map = was_on_map
	#save_data.save_data()


#func _load_run() -> void:
	#save_data = SaveGame.load_data()
	#assert(save_data, "Couldn't load last save")
	#
	#RNG.set_from_save_data(save_data.rng_seed, save_data.rng_state)
	#stats = save_data.run_stats
	#character = save_data.char_stats
	#character.deck = save_data.current_deck
	#character.health = save_data.current_health
	#relic_handler.add_relics(save_data.relics)
	#_setup_top_bar()
	#_setup_event_connections()
	#
	#map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_room)
	#if save_data.last_room and not save_data.was_on_map:
		#_on_map_exited(save_data.last_room)


func _change_view(scene: PackedScene) -> Node:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()
	
	get_tree().paused = false
	var new_view := scene.instantiate()
	current_view.add_child(new_view)
	map.hide_map()
	
	return new_view


func _show_map() -> void:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	map.show_map()
	map.unlock_next_rooms()
	
	#_save_run(true)


func _setup_event_connections() -> void:
	pass
	#Events.battle_won.connect(_on_battle_won)
	#Events.battle_reward_exited.connect(_show_map)
	#Events.campfire_exited.connect(_show_map)
	#Events.map_exited.connect(_on_map_exited)
	#Events.shop_exited.connect(_show_map)
	#Events.treasure_room_exited.connect(_on_treasure_room_exited)
	#Events.event_room_exited.connect(_show_map)
	#
	#battle_button.pressed.connect(_change_view.bind(BATTLE_SCENE))
	#campfire_button.pressed.connect(_change_view.bind(CAMPFIRE_SCENE))
	#map_button.pressed.connect(_show_map)
	#rewards_button.pressed.connect(_change_view.bind(BATTLE_REWARD_SCENE))
	#shop_button.pressed.connect(_change_view.bind(SHOP_SCENE))
	#treasure_button.pressed.connect(_change_view.bind(TREASURE_SCENE))


func _on_battle_room_entered(room: Room) -> void:
	var battle_scene = _change_view(BATTLE_SCENE)

func _on_treasure_room_entered() -> void:
	var treasure_scene := _change_view(TREASURE_SCENE)

func _on_campfire_entered() -> void:
	var campfire := _change_view(CAMPFIRE_SCENE)


func _on_shop_entered() -> void:
	var shop := _change_view(SHOP_SCENE)


func _on_event_room_entered(room: Room) -> void:
	var event_room := _change_view(room.event_scene)


func _on_map_exited(room: Room) -> void:
	match room.type:
		Room.Type.MONSTER:
			_on_battle_room_entered(room)
		Room.Type.TREASURE:
			_on_treasure_room_entered()
		Room.Type.CAMPFIRE:
			_on_campfire_entered()
		Room.Type.SHOP:
			_on_shop_entered()
		Room.Type.BOSS:
			_on_battle_room_entered(room)
		Room.Type.EVENT:
			_on_event_room_entered(room)
