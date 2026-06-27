extends CanvasLayer

@onready var button_save: Button = $VBoxContainer/Button_Save
@onready var button_load: Button = $VBoxContainer/Button_Load

var is_paused : bool = false
var map_was_open : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_pause_menu()
	button_save.pressed.connect(_on_save_pressed)
	button_load.pressed.connect(_on_load_pressed)
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused == false:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled() #consuma l'input	
		
func show_pause_menu() -> void:
	GameManager.request_pause("pause_menu")
	
	var map_node = get_tree().get_first_node_in_group("Map")
	if map_node and map_node.visible:
		map_was_open = true
		map_node.process_mode = Node.PROCESS_MODE_DISABLED   # blocca input
	else:
		map_was_open = false
	
	visible = true
	is_paused = true
	button_save.grab_focus()


func hide_pause_menu() -> void:
	GameManager.release_pause("pause_menu")
	
	if map_was_open:
		var map_node = get_tree().get_first_node_in_group("Map")
		if map_node:
			map_node.process_mode = Node.PROCESS_MODE_ALWAYS
		map_was_open = false
	
	visible = false
	is_paused = false
	
func _on_save_pressed() -> void:
	if is_paused == false:
		return
	SaveManager.save_game()
	hide_pause_menu()
	pass
	
func _on_load_pressed() -> void:
	if is_paused == false:
		return
	SaveManager.load_game()
	hide_pause_menu()
	pass
	
