class_name CharacterData extends Resource

@export var char_name : String = ""
## Ritratto per la HUD. Se null, la HUD usa il primo frame dello sprite_sheet.
@export var icon : Texture2D
@export var sprite_sheet : Texture2D
@export var speed : float = 300.0
@export var max_hp : int = 100
@export var atk : int = 2
## Probabilita' di colpo critico, 0.0 - 1.0
@export_range(0.0, 1.0, 0.01) var crit_rate : float = 0.05
## Tasto E
@export var skill : SkillData
## Tasto Q
@export var ultimate : SkillData
## Proiettile dell'attacco base. Se null, l'attacco base è corpo a corpo.
@export var projectile : PackedScene
