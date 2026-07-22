extends TextureProgressBar

func _ready() -> void:
	PartyManager.member_changed.connect(_on_party_signal)
	PartyManager.member_hp_changed.connect(_on_party_signal)
	_refresh()

func _on_party_signal(_index : int, _member : PartyMember) -> void:
	_refresh()

func _refresh() -> void:
	var member := PartyManager.get_active()
	if member == null or member.get_max_hp() <= 0:
		value = 0
		return
	value = member.current_hp * 100.0 / member.get_max_hp()
