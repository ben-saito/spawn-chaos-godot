extends "res://entities/player/weapons/weapon_base.gd"
## Lightning Strike – auto-targets random enemy with lightning bolt.

var lightning_damage: int = 40
var lightning_cooldown: int = 75
const MAX_EFFECTS := 6

var _effects: Array = []

func _weapon_update() -> void:
	_effects = _effects.filter(func(e): return is_instance_valid(e))

	if _cooldown_timer > 0 or _effects.size() >= MAX_EFFECTS:
		return

	var enemies := get_enemies()
	var alive_enemies: Array = []
	for e in enemies:
		if e.has_method("take_damage") and e.alive:
			alive_enemies.append(e)
	if alive_enemies.is_empty():
		return

	# Pick random enemy
	var target = alive_enemies[randi() % alive_enemies.size()]
	target.take_damage(lightning_damage)
	_spawn_effect(target.position)
	_cooldown_timer = lightning_cooldown

func _spawn_effect(pos: Vector2) -> void:
	var effect := LightningEffect.new()
	effect.position = pos
	var scene = get_tree().current_scene
	var container = scene.find_child("Effects") if scene else null
	if container:
		container.add_child(effect)
		_effects.append(effect)


class LightningEffect extends Node2D:
	var _timer: int = 0
	const DURATION := 8
	var _segments: Array = []

	func _ready() -> void:
		# Generate zigzag segments
		var y := position.y
		var segments_arr: Array = []
		var current_y := -40.0
		while current_y < 0:
			var next_y := current_y + randf_range(4, 8)
			var offset_x := randf_range(-4, 4)
			segments_arr.append({"from": Vector2(offset_x, current_y), "to": Vector2(randf_range(-4, 4), next_y)})
			current_y = next_y
		_segments = segments_arr

	func _physics_process(_delta: float) -> void:
		_timer += 1
		if _timer >= DURATION:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var alpha := 1.0 - float(_timer) / DURATION
		for seg in _segments:
			draw_line(seg["from"], seg["to"], Color(1, 1, 0.5, alpha), 2.0)
			draw_line(seg["from"] + Vector2(1, 0), seg["to"] + Vector2(1, 0), Color(1, 1, 1, alpha * 0.5), 1.0)
		# Impact circle
		draw_circle(Vector2.ZERO, 4.0 * alpha, Color(1, 1, 0.8, alpha * 0.4))
