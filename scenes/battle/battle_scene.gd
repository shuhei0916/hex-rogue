class_name BattleScene
extends Node2D
## 1戦を表示し、クリックを主人公の行動に変える。

const HEX_SIZE := 40.0

## 起動前に入れておくとその戦闘を表示する。入れなければ既定の戦闘を始める。
var battle: Battle

var _views: Dictionary[Unit, UnitView] = {}

@onready var _board: BoardView = $Board
@onready var _units: Node2D = $Units
@onready var _ap_label: Label = $Hud/ApLabel
@onready var _turn_label: Label = $Hud/TurnLabel
@onready var _result_label: Label = $Hud/ResultLabel
@onready var _end_turn_button: Button = $Hud/EndTurnButton


## 動作確認用の固定配置の戦闘を作る。
static func create_default_battle() -> Battle:
	var field := Battlefield.hexagon(4)
	for wall in [Vector2i(1, -2), Vector2i(1, 1), Vector2i(-2, 1)]:
		field.set_terrain(wall, Battlefield.Terrain.WALL)
	field.place_unit(Unit.new(Unit.Team.PLAYER, 12, 3), Vector2i(-3, 1))
	for hex in [Vector2i(3, -3), Vector2i(4, -2), Vector2i(2, 2)]:
		field.place_unit(Unit.new(Unit.Team.ENEMY, 5, 2), hex)
	return Battle.new(field)


func _ready() -> void:
	if battle == null:
		battle = create_default_battle()
	_board.field = battle.field
	_board.hex_size = HEX_SIZE
	_end_turn_button.pressed.connect(end_turn)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_board.hovered = Hex.from_pixel(get_global_mouse_position(), HEX_SIZE)
		_board.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_hex(Hex.from_pixel(get_global_mouse_position(), HEX_SIZE))
	elif event.is_action_pressed("ui_accept"):
		end_turn()


## マスを選んだときの操作。敵がいれば攻撃し、空いていれば移動する。
func click_hex(hex: Vector2i) -> void:
	var target := battle.field.unit_at(hex)
	if target != null:
		battle.perform(AttackAction.new(battle.player, target))
	else:
		battle.perform(MoveAction.new(battle.player, hex))
	_refresh()


func end_turn() -> void:
	if battle.outcome() == Battle.Outcome.ONGOING:
		battle.end_turn()
	_refresh()


## ユニットの表示を返す。戦場にいなければ null。
func view_of(unit: Unit) -> UnitView:
	return _views.get(unit)


func _refresh() -> void:
	_sync_unit_views()
	var ongoing := battle.outcome() == Battle.Outcome.ONGOING
	_board.reachable.clear()
	_board.threatened.clear()
	if ongoing:
		_board.reachable = battle.field.reachable(battle.player.position, battle.ap)
		_board.threatened = battle.threatened_hexes()
	_board.queue_redraw()
	_ap_label.text = "行動ポイント: %d / %d" % [battle.ap, Battle.AP_PER_TURN]
	_turn_label.text = "ターン %d" % battle.turn
	_end_turn_button.disabled = not ongoing
	_result_label.visible = not ongoing
	_result_label.text = "勝利" if battle.outcome() == Battle.Outcome.VICTORY else "敗北"


func _sync_unit_views() -> void:
	var alive := battle.field.units()
	for unit in _views.keys():
		if not alive.has(unit):
			_views[unit].free()
			_views.erase(unit)
	for unit in alive:
		if not _views.has(unit):
			var view := UnitView.new()
			view.unit = unit
			_units.add_child(view)
			_views[unit] = view
		_views[unit].refresh(HEX_SIZE)
