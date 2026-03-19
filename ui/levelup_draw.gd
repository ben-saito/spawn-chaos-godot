extends Node2D
## Draw node for level-up menu overlay with icons.

func _draw() -> void:
	var menu: CanvasLayer = get_parent()
	if not menu.visible:
		return
	# Dim background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.7))
	# Title
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 120, 100), "レベルアップ!", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 1, 0))
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 160, 140), "強化を選んでください（1/2/3）:", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	# Choices
	for i in range(menu.choices.size()):
		var upgrade_id: String = menu.choices[i]
		var info: Dictionary = menu.UPGRADES.get(upgrade_id, {"name": upgrade_id, "desc": ""})
		var y := 180.0 + i * 100.0
		var x := 130.0
		var box_w: float = Config.SCREEN_W - 260.0
		# Box with category color
		var cat_color := _get_category_color(upgrade_id)
		draw_rect(Rect2(x - 10, y - 20, box_w, 80), Color(cat_color.r * 0.3, cat_color.g * 0.3, cat_color.b * 0.3, 0.85))
		draw_rect(Rect2(x - 10, y - 20, box_w, 80), cat_color.lightened(0.3), false, 2.0)
		# Icon
		var icon_center := Vector2(x + 30, y + 20)
		_draw_upgrade_icon(icon_center, upgrade_id, cat_color)
		# Key number
		draw_string(ThemeDB.fallback_font, Vector2(x + 70, y + 12), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 0))
		# Name
		draw_string(ThemeDB.fallback_font, Vector2(x + 110, y + 12), info["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		# Description
		draw_string(ThemeDB.fallback_font, Vector2(x + 110, y + 42), info["desc"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.7))

func _get_category_color(upgrade_id: String) -> Color:
	if upgrade_id.begins_with("unlock_"):
		return Color(0.2, 0.8, 0.3)   # green - unlock
	elif upgrade_id.begins_with("aura"):
		return Color(0.3, 0.7, 1.0)   # light blue - aura
	elif upgrade_id.begins_with("missile"):
		return Color(0.6, 0.3, 1.0)   # purple - missile
	elif upgrade_id.begins_with("blade"):
		return Color(0.4, 0.6, 1.0)   # blue - blade
	elif upgrade_id.begins_with("lightning"):
		return Color(1.0, 0.9, 0.2)   # yellow - lightning
	elif upgrade_id.begins_with("hw"):
		return Color(0.3, 0.6, 0.9)   # cyan - holy water
	elif upgrade_id == "speed_up":
		return Color(0.2, 0.9, 0.6)   # teal - speed
	elif upgrade_id == "max_hp":
		return Color(0.9, 0.3, 0.3)   # red - HP
	elif upgrade_id == "heal":
		return Color(0.9, 0.5, 0.6)   # pink - heal
	return Color(0.5, 0.5, 0.5)

func _draw_upgrade_icon(center: Vector2, upgrade_id: String, color: Color) -> void:
	# Icon background circle
	draw_circle(center, 22, Color(0, 0, 0, 0.5))
	draw_arc(center, 22, 0, TAU, 20, color.lightened(0.2), 1.5)

	match upgrade_id:
		"unlock_missile", "missile_damage", "missile_cooldown":
			_draw_icon_missile(center, color)
		"unlock_blade", "blade_add", "blade_damage":
			_draw_icon_blade(center, color)
		"unlock_lightning", "lightning_damage", "lightning_cooldown":
			_draw_icon_lightning(center, color)
		"unlock_holy_water", "hw_damage", "hw_duration":
			_draw_icon_holywater(center, color)
		"aura_damage", "aura_range":
			_draw_icon_aura(center, color)
		"speed_up":
			_draw_icon_speed(center, color)
		"max_hp":
			_draw_icon_hp(center, color)
		"heal":
			_draw_icon_heal(center, color)
		_:
			draw_circle(center, 8, color)

func _draw_icon_aura(center: Vector2, color: Color) -> void:
	draw_arc(center, 14, 0, TAU, 16, color, 2.0)
	draw_arc(center, 8, 0, TAU, 12, color.lightened(0.3), 1.5)
	# Sword
	draw_rect(Rect2(center.x - 1, center.y - 10, 2, 14), Color(0.85, 0.9, 1))
	draw_rect(Rect2(center.x - 4, center.y + 2, 8, 2), Color(0.7, 0.6, 0.2))

func _draw_icon_missile(center: Vector2, color: Color) -> void:
	# Missile
	draw_circle(center + Vector2(-3, 0), 5, color)
	draw_circle(center + Vector2(-3, 0), 2.5, Color(1, 1, 1, 0.7))
	# Trail
	for i in range(3):
		draw_circle(center + Vector2(5 + i * 4, 0), 2.5 - i * 0.5, Color(color.r, color.g, color.b, 0.5 - i * 0.12))
	# Homing arrow
	draw_line(center + Vector2(-10, -7), center + Vector2(-5, -2), color.lightened(0.3), 1.5)

func _draw_icon_blade(center: Vector2, color: Color) -> void:
	draw_circle(center, 3, color)
	for i in range(3):
		var angle := TAU / 3.0 * i
		var bp := center + Vector2(cos(angle), sin(angle)) * 12
		var perp := Vector2(-sin(angle), cos(angle)) * 5
		draw_line(bp - perp, bp + perp, color.lightened(0.2), 2.0)
		draw_circle(bp, 2, color)
	draw_arc(center, 12, 0, TAU, 16, Color(color.r, color.g, color.b, 0.3), 1.0)

func _draw_icon_lightning(center: Vector2, color: Color) -> void:
	var pts := [
		center + Vector2(-2, -14),
		center + Vector2(3, -4),
		center + Vector2(-1, -3),
		center + Vector2(4, 10),
	]
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], color, 2.5)
		draw_line(pts[i], pts[i + 1], Color(1, 1, 1, 0.3), 5.0)
	draw_circle(pts[3], 3, Color(1, 1, 0.8, 0.5))

func _draw_icon_holywater(center: Vector2, color: Color) -> void:
	# Pool
	draw_circle(center + Vector2(0, 5), 8, Color(color.r, color.g, color.b, 0.4))
	# Bottle
	draw_rect(Rect2(center.x - 3, center.y - 12, 6, 10), color)
	draw_rect(Rect2(center.x - 1.5, center.y - 15, 3, 4), color.lightened(0.2))
	# Cross
	draw_rect(Rect2(center.x - 0.5, center.y - 10, 1, 6), Color(1, 1, 0.6))
	draw_rect(Rect2(center.x - 2.5, center.y - 8, 5, 1), Color(1, 1, 0.6))

func _draw_icon_speed(center: Vector2, color: Color) -> void:
	# Speed lines + arrow
	for i in range(3):
		var ly := center.y - 6 + i * 6
		draw_line(Vector2(center.x - 12, ly), Vector2(center.x + 6 - i * 2, ly), color, 1.5)
	# Arrow head
	draw_line(center + Vector2(8, 0), center + Vector2(2, -6), color, 2.0)
	draw_line(center + Vector2(8, 0), center + Vector2(2, 6), color, 2.0)
	draw_line(center + Vector2(8, 0), center + Vector2(-4, 0), color, 2.0)

func _draw_icon_hp(center: Vector2, color: Color) -> void:
	# Heart shape (two circles + triangle)
	draw_circle(center + Vector2(-5, -3), 6, color)
	draw_circle(center + Vector2(5, -3), 6, color)
	# Bottom triangle
	var pts := PackedVector2Array([
		center + Vector2(-11, -1),
		center + Vector2(11, -1),
		center + Vector2(0, 12),
	])
	draw_colored_polygon(pts, color)
	# Plus sign
	draw_rect(Rect2(center.x - 1, center.y - 5, 2, 8), Color(1, 1, 1, 0.8))
	draw_rect(Rect2(center.x - 3, center.y - 2, 6, 2), Color(1, 1, 1, 0.8))

func _draw_icon_heal(center: Vector2, color: Color) -> void:
	# Heart
	draw_circle(center + Vector2(-4, -2), 5, color)
	draw_circle(center + Vector2(4, -2), 5, color)
	var pts := PackedVector2Array([
		center + Vector2(-9, 0),
		center + Vector2(9, 0),
		center + Vector2(0, 10),
	])
	draw_colored_polygon(pts, color)
	# Sparkles
	for i in range(3):
		var angle := TAU / 3.0 * i - 0.5
		var sp := center + Vector2(cos(angle), sin(angle)) * 14
		draw_circle(sp, 1.5, Color(1, 1, 0.5, 0.7))
