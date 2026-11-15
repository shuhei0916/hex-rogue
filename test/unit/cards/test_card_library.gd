extends GutTest


func _kinds(cards: Array[Card]) -> Array:
	return cards.map(func(card: Card) -> Card.Kind: return card.kind)


func test_初期デッキは移動と攻撃と防御を含む():
	var kinds := _kinds(CardLibrary.starter_cards())

	assert_has(kinds, Card.Kind.MOVE)
	assert_has(kinds, Card.Kind.ATTACK)
	assert_has(kinds, Card.Kind.BLOCK)


func test_初期デッキは呼ぶたびに別のカードで作られる():
	assert_ne(CardLibrary.starter_cards()[0], CardLibrary.starter_cards()[0])


func test_報酬の候補は指定した枚数で名前が重ならない():
	var rng := RandomNumberGenerator.new()
	rng.seed = 3

	var choices := CardLibrary.reward_choices(3, rng)

	var titles := choices.map(func(card: Card) -> String: return card.title)
	assert_eq(choices.size(), 3)
	assert_ne(titles[0], titles[1])
	assert_ne(titles[1], titles[2])
	assert_ne(titles[0], titles[2])


func test_報酬の候補は同じシードなら同じになる():
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 7
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 7

	var titles_a := CardLibrary.reward_choices(3, rng_a).map(func(card: Card) -> String: return card.title)
	var titles_b := CardLibrary.reward_choices(3, rng_b).map(func(card: Card) -> String: return card.title)

	assert_eq(titles_a, titles_b)
