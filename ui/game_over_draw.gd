extends Node2D

func _draw() -> void:
	if not get_parent().visible:
		return
	# Dim
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.8))
	# Title
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 140, 200), "ゲームオーバー", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(1, 0, 0.3))
	# Score
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 80, 280), "スコア: %d" % GameState.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	# Time
	var sec := GameState.elapsed_seconds()
	var m := int(sec) / 60
	var s := int(sec) % 60
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 80, 320), "時間: %02d:%02d" % [m, s], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	# Restart
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 150, 400), "Rキーでリトライ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 0))
