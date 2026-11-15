class_name AttackAction
extends BattleAction
## 隣接する敵対ユニットを殴り、攻撃力ぶんのダメージを与える。

const COST := 2

var target: Unit


func _init(p_actor: Unit, p_target: Unit) -> void:
	actor = p_actor
	target = p_target


func cost(_battle: Battle) -> int:
	return COST


func can_perform(_battle: Battle) -> bool:
	return (
		target.is_alive()
		and target.team != actor.team
		and Hex.distance(actor.position, target.position) == 1
	)


func apply(_battle: Battle) -> void:
	target.take_damage(actor.attack_power)
