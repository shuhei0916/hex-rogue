class_name CardTurn
extends RefCounted
## 主人公の手番をカードで行う方式。毎ターン手札を引き、決まった枚数まで使える。

const HAND_SIZE := 4
const PLAYS_PER_TURN := 2

var battle: Battle
var deck: Deck
var plays_left: int


## 試作用の初期デッキ。
static func starter_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for i in range(3):
		cards.append(Card.new("歩く", Card.Kind.MOVE, 2))
		cards.append(Card.new("斬る", Card.Kind.ATTACK, 3))
	for i in range(2):
		cards.append(Card.new("走る", Card.Kind.MOVE, 4))
	cards.append(Card.new("強打", Card.Kind.ATTACK, 5))
	return cards


func _init(p_battle: Battle, p_deck: Deck) -> void:
	battle = p_battle
	deck = p_deck
	_start_turn()


## 手札のカードを hex を対象に使う。使えなければ何もせず false を返す。
func play(card: Card, hex: Vector2i) -> bool:
	if plays_left <= 0 or not deck.hand.has(card):
		return false
	if not battle.execute(card.create_action(battle.player, battle.field, hex)):
		return false
	deck.discard(card)
	plays_left -= 1
	return true


func end_turn() -> void:
	deck.discard_hand()
	battle.end_turn()
	_start_turn()


func _start_turn() -> void:
	deck.draw(HAND_SIZE)
	plays_left = PLAYS_PER_TURN
