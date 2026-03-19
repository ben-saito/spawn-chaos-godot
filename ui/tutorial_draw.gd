extends Node2D

func _draw() -> void:
	var tut := get_parent()
	if not tut.visible:
		return

	var step_data: Dictionary = tut.STEPS[tut._step]
	var fade_in := minf(tut._step_timer / 0.3, 1.0)

	# Background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0.02, 0.04, 0.08, 0.92))

	# Step indicator (dots)
	var total_steps: int = tut.STEPS.size()
	var dot_start_x := Config.SCREEN_W / 2.0 - total_steps * 10.0
	for i in range(total_steps):
		var dot_x := dot_start_x + i * 20.0
		var dot_y := 50.0
		if i == tut._step:
			draw_circle(Vector2(dot_x, dot_y), 5, Color(1, 0.85, 0.2))
		elif i < tut._step:
			draw_circle(Vector2(dot_x, dot_y), 4, Color(0.3, 0.6, 0.3))
		else:
			draw_circle(Vector2(dot_x, dot_y), 3, Color(0.3, 0.3, 0.4))

	# Title
	var title: String = step_data["title"]
	var title_w := title.length() * 16
	draw_string(ThemeDB.fallback_font,
		Vector2(Config.SCREEN_W / 2.0 - title_w / 2.0, 120),
		title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32,
		Color(1, 0.9, 0.3, fade_in))

	# Content box
	var box_x := 140.0
	var box_y := 160.0
	var box_w := Config.SCREEN_W - 280.0
	var lines: Array = step_data["lines"]
	var box_h := 60.0 + lines.size() * 32.0
	draw_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.08, 0.1, 0.15, 0.8 * fade_in))
	draw_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.3, 0.4, 0.6, 0.5 * fade_in), false, 2.0)

	# Lines
	for i in range(lines.size()):
		var line: String = lines[i]
		var line_alpha := minf((tut._step_timer - i * 0.1) / 0.3, 1.0)
		line_alpha = maxf(line_alpha, 0.0)
		draw_string(ThemeDB.fallback_font,
			Vector2(box_x + 30, box_y + 40 + i * 32),
			line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(0.9, 0.9, 0.95, line_alpha * fade_in))

	# Hint (blinking)
	var hint: String = step_data["hint"]
	var blink := 0.6 + sin(tut._step_timer * 4.0) * 0.4
	var hint_w := hint.length() * 10
	draw_string(ThemeDB.fallback_font,
		Vector2(Config.SCREEN_W / 2.0 - hint_w / 2.0, Config.SCREEN_H - 80),
		hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
		Color(0.7, 0.8, 1.0, blink))

	# Step counter
	var counter := "%d / %d" % [tut._step + 1, total_steps]
	draw_string(ThemeDB.fallback_font,
		Vector2(Config.SCREEN_W - 100, Config.SCREEN_H - 40),
		counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		Color(0.4, 0.4, 0.5))

	# Skip hint
	draw_string(ThemeDB.fallback_font,
		Vector2(20, Config.SCREEN_H - 40),
		"Escキーでスキップ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color(0.35, 0.35, 0.4))
