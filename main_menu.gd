extends Control

const MAIN_SCENE := "res://main.tscn"

@onready var load_button : Button = %LoadButton


func _ready() -> void:
	# "Continua" disponibile solo se esiste un salvataggio.
	load_button.disabled = not SaveManager.has_save()


func _on_start_pressed() -> void:
	SaveManager.new_game()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_load_pressed() -> void:
	if SaveManager.load_game():
		get_tree().change_scene_to_file(MAIN_SCENE)
