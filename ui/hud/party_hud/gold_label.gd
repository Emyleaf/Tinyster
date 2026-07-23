extends Label

func _ready() -> void:
	RunState.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(RunState.gold)

func _on_gold_changed(amount : int) -> void:
	text = str(amount)
