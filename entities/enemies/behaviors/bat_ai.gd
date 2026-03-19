extends "res://entities/enemies/enemy_base.gd"
## Bat: fast wave motion, sine-wave perpendicular to direction.

var _wave_phase: float = 0.0

var _bat_material: StandardMaterial3D
var _left_wing: MeshInstance3D
var _right_wing: MeshInstance3D
var _body_mesh: MeshInstance3D
var _shadow: MeshInstance3D

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.3
	shadow_cyl.bottom_radius = 0.3
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.25)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Body (dark purple sphere, smaller)
	_body_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	_body_mesh.mesh = sphere
	_bat_material = StandardMaterial3D.new()
	_bat_material.albedo_color = Color(0.3, 0.15, 0.4)
	_bat_material.roughness = 0.5
	_body_mesh.material_override = _bat_material
	_body_mesh.position = Vector3(0, 0.6, 0)
	_mesh_container.add_child(_body_mesh)

	# Fur/chest detail
	var chest := MeshInstance3D.new()
	var chest_sphere := SphereMesh.new()
	chest_sphere.radius = 0.12
	chest_sphere.height = 0.2
	chest.mesh = chest_sphere
	chest.material_override = _create_material(Color(0.35, 0.2, 0.45))
	chest.position = Vector3(0, 0.52, -0.08)
	_mesh_container.add_child(chest)

	# Large ears (triangular cones on top)
	var ear_mat := _create_material(Color(0.35, 0.18, 0.45))
	for x_off in [-0.12, 0.12]:
		var ear := MeshInstance3D.new()
		var ear_cone := CylinderMesh.new()
		ear_cone.top_radius = 0.0
		ear_cone.bottom_radius = 0.06
		ear_cone.height = 0.18
		ear.mesh = ear_cone
		ear.material_override = ear_mat
		ear.position = Vector3(x_off, 0.82, 0)
		if x_off < 0:
			ear.rotation.z = 0.3
		else:
			ear.rotation.z = -0.3
		_mesh_container.add_child(ear)

	# Eyes (red glowing)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 0.2, 0.15)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.15, 0.1)
	eye_mat.emission_energy_multiplier = 2.5
	for x_off in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.04
		eye_sphere.height = 0.08
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 0.63, -0.17)
		_mesh_container.add_child(eye)

	# Small fangs
	var fang_mat := _create_material(Color(0.95, 0.95, 0.9))
	for x_off in [-0.04, 0.04]:
		var fang := MeshInstance3D.new()
		var fang_cone := CylinderMesh.new()
		fang_cone.top_radius = 0.0
		fang_cone.bottom_radius = 0.015
		fang_cone.height = 0.06
		fang.mesh = fang_cone
		fang.material_override = fang_mat
		fang.position = Vector3(x_off, 0.5, -0.15)
		_mesh_container.add_child(fang)

	# Wings (flat boxes that rotate for flapping)
	var wing_mat := StandardMaterial3D.new()
	wing_mat.albedo_color = Color(0.4, 0.2, 0.5)
	wing_mat.roughness = 0.6
	_left_wing = MeshInstance3D.new()
	var wing_box := BoxMesh.new()
	wing_box.size = Vector3(0.5, 0.02, 0.3)
	_left_wing.mesh = wing_box
	_left_wing.material_override = wing_mat
	_left_wing.position = Vector3(-0.35, 0.6, 0)
	_mesh_container.add_child(_left_wing)

	_right_wing = MeshInstance3D.new()
	_right_wing.mesh = wing_box
	_right_wing.material_override = wing_mat
	_right_wing.position = Vector3(0.35, 0.6, 0)
	_mesh_container.add_child(_right_wing)

	# Wing bone structure (darker edge lines)
	var bone_mat := _create_material(Color(0.25, 0.1, 0.35))
	for side in [-1.0, 1.0]:
		var bone := MeshInstance3D.new()
		var bone_box := BoxMesh.new()
		bone_box.size = Vector3(0.48, 0.03, 0.02)
		bone.mesh = bone_box
		bone.material_override = bone_mat
		bone.position = Vector3(side * 0.35, 0.61, 0.13)
		if side < 0:
			_left_wing.add_child(bone)
			bone.position = Vector3(0, 0.005, 0.13)
		else:
			_right_wing.add_child(bone)
			bone.position = Vector3(0, 0.005, 0.13)

func _ai_update() -> void:
	_wave_phase += 0.15
	var dir := _get_dir_to_player()
	var perp := Vector3(-dir.z, 0, dir.x)
	var wave := sin(_wave_phase) * 0.2
	position += dir * speed * 0.15 + perp * wave
	position.y = 0

	# Continuous wing flapping (±30 degrees = ~0.52 radians)
	if _left_wing and _right_wing:
		var flap := sin(_timer * 0.35) * 0.52
		_left_wing.rotation.z = flap
		_right_wing.rotation.z = -flap

	# Slight vertical bobbing on body
	if _body_mesh:
		_body_mesh.position.y = 0.6 + sin(_timer * 0.12) * 0.05

	# Flash on hit
	if _bat_material:
		if _hit_flash_timer > 0:
			_bat_material.albedo_color = Color.WHITE
		else:
			_bat_material.albedo_color = Color(0.3, 0.15, 0.4)
