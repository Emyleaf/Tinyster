extends Node

const MAIN = preload("res://main.tscn")

enum State { HUB, OVERWORLD, DUNGEON }
 #func go_to_hub()
 #func go_to_overworld()
 #func enter_dungeon(dungeon_id)   → crea DungeonContainer dentro WorldContent
 #func exit_dungeon(success:bool) → distrugge DungeonContainer, go_to_hub()

var current_run : Run = null
