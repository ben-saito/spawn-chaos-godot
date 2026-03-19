extends "res://entities/enemies/enemy_base.gd"
## Mushroom: slow approach, shoots 4-way spore projectiles when near.

const SPORE_RANGE := 6.0
const SPORE_COOLDOWN := 90
var _spore_timer: int = 0

var _cap_material: StandardMaterial3D
var _cap_mesh: MeshInstance3D
var _stem_mesh: MeshInstance3D
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
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Stem (cream/brown cylinder)
	_stem_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.14
	cyl.height = 0.4
	_stem_mesh.mesh = cyl
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.85, 0.78, 0.6)
	stem_mat.roughness = 0.8
	_stem_mesh.material_override = stem_mat
	_stem_mesh.position = Vector3(0, 0.2, 0)
	_mesh_container.add_child(_stem_mesh)

	# Cap (large red dome - sphere with bottom half hidden in stem)
	_cap_mesh = MeshInstance3D.new()
	var cap_sphere := SphereMesh.new()
	cap_sphere.radius = 0.38
	cap_sphere.height = 0.55
	_cap_mesh.mesh = cap_sphere
	_cap_material = StandardMaterial3D.new()
	_cap_material.albedo_color = Color(0.85, 0.2, 0.15)
	_cap_material.roughness = 0.5
	_cap_material.metallic = 0.1
	_cap_mesh.material_override = _cap_material
	_cap_mesh.position = Vector3(0, 0.52, 0)
	_mesh_container.add_child(_cap_mesh)

	# White spots on cap
	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.95, 0.95, 0.9)
	spot_mat.roughness = 0.4
	var spot_positions := [
		Vector3(-0.18, 0.68, -0.2),
		Vector3(0.15, 0.72, -0.18),
		Vector3(0.0, 0.75, 0.2),
		Vector3(-0.22, 0.6, 0.15),
		Vector3(0.2, 0.6, 0.1),
	]
	for sp in spot_positions:
		var spot := MeshInstance3D.new()
		var spot_sphere := SphereMesh.new()
		spot_sphere.radius = 0.055
		spot_sphere.height = 0.11
		spot.mesh = spot_sphere
		spot.material_override = spot_mat
		spot.position = sp
		_mesh_container.add_child(spot)

	# Cute sleepy eyes (thin dark rectangles - half-closed look)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.15, 0.1, 0.08)
	for x_off in [-0.1, 0.1]:
		var eye := MeshInstance3D.new()
		var eye_box := BoxMesh.new()
		eye_box.size = Vector3(0.08, 0.025, 0.02)
		eye.mesh = eye_box
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 0.42, -0.12)
		_mesh_container.add_child(eye)

	# Small rosy cheeks
	var cheek_mat := StandardMaterial3D.new()
	cheek_mat.albedo_color = Color(0.95, 0.55, 0.5, 0.6)
	cheek_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for x_off in [-0.14, 0.14]:
		var cheek := MeshInstance3D.new()
		var cheek_sphere := SphereMesh.new()
		cheek_sphere.radius = 0.04
		cheek_sphere.height = 0.04
		cheek.mesh = cheek_sphere
		cheek.material_override = cheek_mat
		cheek.position = Vector3(x_off, 0.38, -0.1)
		_mesh_container.add_child(cheek)

func _ai_update() -> void:
	var dir := _get_dir_to_player()
	position += dir * speed * 0.15
	position.y = 0

	_spore_timer += 1
	if _spore_timer >= SPORE_COOLDOWN and _get_dist_to_player() < SPORE_RANGE:
		_spore_timer = 0
		_shoot_spores()

	# Gentle swaying (rotation.z oscillates ±5 degrees = ~0.087 radians)
	if _mesh_container:
		_mesh_container.rotation.z = sin(_timer * 0.06) * 0.087

	# Cap wobble (independent slight motion)
	if _cap_mesh:
		_cap_mesh.rotation.z = sin(_timer * 0.1 + 0.5) * 0.05
		_cap_mesh.rotation.x = cos(_timer * 0.08) * 0.03

	# Flash on hit
	if _cap_material:
		if _hit_flash_timer > 0:
			_cap_material.albedo_color = Color.WHITE
		else:
			_cap_material.albedo_color = Color(0.85, 0.2, 0.15)

func _shoot_spores() -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var directions := [
		Vector3(0, 0, -1),  # forward
		Vector3(0, 0, 1),   # back
		Vector3(-1, 0, 0),  # left
		Vector3(1, 0, 0),   # right
	]
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if not container:
		return
	for d in directions:
		var proj := proj_scene.instantiate()
		proj.setup(position + Vector3(0, 0.3, 0), d * 0.18, damage / 2, Color(0.5, 0.8, 0.2))
		container.add_child(proj)
