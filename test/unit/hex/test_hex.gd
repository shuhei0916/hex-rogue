extends GutTest

# テストリスト
# [ ] 隣接する6マスを返す
# [ ] 2マス間の距離を返す
# [ ] 半径N以内のマスを返す
# [ ] 2マスを結ぶ直線上のマスを返す
# [ ] ヘックス座標を画面座標に変換する（頂点が上の向き）
# [ ] 画面座標をヘックス座標に変換する


func test_原点に隣接する6マスを返す():
	var neighbors := Hex.neighbors(Vector2i(0, 0))

	assert_eq(neighbors.size(), 6)
	for expected in [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
	]:
		assert_has(neighbors, expected)
