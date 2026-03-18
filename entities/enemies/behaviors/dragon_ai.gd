extends "res://entities/enemies/enemy_base.gd"
## Dragon: maintains 50-80px distance, fires 3-way fireballs.

const PREFERRED_MIN := 50.0
const PREFERRED_MAX := 80.0
const SHOOT_COOLDOWN := 50
var _shoot_timer: int = 0

func _ai_update() -> void:
	var dist := _get_dist_to_player()
	var dir := _get_dir_to_player()

	# Maintain preferred distance
	if dist < PREFERRED_MIN:
		position -= dir * speed  # retreat
	elif dist > PREFERRED_MAX:
		position += dir * speed  # approach

	# Fire 3-way fireballs
	_shoot_timer += 1
	if _shoot_timer >= SHOOT_COOLDOWN:
		_shoot_timer = 0
		_shoot_fireballs(dir)

func _shoot_fireballs(base_dir: Vector2) -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if not container:
		return
	var spread := 0.3  # radians
	for offset in [-spread, 0.0, spread]:
		var dir := base_dir.rotated(offset)
		var proj := proj_scene.instantiate()
		proj.setup(position, dir * 3.0, damage / 2, Color(1, 0.4, 0.0))
		container.add_child(proj)

func _draw() -> void:
	var color := Color(0.8, 0.15, 0.1)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 6.0
	# Body
	draw_rect(Rect2(-s, -s * 0.7, s * 2, s * 1.4), color)
	# Wings
	var wing_y := sin(_timer * 0.15) * 3.0
	draw_line(Vector2(-s, 0), Vector2(-s - 5, -wing_y - 4), color.lightened(0.2), 2.0)
	draw_line(Vector2(s, 0), Vector2(s + 5, -wing_y - 4), color.lightened(0.2), 2.0)
	# Head
	draw_circle(Vector2(0, -s), 3.0, color)
	# Eyes
	draw_rect(Rect2(-2, -s - 1, 1, 1), Color(1, 0.9, 0))
	draw_rect(Rect2(1, -s - 1, 1, 1), Color(1, 0.9, 0))
	# Fire breath indicator when shooting soon
	if _shoot_timer > SHOOT_COOLDOWN - 10:
		draw_circle(Vector2(0, -s - 4), 2.0, Color(1, 0.5, 0, 0.7))
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 8, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 8, bar_w * float(hp) / max_hp, 2), Color.GREEN)
