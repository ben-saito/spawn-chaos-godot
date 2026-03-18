extends "res://entities/player/weapons/weapon_base.gd"
## Holy Water – auto-places damage pool at nearest enemy location.

var hw_damage: int = 5
var hw_duration: int = 90
const HW_COOLDOWN := 120
const MAX_POOLS := 2
const POOL_RADIUS := 12.0
const HIT_COOLDOWN := 15

var _pools: Array = []

func _weapon_update() -> void:
	_pools = _pools.filter(func(p): return is_instance_valid(p))

	if _cooldown_timer > 0 or _pools.size() >= MAX_POOLS:
		return

	var player_node := get_player()
	if player_node == null:
		return

	# Find nearest enemy
	var enemies := get_enemies()
	var nearest = null
	var nearest_dist := 9999.0
	for e in enemies:
		if e.has_method("take_damage") and e.alive:
			var d := player_node.position.distance_to(e.position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = e

	if nearest:
		_spawn_pool(nearest.position)
		_cooldown_timer = HW_COOLDOWN

func _spawn_pool(pos: Vector2) -> void:
	var pool := HolyWaterPool.new()
	pool.position = pos
	pool.damage = hw_damage
	pool.duration = hw_duration
	pool.radius = POOL_RADIUS
	pool.hit_cooldown = HIT_COOLDOWN
	var scene = get_tree().current_scene
	var container = scene.find_child("Effects") if scene else null
	if container:
		container.add_child(pool)
		_pools.append(pool)


class HolyWaterPool extends Node2D:
	var damage: int = 5
	var duration: int = 90
	var radius: float = 12.0
	var hit_cooldown: int = 15
	var _timer: int = 0
	var _hit_cooldowns: Dictionary = {}

	func _physics_process(_delta: float) -> void:
		if GameState.state != GameState.State.PLAY:
			return
		_timer += 1
		if _timer >= duration:
			queue_free()
			return
		# Tick cooldowns
		var to_remove := []
		for eid in _hit_cooldowns:
			_hit_cooldowns[eid] -= 1
			if _hit_cooldowns[eid] <= 0:
				to_remove.append(eid)
		for eid in to_remove:
			_hit_cooldowns.erase(eid)
		# Damage enemies in radius
		var hw_scene = get_tree().current_scene
		var enemies_node = hw_scene.find_child("Enemies") if hw_scene else null
		if enemies_node:
			for enemy in enemies_node.get_children():
				if enemy.has_method("take_damage") and enemy.alive:
					var eid := enemy.get_instance_id()
					if _hit_cooldowns.has(eid):
						continue
					if position.distance_to(enemy.position) < radius:
						enemy.take_damage(damage)
						_hit_cooldowns[eid] = hit_cooldown
		queue_redraw()

	func _draw() -> void:
		var alpha := 0.4 * (1.0 - float(_timer) / duration)
		draw_circle(Vector2.ZERO, radius, Color(0.2, 0.5, 1.0, alpha))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(0.4, 0.7, 1.0, alpha * 1.5), 1.0)
		# Bubbling effect
		for i in range(3):
			var angle := (_timer * 0.1 + i * TAU / 3.0)
			var bubble_pos := Vector2(cos(angle), sin(angle)) * radius * 0.5
			draw_circle(bubble_pos, 1.5, Color(0.6, 0.8, 1.0, alpha * 2.0))
