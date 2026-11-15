class_name Card
extends RefCounted
## 手札から使う1枚のカード。使うとマスを対象にした行動になる。

enum Kind { MOVE, ATTACK }

var title: String
var kind: Kind
## 移動なら歩ける歩数、攻撃なら与えるダメージ。
var value: int


func _init(p_title: String, p_kind: Kind, p_value: int) -> void:
	title = p_title
	kind = p_kind
	value = p_value


func description() -> String:
	return "%s %d" % ["移動" if kind == Kind.MOVE else "攻撃", value]


## actor が hex を対象にこのカードを使うときの行動を返す。対象にならなければ null。
func create_action(actor: Unit, field: Battlefield, hex: Vector2i) -> BattleAction:
	if kind == Kind.MOVE:
		return MoveAction.new(actor, hex, value)
	var target := field.unit_at(hex)
	if target == null:
		return null
	return AttackAction.new(actor, target, value)
