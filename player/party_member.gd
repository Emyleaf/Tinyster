class_name PartyMember extends RefCounted

var data: CharacterData
var current_hp: int
var atk : int 
var speed : float

func _init(character_data: CharacterData):
	data = character_data
	current_hp = data.max_hp
	atk = data.atk
	speed = data.speed
