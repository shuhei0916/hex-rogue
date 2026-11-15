class_name EnemyAi
extends RefCounted
## 敵の行動を決める。主人公に隣接していれば攻撃し、そうでなければ近づく。


## unit が次に取る行動を返す。できることがなければ null。
func next_action(battle: Battle, unit: Unit) -> BattleAction:
	var target := battle.player
	if Hex.distance(unit.position, target.position) == 1:
		return AttackAction.new(unit, target)
	var path := _path_to_adjacent(battle.field, unit.position, target.position)
	if path.is_empty():
		return null
	return MoveAction.new(unit, path[mini(battle.ap, path.size() - 1)])


## target の隣のマスのうち、最も少ない歩数で行けるマスまでの経路を返す。
func _path_to_adjacent(field: Battlefield, from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	for hex in Hex.neighbors(target):
		var path := field.find_path(from, hex)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	return best
