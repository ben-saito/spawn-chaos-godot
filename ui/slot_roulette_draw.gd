extends Node2D

func _draw() -> void:
	var slot := get_parent()
	if not slot._active:
		return

	var cx := Config.SCREEN_W / 2.0
	var cy := Config.SCREEN_H / 2.0

	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.65))

	var visible_count: int = slot._lane_count
	var items: Array = slot.ITEMS
	var total_items: int = items.size()

	var lane_w := 160.0
	var lane_h := 90.0
	var lane_gap := 20.0
	var lanes_total := lane_w * visible_count + lane_gap * maxi(visible_count - 1, 0)
	var frame_w := lanes_total + 60
	var frame_h := 260.0
	var frame_x := cx - frame_w / 2.0
	var frame_y := cy - frame_h / 2.0

	# Background panel
	draw_rect(Rect2(frame_x - 10, frame_y - 10, frame_w + 20, frame_h + 20), Color(0.06, 0.04, 0.1, 0.95))

	# Border color by current visible count (escalates)
	var border_color := Color(0.5, 0.5, 0.5)
	if visible_count >= 3:
		border_color = Color(1, 0.2, 0.2)
	elif visible_count >= 2:
		border_color = Color(1, 0.7, 0.1)
	draw_rect(Rect2(frame_x - 10, frame_y - 10, frame_w + 20, frame_h + 20), border_color, false, 3.0)

	# Title changes as lanes appear
	var title := "抽選中..."
	var title_color := Color(1, 0.85, 0.2)
	if visible_count >= 3:
		title = "大当たりチャンス!!!"
		title_color = Color(1, 0.2, 0.2)
	elif visible_count >= 2:
		title = "当たりチャンス!"
		title_color = Color(1, 0.7, 0.1)
	if slot._phase == 4:
		match slot._rarity:
			0: title = "GET!"
			1: title = "当たり!"
			2: title = "大当たり!!!"
	var tw := title.length() * 10
	draw_string(ThemeDB.fallback_font, Vector2(cx - tw / 2, frame_y + 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, title_color)

	# Draw visible lanes
	var lanes_start_x := cx - lanes_total / 2.0
	var lanes_y := frame_y + 55

	for lane in range(visible_count):
		if not slot._lane_visible[lane]:
			continue

		var lx := lanes_start_x + lane * (lane_w + lane_gap)
		var ly := lanes_y

		# Appear animation (scale in from center)
		var age: float = slot._timer - slot._lane_appear_time[lane]
		var appear_scale := clampf(age / 0.3, 0.0, 1.0)  # 0.3s to fully appear

		# Lane background
		var lane_alpha := appear_scale
		draw_rect(Rect2(lx, ly, lane_w, lane_h), Color(0.04, 0.04, 0.07, lane_alpha))

		# New lane flash effect
		if age < 0.5:
			var flash_alpha := (0.5 - age) * 0.6
			var flash_color := Color(1, 0.85, 0.2) if lane < 2 else Color(1, 0.3, 0.3)
			draw_rect(Rect2(lx - 3, ly - 3, lane_w + 6, lane_h + 6), Color(flash_color.r, flash_color.g, flash_color.b, flash_alpha))

		# Scrolling items
		var offset: float = slot._lane_offset[lane]
		var frac := fmod(offset, 1.0)
		var center_idx: int = int(offset) % total_items

		for i in range(-1, 2):
			var idx: int = (center_idx + i) % total_items
			if idx < 0:
				idx += total_items
			var item: Dictionary = items[idx]
			var iy := ly + lane_h / 2.0 + (float(i) - frac) * lane_h

			if iy < ly - lane_h or iy > ly + lane_h * 2:
				continue

			var dist_from_center := absf(iy - (ly + lane_h / 2.0))
			var alpha := clampf(1.0 - dist_from_center / lane_h, 0.2, 1.0) * lane_alpha

			var item_color: Color = item["color"]
			draw_rect(Rect2(lx + 4, iy - 32, lane_w - 8, 64), Color(item_color.r * 0.25, item_color.g * 0.25, item_color.b * 0.25, alpha * 0.8))
			draw_circle(Vector2(lx + 32, iy), 16, Color(item_color.r, item_color.g, item_color.b, alpha))

			var name_str: String = item["name"]
			draw_string(ThemeDB.fallback_font, Vector2(lx + 55, iy + 5), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, alpha))

		# Lane border
		draw_rect(Rect2(lx, ly, lane_w, lane_h), Color(0.5, 0.45, 0.2, lane_alpha), false, 2.0)

		# Center arrows
		var center_y := ly + lane_h / 2.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 6, center_y - 6),
			Vector2(lx - 6, center_y + 6),
			Vector2(lx + 3, center_y),
		]), Color(1, 0.85, 0.2, lane_alpha))
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx + lane_w + 6, center_y - 6),
			Vector2(lx + lane_w + 6, center_y + 6),
			Vector2(lx + lane_w - 3, center_y),
		]), Color(1, 0.85, 0.2, lane_alpha))

		# Glow when stopped
		if slot._lane_stopped[lane]:
			var flash := 0.5 + sin(slot._timer * 6.0) * 0.3
			draw_rect(Rect2(lx, ly, lane_w, lane_h), Color(1, 0.85, 0.2, flash * 0.15))

	# "+" between lanes
	if visible_count >= 2:
		for i in range(visible_count - 1):
			var px := lanes_start_x + (i + 1) * lane_w + i * lane_gap + lane_gap / 2.0
			var py := lanes_y + lane_h / 2.0
			draw_string(ThemeDB.fallback_font, Vector2(px - 6, py + 7), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.85, 0.2))

	# Result display
	if slot._phase == 4:
		var result_y := lanes_y + lane_h + 25

		var reward_texts: Array = []
		for i in range(visible_count):
			var item: Dictionary = items[slot._lane_result[i]]
			reward_texts.append(item["name"])

		var result_text := " + ".join(PackedStringArray(reward_texts))
		var flash := 0.7 + sin(slot._phase_timer * 8.0) * 0.3

		var banner_w := maxf(result_text.length() * 10 + 40, 300)
		draw_rect(Rect2(cx - banner_w / 2, result_y, banner_w, 50), Color(0.1, 0.08, 0.15, 0.9))
		draw_rect(Rect2(cx - banner_w / 2, result_y, banner_w, 50), Color(border_color.r, border_color.g, border_color.b, flash), false, 3.0)

		var rtw := result_text.length() * 7
		draw_string(ThemeDB.fallback_font, Vector2(cx - rtw / 2, result_y + 35), result_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 0.9))

		# Jackpot sparkles
		if slot._rarity == 2:
			for j in range(10):
				var sa: float = slot._phase_timer * 2.5 + j * TAU / 10.0
				var sr := frame_w / 2.0 + sin(slot._phase_timer * 3.0 + j) * 30
				var sp := Vector2(cx + cos(sa) * sr, result_y + 25 + sin(sa) * 20)
				draw_circle(sp, 3, Color(1, 1, 0.4, flash * 0.8))
				draw_circle(sp, 1.5, Color(1, 1, 1, flash))
