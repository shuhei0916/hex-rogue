class_name Run
extends RefCounted
## 1回の挑戦。戦闘と報酬をくり返し、最後の戦闘に勝てばクリア、途中で倒れれば終わり。

enum Phase { BATTLE, REWARD, VICTORY, DEFEAT }

const PLAYER_MAX_HP := 30
const PLAYER_ATTACK := 3
## 戦闘に勝つたびに回復するHP。
const HEAL_AFTER_BATTLE := 5
const REWARD_CHOICE_COUNT := 3

var player: Unit
## いま持っているデッキのカード。
var cards: Array[Card]
## いま何番目の戦闘か（1始まり）。
var stage := 1
var phase := Phase.BATTLE
## いまの戦闘の主人公の手番。
var card_turn: CardTurn
## 報酬として選べるカード。報酬を選ぶ段階でだけ入っている。
var reward_choices: Array[Card] = []

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	player = Unit.new(Unit.Team.PLAYER, PLAYER_MAX_HP, PLAYER_ATTACK)
	cards = CardLibrary.starter_cards()
	_start_battle()


## 決着した戦闘を終える。勝てば報酬（最後の戦闘ならクリア）、負ければランが終わる。
func finish_battle() -> void:
	if phase != Phase.BATTLE:
		return
	match card_turn.battle.outcome():
		Battle.Outcome.DEFEAT:
			phase = Phase.DEFEAT
		Battle.Outcome.VICTORY:
			if stage == Encounter.STAGE_COUNT:
				phase = Phase.VICTORY
			else:
				player.heal(HEAL_AFTER_BATTLE)
				reward_choices = CardLibrary.reward_choices(REWARD_CHOICE_COUNT, _rng)
				phase = Phase.REWARD


## 報酬の候補から1枚をデッキに加えて次の戦闘へ進む。null を渡すと何も加えずに進む。
func choose_reward(card: Card) -> void:
	if phase != Phase.REWARD or (card != null and not reward_choices.has(card)):
		return
	if card != null:
		cards.append(card)
	reward_choices = []
	stage += 1
	_start_battle()


func _start_battle() -> void:
	card_turn = CardTurn.new(Encounter.generate(stage, player, _rng), Deck.new(cards, _rng))
	phase = Phase.BATTLE
