extends "res://entities/enemies/enemy_base.gd"
## Bat: fast wave motion, sine-wave perpendicular to direction.

var _wave_phase: float = 0.0

func _ai_update() -> void:
	_wave_phase += 0.15
	var dir := _get_dir_to_player()
	var perp := Vector2(-dir.y, dir.x)
	var wave := sin(_wave_phase) * 1.5
	position += dir * speed + perp * wave

func _draw() -> void:
	var color := Color(0.4, 0.2, 0.5)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 3.0
	# Wings flap animation
	var wing_offset := sin(_timer * 0.3) * 3.0
	# Left wing
	draw_line(Vector2(0, 0), Vector2(-s - 3, -wing_offset), color, 2.0)
	# Right wing
	draw_line(Vector2(0, 0), Vector2(s + 3, -wing_offset), color, 2.0)
	# Body
	draw_circle(Vector2.ZERO, s * 0.6, color)
	# Eyes
	draw_rect(Rect2(-2, -1, 1, 1), Color(1, 0.3, 0.3))
	draw_rect(Rect2(1, -1, 1, 1), Color(1, 0.3, 0.3))
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 4, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 4, bar_w * float(hp) / max_hp, 2), Color.GREEN)
