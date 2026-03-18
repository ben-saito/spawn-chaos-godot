extends Node2D

func _draw() -> void:
	if not get_parent().visible:
		return
	# Dim
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.8))
	# Title
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 36, 70), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0, 0.3))
	# Score
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 30, 100), "Score: %d" % GameState.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	# Time
	var sec := GameState.elapsed_seconds()
	var m := int(sec) / 60
	var s := int(sec) % 60
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 25, 115), "Time: %02d:%02d" % [m, s], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	# Restart
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 42, 145), "PRESS R TO RETRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 0))
