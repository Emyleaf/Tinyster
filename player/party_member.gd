class_name PartyMember extends RefCounted

var data: CharacterData
var current_hp: int
var current_mp: int
var level: int = 1
var experience: int = 0

func _init(character_data: CharacterData):
	data = character_data
	current_hp = data.max_hp
