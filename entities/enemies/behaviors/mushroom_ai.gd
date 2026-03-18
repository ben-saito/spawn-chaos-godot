extends "res://entities/enemies/enemy_base.gd"
## Mushroom: slow approach, shoots 4-way spore projectiles when near.

const SPORE_RANGE := 40.0
const SPORE_COOLDOWN := 90
var _spore_timer: int = 0

func _ai_update() -> void:
	var dir := _get_dir_to_player()
	position += dir * speed

	_spore_timer += 1
	if _spore_timer >= SPORE_COOLDOWN and _get_dist_to_player() < SPORE_RANGE:
		_spore_timer = 0
		_shoot_spores()

func _shoot_spores() -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if not container:
		return
	for dir in directions:
		var proj := proj_scene.instantiate()
		proj.setup(position, dir * 1.5, damage / 2, Color(0.5, 0.8, 0.2))
		container.add_child(proj)

func _draw() -> void:
	var color := Color(0.7, 0.5, 0.3)
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var s: float = def_data.size / 2.0 if def_data else 3.5
	# Stem
	draw_rect(Rect2(-1.5, 0, 3, s), Color(0.6, 0.5, 0.3))
	# Cap (top half circle via filled arc approximation)
	draw_circle(Vector2(0, -1), s, color)
	# Spots
	draw_circle(Vector2(-2, -3), 1.0, Color(1, 0.3, 0.3))
	draw_circle(Vector2(2, -2), 1.0, Color(1, 0.3, 0.3))
	# HP bar
	if hp < max_hp and alive:
		var bar_w: float = s * 2
		draw_rect(Rect2(-s, -s - 4, bar_w, 2), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(-s, -s - 4, bar_w * float(hp) / max_hp, 2), Color.GREEN)
