extends "res://entities/enemies/enemy_base.gd"
## Skeleton: ranged attacker, maintains distance, throws bones.

const PREFERRED_MIN := 5.0
const PREFERRED_MAX := 8.0
const SHOOT_COOLDOWN := 45
var _shoot_timer: int = 0

var _skeleton_material: StandardMaterial3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _throw_arm: MeshInstance3D

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.25
	shadow_cyl.bottom_radius = 0.25
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Body (thin capsule, ivory)
	_body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.15
	capsule.height = 0.6
	_body_mesh.mesh = capsule
	_skeleton_material = StandardMaterial3D.new()
	_skeleton_material.albedo_color = Color(0.9, 0.88, 0.82)
	_skeleton_material.roughness = 0.6
	_body_mesh.material_override = _skeleton_material
	_body_mesh.position = Vector3(0, 0.35, 0)
	_mesh_container.add_child(_body_mesh)

	# Rib cage details (thin horizontal boxes)
	var rib_mat := _create_material(Color(0.82, 0.8, 0.75))
	for i in range(3):
		var rib := MeshInstance3D.new()
		var rib_box := BoxMesh.new()
		rib_box.size = Vector3(0.28, 0.025, 0.15)
		rib.mesh = rib_box
		rib.material_override = rib_mat
		rib.position = Vector3(0, 0.28 + i * 0.08, 0)
		_mesh_container.add_child(rib)

	# Skull head
	_head_mesh = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.18
	head_sphere.height = 0.36
	_head_mesh.mesh = head_sphere
	_head_mesh.material_override = _create_material(Color(0.9, 0.88, 0.82))
	_head_mesh.position = Vector3(0, 0.8, 0)
	_mesh_container.add_child(_head_mesh)

	# Eye sockets (dark, inset)
	var socket_mat := StandardMaterial3D.new()
	socket_mat.albedo_color = Color(0.05, 0.02, 0.02)
	for x_off in [-0.07, 0.07]:
		var socket := MeshInstance3D.new()
		var socket_sphere := SphereMesh.new()
		socket_sphere.radius = 0.05
		socket_sphere.height = 0.1
		socket.mesh = socket_sphere
		socket.material_override = socket_mat
		socket.position = Vector3(x_off, 0.83, -0.13)
		_mesh_container.add_child(socket)

	# Jaw line
	var jaw := MeshInstance3D.new()
	var jaw_box := BoxMesh.new()
	jaw_box.size = Vector3(0.2, 0.04, 0.1)
	jaw.mesh = jaw_box
	jaw.material_override = _create_material(Color(0.85, 0.83, 0.78))
	jaw.position = Vector3(0, 0.67, -0.06)
	_mesh_container.add_child(jaw)

	# Arms (thin bones)
	var arm_mat := _create_material(Color(0.9, 0.88, 0.82))
	# Left arm
	var left_arm := MeshInstance3D.new()
	var arm_cyl := CylinderMesh.new()
	arm_cyl.top_radius = 0.03
	arm_cyl.bottom_radius = 0.03
	arm_cyl.height = 0.35
	left_arm.mesh = arm_cyl
	left_arm.material_override = arm_mat
	left_arm.position = Vector3(-0.22, 0.4, 0)
	_mesh_container.add_child(left_arm)

	# Right arm (throwing arm)
	_throw_arm = MeshInstance3D.new()
	_throw_arm.mesh = arm_cyl
	_throw_arm.material_override = arm_mat
	_throw_arm.position = Vector3(0.22, 0.4, 0)
	_mesh_container.add_child(_throw_arm)

func _ai_update() -> void:
	var dist := _get_dist_to_player()
	var dir := _get_dir_to_player()

	# Maintain preferred distance
	if dist < PREFERRED_MIN:
		position -= dir * speed * 0.15  # retreat
	elif dist > PREFERRED_MAX:
		position += dir * speed * 0.15  # approach
	position.y = 0

	# Rattling animation (random small position jitter)
	if _body_mesh:
		_body_mesh.position.x = (sin(_timer * 0.7) * 0.015)
		_body_mesh.position.z = (cos(_timer * 0.9) * 0.01)

	if _head_mesh:
		_head_mesh.position.x = (sin(_timer * 0.8 + 1.0) * 0.01)

	# Throw motion when shooting
	if _throw_arm:
		if _shoot_timer >= SHOOT_COOLDOWN - 8 and _shoot_timer < SHOOT_COOLDOWN:
			# Wind up and throw
			var throw_phase := float(_shoot_timer - (SHOOT_COOLDOWN - 8)) / 8.0
			_throw_arm.rotation.x = -1.5 * sin(throw_phase * PI)
		else:
			_throw_arm.rotation.x = 0.0

	# Shoot bones
	_shoot_timer += 1
	if _shoot_timer >= SHOOT_COOLDOWN and dist < 12.0:
		_shoot_timer = 0
		_shoot_bone(dir)

	# Flash on hit
	if _skeleton_material:
		if _hit_flash_timer > 0:
			_skeleton_material.albedo_color = Color.WHITE
		else:
			_skeleton_material.albedo_color = Color(0.9, 0.88, 0.82)

func _shoot_bone(dir: Vector3) -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var proj := proj_scene.instantiate()
	proj.setup(position + Vector3(0, 0.3, 0), dir * 0.3, damage / 2, Color(0.9, 0.9, 0.8))
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if container:
		container.add_child(proj)
