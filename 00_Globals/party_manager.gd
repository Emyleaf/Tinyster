extends Node

const MAX_SLOTS : int = 4

signal member_changed(index : int, member : PartyMember)
signal member_added(index : int, member : PartyMember)
signal member_hp_changed(index : int, member : PartyMember)
signal party_wiped()

var members : Array[PartyMember] = []
var active_index : int = -1

func _ready() -> void:
	var warrior : CharacterData = preload("res://player/warrior.tres")
	var archer : CharacterData = preload("res://player/archer.tres")
	var starting : Array[CharacterData] = [warrior, archer]
	initialize_party(starting)

func initialize_party(character_datas : Array[CharacterData]) -> void:
	members.clear()
	active_index = -1
	for d in character_datas:
		add_member(d)
	if not members.is_empty():
		set_active(0)

func add_member(data : CharacterData) -> PartyMember:
	if members.size() >= MAX_SLOTS:
		return null
	var member := PartyMember.new(data)
	members.append(member)
	member_added.emit(members.size() - 1, member)
	return member

## Swap sullo slot index (0-3). Fallisce se lo slot è vuoto o il membro è morto.
func set_active(index : int) -> bool:
	if index < 0 or index >= members.size():
		return false
	if index == active_index:
		return false
	if not members[index].is_alive():
		return false
	active_index = index
	member_changed.emit(active_index, members[active_index])
	return true

func get_active() -> PartyMember:
	return get_member(active_index)

func get_member(index : int) -> PartyMember:
	if index < 0 or index >= members.size():
		return null
	return members[index]

## Unico punto in cui gli HP del membro attivo vengono modificati
func damage_active(amount : int) -> void:
	var member := get_active()
	if member == null:
		return
	member.current_hp = clampi(member.current_hp - amount, 0, member.get_max_hp())
	member_hp_changed.emit(active_index, member)
	if not member.is_alive():
		_on_active_died()

func heal_active(amount : int) -> void:
	damage_active(-amount)

func _on_active_died() -> void:
	var next := _find_next_alive()
	if next == -1:
		party_wiped.emit()
		return
	active_index = next
	member_changed.emit(active_index, members[active_index])

func _find_next_alive() -> int:
	for i in members.size():
		var idx : int = (active_index + 1 + i) % members.size()
		if members[idx].is_alive():
			return idx
	return -1

func _unhandled_input(event : InputEvent) -> void:
	for i in MAX_SLOTS:
		if event.is_action_pressed("swap_char%d" % (i + 1)):
			set_active(i)
			return
