class_name BattleScene
extends Node2D
## 1戦を表示し、クリックを主人公の行動に変える。

const HEX_SIZE := 40.0

## 起動前に入れておくとその戦闘を表示する。入れなければ既定の戦闘を始める。
var battle: Battle
## カード制の手番。null なら行動ポイント制。起動前に入れておくとその戦闘をカード制で表示する。
var card_turn: CardTurn
var selected_card: Card

var _views: Dictionary[Unit, UnitView] = {}

@onready var _board: BoardView = $Board
@onready var _units: Node2D = $Units
@onready var _ap_label: Label = $Hud/ApLabel
@onready var _turn_label: Label = $Hud/TurnLabel
@onready var _result_label: Label = $Hud/ResultLabel
@onready var _end_turn_button: Button = $Hud/EndTurnButton
@onready var _mode_button: Button = $Hud/ModeButton
@onready var _restart_button: Button = $Hud/RestartButton
@onready var _hand: HBoxContainer = $Hud/Hand


## 動作確認用の固定配置の戦闘を作る。
static func create_default_battle() -> Battle:
	var field := Battlefield.hexagon(4)
	for wall in [Vector2i(1, -2), Vector2i(1, 1), Vector2i(-2, 1)]:
		field.set_terrain(wall, Battlefield.Terrain.WALL)
	field.place_unit(Unit.new(Unit.Team.PLAYER, 12, 3), Vector2i(-3, 1))
	for hex in [Vector2i(3, -3), Vector2i(4, -2), Vector2i(2, 2)]:
		field.place_unit(Unit.new(Unit.Team.ENEMY, 5, 2), hex)
	return Battle.new(field)


## 試作用の初期デッキで、戦闘をカード制で進める手番を作る。
static func create_card_turn(p_battle: Battle) -> CardTurn:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return CardTurn.new(p_battle, Deck.new(CardTurn.starter_cards(), rng))


func _ready() -> void:
	if card_turn != null:
		battle = card_turn.battle
	elif battle == null:
		battle = create_default_battle()
	_board.hex_size = HEX_SIZE
	_end_turn_button.pressed.connect(end_turn)
	_mode_button.pressed.connect(toggle_mode)
	_restart_button.pressed.connect(restart)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_board.hovered = Hex.from_pixel(get_global_mouse_position(), HEX_SIZE)
		_board.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_hex(Hex.from_pixel(get_global_mouse_position(), HEX_SIZE))
	elif event.is_action_pressed("ui_accept"):
		end_turn()


## マスを選んだときの操作。行動ポイント制では敵がいれば攻撃し、空いていれば移動する。
## カード制では選んでいるカードをそのマスに使う。
func click_hex(hex: Vector2i) -> void:
	if card_turn != null:
		if selected_card != null and card_turn.play(selected_card, hex):
			selected_card = null
	else:
		var target := battle.field.unit_at(hex)
		if target != null:
			battle.perform(AttackAction.new(battle.player, target))
		else:
			battle.perform(MoveAction.new(battle.player, hex))
	_refresh()


## 手札のカードを選ぶ。選んでいるカードをもう一度選ぶと選択を外す。
func select_card(card: Card) -> void:
	var selectable := card_turn != null and card.cost <= card_turn.energy
	selected_card = card if selectable and selected_card != card else null
	_refresh()


func end_turn() -> void:
	if battle.outcome() == Battle.Outcome.ONGOING:
		selected_card = null
		if card_turn != null:
			card_turn.end_turn()
		else:
			battle.end_turn()
	_refresh()


## いまの方式のまま、既定の戦闘を最初から始める。
func restart() -> void:
	var use_cards := card_turn != null
	battle = create_default_battle()
	card_turn = create_card_turn(battle) if use_cards else null
	selected_card = null
	_refresh()


## 行動ポイント制とカード制を切り替えて、戦闘を最初から始める。
func toggle_mode() -> void:
	card_turn = null if card_turn != null else create_card_turn(battle)
	restart()


## ユニットの表示を返す。戦場にいなければ null。
func view_of(unit: Unit) -> UnitView:
	return _views.get(unit)


func _refresh() -> void:
	_sync_unit_views()
	var ongoing := battle.outcome() == Battle.Outcome.ONGOING
	_board.field = battle.field
	_board.reachable.clear()
	_board.threatened.clear()
	if ongoing:
		_board.reachable = battle.field.reachable(battle.player.position, _move_range())
		_board.threatened = battle.threatened_hexes()
	_board.queue_redraw()
	_refresh_hand(ongoing)
	if card_turn != null:
		_ap_label.text = "マナ: %d / %d (山札 %d / 捨て札 %d)" % [
			card_turn.energy, CardTurn.ENERGY_PER_TURN,
			card_turn.deck.draw_pile.size(), card_turn.deck.discard_pile.size(),
		]
		_mode_button.text = "行動ポイント制に切替"
	else:
		_ap_label.text = "行動ポイント: %d / %d" % [battle.ap, Battle.AP_PER_TURN]
		_mode_button.text = "カード制に切替"
	_turn_label.text = "ターン %d" % battle.turn
	_end_turn_button.disabled = not ongoing
	_result_label.visible = not ongoing
	_result_label.text = "勝利" if battle.outcome() == Battle.Outcome.VICTORY else "敗北"


## いま主人公が歩ける歩数。カード制では選んでいる移動カードの歩数になる。
func _move_range() -> int:
	if card_turn == null:
		return battle.ap
	if selected_card != null and selected_card.kind == Card.Kind.MOVE:
		return selected_card.value
	return 0


func _refresh_hand(ongoing: bool) -> void:
	for button in _hand.get_children():
		_hand.remove_child(button)
		button.queue_free()
	if card_turn == null:
		return
	for card in card_turn.deck.hand:
		var button := Button.new()
		button.text = "%s (%d)\n%s" % [card.title, card.cost, card.description()]
		button.custom_minimum_size = Vector2(110.0, 72.0)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = card == selected_card
		button.disabled = not ongoing or card.cost > card_turn.energy
		button.pressed.connect(select_card.bind(card))
		_hand.add_child(button)


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
