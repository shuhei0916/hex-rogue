class_name Unit
extends RefCounted
## 戦場に立つ1体のユニット。

enum Team { PLAYER, ENEMY }

var team: Team
var max_hp: int
var hp: int
var attack_power: int
var position: Vector2i


func _init(p_team: Team, p_max_hp: int, p_attack_power: int) -> void:
	team = p_team
	max_hp = p_max_hp
	hp = p_max_hp
	attack_power = p_attack_power


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)


func is_alive() -> bool:
	return hp > 0
