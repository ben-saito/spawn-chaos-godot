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

func _spawn_effect(pos: Vector3) -> void:
	var effect := LightningEffect.new()
	effect.position = pos
	var scene = get_tree().current_scene
	var container = scene.find_child("Effects") if scene else null
	if container:
		container.add_child(effect)
		_effects.append(effect)


class LightningEffect extends Node3D:
	var _timer: int = 0
	const DURATION := 8
	var _bolt_meshes: Array = []

	func _ready() -> void:
		# Create zigzag bolt from above
		var bolt_mat := StandardMaterial3D.new()
		bolt_mat.albedo_color = Color(1, 1, 0.5)
		bolt_mat.emission_enabled = true
		bolt_mat.emission = Color(1, 1, 0.5)
		bolt_mat.emission_energy_multiplier = 3.0
		bolt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		var current_y := 8.0
		var current_x := 0.0
		var current_z := 0.0
		while current_y > 0.1:
			var next_y := maxf(current_y - randf_range(0.8, 1.5), 0.0)
			var next_x := randf_range(-0.4, 0.4)
			var next_z := randf_range(-0.4, 0.4)
			# Create a thin cylinder/box segment
			var seg := MeshInstance3D.new()
			var box := BoxMesh.new()
			var seg_len := Vector3(next_x - current_x, next_y - current_y, next_z - current_z).length()
			box.size = Vector3(0.06, seg_len, 0.06)
			seg.mesh = box
			seg.material_override = bolt_mat
			# Position at midpoint
			seg.position = Vector3(
				(current_x + next_x) / 2.0,
				(current_y + next_y) / 2.0,
				(current_z + next_z) / 2.0
			)
			add_child(seg)
			# Look at target (must be in tree first)
			var dir := Vector3(next_x - current_x, next_y - current_y, next_z - current_z).normalized()
			if dir.length_squared() > 0.001:
				seg.look_at(seg.global_position + dir, Vector3.RIGHT)
			_bolt_meshes.append(seg)
			current_y = next_y
			current_x = next_x
			current_z = next_z

		# Impact sphere
		var impact := MeshInstance3D.new()
		var impact_sphere := SphereMesh.new()
		impact_sphere.radius = 0.4
		impact_sphere.height = 0.8
		impact.mesh = impact_sphere
		var impact_mat := StandardMaterial3D.new()
		impact_mat.albedo_color = Color(1, 1, 0.8, 0.6)
		impact_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		impact_mat.emission_enabled = true
		impact_mat.emission = Color(1, 1, 0.8)
		impact_mat.emission_energy_multiplier = 2.0
		impact_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		impact.material_override = impact_mat
		impact.position = Vector3(0, 0.2, 0)
		add_child(impact)
		_bolt_meshes.append(impact)

	func _physics_process(_delta: float) -> void:
		_timer += 1
		if _timer >= DURATION:
			queue_free()
			return
		# Fade out
		var alpha := 1.0 - float(_timer) / DURATION
		for mesh in _bolt_meshes:
			if is_instance_valid(mesh) and mesh.material_override:
				mesh.material_override.albedo_color.a = alpha
