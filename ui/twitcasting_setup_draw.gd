extends Node2D

func _draw() -> void:
	var setup := get_parent()
	if not setup._active:
		return

	var cx := Config.SCREEN_W / 2.0
	var cy := Config.SCREEN_H / 2.0

	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.8))

	# Panel
	var panel_w := 580.0
	var panel_h := 420.0
	var px := cx - panel_w / 2.0
	var py := cy - panel_h / 2.0
	draw_rect(Rect2(px, py, panel_w, panel_h), Color(0.06, 0.06, 0.1, 0.95))
	draw_rect(Rect2(px, py, panel_w, panel_h), Color(0.4, 0.3, 0.8), false, 2.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(cx - 120, py + 35), "Twitcasting 接続設定", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.6, 0.5, 1.0))

	var cursor_visible := int(setup._cursor_blink * 2) % 2 == 0

	# --- Field 1: API Token ---
	var f1_y := py + 60
	var f1_active: bool = (setup._active_field == 0)
	var f1_border: Color = Color(0.5, 0.4, 0.9) if f1_active else Color(0.3, 0.3, 0.4)
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, f1_y + 18), "APIトークン:", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.8))

	var field_x := px + 30
	var field_w := panel_w - 60
	var field_h := 36.0
	var f1_field_y := f1_y + 25
	draw_rect(Rect2(field_x, f1_field_y, field_w, field_h), Color(0.02, 0.02, 0.04))
	draw_rect(Rect2(field_x, f1_field_y, field_w, field_h), f1_border, false, 1.5)

	# Token display (masked)
	var token_display: String = setup._token_input
	if token_display.length() > 0:
		# Show first 8 chars, mask the rest
		if token_display.length() > 8:
			token_display = token_display.substr(0, 8) + "..." + "●".repeat(mini(token_display.length() - 8, 10))
		if f1_active and cursor_visible:
			token_display += "|"
	elif f1_active:
		if cursor_visible:
			token_display = "|"
	draw_string(ThemeDB.fallback_font, Vector2(field_x + 10, f1_field_y + 25), token_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.8, 0.8))

	if setup._token_input == "":
		draw_string(ThemeDB.fallback_font, Vector2(field_x + 10, f1_field_y + 25), "Bearer トークンを入力", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.3, 0.4))

	# --- Field 2: User ID ---
	var f2_y := f1_field_y + field_h + 20
	var f2_active: bool = (setup._active_field == 1)
	var f2_border := Color(0.5, 0.4, 0.9) if f2_active else Color(0.3, 0.3, 0.4)
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, f2_y + 18), "ユーザーID:", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.8))

	var f2_field_y := f2_y + 25
	draw_rect(Rect2(field_x, f2_field_y, field_w, field_h), Color(0.02, 0.02, 0.04))
	draw_rect(Rect2(field_x, f2_field_y, field_w, field_h), f2_border, false, 1.5)

	var uid_display: String = setup._user_id_input
	if f2_active and cursor_visible:
		uid_display += "|"
	draw_string(ThemeDB.fallback_font, Vector2(field_x + 10, f2_field_y + 25), uid_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1))

	if setup._user_id_input == "":
		draw_string(ThemeDB.fallback_font, Vector2(field_x + 10, f2_field_y + 25), "例: c:username", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.3, 0.4))

	# Tab hint
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, f2_field_y + field_h + 18), "Tabキーで項目を切り替え", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 0.4, 0.5))

	# Connect button
	var btn_y := f2_field_y + field_h + 35
	var can_connect: bool = setup._token_input != "" and setup._user_id_input != ""
	var btn_color := Color(0.2, 0.15, 0.4) if can_connect else Color(0.15, 0.15, 0.18)
	draw_rect(Rect2(cx - 80, btn_y, 160, 36), btn_color)
	draw_rect(Rect2(cx - 80, btn_y, 160, 36), Color(0.5, 0.4, 0.9) if can_connect else Color(0.25, 0.25, 0.3), false, 1.5)
	var btn_text_color := Color(0.8, 0.8, 1.0) if can_connect else Color(0.4, 0.4, 0.45)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 40, btn_y + 25), "Enter: 接続", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, btn_text_color)

	# Status message
	if setup._status_message != "":
		var status_y := btn_y + 50
		var status_color := Color(0.3, 1.0, 0.4) if setup._status_ok else Color(1.0, 0.7, 0.3)
		var lines: PackedStringArray = setup._status_message.split("\n")
		for i in range(lines.size()):
			draw_string(ThemeDB.fallback_font, Vector2(px + 30, status_y + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, status_color)

	# How it works
	var info_y := py + panel_h - 75
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y), "手順:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y + 18), "1. twitcasting.tv/indexapi.phpでトークンを取得", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.45, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y + 34), "2. ユーザーIDを入力してEnter → 自動で配信に接続", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.45, 0.55))

	# Close hint
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, py + panel_h - 15), "Escキーで閉じる", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.35, 0.35, 0.4))
