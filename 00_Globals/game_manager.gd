extends Node2D

const MAIN = preload("res://main.tscn")

@onready var main_scene = get_node("/root/Main")

var current_run : Run = null
