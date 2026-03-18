extends "res://entities/player/weapons/weapon_base.gd"
## Magic Missile – auto-fires homing projectiles at nearest enemy.

var missile_damage: int = 15
var missile_cooldown: int = 40
const MAX_PROJECTILES := 5
const MISSILE_SPEED := 3.0
const MISSILE_LIFETIME := 90

var _missiles: Array = []  # Active missile nodes

func _weapon_update() -> void:
	# Clean up dead missiles
	_missiles = _missiles.filter(func(m): return is_instance_valid(m))

	if _cooldown_timer > 0 or _missiles.size() >= MAX_PROJECTILES:
		return

	var enemies := get_enemies()
	if enemies.is_empty():
		return

	# Find nearest alive enemy
	var player_node := get_player()
	if player_node == null:
		return
	var nearest = null
	var nearest_dist := 9999.0
	for e in enemies:
		if e.has_method("take_damage") and e.alive:
			var d := player_node.position.distance_to(e.position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = e

	if nearest:
		_fire_missile(player_node.position, nearest)
		_cooldown_timer = missile_cooldown

func _fire_missile(from: Vector2, target) -> void:
	var missile := MissileProjectile.new()
	missile.position = from
	missile.target = target
	missile.damage = missile_damage
	missile.speed = MISSILE_SPEED
	missile.lifetime = MISSILE_LIFETIME
	var scene = get_tree().current_scene
	var container = scene.find_child("PlayerProjectiles") if scene else null
	if container:
		container.add_child(missile)
		_missiles.append(missile)


class MissileProjectile extends Node2D:
	var target = null
	var damage: int = 15
	var speed: float = 3.0
	var lifetime: int = 90
	var velocity: Vector2 = Vector2.ZERO
	var _timer: int = 0

	func _physics_process(_delta: float) -> void:
		if GameState.state != GameState.State.PLAY:
			return
		_timer += 1
		if _timer >= lifetime:
			queue_free()
			return
		# Home towards target
		if is_instance_valid(target) and target.alive:
			var dir: Vector2 = (target.position - position).normalized()
			velocity = velocity.lerp(dir * speed, 0.1)
		position += velocity
		# Check screen bounds
		if position.x < -16 or position.x > Config.SCREEN_W + 16 \
			or position.y < -16 or position.y > Config.SCREEN_H + 16:
			queue_free()
			return
		# Hit detection
		if is_instance_valid(target) and target.alive:
			if position.distance_to(target.position) < 6.0:
				target.take_damage(damage)
				queue_free()
				return
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 2.0, Color(0.5, 0.3, 1.0))
		draw_circle(Vector2.ZERO, 1.0, Color(1.0, 1.0, 1.0))
