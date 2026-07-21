extends Node

const PLAYER = preload("res://player/player.tscn")

var player : Player
var player_spawned : bool = false

var max_hp = 5
var current_hp = 5
var atk_dmg = 2
var char_name : String = "Warrior"
