extends Node2D
## Draws connection status overlay (used for web version after prompt).

func _draw() -> void:
	var setup := get_parent()
	if not setup._active or not setup._show_status_only:
		return

	var cx := Config.SCREEN_W / 2.0
	var cy := Config.SCREEN_H / 2.0

	# Dim background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.7))

	# Status box
	var box_w := 450.0
	var box_h := 100.0
	draw_rect(Rect2(cx - box_w / 2, cy - box_h / 2, box_w, box_h), Color(0.06, 0.06, 0.1, 0.95))
	draw_rect(Rect2(cx - box_w / 2, cy - box_h / 2, box_w, box_h), Color(0.4, 0.3, 0.8), false, 2.0)

	# Status text
	var color := Color(0.3, 1, 0.4) if setup._status_ok else Color(1, 0.7, 0.3)
	var msg: String = setup._status_message
	var lines: PackedStringArray = msg.split("\n")
	for i in range(lines.size()):
		var tw := lines[i].length() * 8
		draw_string(ThemeDB.fallback_font, Vector2(cx - tw / 2, cy - 10 + i * 24), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)
