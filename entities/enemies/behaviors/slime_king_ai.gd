extends "res://entities/enemies/enemy_base.gd"
## Slime King: large, slow, shoots 4-way slime balls. Splits into 3 slimes on death.

const SHOOT_COOLDOWN := 90
var _shoot_timer: int = 0

var _king_material: StandardMaterial3D
var _king_mesh: MeshInstance3D
var _crown_base: MeshInstance3D
var _sparkle_left: MeshInstance3D
var _sparkle_right: MeshInstance3D
var _shadow: MeshInstance3D

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.6
	shadow_cyl.bottom_radius = 0.6
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Large slime body (translucent green)
	_king_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.7
	sphere.height = 1.2
	_king_mesh.mesh = sphere
	_king_material = StandardMaterial3D.new()
	_king_material.albedo_color = Color(0.15, 0.8, 0.15, 0.8)
	_king_material.metallic = 0.3
	_king_material.roughness = 0.2
	_king_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_king_mesh.material_override = _king_material
	_king_mesh.position = Vector3(0, 0.55, 0)
	_mesh_container.add_child(_king_mesh)

	# Specular highlight
	var highlight := MeshInstance3D.new()
	var hl_sphere := SphereMesh.new()
	hl_sphere.radius = 0.12
	hl_sphere.height = 0.24
	highlight.mesh = hl_sphere
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1, 1, 1, 0.5)
	hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight.material_override = hl_mat
	highlight.position = Vector3(-0.2, 0.9, -0.25)
	_mesh_container.add_child(highlight)

	# Golden crown base (cylinder)
	_crown_base = MeshInstance3D.new()
	var crown_cyl := CylinderMesh.new()
	crown_cyl.top_radius = 0.28
	crown_cyl.bottom_radius = 0.32
	crown_cyl.height = 0.15
	_crown_base.mesh = crown_cyl
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color(1, 0.85, 0.0)
	crown_mat.metallic = 0.7
	crown_mat.roughness = 0.3
	_crown_base.material_override = crown_mat
	_crown_base.position = Vector3(0, 1.2, 0)
	_mesh_container.add_child(_crown_base)

	# Crown tips (3 triangular cone points)
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(1, 0.85, 0.0)
	tip_mat.metallic = 0.7
	tip_mat.roughness = 0.3
	for x_off in [-0.18, 0.0, 0.18]:
		var tip := MeshInstance3D.new()
		var tip_cone := CylinderMesh.new()
		tip_cone.top_radius = 0.0
		tip_cone.bottom_radius = 0.06
		tip_cone.height = 0.15
		tip.mesh = tip_cone
		tip.material_override = tip_mat
		tip.position = Vector3(x_off, 1.35, 0)
		_mesh_container.add_child(tip)

	# Crown jewel (red sphere in center)
	var jewel := MeshInstance3D.new()
	var jewel_sphere := SphereMesh.new()
	jewel_sphere.radius = 0.04
	jewel_sphere.height = 0.08
	jewel.mesh = jewel_sphere
	var jewel_mat := StandardMaterial3D.new()
	jewel_mat.albedo_color = Color(0.9, 0.1, 0.15)
	jewel_mat.emission_enabled = true
	jewel_mat.emission = Color(0.8, 0.1, 0.1)
	jewel_mat.emission_energy_multiplier = 1.5
	jewel.material_override = jewel_mat
	jewel.position = Vector3(0, 1.22, -0.28)
	_mesh_container.add_child(jewel)

	# Royal eyes (larger than regular slime)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color.WHITE
	eye_mat.roughness = 0.3
	for x_off in [-0.2, 0.2]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.1
		eye_sphere.height = 0.2
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 0.7, -0.55)
		_mesh_container.add_child(eye)

	# Large pupils
	var pupil_mat := _create_material(Color(0.05, 0.05, 0.05))
	for x_off in [-0.2, 0.2]:
		var pupil := MeshInstance3D.new()
		var pupil_sphere := SphereMesh.new()
		pupil_sphere.radius = 0.055
		pupil_sphere.height = 0.11
		pupil.mesh = pupil_sphere
		pupil.material_override = pupil_mat
		pupil.position = Vector3(x_off, 0.7, -0.62)
		_mesh_container.add_child(pupil)

	# Eye sparkle (small white emissive spheres near eyes)
	var sparkle_mat := StandardMaterial3D.new()
	sparkle_mat.albedo_color = Color.WHITE
	sparkle_mat.emission_enabled = true
	sparkle_mat.emission = Color.WHITE
	sparkle_mat.emission_energy_multiplier = 2.0

	_sparkle_left = MeshInstance3D.new()
	var sparkle_sphere := SphereMesh.new()
	sparkle_sphere.radius = 0.025
	sparkle_sphere.height = 0.05
	_sparkle_left.mesh = sparkle_sphere
	_sparkle_left.material_override = sparkle_mat
	_sparkle_left.position = Vector3(-0.23, 0.75, -0.63)
	_mesh_container.add_child(_sparkle_left)

	_sparkle_right = MeshInstance3D.new()
	_sparkle_right.mesh = sparkle_sphere
	_sparkle_right.material_override = sparkle_mat
	_sparkle_right.position = Vector3(0.17, 0.75, -0.63)
	_mesh_container.add_child(_sparkle_right)

	# Mouth (curved arc of small spheres)
	var mouth_mat := _create_material(Color(0.1, 0.5, 0.1))
	for i in range(7):
		var dot := MeshInstance3D.new()
		var dot_sphere := SphereMesh.new()
		dot_sphere.radius = 0.02
		dot_sphere.height = 0.04
		dot.mesh = dot_sphere
		dot.material_override = mouth_mat
		var angle := -0.5 + i * 0.17
		dot.position = Vector3(sin(angle) * 0.18, 0.48 - cos(angle) * 0.04, -0.58)
		_mesh_container.add_child(dot)

func _ai_update() -> void:
	var dir := _get_dir_to_player()
	position += dir * speed * 0.15
	position.y = 0

	_shoot_timer += 1
	if _shoot_timer >= SHOOT_COOLDOWN:
		_shoot_timer = 0
		_shoot_slime_balls()

	# Pulsating size (scale oscillates 0.95-1.05)
	if _king_mesh:
		var pulse := 1.0 + sin(_timer * 0.06) * 0.05
		_king_mesh.scale = Vector3(pulse, pulse, pulse)

	# Majestic slow wobble
	if _mesh_container:
		_mesh_container.rotation.z = sin(_timer * 0.04) * 0.04

	# Crown bobs independently
	if _crown_base:
		_crown_base.position.y = 1.2 + sin(_timer * 0.1 + 0.5) * 0.03

	# Sparkle animation (blink on/off)
	if _sparkle_left:
		_sparkle_left.visible = (int(_timer / 10) % 2 == 0)
	if _sparkle_right:
		_sparkle_right.visible = (int(_timer / 10) % 2 == 0)

	# Flash on hit
	if _king_material:
		if _hit_flash_timer > 0:
			_king_material.albedo_color = Color(1, 1, 1, 0.8)
		else:
			_king_material.albedo_color = Color(0.15, 0.8, 0.15, 0.8)

func _shoot_slime_balls() -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var directions := [
		Vector3(0, 0, -1),
		Vector3(0, 0, 1),
		Vector3(-1, 0, 0),
		Vector3(1, 0, 0),
	]
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if not container:
		return
	for d in directions:
		var proj := proj_scene.instantiate()
		proj.setup(position + Vector3(0, 0.3, 0), d * 0.25, damage / 2, Color(0.1, 0.7, 0.1))
		container.add_child(proj)
