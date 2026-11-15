extends GutTest

var run: Run


func before_each():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	run = Run.new(rng)


## いまの戦闘の敵をすべて取り除いて、勝った状態にする。
func _win_battle() -> void:
	var battle := run.card_turn.battle
	for enemy in battle.enemies():
		battle.field.remove_unit(enemy)
	run.finish_battle()


func _win_and_skip_until(stage: int) -> void:
	while run.stage < stage:
		_win_battle()
		run.choose_reward(null)


func test_開始時は最初の戦闘中():
	assert_eq(run.stage, 1)
	assert_eq(run.phase, Run.Phase.BATTLE)
	assert_eq(run.card_turn.battle.outcome(), Battle.Outcome.ONGOING)
	assert_eq(run.card_turn.battle.player, run.player)


func test_開始時のデッキは初期デッキ():
	assert_eq(run.cards.size(), CardLibrary.starter_cards().size())


func test_決着していない戦闘は終えられない():
	run.finish_battle()

	assert_eq(run.phase, Run.Phase.BATTLE)


func test_戦闘に勝つと報酬の候補が3枚出る():
	_win_battle()

	assert_eq(run.phase, Run.Phase.REWARD)
	assert_eq(run.reward_choices.size(), 3)


func test_報酬を選ぶとデッキに加わって次の戦闘が始まる():
	_win_battle()
	var chosen := run.reward_choices[1]
	var size_before := run.cards.size()
	var old_card_turn := run.card_turn

	run.choose_reward(chosen)

	assert_has(run.cards, chosen)
	assert_eq(run.cards.size(), size_before + 1)
	assert_eq(run.stage, 2)
	assert_eq(run.phase, Run.Phase.BATTLE)
	assert_ne(run.card_turn, old_card_turn)
	assert_eq(run.card_turn.battle.outcome(), Battle.Outcome.ONGOING)


func test_加えたカードは次の戦闘の山札と手札のどこかにある():
	_win_battle()
	var chosen := run.reward_choices[0]

	run.choose_reward(chosen)

	var deck := run.card_turn.deck
	assert_has(deck.hand + deck.draw_pile, chosen)


func test_報酬を見送るとデッキは増えずに次の戦闘が始まる():
	_win_battle()
	var size_before := run.cards.size()

	run.choose_reward(null)

	assert_eq(run.cards.size(), size_before)
	assert_eq(run.stage, 2)


func test_候補にないカードは報酬として選べない():
	_win_battle()

	run.choose_reward(Card.new("偽物", Card.Kind.ATTACK, 99))

	assert_eq(run.phase, Run.Phase.REWARD)
	assert_eq(run.stage, 1)


func test_戦闘中は報酬を選べない():
	run.choose_reward(null)

	assert_eq(run.stage, 1)


func test_HPは次の戦闘に持ち越し勝つたびに少し回復する():
	run.player.take_damage(12)

	_win_battle()
	run.choose_reward(null)

	assert_eq(run.player.hp, Run.PLAYER_MAX_HP - 12 + Run.HEAL_AFTER_BATTLE)


func test_回復で最大HPは超えない():
	run.player.take_damage(2)

	_win_battle()

	assert_eq(run.player.hp, Run.PLAYER_MAX_HP)


func test_ブロックは次の戦闘に持ち越さない():
	run.player.gain_block(5)

	_win_battle()
	run.choose_reward(null)

	assert_eq(run.player.block, 0)


func test_最後の戦闘に勝つとラン勝利():
	_win_and_skip_until(Encounter.STAGE_COUNT)

	_win_battle()

	assert_eq(run.phase, Run.Phase.VICTORY)


func test_戦闘に負けるとラン敗北():
	run.player.take_damage(999)

	run.finish_battle()

	assert_eq(run.phase, Run.Phase.DEFEAT)
