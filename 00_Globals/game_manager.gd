extends Node

const MAIN = preload("res://main.tscn")

@onready var main_scene = get_node("/root/Main")

var current_run : Run = null

var _pause_sources: Array[String] = []  # tiene traccia di chi ha chiesto la pausa

func request_pause(source: String) -> void:
	if not source in _pause_sources:
		_pause_sources.append(source)
		_update_pause()


func release_pause(source: String) -> void:
	if source in _pause_sources:
		_pause_sources.erase(source)
		_update_pause()

func _update_pause() -> void:
	get_tree().paused = not _pause_sources.is_empty()
	
func is_paused_by(source: String) -> bool:
	return source in _pause_sources
