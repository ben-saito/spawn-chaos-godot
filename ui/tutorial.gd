extends CanvasLayer
## Step-by-step tutorial at game start.

var _draw_node: Node2D
var _step: int = 0
var _key_held: bool = false
var _step_timer: float = 0.0

const STEPS := [
	{
		"title": "スポーン・カオスへようこそ!",
		"lines": [
			"配信者が主人公を操作し、",
			"視聴者がコメントで敵を召喚する",
			"バンパイアサバイバーズ風ゲームです!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "移動",
		"lines": [
			"矢印キー（↑↓←→）で移動します。",
			"マップを探索して宝箱を見つけよう!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "攻撃",
		"lines": [
			"Spaceキー: 聖剣オーラ（近距離攻撃）",
			"その他の武器はレベルアップや",
			"宝箱で入手できます!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "敵の召喚（キーボード）",
		"lines": [
			"数字キー 1〜9: 敵を手動で召喚",
			"  1:スライム(10pt)  2:ゴブリン(20pt)",
			"  3:スケルトン(30pt) 4:オーガ(80pt)",
			"  5:ドラゴン(500pt)",
			"ポイントを消費して召喚できます。",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "ギミック",
		"lines": [
			"Qキー: アイスフロア（移動速度低下）",
			"Wキー: ダークネス（視界制限）",
			"Eキー: 重力反転（上下逆転）",
			"視聴者もコマンドで発動できます!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "Twitcasting連携",
		"lines": [
			"視聴者はコメント欄でコマンドを入力:",
			"  !spawn スライム — 敵を召喚",
			"  !gimmick アイス — ギミック発動",
			"  !points — ポイント確認",
			"視聴者にはポイントが配られます。",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "レベルアップ & 宝箱",
		"lines": [
			"敵を倒すとXPが貯まります。",
			"レベルアップ時に3つの強化から選択!",
			"マップ上の光る宝箱に近づくと",
			"ランダムでスキルを入手できます。",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "準備完了!",
		"lines": [
			"敵は自動的に湧いてきます。",
			"できるだけ長く生き残ろう!",
			"",
			"GOOD LUCK!",
		],
		"hint": "Spaceキーでゲーム開始!",
	},
]

func _ready() -> void:
	_draw_node = $DrawLayer
	EventBus.game_reset.connect(_on_game_reset)

func _on_game_reset() -> void:
	_step = 0
	_step_timer = 0.0
	visible = true

func _process(delta: float) -> void:
	if GameState.state != GameState.State.TUTORIAL:
		visible = false
		return
	visible = true
	_step_timer += delta
	_draw_node.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if GameState.state != GameState.State.TUTORIAL:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _step_timer < 0.3:
		return

	# Skip with Escape
	if event.keycode == KEY_ESCAPE:
		GameState.state = GameState.State.WEAPON_SELECT
		visible = false
		get_viewport().set_input_as_handled()
		return

	# Advance with Space or Enter or any key
	_step += 1
	_step_timer = 0.0
	if _step >= STEPS.size():
		GameState.state = GameState.State.WEAPON_SELECT
		visible = false
	get_viewport().set_input_as_handled()
