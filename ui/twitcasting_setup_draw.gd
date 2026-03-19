extends Node2D

func _draw() -> void:
	var setup := get_parent()
	if not setup._active:
		return

	var cx := Config.SCREEN_W / 2.0
	var cy := Config.SCREEN_H / 2.0

	# Dim background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0, 0, 0, 0.8))

	# Panel
	var panel_w := 550.0
	var panel_h := 350.0
	var px := cx - panel_w / 2.0
	var py := cy - panel_h / 2.0
	draw_rect(Rect2(px, py, panel_w, panel_h), Color(0.06, 0.06, 0.1, 0.95))
	draw_rect(Rect2(px, py, panel_w, panel_h), Color(0.4, 0.3, 0.8), false, 2.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(cx - 120, py + 35), "Twitcasting 接続設定", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.6, 0.5, 1.0))

	# Instructions
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, py + 75), "TwitcastingのユーザーIDを入力してください:", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, py + 95), "（配信ページURLの twitcasting.tv/ の後の部分）", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.5, 0.6))

	# Input field
	var field_x := px + 30
	var field_y := py + 115
	var field_w := panel_w - 60
	var field_h := 40.0
	draw_rect(Rect2(field_x, field_y, field_w, field_h), Color(0.02, 0.02, 0.04))
	draw_rect(Rect2(field_x, field_y, field_w, field_h), Color(0.4, 0.4, 0.6), false, 1.5)

	# Input text with cursor
	var display_text: String = setup._user_id_input
	var cursor_visible := int(setup._cursor_blink * 2) % 2 == 0
	if cursor_visible:
		display_text += "|"
	draw_string(ThemeDB.fallback_font, Vector2(field_x + 10, field_y + 28), display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1))

	# Placeholder
	if setup._user_id_input == "":
		draw_string(ThemeDB.fallback_font, Vector2(field_x + 10, field_y + 28), "例: c:username", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.3, 0.3, 0.4))

	# Connect button hint
	var btn_y := field_y + field_h + 20
	if setup._user_id_input != "":
		draw_rect(Rect2(cx - 80, btn_y, 160, 35), Color(0.2, 0.15, 0.4))
		draw_rect(Rect2(cx - 80, btn_y, 160, 35), Color(0.5, 0.4, 0.9), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(cx - 55, btn_y + 24), "Enter: 接続", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 1.0))

	# Status message
	if setup._status_message != "":
		var status_y := btn_y + 55
		var status_color := Color(0.3, 1.0, 0.4) if setup._status_ok else Color(1.0, 0.7, 0.3)
		# Wrap long messages
		var lines: PackedStringArray = setup._status_message.split("\n")
		for i in range(lines.size()):
			draw_string(ThemeDB.fallback_font, Vector2(px + 30, status_y + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, status_color)

	# How it works
	var info_y := py + panel_h - 80
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y), "仕組み:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y + 18), "1. ユーザーIDからライブ配信を自動検索", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.45, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y + 34), "2. 配信のコメント欄を2秒間隔で監視開始", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.45, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, info_y + 50), "3. 視聴者のコマンド(!spawn等)がゲームに反映", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.45, 0.55))

	# Close hint
	draw_string(ThemeDB.fallback_font, Vector2(px + 30, py + panel_h - 15), "Escキーで閉じる", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.35, 0.35, 0.4))
