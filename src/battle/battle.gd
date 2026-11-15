class_name Battle
extends RefCounted
## 1戦の進行役。手番・行動ポイント・勝敗を管理し、行動を戦場に適用する。

enum Outcome { ONGOING, VICTORY, DEFEAT }

const AP_PER_TURN := 3

var field: Battlefield
var player: Unit
var acting_unit: Unit
var ap: int
var turn := 1

var _enemy_ai := EnemyAi.new()


func _init(p_field: Battlefield) -> void:
	field = p_field
	for unit in field.units():
		if unit.team == Unit.Team.PLAYER:
			player = unit
	_start_turn_of(player)


## 行動を実行する。実行できなければ何もせず false を返す。
func perform(action: BattleAction) -> bool:
	if outcome() != Outcome.ONGOING or action.actor != acting_unit:
		return false
	if not action.can_perform(self) or action.cost(self) > ap:
		return false
	ap -= action.cost(self)
	action.apply(self)
	_remove_dead_units()
	return true


## 主人公の手番を終える。敵が順に行動し、次のターンの主人公の手番になる。
func end_turn() -> void:
	for enemy in enemies():
		_start_turn_of(enemy)
		while true:
			var action := _enemy_ai.next_action(self, enemy)
			if action == null or not perform(action):
				break
	turn += 1
	_start_turn_of(player)


func enemies() -> Array[Unit]:
	return field.units().filter(func(unit: Unit) -> bool: return unit.team == Unit.Team.ENEMY)


## 主人公がそこでターンを終えると、次の敵ターンに攻撃されうるマスを返す。
func threatened_hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for enemy in enemies():
		for origin in field.reachable(enemy.position, AP_PER_TURN - AttackAction.COST):
			for hex in Hex.neighbors(origin):
				var standable := field.is_walkable(hex) or hex == player.position
				if standable and not result.has(hex):
					result.append(hex)
	return result


func outcome() -> Outcome:
	if not player.is_alive():
		return Outcome.DEFEAT
	if enemies().is_empty():
		return Outcome.VICTORY
	return Outcome.ONGOING


func _start_turn_of(unit: Unit) -> void:
	acting_unit = unit
	ap = AP_PER_TURN


func _remove_dead_units() -> void:
	for unit in field.units():
		if not unit.is_alive():
			field.remove_unit(unit)
