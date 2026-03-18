extends Node2D
## Draw node for level-up menu overlay.

func _draw() -> void:
	var menu: CanvasLayer = get_parent()
	if not menu.visible:
		return
	# Dim background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.7))
	# Title
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 30, 40), "LEVEL UP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 0))
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 45, 55), "Choose an upgrade:", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
	# Choices
	for i in range(menu.choices.size()):
		var upgrade_id: String = menu.choices[i]
		var info: Dictionary = menu.UPGRADES.get(upgrade_id, {"name": upgrade_id, "desc": ""})
		var y := 75.0 + i * 35.0
		var x := 30.0
		# Box
		draw_rect(Rect2(x - 4, y - 10, Config.SCREEN_W - 52, 28), Color(0.2, 0.2, 0.3, 0.9))
		draw_rect(Rect2(x - 4, y - 10, Config.SCREEN_W - 52, 28), Color(0.5, 0.5, 0.7), false, 1.0)
		# Key number
		draw_string(ThemeDB.fallback_font, Vector2(x, y + 2), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 0))
		# Name
		draw_string(ThemeDB.fallback_font, Vector2(x + 22, y + 2), info["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		# Description
		draw_string(ThemeDB.fallback_font, Vector2(x + 22, y + 12), info["desc"], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.7, 0.7, 0.7))
