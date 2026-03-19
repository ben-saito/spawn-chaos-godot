extends Node2D

func _draw() -> void:
	var parent := get_parent()
	if not parent.visible:
		return

	# Background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0.02, 0.02, 0.06, 0.95))

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 220, 80), "スポーン・カオス", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(0.3, 0.7, 1.0))

	# Subtitle
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 180, 130), "初期武器を選んでください:", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8, 0.8, 0.8))

	# Aura (always equipped) - top row
	var y := 170.0
	var x := 100.0
	var box_w: float = Config.SCREEN_W - 200.0
	draw_rect(Rect2(x, y, box_w, 65), Color(0.12, 0.22, 0.12, 0.8))
	draw_rect(Rect2(x, y, box_w, 65), Color(0.3, 0.6, 0.3), false, 2.0)
	# Aura icon
	_draw_aura_icon(Vector2(x + 40, y + 32))
	# Text
	draw_string(ThemeDB.fallback_font, Vector2(x + 80, y + 25), "[ 1 ] 聖剣オーラ（常時装備）", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.5, 0.9, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(x + 80, y + 50), "近距離の衝撃波攻撃（Spaceキー）", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.7, 0.6))

	# Selectable weapons (2-5) - grid layout
	var weapons: Dictionary = parent.WEAPONS
	var icons := [null, null, "_draw_missile_icon", "_draw_blade_icon", "_draw_lightning_icon", "_draw_holywater_icon"]
	var colors := [
		Color(0, 0, 0),
		Color(0, 0, 0),
		Color(0.3, 0.2, 0.5),   # missile - purple
		Color(0.2, 0.3, 0.5),   # blade - blue
		Color(0.4, 0.4, 0.2),   # lightning - yellow
		Color(0.15, 0.25, 0.4), # holy water - cyan
	]

	for key_num in [2, 3, 4, 5]:
		var info: Dictionary = weapons[key_num]
		var row: int = (key_num - 2) / 2
		var col: int = (key_num - 2) % 2
		var bx: float = x + col * (box_w / 2.0 + 10) * 0.98
		var by: float = 255.0 + row * 95.0
		var bw := box_w / 2.0 - 15
		var bh := 80.0

		# Box
		draw_rect(Rect2(bx, by, bw, bh), Color(colors[key_num].r, colors[key_num].g, colors[key_num].b, 0.7))
		draw_rect(Rect2(bx, by, bw, bh), Color(0.4, 0.4, 0.7), false, 2.0)

		# Icon
		var icon_center := Vector2(bx + 40, by + 40)
		match key_num:
			2: _draw_missile_icon(icon_center)
			3: _draw_blade_icon(icon_center)
			4: _draw_lightning_icon(icon_center)
			5: _draw_holywater_icon(icon_center)

		# Key number + name
		draw_string(ThemeDB.fallback_font, Vector2(bx + 75, by + 28), "[ %d ] %s" % [key_num, info["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 0.8))
		# Description
		draw_string(ThemeDB.fallback_font, Vector2(bx + 75, by + 55), info["desc"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65, 0.65, 0.75))

	# Hint
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 160, Config.SCREEN_H - 55), "2〜5キーで武器を選択してください", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 0.5, 0.6))
	# Twitcasting setup hint
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 150, Config.SCREEN_H - 30), "T or 6キー: Twitcasting接続設定", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.35, 0.6))

# --- Weapon Icons ---

func _draw_aura_icon(center: Vector2) -> void:
	# Expanding rings (aura effect)
	draw_arc(center, 18, 0, TAU, 24, Color(0.4, 0.8, 1.0, 0.7), 2.5)
	draw_arc(center, 12, 0, TAU, 16, Color(0.6, 0.9, 1.0, 0.5), 2.0)
	draw_arc(center, 6, 0, TAU, 12, Color(1, 1, 1, 0.6), 1.5)
	# Sword in center
	draw_rect(Rect2(center.x - 1.5, center.y - 14, 3, 20), Color(0.8, 0.85, 1.0))  # blade
	draw_rect(Rect2(center.x - 6, center.y + 4, 12, 3), Color(0.7, 0.6, 0.2))       # crossguard
	draw_rect(Rect2(center.x - 1, center.y + 7, 2, 6), Color(0.5, 0.3, 0.15))       # handle

func _draw_missile_icon(center: Vector2) -> void:
	# Homing missile with trail
	# Trail particles
	for i in range(4):
		var tx := center.x + 10 + i * 5
		var ty := center.y + sin(i * 0.8) * 2
		var r := 3.0 - i * 0.5
		draw_circle(Vector2(tx, ty), r, Color(0.4, 0.2, 0.8, 0.6 - i * 0.12))
	# Missile body
	draw_circle(center, 6, Color(0.6, 0.3, 1.0))
	draw_circle(center, 3, Color(1, 1, 1, 0.8))
	# Arrow indicator (homing)
	draw_line(center + Vector2(-12, -8), center + Vector2(-6, -2), Color(0.8, 0.6, 1), 1.5)
	draw_line(center + Vector2(-6, -2), center + Vector2(-4, -8), Color(0.8, 0.6, 1), 1.5)

func _draw_blade_icon(center: Vector2) -> void:
	# Rotating blades around a center
	draw_circle(center, 4, Color(0.3, 0.5, 0.8))
	for i in range(3):
		var angle := TAU / 3.0 * i - 0.3
		var bx := center.x + cos(angle) * 16
		var by := center.y + sin(angle) * 16
		# Blade shape (line + circle)
		var perp := Vector2(-sin(angle), cos(angle)) * 6
		draw_line(Vector2(bx, by) - perp, Vector2(bx, by) + perp, Color(0.7, 0.8, 1.0), 2.5)
		draw_circle(Vector2(bx, by), 3, Color(0.5, 0.65, 1.0))
	# Orbit circle
	draw_arc(center, 16, 0, TAU, 24, Color(0.4, 0.5, 0.8, 0.3), 1.0)

func _draw_lightning_icon(center: Vector2) -> void:
	# Lightning bolt zigzag
	var points := PackedVector2Array([
		center + Vector2(-3, -20),
		center + Vector2(3, -10),
		center + Vector2(-2, -8),
		center + Vector2(5, 2),
		center + Vector2(-1, 0),
		center + Vector2(4, 14),
	])
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(1, 1, 0.4), 2.5)
		# Glow
		draw_line(points[i], points[i + 1], Color(1, 1, 0.8, 0.3), 5.0)
	# Impact spark
	draw_circle(center + Vector2(4, 14), 5, Color(1, 1, 0.6, 0.4))
	draw_circle(center + Vector2(4, 14), 2.5, Color(1, 1, 1, 0.7))

func _draw_holywater_icon(center: Vector2) -> void:
	# Water pool (ellipse + drops)
	# Pool base
	draw_arc(center + Vector2(0, 6), 16, 0, TAU, 20, Color(0.2, 0.5, 1.0, 0.5), 8.0)
	draw_circle(center + Vector2(0, 6), 10, Color(0.3, 0.6, 1.0, 0.4))
	# Water bottle
	draw_rect(Rect2(center.x - 4, center.y - 16, 8, 14), Color(0.3, 0.5, 0.9))  # body
	draw_rect(Rect2(center.x - 2, center.y - 20, 4, 5), Color(0.4, 0.6, 0.95))  # neck
	draw_rect(Rect2(center.x - 3, center.y - 21, 6, 2), Color(0.5, 0.4, 0.2))   # cap
	# Cross on bottle
	draw_rect(Rect2(center.x - 0.5, center.y - 14, 1, 8), Color(1, 1, 0.6))
	draw_rect(Rect2(center.x - 3, center.y - 11, 6, 1), Color(1, 1, 0.6))
	# Drops
	draw_circle(center + Vector2(-8, -2), 2, Color(0.4, 0.7, 1.0, 0.6))
	draw_circle(center + Vector2(9, 1), 1.5, Color(0.4, 0.7, 1.0, 0.5))
