extends "res://entities/enemies/enemy_base.gd"
## Goblin: zigzag approach with knife swing animation.

var _zigzag_dir: float = 1.0
const ZIGZAG_INTERVAL := 20

func _ai_update() -> void:
	if _timer % ZIGZAG_INTERVAL == 0:
		_zigzag_dir *= -1.0
	var dir := _get_dir_to_player()
	var perp := Vector2(-dir.y, dir.x) * _zigzag_dir
	position += (dir + perp * 0.5) * speed

func _draw() -> void:
	var color := Color(0.6, 0.3, 0.1)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 3.5
	# Body
	draw_rect(Rect2(-s, -s, s * 2, s * 2), color)
	# Ears (triangles via small rects)
	draw_rect(Rect2(-s - 1, -s - 2, 2, 2), color)
	draw_rect(Rect2(s - 1, -s - 2, 2, 2), color)
	# Eyes (red)
	draw_rect(Rect2(-2, -1, 2, 2), Color(1, 0, 0))
	draw_rect(Rect2(1, -1, 2, 2), Color(1, 0, 0))
	# Knife swing
	if _timer % 30 < 10:
		var knife_angle := (_timer % 30) * PI / 20.0
		var knife_end := Vector2(cos(knife_angle), sin(knife_angle)) * (s + 4)
		draw_line(Vector2.ZERO, knife_end, Color(0.8, 0.8, 0.8), 1.0)
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 4, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 4, bar_w * float(hp) / max_hp, 2), Color.GREEN)
