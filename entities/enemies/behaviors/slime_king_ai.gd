extends "res://entities/enemies/enemy_base.gd"
## Slime King: large, slow, shoots 4-way slime balls. Splits into 3 slimes on death.

const SHOOT_COOLDOWN := 90
var _shoot_timer: int = 0

func _ai_update() -> void:
	var dir := _get_dir_to_player()
	position += dir * speed

	_shoot_timer += 1
	if _shoot_timer >= SHOOT_COOLDOWN:
		_shoot_timer = 0
		_shoot_slime_balls()

func _shoot_slime_balls() -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if not container:
		return
	for dir in directions:
		var proj := proj_scene.instantiate()
		proj.setup(position, dir * 2.0, damage / 2, Color(0.1, 0.7, 0.1))
		container.add_child(proj)

func _draw() -> void:
	var color := Color(0.1, 0.75, 0.1)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 7.0
	# Large body with crown effect
	draw_circle(Vector2.ZERO, s, color)
	# Crown
	draw_rect(Rect2(-4, -s - 3, 8, 3), Color(1, 0.85, 0.0))
	draw_rect(Rect2(-3, -s - 5, 2, 2), Color(1, 0.85, 0.0))
	draw_rect(Rect2(1, -s - 5, 2, 2), Color(1, 0.85, 0.0))
	# Eyes
	draw_rect(Rect2(-3, -2, 2, 2), Color.WHITE)
	draw_rect(Rect2(2, -2, 2, 2), Color.WHITE)
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 8, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 8, bar_w * float(hp) / max_hp, 2), Color.GREEN)
