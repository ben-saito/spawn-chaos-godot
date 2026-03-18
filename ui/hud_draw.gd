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

func _draw_hp_bar(player: CharacterBody2D) -> void:
	var x := 4.0
	var y := 4.0
	var w := 60.0
	var h := 6.0
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(x, y + 5), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
	var bar_x := x + 16
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
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + 2, y + 5), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)

func _draw_timer() -> void:
	var sec := GameState.elapsed_seconds()
	var m := int(sec) / 60
	var s := int(sec) % 60
	var text := "%02d:%02d" % [m, s]
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W - 34, 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_points() -> void:
	var text := "PT:%d" % GameState.game_points
	draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W - 44, 19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.9, 0.15))

func _draw_enemy_count() -> void:
	var scene = get_tree().current_scene
	var container = scene.find_child("Enemies") if scene else null
	var count: int = container.get_child_count() if container else 0
	draw_string(ThemeDB.fallback_font, Vector2(4, 20), "ENEMY:%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.6, 0.3))

func _draw_xp_bar(player: CharacterBody2D) -> void:
	var y := Config.SCREEN_H - 6.0
	var w := float(Config.SCREEN_W)
	draw_rect(Rect2(0, y, w, 4), Color(0.15, 0.15, 0.2))
	var ratio: float = float(player.xp) / float(player.xp_to_next) if player.xp_to_next > 0 else 0.0
	draw_rect(Rect2(0, y, w * ratio, 4), Color(0.3, 0.6, 1.0))

func _draw_level(player: CharacterBody2D) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(4, Config.SCREEN_H - 10), "Lv.%d" % player.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)

func _draw_spawn_log() -> void:
	var x := 4.0
	var y := Config.SCREEN_H - 60.0
	for i in range(hud.spawn_log.size()):
		draw_string(ThemeDB.fallback_font, Vector2(x, y + i * 9), hud.spawn_log[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.7, 0.7, 0.7))

func _draw_spawn_guide() -> void:
	var x := Config.SCREEN_W - 62.0
	var y := Config.SCREEN_H - 60.0
	var guides := [
		"1:Slime  10",
		"2:Goblin 20",
		"3:Skel   30",
		"4:Ogre   80",
		"5:Dragon 500",
	]
	for i in range(guides.size()):
		draw_string(ThemeDB.fallback_font, Vector2(x, y + i * 8), guides[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.5, 0.5, 0.6))

func _draw_event_banner() -> void:
	if hud._event_timer > 0 and hud._event_text != "":
		var alpha := minf(hud._event_timer, 1.0)
		var text: String = hud._event_text
		draw_string(ThemeDB.fallback_font, Vector2(Config.SCREEN_W / 2.0 - 40, 30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0, alpha))
