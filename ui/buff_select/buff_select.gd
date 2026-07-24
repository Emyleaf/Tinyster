class_name BuffSelect extends CanvasLayer

## Tre carte a fine stanza: se ne sceglie una, poi si torna alla mappa.
## Costruita da codice e non da .tscn: e' UI usa-e-getta, un file solo.

signal chosen(buff : RunBuff)

const CARD_SIZE := Vector2(260, 320)

var _buffs : Array[RunBuff] = []
var _done : bool = false

## Apre la schermata e restituisce il buff scelto. Va chiamata con await.
## Ritorna null se non ci sono carte da mostrare.
static func open(parent : Node, buffs : Array[RunBuff]) -> RunBuff:
	if buffs.is_empty():
		return null

	var ui := BuffSelect.new()
	ui._buffs = buffs
	parent.add_child(ui)

	var buff : RunBuff = await ui.chosen
	ui.queue_free()
	return buff

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 32)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var title := Label.new()
	title.text = "Scegli una benedizione"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	root.add_child(row)

	for buff in _buffs:
		row.add_child(_make_card(buff))

func _make_card(buff : RunBuff) -> Control:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.pressed.connect(_on_card_pressed.bind(buff))

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	# Senza questo il VBox mangia il click destinato al Button sotto
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var name_label := Label.new()
	name_label.text = buff.buff_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 24)
	box.add_child(name_label)

	var desc := Label.new()
	desc.text = buff.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.78, 0.84, 0.95)
	box.add_child(desc)

	return card

## Una sola carta e' selezionabile: dopo la prima pressione il pannello e' morto
func _on_card_pressed(buff : RunBuff) -> void:
	if _done:
		return
	_done = true
	chosen.emit(buff)
