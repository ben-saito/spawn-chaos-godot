extends "res://entities/enemies/enemy_base.gd"
## Wolfpack: orbits player at 50px, then dashes in at 2.5x speed.

const ORBIT_RADIUS := 50.0
const ORBIT_DURATION := 90
const DASH_SPEED_MULT := 2.5
const DASH_DURATION := 20

var _orbit_angle: float = 0.0
var _phase_timer: int = 0
var _dashing: bool = false
var _dash_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	_orbit_angle = randf() * TAU

func _ai_update() -> void:
	_phase_timer += 1
	if _dashing:
		position += _dash_dir * speed * DASH_SPEED_MULT
		if _phase_timer >= DASH_DURATION:
			_dashing = false
			_phase_timer = 0
	else:
		# Orbit around player
		_orbit_angle += 0.05
		if player:
			var target := player.position + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * ORBIT_RADIUS
			var dir := (target - position).normalized()
			position += dir * speed * 1.5
		if _phase_timer >= ORBIT_DURATION:
			_dashing = true
			_phase_timer = 0
			_dash_dir = _get_dir_to_player()

func _draw() -> void:
	var color := Color(0.5, 0.5, 0.55)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	if _dashing:
		color = Color(0.8, 0.3, 0.3)
	var s: float = def_data.size / 2.0 if def_data else 4.0
	# Wolf body
	draw_rect(Rect2(-s, -s * 0.6, s * 2, s * 1.2), color)
	# Head (front)
	draw_rect(Rect2(s - 1, -s * 0.4, 3, s * 0.8), color)
	# Ears
	draw_rect(Rect2(-s, -s, 2, 2), color.lightened(0.2))
	draw_rect(Rect2(s - 2, -s, 2, 2), color.lightened(0.2))
	# Eyes
	draw_rect(Rect2(s, -2, 1, 1), Color(1, 1, 0))
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 4, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 4, bar_w * float(hp) / max_hp, 2), Color.GREEN)
