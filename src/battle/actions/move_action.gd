class_name MoveAction
extends BattleAction
## 目的地まで歩く。1マスにつき行動ポイントを1使う。

var destination: Vector2i


func _init(p_actor: Unit, p_destination: Vector2i) -> void:
	actor = p_actor
	destination = p_destination


func cost(battle: Battle) -> int:
	return maxi(battle.field.find_path(actor.position, destination).size() - 1, 0)


func can_perform(battle: Battle) -> bool:
	return cost(battle) > 0


func apply(battle: Battle) -> void:
	battle.field.place_unit(actor, destination)
