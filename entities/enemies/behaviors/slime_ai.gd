extends "res://entities/enemies/enemy_base.gd"
## Slime: bouncy hop-and-chase.

var _hop_timer: int = 0
const HOP_INTERVAL := 30

func _ai_update() -> void:
	_hop_timer += 1
	var dir := _get_dir_to_player()
	# Hop every HOP_INTERVAL frames
	if _hop_timer >= HOP_INTERVAL:
		_hop_timer = 0
	# Only move during "hop" (first 10 frames of cycle)
	if _hop_timer < 10:
		position += dir * speed

func _draw() -> void:
	var color := Color(0.2, 0.9, 0.2)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 3.0
	# Squash-and-stretch based on hop
	var stretch := 1.0
	if _hop_timer < 10:
		stretch = 1.0 + 0.3 * sin(_hop_timer * PI / 10.0)
	var w: float = s * 2.0 / stretch
	var h: float = s * 2.0 * stretch
	draw_rect(Rect2(-w / 2, -h / 2, w, h), color)
	# Eyes
	draw_rect(Rect2(-2, -2, 2, 2), Color.WHITE)
	draw_rect(Rect2(1, -2, 2, 2), Color.WHITE)
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 4, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 4, bar_w * float(hp) / max_hp, 2), Color.GREEN)
