extends Node

signal member_changed(new_index: int, member: PartyMember)
signal member_added(member: PartyMember)
signal member_stats_updated(index: int, member: PartyMember)

var members: Array[PartyMember] = []
var active_index: int = -1

func _ready():
	# Carica i membri iniziali (oppure fallo da un GameManager/Level)
	var warrior_data: CharacterData = preload("res://player/warrior.tres")
	var archer_data: CharacterData = preload("res://player/archer.tres")
	
	initialize_party([warrior_data, archer_data])

## Inizializza il party da un array di CharacterData
func initialize_party(character_datas: Array[CharacterData]):
	members.clear()
	for d in character_datas:
		add_member(d)
	
	if members.size() > 0:
		set_active(0)

func add_member(data: CharacterData) -> PartyMember:
	var member = PartyMember.new(data)
	members.append(member)
	member_added.emit(member)
	return member

# Swappa al membro dato l'indice (0 = Warrior, 1 = Archer)
func set_active(index: int) -> bool:
	if index < 0 or index >= members.size() or index == active_index:
		return false
	
	active_index = index
	var member = members[active_index]
	member_changed.emit(active_index, member)
	return true

func get_active() -> PartyMember:
	if active_index >= 0 and active_index < members.size():
		return members[active_index]
	return null

func get_member(index: int) -> PartyMember:
	if index >= 0 and index < members.size():
		return members[index]
	return null

func _input(event: InputEvent):
	if event.is_action_pressed("swap_char1"):
		set_active(0)
	elif event.is_action_pressed("swap_char2"):
		set_active(1)
