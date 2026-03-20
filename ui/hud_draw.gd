extends Node2D
## Actual drawing node for HUD (child of CanvasLayer).

@onready var hud: CanvasLayer = get_parent()

func _draw() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var player = scene.find_child("Player")
	if player == null:
		return

	_draw_hp_bar(player)
	_draw_countdown_timer()
	_draw_phase_indicator()
	_draw_enemy_count()
	_draw_viewer_stats()
	_draw_xp_bar(player)
	_draw_level(player)
	_draw_spawn_log()
	_draw_viewer_commands()
	_draw_event_banner()
	_draw_combo()
	_draw_final_rush_banner()

func _draw_hp_bar(player) -> void:
	var x := 20.0
	var y := 16.0
	var w := 200.0
	var h := 18.0
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(x, y + 14), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	var bar_x := x + 40
	# Background
	draw_rect(Rect2(bar_x, y, w, h), Color(0.2, 0.2, 0.2))
	# Fill
	var ratio := float(player.hp) / float(player.max_hp)
	var bar_color := Color(0, 0.85, 0.2)
	if ratio < 0.25:
		bar_color = Color(1, 0, 0.3)
	elif ratio < 0.5:
		bar_color = Color(1, 0.9, 0.15)
	draw_rect(Rect2(bar_x, y, w * ratio, h), bar_color)
	# Text
	var hp_text := "%d/%d" % [player.hp, player.max_hp]
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + 6, y + 14), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_countdown_timer() -> void:
	var remaining: float = GameState.remaining_time
	var m: int = int(remaining) / 60
	var s: int = int(remaining) % 60
	var text := "%02d:%02d" % [m, s]

	# Timer color based on remaining time
	var timer_color := Color.WHITE
	if remaining <= Config.PHASE3_TIME:
		# Red pulsing for final rush
		var pulse: float = abs(sin(GameState.elapsed_frames * 0.15))
		timer_color = Color(1, 0.1 + pulse * 0.2, 0.1 + pulse * 0.2)
	elif remaining <= Config.PHASE2_TIME:
		timer_color = Color(1, 1, 0.15)

	# Big countdown at center-top
	var cx: float = Config.SCREEN_W / 2.0
	# Background box
	draw_rect(Rect2(cx - 65, 4, 130, 42), Color(0, 0, 0, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(cx - 50, 36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, timer_color)

func _draw_phase_indicator() -> void:
	var cx: float = Config.SCREEN_W / 2.0
	var phase_text := ""
	var phase_color := Color(0.7, 0.7, 0.7)
	match GameState.phase:
		1:
			phase_text = "Phase 1"
			phase_color = Color(0.6, 0.8, 0.6)
		2:
			phase_text = "Phase 2"
			phase_color = Color(1, 0.9, 0.2)
		3:
			phase_text = "Phase 3"
			phase_color = Color(1, 0.3, 0.3)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 30, 62), phase_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, phase_color)

func _draw_enemy_count() -> void:
	var scene = get_tree().current_scene
	var container = scene.find_child("Enemies") if scene else null
	var count: int = container.get_child_count() if container else 0
	draw_string(ThemeDB.fallback_font, Vector2(20, 56), "敵数:%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.6, 0.3))

func _draw_viewer_stats() -> void:
	var x: float = Config.SCREEN_W - 220.0
	var y := 80.0
	draw_string(ThemeDB.fallback_font, Vector2(x, y), "視聴者スポーン: %d体" % GameState.viewer_total_spawns, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(x, y + 20), "視聴者ダメージ: %d" % GameState.viewer_total_damage, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.5, 0.5))
	# Show cost multiplier if not 1.0
	var mult: float = GameState.get_viewer_cost_multiplier()
	if mult < 1.0:
		var pct: int = int(mult * 100)
		draw_string(ThemeDB.fallback_font, Vector2(x, y + 40), "コスト: %d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 1.0, 0.3))

func _draw_xp_bar(player) -> void:
	var y := Config.SCREEN_H - 16.0
	var w := float(Config.SCREEN_W)
	draw_rect(Rect2(0, y, w, 10), Color(0.15, 0.15, 0.2))
	var ratio: float = float(player.xp) / float(player.xp_to_next) if player.xp_to_next > 0 else 0.0
	draw_rect(Rect2(0, y, w * ratio, 10), Color(0.3, 0.6, 1.0))

func _draw_level(player) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(20, Config.SCREEN_H - 28), "Lv.%d" % player.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func _draw_spawn_log() -> void:
	var x := 20.0
	var y := Config.SCREEN_H - 180.0
	for i in range(hud.spawn_log.size()):
		draw_string(ThemeDB.fallback_font, Vector2(x, y + i * 22), hud.spawn_log[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.7))

func _draw_viewer_commands() -> void:
	var x := Config.SCREEN_W - 260.0
	var y := Config.SCREEN_H - 280.0
	# Background panel
	draw_rect(Rect2(x - 10, y - 22, 260, 270), Color(0, 0, 0, 0.65))
	draw_rect(Rect2(x - 10, y - 22, 260, 270), Color(0.5, 0.3, 0.8, 0.6), false, 2.0)
	# Title
	draw_string(ThemeDB.fallback_font, Vector2(x, y), "視聴者コマンド", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.6, 1.0))
	y += 26
	# Spawn commands
	var cmds := [
		["!spawn スライム", "10pt"],
		["!spawn ゴブリン", "20pt"],
		["!spawn スケルトン", "30pt"],
		["!spawn バット", "25pt"],
		["!spawn マッシュルーム", "15pt"],
		["!spawn オーガ", "80pt"],
		["!spawn ドラゴン", "500pt"],
	]
	for cmd in cmds:
		draw_string(ThemeDB.fallback_font, Vector2(x, y), cmd[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.85, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(x + 200, y), cmd[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.5))
		y += 18
	y += 6
	# Gimmick commands
	var gimmicks := [
		["!gimmick アイス", "50pt"],
		["!gimmick ダーク", "80pt"],
		["!gimmick 重力", "120pt"],
	]
	for g in gimmicks:
		draw_string(ThemeDB.fallback_font, Vector2(x, y), g[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.75, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(x + 200, y), g[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.5))
		y += 18
	# Cost discount note
	var mult: float = GameState.get_viewer_cost_multiplier()
	if mult < 1.0:
		y += 4
		var pct: int = int((1.0 - mult) * 100)
		draw_string(ThemeDB.fallback_font, Vector2(x, y), "現在 %d%%OFF!" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.3, 0.3))

func _draw_event_banner() -> void:
	if hud._event_timer > 0 and hud._event_text != "":
		var alpha := minf(hud._event_timer, 1.0)
		var text: String = hud._event_text
		# Background box for better readability
		var tw := text.length() * 14
		draw_rect(Rect2(Config.SCREEN_W / 2.0 - tw / 2.0 - 10, 70, tw + 20, 35), Color(0, 0, 0, 0.5 * alpha))
		draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - tw / 2.0, 95), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 0, alpha))

func _draw_combo() -> void:
	if GameState.combo_count >= 3:
		var combo_text := "%d コンボ! x%.1f" % [GameState.combo_count, GameState.combo_multiplier]
		var pulse := 1.0 + sin(GameState.elapsed_frames * 0.2) * 0.1
		var font_size := int(24 * pulse)
		var color := Color(1, 0.5, 0) if GameState.combo_count < 10 else Color(1, 0.2, 0.2)
		if GameState.combo_count >= 20:
			color = Color(1, 0, 1)  # Purple for insane combos
		draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 80, 140), combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_final_rush_banner() -> void:
	if GameState.phase != 3 or GameState.state != GameState.State.PLAY:
		return
	# Flashing "FINAL RUSH" text above the timer
	var flash: float = abs(sin(GameState.elapsed_frames * 0.2))
	if flash > 0.3:
		var cx: float = Config.SCREEN_W / 2.0
		var rush_color := Color(1, 0.2, 0.1, flash)
		draw_string(ThemeDB.fallback_font, Vector2(cx - 80, 100), "FINAL RUSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, rush_color)
	# Red screen flash overlay (subtle)
	var screen_flash: float = abs(sin(GameState.elapsed_frames * 0.08)) * 0.06
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(1, 0, 0, screen_flash))
