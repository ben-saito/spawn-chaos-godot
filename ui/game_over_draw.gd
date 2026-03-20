extends Node2D

func _draw() -> void:
	if not get_parent().visible:
		return

	if GameState.game_result == "streamer_win":
		_draw_streamer_win()
	else:
		_draw_viewer_win()

func _draw_streamer_win() -> void:
	# Dim with gold/green tint
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0.05, 0.08, 0.0, 0.85))

	var cx: float = Config.SCREEN_W / 2.0

	# Title - gold
	draw_string(ThemeDB.fallback_font, Vector2(cx - 180, 180), "配信者の勝利!", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1, 0.85, 0.2))

	# Subtitle
	draw_string(ThemeDB.fallback_font, Vector2(cx - 140, 230), "5分間生き残った!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.8, 1.0, 0.5))

	# Stats
	var y := 280.0
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, y), "スコア: %d" % GameState.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	y += 40
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, y), "視聴者スポーン: %d体" % GameState.viewer_total_spawns, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.7, 0.8, 1.0))
	y += 40
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, y), "視聴者ダメージ: %d" % GameState.viewer_total_damage, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.7, 0.8, 1.0))

	# Restart
	draw_string(ThemeDB.fallback_font, Vector2(cx - 150, Config.SCREEN_H - 100), "Rキーでリトライ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 0))

func _draw_viewer_win() -> void:
	# Dim with dark red tint
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0.08, 0.0, 0.0, 0.85))

	var cx: float = Config.SCREEN_W / 2.0

	# Title - red
	draw_string(ThemeDB.fallback_font, Vector2(cx - 180, 180), "視聴者の勝利!", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1, 0.15, 0.15))

	# Survival time
	var survived: float = GameState.elapsed_seconds()
	var m: int = int(survived) / 60
	var s: int = int(survived) % 60
	draw_string(ThemeDB.fallback_font, Vector2(cx - 140, 230), "生存時間: %02d:%02d" % [m, s], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.9, 0.7, 0.7))

	# Stats
	var y := 280.0
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, y), "スコア: %d" % GameState.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	y += 40
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, y), "視聴者スポーン: %d体" % GameState.viewer_total_spawns, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.5, 0.5))
	y += 40
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, y), "視聴者ダメージ: %d" % GameState.viewer_total_damage, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.5, 0.5))

	# Restart
	draw_string(ThemeDB.fallback_font, Vector2(cx - 150, Config.SCREEN_H - 100), "Rキーでリトライ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 0))
