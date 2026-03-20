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
			"配信者 vs 視聴者の対決ゲーム!",
			"配信者が主人公を操作し、",
			"視聴者がコメントで敵を召喚します!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "ルール",
		"lines": [
			"配信者: 5分間生き残れば勝利!",
			"視聴者: 5分以内に配信者を倒せば勝利!",
			"カウントダウンが0になるまで戦え!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "移動と攻撃",
		"lines": [
			"矢印キー（↑↓←→）で移動します。",
			"Spaceキー: 聖剣オーラ（近距離攻撃）",
			"その他の武器はレベルアップや宝箱で入手!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "パワーアップ",
		"lines": [
			"敵を倒すとXPが貯まります。",
			"レベルアップ時に3つの強化から選択!",
			"マップ上の宝箱やNPCクエストも活用しよう!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "視聴者の攻撃",
		"lines": [
			"視聴者は !spawn コマンドで敵を召喚!",
			"時間が経つとコストが下がります:",
			"  Phase 2 (残り3分): コスト75%",
			"  Phase 3 (残り1分): コスト50%",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "ファイナルラッシュ",
		"lines": [
			"残り60秒でファイナルラッシュ突入!",
			"全種類の敵が出現、スポーン速度2倍!",
			"視聴者のコストも半額に!",
			"ここを乗り越えれば配信者の勝ち!",
		],
		"hint": "Spaceキーで次へ",
	},
	{
		"title": "準備完了!",
		"lines": [
			"5分間のサバイバルが始まる!",
			"視聴者の猛攻を耐え抜け!",
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
