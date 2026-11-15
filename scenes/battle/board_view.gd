class_name BoardView
extends Node2D
## 戦場のマスを描く。移動できるマスと攻撃されうるマスを色で示す。

const FLOOR_COLOR := Color(0.24, 0.27, 0.32)
const WALL_COLOR := Color(0.09, 0.1, 0.12)
const REACHABLE_COLOR := Color(0.25, 0.45, 0.7)
const BORDER_COLOR := Color(0.05, 0.06, 0.08)
const THREAT_COLOR := Color(0.9, 0.3, 0.25)
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.25)

var field: Battlefield
var hex_size := 40.0
var reachable: Dictionary[Vector2i, int] = {}
var threatened: Array[Vector2i] = []
var hovered: Variant = null


func _draw() -> void:
	if field == null:
		return
	for hex in field.cells():
		var color := FLOOR_COLOR
		if field.terrain_at(hex) == Battlefield.Terrain.WALL:
			color = WALL_COLOR
		elif reachable.get(hex, 0) > 0:
			color = REACHABLE_COLOR
		var corners := _corners(hex, hex_size)
		draw_colored_polygon(corners, color)
		draw_polyline(_closed(corners), BORDER_COLOR, 2.0)
	for hex in threatened:
		draw_polyline(_closed(_corners(hex, hex_size * 0.82)), THREAT_COLOR, 2.0)
	if hovered != null and field.has_cell(hovered):
		draw_colored_polygon(_corners(hovered, hex_size), HOVER_COLOR)


func _corners(hex: Vector2i, radius: float) -> PackedVector2Array:
	var center := Hex.to_pixel(hex, hex_size)
	var corners := PackedVector2Array()
	for i in range(6):
		corners.append(center + Vector2.from_angle(deg_to_rad(60.0 * i - 30.0)) * radius)
	return corners


func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var closed := corners.duplicate()
	closed.append(corners[0])
	return closed
