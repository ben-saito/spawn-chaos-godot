extends Node2D
## Actual drawing node for HUD (child of CanvasLayer).

@onready var hud: CanvasLayer = get_parent()

func _draw() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var player = scene.find_child("Player")
	if player == null:
		return

	_draw_hp_bar(player)
	_draw_timer()
	_draw_points()
	_draw_enemy_count()
	_draw_xp_bar(player)
	_draw_level(player)
	_draw_spawn_log()
	_draw_spawn_guide()
	_draw_event_banner()
	_draw_combo()

func _draw_hp_bar(player) -> void:
	var x := 20.0
	var y := 16.0
	var w := 200.0
	var h := 18.0
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(x, y + 14), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	var bar_x := x + 40
	# Background
	draw_rect(Rect2(bar_x, y, w, h), Color(0.2, 0.2, 0.2))
	# Fill
	var ratio := float(player.hp) / float(player.max_hp)
	var bar_color := Color(0, 0.85, 0.2)
	if ratio < 0.25:
		bar_color = Color(1, 0, 0.3)
	elif ratio < 0.5:
		bar_color = Color(1, 0.9, 0.15)
	draw_rect(Rect2(bar_x, y, w * ratio, h), bar_color)
	# Text
	var hp_text := "%d/%d" % [player.hp, player.max_hp]
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + 6, y + 14), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_timer() -> void:
	var sec := GameState.elapsed_seconds()
	var m := int(sec) / 60
	var s := int(sec) % 60
	var text := "%02d:%02d" % [m, s]
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W - 100, 28), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

func _draw_points() -> void:
	var text := "PT:%d" % GameState.game_points
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W - 150, 56), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.15))

func _draw_enemy_count() -> void:
	var scene = get_tree().current_scene
	var container = scene.find_child("Enemies") if scene else null
	var count: int = container.get_child_count() if container else 0
	draw_string(ThemeDB.fallback_font, Vector2(20, 56), "敵数:%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.6, 0.3))

func _draw_xp_bar(player) -> void:
	var y := Config.SCREEN_H - 16.0
	var w := float(Config.SCREEN_W)
	draw_rect(Rect2(0, y, w, 10), Color(0.15, 0.15, 0.2))
	var ratio: float = float(player.xp) / float(player.xp_to_next) if player.xp_to_next > 0 else 0.0
	draw_rect(Rect2(0, y, w * ratio, 10), Color(0.3, 0.6, 1.0))

func _draw_level(player) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(20, Config.SCREEN_H - 28), "Lv.%d" % player.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func _draw_spawn_log() -> void:
	var x := 20.0
	var y := Config.SCREEN_H - 180.0
	for i in range(hud.spawn_log.size()):
		draw_string(ThemeDB.fallback_font, Vector2(x, y + i * 22), hud.spawn_log[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.7))

func _draw_spawn_guide() -> void:
	var x := Config.SCREEN_W - 200.0
	var y := Config.SCREEN_H - 180.0
	var guides := [
		"1:スライム  10",
		"2:ゴブリン  20",
		"3:スケルトン 30",
		"4:オーガ    80",
		"5:ドラゴン  500",
	]
	for i in range(guides.size()):
		draw_string(ThemeDB.fallback_font, Vector2(x, y + i * 20), guides[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.6))

func _draw_event_banner() -> void:
	if hud._event_timer > 0 and hud._event_text != "":
		var alpha := minf(hud._event_timer, 1.0)
		var text: String = hud._event_text
		# Background box for better readability
		var tw := text.length() * 14
		draw_rect(Rect2(Config.SCREEN_W / 2.0 - tw / 2.0 - 10, 55, tw + 20, 35), Color(0, 0, 0, 0.5 * alpha))
		draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - tw / 2.0, 80), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 0, alpha))

func _draw_combo() -> void:
	if GameState.combo_count >= 3:
		var combo_text := "%d コンボ! x%.1f" % [GameState.combo_count, GameState.combo_multiplier]
		var pulse := 1.0 + sin(GameState.elapsed_frames * 0.2) * 0.1
		var font_size := int(24 * pulse)
		var color := Color(1, 0.5, 0) if GameState.combo_count < 10 else Color(1, 0.2, 0.2)
		if GameState.combo_count >= 20:
			color = Color(1, 0, 1)  # Purple for insane combos
		draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 80, 120), combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
