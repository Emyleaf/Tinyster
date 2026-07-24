extends HBoxContainer

## Chiavi possedute, accanto all'oro. Compare solo quando ne hai almeno una.

@onready var amount_label : Label = $Amount

func _ready() -> void:
	RunState.keys_changed.connect(_on_keys_changed)
	_on_keys_changed(RunState.keys)

func _on_keys_changed(amount : int) -> void:
	amount_label.text = str(amount)
	visible = amount > 0
