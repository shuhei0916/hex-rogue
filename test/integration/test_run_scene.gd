extends GutTest

const RunSceneScene := preload("res://scenes/run/run_scene.tscn")

var run: Run
var scene: RunScene


func before_each():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	run = Run.new(rng)
	scene = RunSceneScene.instantiate()
	scene.run = run
	scene.animations_enabled = false
	add_child_autofree(scene)


## いまの戦闘の敵をすべて取り除いて、画面に反映する。
func _win_battle() -> void:
	var battle := scene.run.card_turn.battle
	for enemy in battle.enemies():
		battle.field.remove_unit(enemy)
	scene.battle_scene.refresh()


func _reward_buttons() -> Array[Node]:
	return scene.get_node("Ui/RewardPanel/Box/Choices").get_children()


func test_起動すると最初の戦闘の画面が出る():
	assert_eq(scene.battle_scene.card_turn, run.card_turn)
	assert_eq(scene.get_node("BattleHolder").get_child_count(), 1)
	assert_eq(scene.get_node("Ui/StageLabel").text, "戦闘 1 / 5")
	assert_false(scene.get_node("Ui/RewardPanel").visible)
	assert_false(scene.get_node("Ui/EndPanel").visible)


func test_ランを渡さずに起動すると新しいランを始める():
	var fresh: RunScene = RunSceneScene.instantiate()
	add_child_autofree(fresh)

	assert_not_null(fresh.run)
	assert_eq(fresh.run.stage, 1)
	assert_not_null(fresh.battle_scene)


func test_戦闘に勝つと報酬の候補が名前と効果つきで並ぶ():
	_win_battle()

	assert_true(scene.get_node("Ui/RewardPanel").visible)
	var buttons := _reward_buttons()
	assert_eq(buttons.size(), 3)
	var first := run.reward_choices[0]
	assert_eq(buttons[0].text, "%s (%d)\n%s" % [first.title, first.cost, first.description()])


func test_報酬のカードを押すとデッキに加わって次の戦闘の画面になる():
	_win_battle()
	var chosen := run.reward_choices[2]

	_reward_buttons()[2].pressed.emit()

	assert_has(run.cards, chosen)
	assert_eq(run.stage, 2)
	assert_eq(scene.battle_scene.card_turn, run.card_turn)
	assert_eq(scene.get_node("BattleHolder").get_child_count(), 1)
	assert_eq(scene.get_node("Ui/StageLabel").text, "戦闘 2 / 5")
	assert_false(scene.get_node("Ui/RewardPanel").visible)


func test_見送るボタンを押すとカードを加えずに次の戦闘へ進む():
	_win_battle()
	var size_before := run.cards.size()

	scene.get_node("Ui/RewardPanel/Box/SkipButton").pressed.emit()

	assert_eq(run.cards.size(), size_before)
	assert_eq(run.stage, 2)
	assert_false(scene.get_node("Ui/RewardPanel").visible)


func test_2回目の報酬では前回の候補が残らない():
	_win_battle()
	scene.get_node("Ui/RewardPanel/Box/SkipButton").pressed.emit()

	_win_battle()

	assert_eq(_reward_buttons().size(), 3)


func test_戦闘に負けると敗北を表示する():
	run.player.take_damage(999)

	scene.battle_scene.refresh()

	assert_true(scene.get_node("Ui/EndPanel").visible)
	assert_eq(scene.get_node("Ui/EndPanel/Box/EndLabel").text, "敗北")


func test_最後の戦闘に勝つとクリアを表示する():
	for i in range(Encounter.STAGE_COUNT - 1):
		_win_battle()
		scene.get_node("Ui/RewardPanel/Box/SkipButton").pressed.emit()

	_win_battle()

	assert_true(scene.get_node("Ui/EndPanel").visible)
	assert_eq(scene.get_node("Ui/EndPanel/Box/EndLabel").text, "クリア！")
	assert_false(scene.get_node("Ui/RewardPanel").visible)


func test_終了後にもう一度ボタンを押すと新しいランが始まる():
	run.player.take_damage(999)
	scene.battle_scene.refresh()

	scene.get_node("Ui/EndPanel/Box/RestartButton").pressed.emit()

	assert_ne(scene.run, run)
	assert_eq(scene.run.stage, 1)
	assert_eq(scene.battle_scene.card_turn, scene.run.card_turn)
	assert_eq(scene.get_node("BattleHolder").get_child_count(), 1)
	assert_false(scene.get_node("Ui/EndPanel").visible)


func test_途中でも最初からボタンで新しいランを始められる():
	_win_battle()

	scene.get_node("Ui/NewRunButton").pressed.emit()

	assert_ne(scene.run, run)
	assert_eq(scene.get_node("Ui/StageLabel").text, "戦闘 1 / 5")
	assert_false(scene.get_node("Ui/RewardPanel").visible)


func test_主人公のHPとデッキの枚数を表示する():
	assert_eq(scene.get_node("Ui/StatusLabel").text, "HP 30 / 30　デッキ 12 枚")
