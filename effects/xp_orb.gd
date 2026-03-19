extends Node3D
## XP orb that floats from dead enemy toward player, then grants XP.

var _mesh: MeshInstance3D
var _material: StandardMaterial3D
var xp_amount: int = 10
var _age: float = 0.0
var _phase: int = 0  # 0=float up, 1=seek player
var _velocity: Vector3
var _player: CharacterBody3D

func setup(pos: Vector3, amount: int, player_ref: CharacterBody3D) -> void:
	position = pos + Vector3(randf_range(-0.5, 0.5), 0.3, randf_range(-0.5, 0.5))
	xp_amount = amount
	_player = player_ref
	_velocity = Vector3(randf_range(-1, 1), 2.5, randf_range(-1, 1))

	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	_mesh.mesh = sphere
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.3, 0.7, 1.0)
	_material.emission_enabled = true
	_material.emission = Color(0.2, 0.5, 1.0)
	_material.emission_energy_multiplier = 3.0
	_mesh.material_override = _material
	add_child(_mesh)

func _process(delta: float) -> void:
	_age += delta
	if _phase == 0:
		# Float up briefly
		position += _velocity * delta
		_velocity.y -= 6.0 * delta
		if _age > 0.3:
			_phase = 1
	elif _phase == 1:
		# Seek player
		if _player and is_instance_valid(_player):
			var dir := (_player.position + Vector3(0, 0.5, 0) - position)
			var dist := dir.length()
			if dist < 0.5:
				# Collected!
				_player.add_xp(xp_amount)
				queue_free()
				return
			dir = dir.normalized()
			var seek_speed := 15.0 * (_age - 0.3)  # Accelerate over time
			position += dir * minf(seek_speed, 25.0) * delta
		else:
			queue_free()
			return
	# Timeout safety
	if _age > 5.0:
		if _player and is_instance_valid(_player):
			_player.add_xp(xp_amount)
		queue_free()

	# Pulse glow
	if _material:
		var pulse := 1.0 + sin(_age * 12.0) * 0.3
		_material.emission_energy_multiplier = 2.0 * pulse
	if _mesh:
		var s := 0.8 + sin(_age * 10.0) * 0.2
		_mesh.scale = Vector3(s, s, s)
