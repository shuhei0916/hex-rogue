extends GutTest

const BattleSceneScene := preload("res://scenes/battle/battle_scene.tscn")

var field: Battlefield
var player: Unit
var enemy: Unit
var move_card: Card
var attack_card: Card
var deck: Deck
var scene: BattleScene


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(1, 0))
	move_card = Card.new("歩く", Card.Kind.MOVE, 2)
	attack_card = Card.new("斬る", Card.Kind.ATTACK, 3)
	var cards: Array[Card] = [
		move_card, attack_card,
		Card.new("歩く", Card.Kind.MOVE, 2), Card.new("斬る", Card.Kind.ATTACK, 3),
	]
	deck = Deck.new(cards, RandomNumberGenerator.new())
	scene = BattleSceneScene.instantiate()
	scene.card_turn = CardTurn.new(Battle.new(field), deck)
	add_child_autofree(scene)


func _hand() -> Node:
	return scene.get_node("Hud/Hand")


func test_手札の枚数ぶんカードが並ぶ():
	assert_eq(_hand().get_child_count(), 4)


func test_カードには名前と効果が書かれる():
	var texts := _hand().get_children().map(func(button: Button) -> String: return button.text)

	assert_has(texts, "歩く\n移動 2")
	assert_has(texts, "斬る\n攻撃 3")


func test_カードを選ぶ前は移動できるマスを示さない():
	assert_does_not_have(scene.get_node("Board").reachable, Vector2i(0, 1))


func test_移動カードを選ぶとその歩数で行けるマスを示す():
	scene.select_card(move_card)

	var reachable: Dictionary = scene.get_node("Board").reachable
	assert_has(reachable, Vector2i(0, 2))
	assert_does_not_have(reachable, Vector2i(0, 3))


func test_移動カードを選んでマスをクリックすると移動する():
	scene.select_card(move_card)

	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 2))
	assert_eq(_hand().get_child_count(), 3)


func test_攻撃カードを選んで敵をクリックすると攻撃する():
	scene.select_card(attack_card)

	scene.click_hex(Vector2i(1, 0))

	assert_eq(enemy.hp, 2)


func test_カードを選ばずにクリックしても何も起きない():
	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 0))
	assert_eq(_hand().get_child_count(), 4)


func test_カードを使うと選択が外れる():
	scene.select_card(move_card)

	scene.click_hex(Vector2i(0, 2))

	assert_null(scene.selected_card)


func test_選んだカードをもう一度選ぶと選択が外れる():
	scene.select_card(move_card)

	scene.select_card(move_card)

	assert_null(scene.selected_card)


func test_残りの使える枚数を表示する():
	scene.select_card(move_card)
	scene.click_hex(Vector2i(0, 2))

	assert_string_contains(scene.get_node("Hud/ApLabel").text, "あと 1 枚")


func test_ターン終了で手札を引き直す():
	scene.select_card(move_card)
	scene.click_hex(Vector2i(0, 2))

	scene.get_node("Hud/EndTurnButton").pressed.emit()

	assert_eq(_hand().get_child_count(), 4)
	assert_eq(scene.battle.turn, 2)
