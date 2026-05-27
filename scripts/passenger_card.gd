extends Control

signal accepted
signal declined

const CARD_W := 280.0
const CARD_H := 120.0
const OFF_X  := -320.0
const ON_X   :=  20.0

var _is_shown := false

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	size = Vector2(CARD_W, CARD_H)
	_build_ui()
	position = Vector2(OFF_X, _card_y())

func _card_y() -> float:
	return get_viewport_rect().size.y - CARD_H - 20.0

func _build_ui() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color                  = Color(0.08, 0.08, 0.08, 0.88)
	bg_style.corner_radius_top_left    = 8
	bg_style.corner_radius_top_right   = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	add_child(_make_label("NameLabel", Vector2(12, 10), 15, Color.WHITE))
	add_child(_make_label("DestLabel", Vector2(12, 34), 13, Color(0.8, 0.8, 0.8)))
	add_child(_make_label("FareLabel", Vector2(12, 56), 14, Color(0.95, 0.85, 0.3)))

	add_child(_make_button("AcceptBtn",  "Accept ✓",  Vector2(12,  86), Color("#2a7a3a"), _on_accept))
	add_child(_make_button("DeclineBtn", "Decline ✗", Vector2(148, 86), Color("#7a2a2a"), _on_decline))

func _make_label(lbl_name: String, pos: Vector2, sz: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.name = lbl_name
	lbl.position = pos
	lbl.size = Vector2(256, 22)
	lbl.add_theme_font_size_override("font_size", sz)
	lbl.add_theme_color_override("font_color", col)
	return lbl

func _make_button(btn_name: String, lbl: String, pos: Vector2, col: Color, cb: Callable) -> Button:
	var s := StyleBoxFlat.new()
	s.bg_color                  = col
	s.corner_radius_top_left    = 5
	s.corner_radius_top_right   = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5

	var btn := Button.new()
	btn.name = btn_name
	btn.text = lbl
	btn.position = pos
	btn.size = Vector2(118, 26)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(cb)
	return btn

func show_for(npc: Node) -> void:
	get_node("NameLabel").text = npc.passenger_name
	get_node("DestLabel").text = "→ " + npc.destination
	get_node("FareLabel").text = "₹" + str(npc.fare)
	if not _is_shown:
		_is_shown = true
		position = Vector2(OFF_X, _card_y())
		var tw := create_tween()
		tw.tween_property(self, "position:x", ON_X, 0.3) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func hide_card() -> void:
	if not _is_shown:
		return
	_is_shown = false
	var tw := create_tween()
	tw.tween_property(self, "position:x", OFF_X, 0.3) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func _on_accept() -> void:
	accepted.emit()

func _on_decline() -> void:
	declined.emit()
