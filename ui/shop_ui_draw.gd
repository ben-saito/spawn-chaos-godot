extends Node2D
## Drawing node for shop UI overlay.

func _draw() -> void:
	var shop: CanvasLayer = get_parent()
	if not shop._is_open:
		return

	var font: Font = ThemeDB.fallback_font
	var sw: float = Config.SCREEN_W
	var sh: float = Config.SCREEN_H

	# Dark overlay
	draw_rect(Rect2(0, 0, sw, sh), Color(0, 0, 0, 0.6))

	# Shop panel
	var panel_w: float = 500.0
	var panel_h: float = 420.0
	var panel_x: float = (sw - panel_w) / 2.0
	var panel_y: float = (sh - panel_h) / 2.0

	# Panel background
	draw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.1, 0.08, 0.15, 0.95))
	# Panel border
	draw_rect(Rect2(panel_x, panel_y, panel_w, panel_h), Color(0.8, 0.65, 0.2), false, 2.0)

	# Title
	draw_string(font, Vector2(panel_x + 20, panel_y + 40), "商人のショップ", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.9, 0.4))

	# Points display
	var pts_text: String = "所持PT: %d" % GameState.game_points
	draw_string(font, Vector2(panel_x + 20, panel_y + 70), pts_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.9, 0.15))

	# Items list
	var y_offset: float = panel_y + 110.0
	var items: Array = shop.SHOP_ITEMS
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var item_name: String = item["name"]
		var cost: int = item["cost"]
		var can_afford: bool = GameState.game_points >= cost
		var text_color: Color = Color(1, 1, 1) if can_afford else Color(0.5, 0.5, 0.5)
		var cost_color: Color = Color(1, 0.9, 0.15) if can_afford else Color(0.5, 0.4, 0.3)

		# Item number
		var num_text: String = "[%d]" % (i + 1)
		draw_string(font, Vector2(panel_x + 30, y_offset), num_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.7, 0.7, 0.8))

		# Item name
		draw_string(font, Vector2(panel_x + 80, y_offset), item_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, text_color)

		# Cost
		var cost_text: String = "%dpt" % cost
		draw_string(font, Vector2(panel_x + 380, y_offset), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, cost_color)

		y_offset += 36.0

	# Close instruction
	draw_string(font, Vector2(panel_x + 20, panel_y + panel_h - 20), "[ESC] 閉じる", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.6, 0.7))

	# Purchase message
	if shop._message_timer > 0 and shop._message != "":
		var alpha: float = minf(shop._message_timer, 1.0)
		var msg_color: Color = Color(0.3, 1, 0.3, alpha)
		if shop._message.contains("不足"):
			msg_color = Color(1, 0.3, 0.3, alpha)
		draw_string(font, Vector2(panel_x + 150, panel_y + panel_h - 50), shop._message, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, msg_color)
