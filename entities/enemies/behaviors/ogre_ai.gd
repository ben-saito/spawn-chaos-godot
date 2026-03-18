extends "res://entities/enemies/enemy_base.gd"
## Ogre: approaches player, charges at 3x speed when within 60px.

const CHARGE_RANGE := 60.0
const CHARGE_SPEED_MULT := 3.0
const CHARGE_DURATION := 15

var _charging: bool = false
var _charge_timer: int = 0
var _charge_dir: Vector2 = Vector2.ZERO

func _ai_update() -> void:
	if _charging:
		_charge_timer += 1
		position += _charge_dir * speed * CHARGE_SPEED_MULT
		if _charge_timer >= CHARGE_DURATION:
			_charging = false
			_charge_timer = 0
	else:
		var dist := _get_dist_to_player()
		var dir := _get_dir_to_player()
		if dist < CHARGE_RANGE:
			_charging = true
			_charge_timer = 0
			_charge_dir = dir
		else:
			position += dir * speed

func _draw() -> void:
	var color := Color(0.5, 0.35, 0.2)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	if _charging:
		color = color.lightened(0.3)
	var s: float = def_data.size / 2.0 if def_data else 5.0
	# Large body
	draw_rect(Rect2(-s, -s, s * 2, s * 2), color)
	# Thick arms
	draw_rect(Rect2(-s - 2, -2, 2, 4), color)
	draw_rect(Rect2(s, -2, 2, 4), color)
	# Eyes
	draw_rect(Rect2(-3, -3, 2, 2), Color(1, 0, 0))
	draw_rect(Rect2(1, -3, 2, 2), Color(1, 0, 0))
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 4, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 4, bar_w * float(hp) / max_hp, 2), Color.GREEN)
