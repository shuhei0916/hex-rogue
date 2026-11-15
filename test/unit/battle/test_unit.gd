extends GutTest


func test_生成直後は最大HPで生きている():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)

	assert_eq(unit.hp, 10)
	assert_true(unit.is_alive())


func test_ダメージを受けるとHPが減る():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)

	unit.take_damage(4)

	assert_eq(unit.hp, 6)


func test_HPが0になると死亡する():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)

	unit.take_damage(10)

	assert_false(unit.is_alive())


func test_HPは0より小さくならない():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)

	unit.take_damage(25)

	assert_eq(unit.hp, 0)
