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


func end_turn() -> void:
	turn += 1
	_start_turn_of(player)


func enemies() -> Array[Unit]:
	return field.units().filter(func(unit: Unit) -> bool: return unit.team == Unit.Team.ENEMY)


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
