extends "res://entities/enemies/enemy_base.gd"
## Ogre: approaches player, charges at 3x speed when within range.

const CHARGE_RANGE := 8.0
const CHARGE_SPEED_MULT := 3.0
const CHARGE_DURATION := 15

var _charging: bool = false
var _charge_timer: int = 0
var _charge_dir: Vector3 = Vector3.ZERO

var _ogre_material: StandardMaterial3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _left_arm: MeshInstance3D
var _right_arm: MeshInstance3D
var _shadow: MeshInstance3D

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.5
	shadow_cyl.bottom_radius = 0.5
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Large body (wide, muscular feel)
	_body_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.9, 0.6)
	_body_mesh.mesh = box
	_ogre_material = StandardMaterial3D.new()
	_ogre_material.albedo_color = Color(0.45, 0.5, 0.25)
	_ogre_material.roughness = 0.8
	_body_mesh.material_override = _ogre_material
	_body_mesh.position = Vector3(0, 0.45, 0)
	_mesh_container.add_child(_body_mesh)

	# Belt detail
	var belt := MeshInstance3D.new()
	var belt_box := BoxMesh.new()
	belt_box.size = Vector3(0.82, 0.1, 0.62)
	belt.mesh = belt_box
	belt.material_override = _create_material(Color(0.4, 0.25, 0.1))
	belt.position = Vector3(0, 0.15, 0)
	_mesh_container.add_child(belt)

	# Small head relative to body (angry face)
	_head_mesh = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.2
	head_sphere.height = 0.4
	_head_mesh.mesh = head_sphere
	_head_mesh.material_override = _create_material(Color(0.45, 0.5, 0.25))
	_head_mesh.position = Vector3(0, 1.05, 0)
	_mesh_container.add_child(_head_mesh)

	# Furrowed brow (thick dark bar above eyes)
	var brow := MeshInstance3D.new()
	var brow_box := BoxMesh.new()
	brow_box.size = Vector3(0.3, 0.05, 0.08)
	brow.mesh = brow_box
	brow.material_override = _create_material(Color(0.3, 0.35, 0.15))
	brow.position = Vector3(0, 1.12, -0.15)
	brow.rotation.x = -0.2
	_mesh_container.add_child(brow)

	# Two horns (cones pointing up)
	var horn_mat := StandardMaterial3D.new()
	horn_mat.albedo_color = Color(0.7, 0.65, 0.5)
	horn_mat.roughness = 0.4
	for x_off in [-0.12, 0.12]:
		var horn := MeshInstance3D.new()
		var horn_cone := CylinderMesh.new()
		horn_cone.top_radius = 0.0
		horn_cone.bottom_radius = 0.05
		horn_cone.height = 0.2
		horn.mesh = horn_cone
		horn.material_override = horn_mat
		horn.position = Vector3(x_off, 1.28, 0)
		if x_off < 0:
			horn.rotation.z = 0.2
		else:
			horn.rotation.z = -0.2
		_mesh_container.add_child(horn)

	# Eyes (angry red)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 0.15, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.1, 0.05)
	eye_mat.emission_energy_multiplier = 1.5
	for x_off in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.04
		eye_sphere.height = 0.08
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 1.08, -0.17)
		_mesh_container.add_child(eye)

	# Thick arms (cylinders at sides)
	var arm_mat := _create_material(Color(0.45, 0.5, 0.25))
	_left_arm = MeshInstance3D.new()
	var arm_cyl := CylinderMesh.new()
	arm_cyl.top_radius = 0.1
	arm_cyl.bottom_radius = 0.12
	arm_cyl.height = 0.6
	_left_arm.mesh = arm_cyl
	_left_arm.material_override = arm_mat
	_left_arm.position = Vector3(-0.55, 0.45, 0)
	_mesh_container.add_child(_left_arm)

	_right_arm = MeshInstance3D.new()
	_right_arm.mesh = arm_cyl
	_right_arm.material_override = arm_mat
	_right_arm.position = Vector3(0.55, 0.45, 0)
	_mesh_container.add_child(_right_arm)

	# Fists (spheres at bottom of arms)
	var fist_mat := _create_material(Color(0.5, 0.55, 0.3))
	for x_off in [-0.55, 0.55]:
		var fist := MeshInstance3D.new()
		var fist_sphere := SphereMesh.new()
		fist_sphere.radius = 0.08
		fist_sphere.height = 0.16
		fist.mesh = fist_sphere
		fist.material_override = fist_mat
		fist.position = Vector3(x_off, 0.15, 0)
		_mesh_container.add_child(fist)

func _ai_update() -> void:
	if _charging:
		_charge_timer += 1
		position += _charge_dir * speed * CHARGE_SPEED_MULT * 0.15
		if _charge_timer >= CHARGE_DURATION:
			_charging = false
			_charge_timer = 0
	else:
		var dist := _get_dist_to_player()
		var dir := _get_dir_to_player()
		if dist < CHARGE_RANGE:
			_charging = true
			_charge_timer = 0
			_charge_dir = dir
		else:
			position += dir * speed * 0.15
	position.y = 0

	# Chest breathing (scale.z oscillates slightly)
	if _body_mesh:
		_body_mesh.scale.z = 1.0 + sin(_timer * 0.08) * 0.05

	# Charge wind-up: lean back then rush forward
	if _charging:
		if _charge_timer < 3:
			_mesh_container.rotation.x = 0.15  # lean back
		else:
			_mesh_container.rotation.x = -0.1  # lean forward
	else:
		_mesh_container.rotation.x = 0.0

	# Flash on hit / charge color with red glow
	if _ogre_material:
		if _hit_flash_timer > 0:
			_ogre_material.albedo_color = Color.WHITE
			_ogre_material.emission_enabled = false
		elif _charging:
			_ogre_material.albedo_color = Color(0.6, 0.4, 0.2)
			_ogre_material.emission_enabled = true
			_ogre_material.emission = Color(0.8, 0.2, 0.1)
			_ogre_material.emission_energy_multiplier = 0.8
		else:
			_ogre_material.albedo_color = Color(0.45, 0.5, 0.25)
			_ogre_material.emission_enabled = false
