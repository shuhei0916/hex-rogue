extends SceneTree
# 指定したシーンを起動し、画面を PNG に保存して終了する。
# 直接は呼ばず、tools/screenshot.ps1 から使う（ウィンドウを前面に出さずに起動するため）。
#
# 引数（`--` より後ろ）:
#   --out=<保存先 PNG>        省略時は user://screenshot.png
#   --scene=<res:// のシーン>  省略時はプロジェクトのメインシーン
#   --wait=<待つ秒数>          省略時は 0.5。アニメーションが落ち着くまでの待ち時間
#   --setup=<res:// のスクリプト>  省略可。`static func setup(scene: Node) -> void` を持つスクリプト。
#                               撮りたい場面を作るために、シーン追加後に呼ばれる（await 可）


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var scene_path: String = options.get(
		"scene", ProjectSettings.get_setting("application/run/main_scene")
	)
	var out_path: String = options.get("out", "user://screenshot.png")
	var wait_seconds := float(options.get("wait", "0.5"))

	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("シーンを読み込めません: %s" % scene_path)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene

	if options.has("setup"):
		var setup_script := load(options["setup"]) as GDScript
		if setup_script == null:
			_fail("setup スクリプトを読み込めません: %s" % options["setup"])
			return
		await setup_script.setup(scene)

	await create_timer(wait_seconds).timeout
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	var error := image.save_png(out_path)
	if error != OK:
		_fail("保存に失敗しました (%s): %s" % [error_string(error), out_path])
		return
	print("SCREENSHOT_SAVED %s %dx%d" % [out_path, image.get_width(), image.get_height()])
	quit(0)


func _parse_options(args: PackedStringArray) -> Dictionary:
	var options := {}
	for arg in args:
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var separator := arg.find("=")
		options[arg.substr(2, separator - 2)] = arg.substr(separator + 1)
	return options


func _fail(message: String) -> void:
	push_error(message)
	printerr("SCREENSHOT_FAILED " + message)
	quit(1)
