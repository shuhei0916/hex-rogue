class_name RunScene
extends Node
## 1ランを通して表示する。戦闘の画面を戦闘ごとに差し替え、合間に報酬の選択と結果を出す。

const BattleSceneScene := preload("res://scenes/battle/battle_scene.tscn")

## 表示するラン。シーンツリーに入れる前に入れておく。入れなければ新しいランを始める。
var run: Run
## いま表示している戦闘の画面。
var battle_scene: BattleScene
## false にすると戦闘の行動をアニメーションなしですぐ表示する。
var animations_enabled := true

@onready var _battle_holder: Node = $BattleHolder
@onready var _stage_label: Label = $Ui/StageLabel
@onready var _status_label: Label = $Ui/StatusLabel
@onready var _new_run_button: Button = $Ui/NewRunButton
@onready var _reward_panel: Control = $Ui/RewardPanel
@onready var _reward_choices: HBoxContainer = $Ui/RewardPanel/Box/Choices
@onready var _skip_button: Button = $Ui/RewardPanel/Box/SkipButton
@onready var _end_panel: Control = $Ui/EndPanel
@onready var _end_label: Label = $Ui/EndPanel/Box/EndLabel
@onready var _restart_button: Button = $Ui/EndPanel/Box/RestartButton


func _ready() -> void:
	_new_run_button.pressed.connect(start_new_run)
	_restart_button.pressed.connect(start_new_run)
	_skip_button.pressed.connect(choose_reward.bind(null))
	if run == null:
		run = _create_run()
	_open_battle()
	_refresh()


## いまのランを捨てて、新しいランを最初の戦闘から始める。
func start_new_run() -> void:
	run = _create_run()
	_open_battle()
	_refresh()


## 報酬のカードをデッキに加えて次の戦闘へ進む。null なら何も加えずに進む。
func choose_reward(card: Card) -> void:
	run.choose_reward(card)
	if run.phase == Run.Phase.BATTLE:
		_open_battle()
	_refresh()


func _create_run() -> Run:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return Run.new(rng)


## いまの戦闘の画面を、ランの現在の戦闘のものに差し替える。
func _open_battle() -> void:
	if battle_scene != null:
		_battle_holder.remove_child(battle_scene)
		battle_scene.queue_free()
	battle_scene = BattleSceneScene.instantiate()
	battle_scene.card_turn = run.card_turn
	battle_scene.animations_enabled = animations_enabled
	battle_scene.battle_finished.connect(_on_battle_finished)
	battle_scene.animations_finished.connect(_refresh_status)
	_battle_holder.add_child(battle_scene)


func _on_battle_finished(_outcome: Battle.Outcome) -> void:
	run.finish_battle()
	_refresh()


func _refresh() -> void:
	_stage_label.text = "戦闘 %d / %d" % [run.stage, Encounter.STAGE_COUNT]
	_refresh_status()
	_reward_panel.visible = run.phase == Run.Phase.REWARD
	_refresh_reward_choices()
	_end_panel.visible = run.phase == Run.Phase.VICTORY or run.phase == Run.Phase.DEFEAT
	_end_label.text = "クリア！" if run.phase == Run.Phase.VICTORY else "敗北"


func _refresh_status() -> void:
	_status_label.text = "HP %d / %d　デッキ %d 枚" % [
		run.player.hp, run.player.max_hp, run.cards.size(),
	]


func _refresh_reward_choices() -> void:
	for button in _reward_choices.get_children():
		_reward_choices.remove_child(button)
		button.queue_free()
	for card in run.reward_choices:
		var button := Button.new()
		button.text = "%s (%d)\n%s" % [card.title, card.cost, card.description()]
		button.custom_minimum_size = Vector2(140.0, 96.0)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(choose_reward.bind(card))
		_reward_choices.add_child(button)
