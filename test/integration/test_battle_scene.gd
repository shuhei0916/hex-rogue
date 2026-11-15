extends GutTest

const BattleSceneScene := preload("res://scenes/battle/battle_scene.tscn")

var field: Battlefield
var player: Unit
var enemy: Unit
var scene: BattleScene


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(3, 0))
	scene = BattleSceneScene.instantiate()
	scene.battle = Battle.new(field)
	scene.animations_enabled = false
	add_child_autofree(scene)


func test_ユニットごとに表示が作られマスの位置に置かれる():
	assert_eq(scene.get_node("Units").get_child_count(), 2)
	assert_eq(scene.view_of(enemy).position, Hex.to_pixel(Vector2i(3, 0), BattleScene.HEX_SIZE))


func test_戦闘を渡さずに起動すると既定の戦闘が始まる():
	var default_scene: BattleScene = BattleSceneScene.instantiate()
	add_child_autofree(default_scene)

	assert_not_null(default_scene.battle)
	assert_not_null(default_scene.card_turn)
	assert_eq(default_scene.battle.outcome(), Battle.Outcome.ONGOING)
	assert_gt(default_scene.get_node("Units").get_child_count(), 1)


func test_移動できるマスをクリックすると主人公が動く():
	scene.click_hex(Vector2i(2, 0))

	assert_eq(player.position, Vector2i(2, 0))
	assert_eq(scene.view_of(player).position, Hex.to_pixel(Vector2i(2, 0), BattleScene.HEX_SIZE))


func test_隣接する敵をクリックすると攻撃する():
	field.place_unit(enemy, Vector2i(1, 0))

	scene.click_hex(Vector2i(1, 0))

	assert_eq(enemy.hp, 2)
	assert_eq(scene.view_of(enemy).get_node("HpLabel").text, "2")


func test_倒した敵の表示は消える():
	enemy.take_damage(3)
	field.place_unit(enemy, Vector2i(1, 0))

	scene.click_hex(Vector2i(1, 0))

	assert_null(scene.view_of(enemy))


func test_行動ポイントの残りを表示する():
	scene.click_hex(Vector2i(1, 0))

	assert_string_contains(scene.get_node("Hud/ApLabel").text, "2")


func test_ターン終了ボタンを押すと敵が動く():
	scene.get_node("Hud/EndTurnButton").pressed.emit()

	assert_ne(enemy.position, Vector2i(3, 0))
	assert_eq(scene.view_of(enemy).position, Hex.to_pixel(enemy.position, BattleScene.HEX_SIZE))
	assert_eq(scene.battle.turn, 2)


func test_戦闘中は結果を表示しない():
	assert_false(scene.get_node("Hud/ResultLabel").visible)


func test_勝利すると結果を表示する():
	enemy.take_damage(3)
	field.place_unit(enemy, Vector2i(1, 0))

	scene.click_hex(Vector2i(1, 0))

	assert_true(scene.get_node("Hud/ResultLabel").visible)


func test_盤面に移動できるマスと攻撃されうるマスを渡す():
	var board: BoardView = scene.get_node("Board")

	assert_has(board.reachable, Vector2i(3, -1))
	assert_does_not_have(board.reachable, Vector2i(4, 0))
	assert_has(board.threatened, Vector2i(2, 0))


func test_行動ポイント制では手札を表示しない():
	assert_eq(scene.get_node("Hud/Hand").get_child_count(), 0)


func test_方式切替ボタンを押すとカード制で新しい戦闘が始まる():
	var old_battle := scene.battle

	scene.get_node("Hud/ModeButton").pressed.emit()

	assert_ne(scene.battle, old_battle)
	assert_not_null(scene.card_turn)
	assert_eq(scene.get_node("Hud/Hand").get_child_count(), CardTurn.HAND_SIZE)


func test_方式切替ボタンを2回押すと行動ポイント制に戻る():
	scene.get_node("Hud/ModeButton").pressed.emit()
	scene.get_node("Hud/ModeButton").pressed.emit()

	assert_null(scene.card_turn)
	assert_eq(scene.get_node("Hud/Hand").get_child_count(), 0)


func test_やり直しボタンを押すと新しい戦闘が始まる():
	scene.click_hex(Vector2i(1, 0))
	scene.get_node("Hud/EndTurnButton").pressed.emit()
	var old_battle := scene.battle

	scene.get_node("Hud/RestartButton").pressed.emit()

	assert_ne(scene.battle, old_battle)
	assert_eq(scene.battle.turn, 1)
	assert_null(scene.view_of(player))
	assert_eq(scene.get_node("Units").get_child_count(), scene.battle.field.units().size())
