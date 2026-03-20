extends "res://entities/player/weapons/weapon_base.gd"
## Magic Missile – auto-fires homing projectiles at nearest enemy.

var missile_damage: int = 15
var missile_cooldown: int = 40
const MAX_PROJECTILES := 5
const MISSILE_SPEED := 0.4
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
			var dx: float = player_node.position.x - e.position.x
			var dz: float = player_node.position.z - e.position.z
			var d: float = sqrt(dx * dx + dz * dz)
			if d < nearest_dist:
				nearest_dist = d
				nearest = e

	if nearest:
		_fire_missile(player_node.position, nearest)
		_cooldown_timer = missile_cooldown

func _fire_missile(from: Vector3, target) -> void:
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


class MissileProjectile extends Node3D:
	var target = null
	var damage: int = 15
	var speed: float = 0.4
	var lifetime: int = 90
	var velocity: Vector3 = Vector3.ZERO
	var _timer: int = 0
	var _mesh: MeshInstance3D

	func _ready() -> void:
		_mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		_mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.3, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.3, 1.0)
		mat.emission_energy_multiplier = 1.0
		_mesh.material_override = mat
		add_child(_mesh)
		# Inner glow
		var inner := MeshInstance3D.new()
		var inner_sphere := SphereMesh.new()
		inner_sphere.radius = 0.08
		inner_sphere.height = 0.16
		inner.mesh = inner_sphere
		var inner_mat := StandardMaterial3D.new()
		inner_mat.albedo_color = Color(1.0, 1.0, 1.0)
		inner_mat.emission_enabled = true
		inner_mat.emission = Color.WHITE
		inner_mat.emission_energy_multiplier = 2.0
		inner.material_override = inner_mat
		add_child(inner)

	func _physics_process(_delta: float) -> void:
		if GameState.state != GameState.State.PLAY:
			return
		_timer += 1
		if _timer >= lifetime:
			queue_free()
			return
		# Home towards target
		if is_instance_valid(target) and target.alive:
			var dir := Vector3(target.position.x - position.x, 0, target.position.z - position.z)
			if dir.length_squared() > 0.0001:
				dir = dir.normalized()
			velocity = velocity.lerp(dir * speed, 0.1)
		var old_pos := position
		position += velocity
		position.y = 0.3  # Float above ground
		# Raycast for obstacle collision
		var space := get_world_3d().direct_space_state
		if space:
			var query := PhysicsRayQueryParameters3D.create(old_pos, position)
			query.collision_mask = 1
			var hit := space.intersect_ray(query)
			if not hit.is_empty():
				queue_free()
				return
		# Check world bounds
		if position.x < -2 or position.x > Config.WORLD_W + 2 \
			or position.z < -2 or position.z > Config.WORLD_H + 2:
			queue_free()
			return
		# Hit detection
		if is_instance_valid(target) and target.alive:
			var dx: float = position.x - target.position.x
			var dz: float = position.z - target.position.z
			if sqrt(dx * dx + dz * dz) < 0.6:
				target.take_damage(damage)
				queue_free()
				return
