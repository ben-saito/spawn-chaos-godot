extends Node2D
## Minimap showing player and enemies.

const MAP_SIZE := 160.0  # minimap pixel size
const MAP_MARGIN := 20.0
const MAP_ALPHA := 0.8

func _process(_delta: float) -> void:
	if GameState.state == GameState.State.PLAY:
		queue_redraw()

func _draw() -> void:
	if GameState.state != GameState.State.PLAY:
		return

	var scene = get_tree().current_scene
	if scene == null:
		return

	var map_x := Config.SCREEN_W - MAP_SIZE - MAP_MARGIN
	var map_y := MAP_MARGIN + 70  # below timer/points

	# Background
	draw_rect(Rect2(map_x - 2, map_y - 2, MAP_SIZE + 4, MAP_SIZE + 4), Color(0.3, 0.35, 0.25, MAP_ALPHA), false, 2.0)
	draw_rect(Rect2(map_x, map_y, MAP_SIZE, MAP_SIZE), Color(0.08, 0.12, 0.08, MAP_ALPHA * 0.85))

	# Scale factors
	var sx := MAP_SIZE / Config.WORLD_W
	var sz := MAP_SIZE / Config.WORLD_H

	# Draw paths (brown lines)
	draw_rect(Rect2(map_x + MAP_SIZE * 0.1, map_y + MAP_SIZE / 2.0 - 1, MAP_SIZE * 0.8, 2), Color(0.3, 0.2, 0.1, 0.4))
	draw_rect(Rect2(map_x + MAP_SIZE / 2.0 - 1, map_y + MAP_SIZE * 0.1, 2, MAP_SIZE * 0.8), Color(0.3, 0.2, 0.1, 0.4))

	# Draw enemies (red dots)
	var enemies = scene.find_child("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			var ex: float = map_x + enemy.position.x * sx
			var ez: float = map_y + enemy.position.z * sz
			draw_circle(Vector2(ex, ez), 1.5, Color(1, 0.2, 0.2, 0.7))

	# Draw player (bright green dot, larger)
	var player = scene.find_child("Player")
	if player:
		var px: float = map_x + player.position.x * sx
		var pz: float = map_y + player.position.z * sz
		draw_circle(Vector2(px, pz), 3.5, Color(0.2, 1.0, 0.3))
		draw_circle(Vector2(px, pz), 2.0, Color(1, 1, 1, 0.8))

	# Border frame
	draw_rect(Rect2(map_x, map_y, MAP_SIZE, MAP_SIZE), Color(0.5, 0.55, 0.4, MAP_ALPHA), false, 1.5)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(map_x, map_y - 4), "MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.65, 0.5))
