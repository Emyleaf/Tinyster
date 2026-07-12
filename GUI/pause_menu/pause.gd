extends CanvasLayer

var is_paused : bool = false
var map_was_open : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_pause_menu()
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused == false:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled() #consuma l'input	
		
func show_pause_menu() -> void:
	visible = true
	is_paused = true

func hide_pause_menu() -> void:
	visible = false
	is_paused = false
