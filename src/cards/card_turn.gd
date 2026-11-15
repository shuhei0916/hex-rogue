class_name CardTurn
extends RefCounted
## 主人公の手番をカードで行う方式。毎ターン手札を引き、マナを払ってカードを使う。

const HAND_SIZE := 5
const ENERGY_PER_TURN := 3

var battle: Battle
var deck: Deck
var energy: int


## 試作用の初期デッキ。
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


func _init(p_battle: Battle, p_deck: Deck) -> void:
	battle = p_battle
	deck = p_deck
	_start_turn()


## 手札のカードを hex を対象に使う。使えなければ何もせず false を返す。
func play(card: Card, hex: Vector2i) -> bool:
	if card.cost > energy or not deck.hand.has(card):
		return false
	if not battle.execute(card.create_action(battle.player, battle.field, hex)):
		return false
	deck.discard(card)
	energy -= card.cost
	return true


func end_turn() -> void:
	deck.discard_hand()
	battle.end_turn()
	_start_turn()


func _start_turn() -> void:
	deck.draw(HAND_SIZE)
	energy = ENERGY_PER_TURN
