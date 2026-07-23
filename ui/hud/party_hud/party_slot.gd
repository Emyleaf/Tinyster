class_name PartySlot extends Control

@export var slot_index : int = 0

const COL_HP_FILL := Color(0.36, 0.86, 0.44)
const COL_DEAD := Color(0.75, 0.25, 0.25)
# Fallback ritratto: griglia dello sprite sheet quando CharacterData.icon e' null
const SHEET_HFRAMES : int = 8
const SHEET_VFRAMES : int = 4

@onready var ring : CooldownRing = %Ring
@onready var ult_icon : TextureRect = %UltIcon
@onready var name_label : Label = %NameLabel
@onready var hp_bar : ProgressBar = %HpBar
@onready var portrait : TextureRect = %Portrait
@onready var key_label : Label = %KeyLabel

func _ready() -> void:
	key_label.text = str(slot_index + 1)
	PartyManager.member_added.connect(_on_party_signal)
	PartyManager.member_changed.connect(_on_party_signal)
	_refresh_static()

## Ogni frame: HP e cooldown cambiano di continuo, niente da guadagnare
## nell'agganciarsi a segnali dedicati.
func _process(_delta : float) -> void:
	_refresh_dynamic()

func _on_party_signal(_index : int, _member : PartyMember) -> void:
	_refresh_static()

## Dati che cambiano solo su swap / reclutamento
func _refresh_static() -> void:
	var member := PartyManager.get_member(slot_index)
	visible = member != null
	if member == null:
		return
	name_label.text = member.data.char_name
	portrait.texture = _portrait_for(member.data)
	var ult := member.get_skill_data(PartyMember.Slot.ULTIMATE)
	ult_icon.texture = ult.icon if ult else null

## Dati che cambiano ogni frame (HP e cooldown)
func _refresh_dynamic() -> void:
	var member := PartyManager.get_member(slot_index)
	if member == null:
		return
	hp_bar.value = member.current_hp * 100.0 / maxi(member.get_max_hp(), 1)
	ring.charge = member.get_charge(PartyMember.Slot.ULTIMATE)
	if not member.is_alive():
		modulate = Color(COL_DEAD.r, COL_DEAD.g, COL_DEAD.b, 0.5)
	elif slot_index == PartyManager.active_index:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(1, 1, 1, 0.55)

func _portrait_for(data : CharacterData) -> Texture2D:
	if data.icon:
		return data.icon
	if data.sprite_sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = data.sprite_sheet
	var frame_size : Vector2 = data.sprite_sheet.get_size() / Vector2(SHEET_HFRAMES, SHEET_VFRAMES)
	atlas.region = Rect2(Vector2.ZERO, frame_size)
	return atlas
