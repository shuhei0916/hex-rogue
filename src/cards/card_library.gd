class_name CardLibrary
## ゲームに登場するカードの一覧。呼ぶたびに新しいカードを作って返す。


## ランの開始時に持っているデッキ。
static func starter_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for i in range(4):
		cards.append(Card.new("歩く", Card.Kind.MOVE, 2))
	for i in range(3):
		cards.append(Card.new("斬る", Card.Kind.ATTACK, 3))
		cards.append(Card.new("守る", Card.Kind.BLOCK, 4))
	cards.append(Card.new("走る", Card.Kind.MOVE, 4, 2))
	cards.append(Card.new("強打", Card.Kind.ATTACK, 6, 2))
	return cards


## 戦闘の報酬として出るカードの全種類。
static func reward_pool() -> Array[Card]:
	return [
		Card.new("速歩", Card.Kind.MOVE, 3),
		Card.new("疾走", Card.Kind.MOVE, 5, 2),
		Card.new("鋭い一撃", Card.Kind.ATTACK, 4),
		Card.new("両断", Card.Kind.ATTACK, 7, 2),
		Card.new("渾身", Card.Kind.ATTACK, 10, 3),
		Card.new("構える", Card.Kind.BLOCK, 6),
		Card.new("鉄壁", Card.Kind.BLOCK, 10, 2),
	]


## 報酬の候補を、種類が重ならないように count 枚選ぶ。
static func reward_choices(count: int, rng: RandomNumberGenerator) -> Array[Card]:
	var pool := reward_pool()
	Shuffle.in_place(pool, rng)
	return pool.slice(0, count)
