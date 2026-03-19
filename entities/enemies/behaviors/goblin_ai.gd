extends "res://entities/enemies/enemy_base.gd"
## Goblin: zigzag approach with knife swing animation.

var _zigzag_dir: float = 1.0
const ZIGZAG_INTERVAL := 20

var _goblin_material: StandardMaterial3D
var _body_mesh: MeshInstance3D
var _dagger: MeshInstance3D
var _left_ear: MeshInstance3D
var _right_ear: MeshInstance3D
var _shadow: MeshInstance3D
var _dagger_swing: float = 0.0

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.3
	shadow_cyl.bottom_radius = 0.3
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Body (capsule with green-brown skin)
	_body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.55
	_body_mesh.mesh = capsule
	_goblin_material = StandardMaterial3D.new()
	_goblin_material.albedo_color = Color(0.45, 0.65, 0.3)
	_goblin_material.roughness = 0.7
	_body_mesh.material_override = _goblin_material
	_body_mesh.position = Vector3(0, 0.3, 0)
	_mesh_container.add_child(_body_mesh)

	# Leather vest overlay
	var vest := MeshInstance3D.new()
	var vest_box := BoxMesh.new()
	vest_box.size = Vector3(0.32, 0.3, 0.2)
	vest.mesh = vest_box
	var vest_mat := StandardMaterial3D.new()
	vest_mat.albedo_color = Color(0.45, 0.28, 0.12)
	vest_mat.roughness = 0.8
	vest.material_override = vest_mat
	vest.position = Vector3(0, 0.35, 0)
	_mesh_container.add_child(vest)

	# Head (green skin)
	var head := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.18
	head_sphere.height = 0.36
	head.mesh = head_sphere
	head.material_override = _create_material(Color(0.45, 0.65, 0.3))
	head.position = Vector3(0, 0.75, 0)
	_mesh_container.add_child(head)

	# Pointy ears (cones)
	var ear_mat := _create_material(Color(0.45, 0.65, 0.3))
	_left_ear = MeshInstance3D.new()
	var ear_cone := CylinderMesh.new()
	ear_cone.top_radius = 0.0
	ear_cone.bottom_radius = 0.05
	ear_cone.height = 0.18
	_left_ear.mesh = ear_cone
	_left_ear.material_override = ear_mat
	_left_ear.position = Vector3(-0.2, 0.85, 0)
	_left_ear.rotation.z = 0.7
	_mesh_container.add_child(_left_ear)

	_right_ear = MeshInstance3D.new()
	_right_ear.mesh = ear_cone
	_right_ear.material_override = ear_mat
	_right_ear.position = Vector3(0.2, 0.85, 0)
	_right_ear.rotation.z = -0.7
	_mesh_container.add_child(_right_ear)

	# Eyes (red glowing)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 0.1, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.2, 0.1)
	eye_mat.emission_energy_multiplier = 2.0
	for x_off in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.04
		eye_sphere.height = 0.08
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 0.78, -0.15)
		_mesh_container.add_child(eye)

	# Dagger (elongated silver box)
	_dagger = MeshInstance3D.new()
	var dagger_box := BoxMesh.new()
	dagger_box.size = Vector3(0.04, 0.25, 0.04)
	_dagger.mesh = dagger_box
	var dagger_mat := StandardMaterial3D.new()
	dagger_mat.albedo_color = Color(0.8, 0.82, 0.85)
	dagger_mat.metallic = 0.8
	dagger_mat.roughness = 0.2
	_dagger.material_override = dagger_mat
	_dagger.position = Vector3(0.35, 0.35, -0.1)
	_mesh_container.add_child(_dagger)

	# Dagger handle
	var handle := MeshInstance3D.new()
	var handle_box := BoxMesh.new()
	handle_box.size = Vector3(0.06, 0.08, 0.06)
	handle.mesh = handle_box
	handle.material_override = _create_material(Color(0.35, 0.2, 0.1))
	handle.position = Vector3(0.35, 0.2, -0.1)
	_mesh_container.add_child(handle)

func _ai_update() -> void:
	if _timer % ZIGZAG_INTERVAL == 0:
		_zigzag_dir *= -1.0
	var dir := _get_dir_to_player()
	var perp := Vector3(-dir.z, 0, dir.x) * _zigzag_dir
	position += (dir + perp * 0.5) * speed * 0.15
	position.y = 0

	# Running lean - tilt body forward when moving
	if _body_mesh:
		_body_mesh.rotation.x = -0.15

	# Dagger swing animation every 30 frames
	if _dagger:
		_dagger_swing += 1.0
		if int(_dagger_swing) % 30 < 8:
			_dagger.rotation.z = sin(_dagger_swing * 0.5) * 1.2
		else:
			_dagger.rotation.z = 0.0

	# Flash on hit
	if _goblin_material:
		if _hit_flash_timer > 0:
			_goblin_material.albedo_color = Color.WHITE
		else:
			_goblin_material.albedo_color = Color(0.45, 0.65, 0.3)
