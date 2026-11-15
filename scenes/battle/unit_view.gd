class_name UnitView
extends Node2D
## ユニット1体の仮表示。陣営の色の丸と残りHPを描く。

const PLAYER_COLOR := Color(0.35, 0.75, 0.95)
const ENEMY_COLOR := Color(0.9, 0.4, 0.35)
const RADIUS := 22.0

var unit: Unit

var _hp_label := Label.new()


func _init() -> void:
	_hp_label.name = "HpLabel"
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.size = Vector2(RADIUS, RADIUS) * 2.0
	_hp_label.position = -Vector2(RADIUS, RADIUS)
	_hp_label.add_theme_color_override("font_color", Color.BLACK)
	_hp_label.add_theme_font_size_override("font_size", 20)
	add_child(_hp_label)


## ユニットの現在の位置とHPを表示に反映する。
func refresh(hex_size: float) -> void:
	position = Hex.to_pixel(unit.position, hex_size)
	modulate = Color.WHITE
	show_hp(unit.hp)
	queue_redraw()


func show_hp(hp: int) -> void:
	_hp_label.text = str(hp)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, PLAYER_COLOR if unit.team == Unit.Team.PLAYER else ENEMY_COLOR)
