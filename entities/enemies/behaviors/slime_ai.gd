extends "res://entities/enemies/enemy_base.gd"
## Slime: bouncy hop-and-chase.

var _hop_timer: int = 0
const HOP_INTERVAL := 30

var _slime_mesh: MeshInstance3D
var _slime_material: StandardMaterial3D
var _left_eye_white: MeshInstance3D
var _right_eye_white: MeshInstance3D
var _left_pupil: MeshInstance3D
var _right_pupil: MeshInstance3D
var _shadow: MeshInstance3D

func _setup_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.35
	shadow_cyl.bottom_radius = 0.35
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	_mesh_container.add_child(_shadow)

	# Main slime body - translucent glossy green
	_slime_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	_slime_mesh.mesh = sphere
	_slime_material = StandardMaterial3D.new()
	_slime_material.albedo_color = Color(0.2, 0.9, 0.2, 0.8)
	_slime_material.metallic = 0.3
	_slime_material.roughness = 0.2
	_slime_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_slime_mesh.material_override = _slime_material
	_slime_mesh.position = Vector3(0, 0.35, 0)
	_mesh_container.add_child(_slime_mesh)

	# Specular highlight (small white sphere on top for glossy look)
	var highlight := MeshInstance3D.new()
	var hl_sphere := SphereMesh.new()
	hl_sphere.radius = 0.08
	hl_sphere.height = 0.16
	highlight.mesh = hl_sphere
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1, 1, 1, 0.6)
	hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight.material_override = hl_mat
	highlight.position = Vector3(-0.1, 0.6, -0.15)
	_mesh_container.add_child(highlight)

	# Eyes - white spheres with black pupils
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color.WHITE
	eye_mat.roughness = 0.3

	_left_eye_white = MeshInstance3D.new()
	var eye_sphere := SphereMesh.new()
	eye_sphere.radius = 0.08
	eye_sphere.height = 0.16
	_left_eye_white.mesh = eye_sphere
	_left_eye_white.material_override = eye_mat
	_left_eye_white.position = Vector3(-0.12, 0.5, -0.3)
	_mesh_container.add_child(_left_eye_white)

	_right_eye_white = MeshInstance3D.new()
	_right_eye_white.mesh = eye_sphere
	_right_eye_white.material_override = eye_mat
	_right_eye_white.position = Vector3(0.12, 0.5, -0.3)
	_mesh_container.add_child(_right_eye_white)

	# Pupils
	var pupil_mat := StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.05, 0.05, 0.05)
	var pupil_sphere := SphereMesh.new()
	pupil_sphere.radius = 0.04
	pupil_sphere.height = 0.08

	_left_pupil = MeshInstance3D.new()
	_left_pupil.mesh = pupil_sphere
	_left_pupil.material_override = pupil_mat
	_left_pupil.position = Vector3(-0.12, 0.5, -0.36)
	_mesh_container.add_child(_left_pupil)

	_right_pupil = MeshInstance3D.new()
	_right_pupil.mesh = pupil_sphere
	_right_pupil.material_override = pupil_mat
	_right_pupil.position = Vector3(0.12, 0.5, -0.36)
	_mesh_container.add_child(_right_pupil)

	# Mouth - small spheres in a curved arc
	var mouth_mat := StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.1, 0.5, 0.1)
	for i in range(5):
		var mouth_dot := MeshInstance3D.new()
		var dot_sphere := SphereMesh.new()
		dot_sphere.radius = 0.02
		dot_sphere.height = 0.04
		mouth_dot.mesh = dot_sphere
		mouth_dot.material_override = mouth_mat
		var angle := -0.4 + i * 0.2
		mouth_dot.position = Vector3(sin(angle) * 0.12, 0.35 - cos(angle) * 0.03, -0.35)
		_mesh_container.add_child(mouth_dot)

func _ai_update() -> void:
	_hop_timer += 1
	var dir := _get_dir_to_player()
	# Hop every HOP_INTERVAL frames
	if _hop_timer >= HOP_INTERVAL:
		_hop_timer = 0
	# Only move during "hop" (first 10 frames of cycle)
	if _hop_timer < 10:
		position += dir * speed * 0.15
	# Squash-and-stretch
	if _slime_mesh:
		var stretch := 1.0
		if _hop_timer < 10:
			stretch = 1.0 + 0.3 * sin(_hop_timer * PI / 10.0)
		else:
			# Idle jiggle
			stretch = 1.0 + 0.05 * sin(_timer * 0.15)
		_slime_mesh.scale = Vector3(1.0 / sqrt(stretch), stretch, 1.0 / sqrt(stretch))
	# Flash on hit
	if _slime_material:
		if _hit_flash_timer > 0:
			_slime_material.albedo_color = Color(1, 1, 1, 0.8)
		else:
			_slime_material.albedo_color = Color(0.2, 0.9, 0.2, 0.8)
	position.y = 0
