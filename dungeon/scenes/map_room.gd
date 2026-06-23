class_name MapRoom
extends Area2D

signal selected(room:Room)

const ICONS := {
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://dungeon/art/monster_room_icon.png"), Vector2(0.8,0.8)],
	Room.Type.TREASURE: [preload("res://dungeon/art/treasure_room_icon.png"), Vector2(0.8, 0.8)],
	Room.Type.CAMPFIRE: [preload("res://dungeon/art/campfire_room_icon.png"), Vector2(0.8, 0.8)],
	Room.Type.SHOP: [preload("res://dungeon/art/shop_room_icon.png"), Vector2(0.8, 0.8)],
	Room.Type.BOSS: [preload("res://dungeon/art/boss_room_icon.png"), Vector2(1.0, 1.0)],
}

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var room: Room : set = set_room

func set_available(new_value: bool) -> void:
	available = new_value
	
	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")

func hide_selected() -> void:
	animation_player.play("RESET")
	
	
func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	sprite_2d.texture = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]

func show_selected() -> void:
	line_2d.modulate = Color.WHITE


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return

	room.selected = true
	animation_player.play("select")


#called by AnimationPlayer when the "select" animation finishes
func _on_map_room_selected() -> void:
	selected.emit(room)
