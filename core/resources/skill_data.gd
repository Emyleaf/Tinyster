class_name SkillData extends Resource

@export var skill_name : String = ""
## Icona mostrata nella HUD. Se null, la HUD mostra la lettera del tasto.
@export var icon : Texture2D
@export var cooldown : float = 5.0
## Danno finale = atk del membro * damage_mult
@export var damage_mult : float = 1.0
## Animazione nella libreria del personaggio (es. "attack_side").
## Se non esiste, il player ripiega su "attack_side".
@export var anim_name : String = "attack_side"
## Quanto dura il cast (il player resta fermo per questo tempo)
@export var cast_time : float = 0.4
## Moltiplicatore sulla dimensione della HurtBox durante il cast
@export var hitbox_scale : float = 1.0
