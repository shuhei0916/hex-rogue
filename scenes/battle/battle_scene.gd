class_name BattleScene
extends Node2D
## 1戦を表示し、クリックを主人公の行動に変える。

## 行動のアニメーションをすべて再生し終えた。
signal animations_finished

const HEX_SIZE := 40.0
## 1マス歩くのにかける秒数。
const STEP_TIME := 0.12

## 起動前に入れておくとその戦闘を表示する。入れなければ既定の戦闘を始める。
var battle: Battle
## カード制の手番。null なら行動ポイント制。起動前に入れておくとその戦闘をカード制で表示する。
var card_turn: CardTurn
var selected_card: Card
## false にすると行動の結果をアニメーションなしですぐ表示する。
var animations_enabled := true
## アニメーションの再生中。このあいだは操作を受け付けない。
var is_animating := false

var _animations: Array[Callable] = []
var _views: Dictionary[Unit, UnitView] = {}

@onready var _board: BoardView = $Board
@onready var _units: Node2D = $Units
@onready var _effects: Node2D = $Effects
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
		card_turn = create_card_turn(battle)
	_board.hex_size = HEX_SIZE
	_end_turn_button.pressed.connect(end_turn)
	_mode_button.pressed.connect(toggle_mode)
	_restart_button.pressed.connect(restart)
	_connect_battle()
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
	if is_animating:
		return
	if card_turn != null:
		if selected_card != null and card_turn.play(selected_card, hex):
			selected_card = null
	else:
		var target := battle.field.unit_at(hex)
		if target != null:
			battle.perform(AttackAction.new(battle.player, target))
		else:
			battle.perform(MoveAction.new(battle.player, hex))
	_show_result()


## 手札のカードを選ぶ。選んでいるカードをもう一度選ぶと選択を外す。
## マスを選ぶ必要のないカードは、選んだ時点で使う。
func select_card(card: Card) -> void:
	if is_animating:
		return
	if card_turn != null and not card.needs_target():
		selected_card = null
		card_turn.play(card, battle.player.position)
		_show_result()
		return
	var selectable := card_turn != null and card.cost <= card_turn.energy
	selected_card = card if selectable and selected_card != card else null
	_refresh()


func end_turn() -> void:
	if is_animating:
		return
	if battle.outcome() == Battle.Outcome.ONGOING:
		selected_card = null
		if card_turn != null:
			card_turn.end_turn()
		else:
			battle.end_turn()
	_show_result()


## いまの方式のまま、既定の戦闘を最初から始める。
func restart() -> void:
	if is_animating:
		return
	var use_cards := card_turn != null
	battle = create_default_battle()
	card_turn = create_card_turn(battle) if use_cards else null
	selected_card = null
	_connect_battle()
	_refresh()


## 行動ポイント制とカード制を切り替えて、戦闘を最初から始める。
func toggle_mode() -> void:
	if is_animating:
		return
	card_turn = null if card_turn != null else create_card_turn(battle)
	restart()


## ユニットの表示を返す。戦場にいなければ null。
func view_of(unit: Unit) -> UnitView:
	return _views.get(unit)


func _connect_battle() -> void:
	battle.unit_moved.connect(_on_unit_moved)
	battle.unit_attacked.connect(_on_unit_attacked)
	battle.unit_died.connect(_on_unit_died)


func _on_unit_moved(unit: Unit, path: Array[Vector2i]) -> void:
	_animations.append(_animate_move.bind(_views[unit], path))


func _on_unit_attacked(
	attacker: Unit, target: Unit, damage: int, hp_after: int, block_after: int
) -> void:
	_animations.append(
		_animate_attack.bind(_views[attacker], _views[target], damage, hp_after, block_after)
	)


func _on_unit_died(unit: Unit) -> void:
	_animations.append(_animate_death.bind(_views[unit]))


## 行動の結果を画面に出す。起きた出来事があれば順にアニメーションしてから反映する。
func _show_result() -> void:
	if not animations_enabled or _animations.is_empty():
		_animations.clear()
		_refresh()
		return
	is_animating = true
	_board.reachable.clear()
	_board.queue_redraw()
	_refresh_hand(false)
	for button: Button in [_end_turn_button, _mode_button, _restart_button]:
		button.disabled = true
	while not _animations.is_empty():
		await _animations.pop_front().call()
	is_animating = false
	_refresh()
	animations_finished.emit()


func _animate_move(view: UnitView, path: Array[Vector2i]) -> void:
	var tween := create_tween()
	for hex in path.slice(1):
		tween.tween_property(view, "position", Hex.to_pixel(hex, HEX_SIZE), STEP_TIME)
	await tween.finished


## 相手に向かって踏み込み、当たった瞬間にHPの表示を減らして元の位置に戻る。
func _animate_attack(
	attacker: UnitView, target: UnitView, damage: int, hp_after: int, block_after: int
) -> void:
	var origin := attacker.position
	var lunge := create_tween()
	lunge.tween_property(attacker, "position", origin.lerp(target.position, 0.4), 0.08)
	await lunge.finished
	target.show_hp(hp_after)
	target.show_block(block_after)
	_spawn_damage_number(target.position, damage)
	target.modulate = Color(2.5, 2.5, 2.5)
	var recover := create_tween().set_parallel()
	recover.tween_property(attacker, "position", origin, 0.14)
	recover.tween_property(target, "modulate", Color.WHITE, 0.25)
	await recover.finished


func _animate_death(view: UnitView) -> void:
	var tween := create_tween()
	tween.tween_property(view, "modulate:a", 0.0, 0.25)
	await tween.finished


## ダメージの数字を出す。浮かび上がりながら消える。ブロックで防ぎきったら「防御」と出す。
func _spawn_damage_number(at: Vector2, damage: int) -> void:
	var label := Label.new()
	label.text = "-%d" % damage if damage > 0 else "防御"
	label.position = at + Vector2(-12.0, -52.0)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_effects.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


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
	_mode_button.disabled = false
	_restart_button.disabled = false
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
