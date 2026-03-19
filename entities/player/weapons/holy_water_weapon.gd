extends "res://entities/player/weapons/weapon_base.gd"
## Holy Water – auto-places damage pool at nearest enemy location.

var hw_damage: int = 5
var hw_duration: int = 90
const HW_COOLDOWN := 120
const MAX_POOLS := 2
const POOL_RADIUS := 2.0
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
			var dx: float = player_node.position.x - e.position.x
			var dz: float = player_node.position.z - e.position.z
			var d: float = sqrt(dx * dx + dz * dz)
			if d < nearest_dist:
				nearest_dist = d
				nearest = e

	if nearest:
		_spawn_pool(nearest.position)
		_cooldown_timer = HW_COOLDOWN

func _spawn_pool(pos: Vector3) -> void:
	var pool := HolyWaterPool.new()
	pool.position = Vector3(pos.x, 0.01, pos.z)
	pool.damage = hw_damage
	pool.duration = hw_duration
	pool.radius = POOL_RADIUS
	pool.hit_cooldown = HIT_COOLDOWN
	var scene = get_tree().current_scene
	var container = scene.find_child("Effects") if scene else null
	if container:
		container.add_child(pool)
		_pools.append(pool)


class HolyWaterPool extends Node3D:
	var damage: int = 5
	var duration: int = 90
	var radius: float = 2.0
	var hit_cooldown: int = 15
	var _timer: int = 0
	var _hit_cooldowns: Dictionary = {}
	var _pool_mesh: MeshInstance3D
	var _pool_material: StandardMaterial3D

	func _ready() -> void:
		# Flat cylinder for pool
		_pool_mesh = MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = 0.05
		_pool_mesh.mesh = cyl
		_pool_material = StandardMaterial3D.new()
		_pool_material.albedo_color = Color(0.2, 0.5, 1.0, 0.4)
		_pool_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_pool_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_pool_material.emission_enabled = true
		_pool_material.emission = Color(0.2, 0.5, 1.0)
		_pool_material.emission_energy_multiplier = 0.5
		_pool_mesh.material_override = _pool_material
		add_child(_pool_mesh)

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
					var dx: float = position.x - enemy.position.x
					var dz: float = position.z - enemy.position.z
					if sqrt(dx * dx + dz * dz) < radius:
						enemy.take_damage(damage)
						_hit_cooldowns[eid] = hit_cooldown
		# Fade alpha
		if _pool_material:
			var alpha := 0.4 * (1.0 - float(_timer) / duration)
			_pool_material.albedo_color = Color(0.2, 0.5, 1.0, alpha)
