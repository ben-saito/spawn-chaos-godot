extends "res://entities/enemies/enemy_base.gd"
## Skeleton: ranged attacker, maintains 30-50px distance, throws bones.

const PREFERRED_MIN := 30.0
const PREFERRED_MAX := 50.0
const SHOOT_COOLDOWN := 45
var _shoot_timer: int = 0

func _ai_update() -> void:
	var dist := _get_dist_to_player()
	var dir := _get_dir_to_player()

	# Maintain preferred distance
	if dist < PREFERRED_MIN:
		position -= dir * speed  # retreat
	elif dist > PREFERRED_MAX:
		position += dir * speed  # approach
	# else hold position

	# Shoot bones
	_shoot_timer += 1
	if _shoot_timer >= SHOOT_COOLDOWN and dist < 80:
		_shoot_timer = 0
		_shoot_bone(dir)

func _shoot_bone(dir: Vector2) -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var proj := proj_scene.instantiate()
	proj.setup(position, dir * 2.5, damage / 2, Color(0.9, 0.9, 0.8))
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if container:
		container.add_child(proj)

func _draw() -> void:
	var color := Color(0.85, 0.85, 0.8)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 4.0
	# Body (slightly tall)
	draw_rect(Rect2(-s * 0.6, -s, s * 1.2, s * 2), color)
	# Head (circle)
	draw_circle(Vector2(0, -s - 2), 3.0, color)
	# Eyes (dark)
	draw_rect(Rect2(-2, -s - 3, 1, 1), Color(0, 0, 0))
	draw_rect(Rect2(1, -s - 3, 1, 1), Color(0, 0, 0))
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 8, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 8, bar_w * float(hp) / max_hp, 2), Color.GREEN)
