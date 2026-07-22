class_name AbilityButton extends Control

## Quale skill del membro attivo controlla questo tasto: E o Q.
@export var slot : PartyMember.Slot = PartyMember.Slot.SKILL
## Lettera mostrata al centro finche' non c'e' un'icona
@export var key_text : String = "E"

@onready var ring : CooldownRing = %Ring
@onready var content : Control = %Content
@onready var key_label : Label = %KeyLabel
@onready var icon : TextureRect = %Icon
@onready var timer_label : Label = %TimerLabel

func _ready() -> void:
	key_label.text = key_text

func _process(_delta : float) -> void:
	var member := PartyManager.get_active()
	var skill : SkillData = member.get_skill_data(slot) if member else null
	var has_skill : bool = skill != null

	ring.visible = has_skill
	content.visible = has_skill
	if not has_skill:
		timer_label.text = ""
		return

	icon.texture = skill.icon
	ring.charge = member.get_charge(slot)

	var left : float = member.cooldowns[slot]
	content.modulate = Color(1, 1, 1, 1) if left <= 0.0 else Color(0.55, 0.6, 0.7, 1)
	timer_label.text = "" if left <= 0.0 else ("%.1f" % left)
