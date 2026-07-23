extends Node

const MAX_SLOTS : int = 4

signal member_changed(index : int, member : PartyMember)
signal member_added(index : int, member : PartyMember)
signal member_hp_changed(index : int, member : PartyMember)
signal party_wiped()

var members : Array[PartyMember] = []
var active_index : int = -1

func _ready() -> void:
	new_game()

## Party iniziale a full HP. Usato all'avvio e da SaveManager.new_game().
func new_game() -> void:
	var warrior : CharacterData = preload("res://data/characters/warrior.tres")
	var archer : CharacterData = preload("res://data/characters/archer.tres")
	var starting : Array[CharacterData] = [warrior, archer]
	initialize_party(starting)

# --- Save / Load --------------------------------------------------------------

func get_save_data() -> Dictionary:
	var members_data : Array = []
	for m in members:
		var equip : Dictionary = {}
		for slot in m.equipment:
			equip[str(slot)] = m.equipment[slot].resource_path   # chiavi JSON = stringhe
		members_data.append({ "hp": m.current_hp, "equipment": equip })
	return {
		"active_index": active_index,
		"members": members_data,
	}

## La composizione del party è fissa (warrior + archer): ricrea i membri a full
## HP e poi sovrascrive solo gli HP salvati. Così resta robusto anche se in
## futuro cambiano le stat base dei personaggi.
func load_from_data(data : Dictionary) -> void:
	new_game()

	var members_data : Array = data.get("members", [])
	for i in mini(members_data.size(), members.size()):
		# ORDINE IMPORTANTE: prima l'equip, poi gli HP.
		# get_max_hp() dipende dall'equip, se clampi prima perdi HP.
		var equip : Dictionary = members_data[i].get("equipment", {})
		for slot_str in equip:
			var path : String = equip[slot_str]
			if ResourceLoader.exists(path):
				members[i].equip(load(path))

		var hp : int = int(members_data[i].get("hp", members[i].get_max_hp()))
		members[i].current_hp = clampi(hp, 0, members[i].get_max_hp())
		member_hp_changed.emit(i, members[i])

	var idx : int = int(data.get("active_index", 0))
	active_index = clampi(idx, 0, maxi(members.size() - 1, 0))
	if not members.is_empty():
		member_changed.emit(active_index, members[active_index])

## I cooldown scorrono per TUTTI i membri, anche fuori campo (come in Genshin)
func _process(delta : float) -> void:
	for m in members:
		m.tick_cooldowns(delta)

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

## Swap sullo slot index (0-3). Fallisce se lo slot e' vuoto o il membro e' morto.
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

## Unico punto in cui una skill viene consumata.
## Ritorna false se il membro attivo non ha quella skill o e' in cooldown.
func try_use_skill(slot : PartyMember.Slot) -> bool:
	var member := get_active()
	if member == null or not member.is_ready(slot):
		return false
	member.start_cooldown(slot)
	return true

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
