extends "res://entities/enemies/enemy_base.gd"
## Wolfpack: orbits player, then dashes in at 2.5x speed.

const ORBIT_RADIUS := 8.0
const ORBIT_DURATION := 90
const DASH_SPEED_MULT := 2.5
const DASH_DURATION := 20

var _orbit_angle: float = 0.0
var _phase_timer: int = 0
var _dashing: bool = false
var _dash_dir: Vector3 = Vector3.ZERO

var _wolf_material: StandardMaterial3D
var _body_node: MeshInstance3D
var _tail: MeshInstance3D
var _shadow: MeshInstance3D

func _ready() -> void:
	_orbit_angle = randf() * TAU

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.4
	shadow_cyl.bottom_radius = 0.4
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Wolf body (gray elongated capsule)
	_body_node = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.18
	capsule.height = 0.7
	_body_node.mesh = capsule
	_wolf_material = StandardMaterial3D.new()
	_wolf_material.albedo_color = Color(0.5, 0.5, 0.55)
	_wolf_material.roughness = 0.7
	_body_node.material_override = _wolf_material
	_body_node.position = Vector3(0, 0.25, 0)
	_body_node.rotation.x = PI / 2.0  # Lay capsule horizontal
	_mesh_container.add_child(_body_node)

	# Belly fur (lighter underside)
	var belly := MeshInstance3D.new()
	var belly_capsule := CapsuleMesh.new()
	belly_capsule.radius = 0.12
	belly_capsule.height = 0.5
	belly.mesh = belly_capsule
	belly.material_override = _create_material(Color(0.65, 0.63, 0.6))
	belly.position = Vector3(0, 0.18, 0)
	belly.rotation.x = PI / 2.0
	_mesh_container.add_child(belly)

	# Head (sphere)
	var head := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.16
	head_sphere.height = 0.32
	head.mesh = head_sphere
	head.material_override = _create_material(Color(0.52, 0.52, 0.57))
	head.position = Vector3(0, 0.32, -0.4)
	_mesh_container.add_child(head)

	# Pointed snout (cone facing forward)
	var snout := MeshInstance3D.new()
	var snout_cone := CylinderMesh.new()
	snout_cone.top_radius = 0.0
	snout_cone.bottom_radius = 0.08
	snout_cone.height = 0.2
	snout.mesh = snout_cone
	snout.material_override = _create_material(Color(0.45, 0.45, 0.5))
	snout.position = Vector3(0, 0.28, -0.55)
	snout.rotation.x = -PI / 2.0  # Point forward
	_mesh_container.add_child(snout)

	# Nose tip (small dark sphere)
	var nose := MeshInstance3D.new()
	var nose_sphere := SphereMesh.new()
	nose_sphere.radius = 0.03
	nose_sphere.height = 0.06
	nose.mesh = nose_sphere
	nose.material_override = _create_material(Color(0.1, 0.08, 0.08))
	nose.position = Vector3(0, 0.28, -0.65)
	_mesh_container.add_child(nose)

	# Ears (two small triangular cones, tilted)
	var ear_mat := _create_material(Color(0.55, 0.55, 0.6))
	for x_off in [-0.1, 0.1]:
		var ear := MeshInstance3D.new()
		var ear_cone := CylinderMesh.new()
		ear_cone.top_radius = 0.0
		ear_cone.bottom_radius = 0.05
		ear_cone.height = 0.14
		ear.mesh = ear_cone
		ear.material_override = ear_mat
		ear.position = Vector3(x_off, 0.48, -0.38)
		if x_off < 0:
			ear.rotation.z = 0.25
		else:
			ear.rotation.z = -0.25
		ear.rotation.x = -0.2
		_mesh_container.add_child(ear)

	# Inner ears (pink tint)
	var inner_ear_mat := _create_material(Color(0.7, 0.5, 0.5))
	for x_off in [-0.1, 0.1]:
		var inner := MeshInstance3D.new()
		var inner_cone := CylinderMesh.new()
		inner_cone.top_radius = 0.0
		inner_cone.bottom_radius = 0.025
		inner_cone.height = 0.08
		inner.mesh = inner_cone
		inner.material_override = inner_ear_mat
		inner.position = Vector3(x_off, 0.47, -0.39)
		if x_off < 0:
			inner.rotation.z = 0.25
		else:
			inner.rotation.z = -0.25
		inner.rotation.x = -0.2
		_mesh_container.add_child(inner)

	# Eyes (yellow glowing with emission)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 0.95, 0.2)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.9, 0.1)
	eye_mat.emission_energy_multiplier = 2.0
	for x_off in [-0.07, 0.07]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.035
		eye_sphere.height = 0.07
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 0.36, -0.52)
		_mesh_container.add_child(eye)

	# Pupils (small dark slits)
	var pupil_mat := _create_material(Color(0.05, 0.05, 0.05))
	for x_off in [-0.07, 0.07]:
		var pupil := MeshInstance3D.new()
		var pupil_box := BoxMesh.new()
		pupil_box.size = Vector3(0.015, 0.04, 0.01)
		pupil.mesh = pupil_box
		pupil.material_override = pupil_mat
		pupil.position = Vector3(x_off, 0.36, -0.555)
		_mesh_container.add_child(pupil)

	# Legs (4 small cylinders)
	var leg_mat := _create_material(Color(0.48, 0.48, 0.53))
	var leg_positions := [
		Vector3(-0.12, 0.08, -0.18),
		Vector3(0.12, 0.08, -0.18),
		Vector3(-0.12, 0.08, 0.18),
		Vector3(0.12, 0.08, 0.18),
	]
	for lp in leg_positions:
		var leg := MeshInstance3D.new()
		var leg_cyl := CylinderMesh.new()
		leg_cyl.top_radius = 0.04
		leg_cyl.bottom_radius = 0.035
		leg_cyl.height = 0.16
		leg.mesh = leg_cyl
		leg.material_override = leg_mat
		leg.position = lp
		_mesh_container.add_child(leg)

	# Tail (small cylinder at back, angled)
	_tail = MeshInstance3D.new()
	var tail_cyl := CylinderMesh.new()
	tail_cyl.top_radius = 0.02
	tail_cyl.bottom_radius = 0.04
	tail_cyl.height = 0.22
	_tail.mesh = tail_cyl
	_tail.material_override = _create_material(Color(0.52, 0.52, 0.57))
	_tail.position = Vector3(0, 0.35, 0.38)
	_tail.rotation.x = -0.6  # Angled upward
	_mesh_container.add_child(_tail)

	# Tail tip (lighter)
	var tail_tip := MeshInstance3D.new()
	var tip_sphere := SphereMesh.new()
	tip_sphere.radius = 0.03
	tip_sphere.height = 0.06
	tail_tip.mesh = tip_sphere
	tail_tip.material_override = _create_material(Color(0.7, 0.7, 0.72))
	tail_tip.position = Vector3(0, 0.1, 0)
	_tail.add_child(tail_tip)

func _ai_update() -> void:
	_phase_timer += 1
	if _dashing:
		position += _dash_dir * speed * DASH_SPEED_MULT * 0.15
		if _phase_timer >= DASH_DURATION:
			_dashing = false
			_phase_timer = 0
	else:
		# Orbit around player
		_orbit_angle += 0.05
		if player:
			var target := Vector3(
				player.position.x + cos(_orbit_angle) * ORBIT_RADIUS,
				0,
				player.position.z + sin(_orbit_angle) * ORBIT_RADIUS
			)
			var dir := (target - position)
			dir.y = 0
			if dir.length_squared() > 0.0001:
				dir = dir.normalized()
			position += dir * speed * 1.5 * 0.15
		if _phase_timer >= ORBIT_DURATION:
			_dashing = true
			_phase_timer = 0
			_dash_dir = _get_dir_to_player()
	position.y = 0

	# Running gallop: body tilts forward when dashing
	if _dashing:
		_mesh_container.rotation.x = -0.2
	else:
		_mesh_container.rotation.x = 0.0

	# Tail wag when orbiting (not dashing)
	if _tail:
		if not _dashing:
			_tail.rotation.z = sin(_timer * 0.3) * 0.5
		else:
			_tail.rotation.z = 0.0  # Tail straight when dashing

	# Flash on hit / dash color
	if _wolf_material:
		if _hit_flash_timer > 0:
			_wolf_material.albedo_color = Color.WHITE
		elif _dashing:
			_wolf_material.albedo_color = Color(0.8, 0.3, 0.3)
		else:
			_wolf_material.albedo_color = Color(0.5, 0.5, 0.55)
