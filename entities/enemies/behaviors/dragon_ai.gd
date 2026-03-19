extends "res://entities/enemies/enemy_base.gd"
## Dragon: maintains distance, fires 3-way fireballs.

const PREFERRED_MIN := 8.0
const PREFERRED_MAX := 12.0
const SHOOT_COOLDOWN := 50
var _shoot_timer: int = 0

var _dragon_material: StandardMaterial3D
var _left_wing: MeshInstance3D
var _right_wing: MeshInstance3D
var _head_mesh: MeshInstance3D
var _mouth_fire: MeshInstance3D
var _mouth_fire_mat: StandardMaterial3D
var _tail_segments: Array[MeshInstance3D] = []
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

	# Body (large capsule, red/crimson)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.0
	body.mesh = capsule
	_dragon_material = StandardMaterial3D.new()
	_dragon_material.albedo_color = Color(0.8, 0.15, 0.1)
	_dragon_material.roughness = 0.6
	_dragon_material.metallic = 0.15
	body.material_override = _dragon_material
	body.position = Vector3(0, 0.5, 0)
	_mesh_container.add_child(body)

	# Belly scales (lighter underbelly)
	var belly := MeshInstance3D.new()
	var belly_box := BoxMesh.new()
	belly_box.size = Vector3(0.5, 0.6, 0.3)
	belly.mesh = belly_box
	var belly_mat := _create_material(Color(0.9, 0.6, 0.3))
	belly_mat.roughness = 0.7
	belly.material_override = belly_mat
	belly.position = Vector3(0, 0.4, -0.12)
	_mesh_container.add_child(belly)

	# Neck (cylinder connecting body to head)
	var neck := MeshInstance3D.new()
	var neck_cyl := CylinderMesh.new()
	neck_cyl.top_radius = 0.12
	neck_cyl.bottom_radius = 0.18
	neck_cyl.height = 0.35
	neck.mesh = neck_cyl
	neck.material_override = _create_material(Color(0.8, 0.15, 0.1))
	neck.position = Vector3(0, 1.05, -0.1)
	neck.rotation.x = 0.2  # Slight forward tilt
	_mesh_container.add_child(neck)

	# Head (sphere with detail)
	_head_mesh = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.25
	head_sphere.height = 0.5
	_head_mesh.mesh = head_sphere
	_head_mesh.material_override = _create_material(Color(0.8, 0.15, 0.1))
	_head_mesh.position = Vector3(0, 1.3, -0.18)
	_mesh_container.add_child(_head_mesh)

	# Snout (elongated forward)
	var snout := MeshInstance3D.new()
	var snout_box := BoxMesh.new()
	snout_box.size = Vector3(0.18, 0.12, 0.2)
	snout.mesh = snout_box
	snout.material_override = _create_material(Color(0.75, 0.12, 0.08))
	snout.position = Vector3(0, 1.25, -0.38)
	_mesh_container.add_child(snout)

	# Nostrils (small dark spheres)
	var nostril_mat := _create_material(Color(0.2, 0.05, 0.05))
	for x_off in [-0.04, 0.04]:
		var nostril := MeshInstance3D.new()
		var nostril_sphere := SphereMesh.new()
		nostril_sphere.radius = 0.02
		nostril_sphere.height = 0.04
		nostril.mesh = nostril_sphere
		nostril.material_override = nostril_mat
		nostril.position = Vector3(x_off, 1.26, -0.48)
		_mesh_container.add_child(nostril)

	# Horn cones on head
	var horn_mat := StandardMaterial3D.new()
	horn_mat.albedo_color = Color(0.7, 0.6, 0.4)
	horn_mat.roughness = 0.4
	horn_mat.metallic = 0.2
	for x_off in [-0.12, 0.12]:
		var horn := MeshInstance3D.new()
		var horn_cone := CylinderMesh.new()
		horn_cone.top_radius = 0.0
		horn_cone.bottom_radius = 0.05
		horn_cone.height = 0.22
		horn.mesh = horn_cone
		horn.material_override = horn_mat
		horn.position = Vector3(x_off, 1.5, -0.05)
		if x_off < 0:
			horn.rotation.z = 0.25
		else:
			horn.rotation.z = -0.25
		horn.rotation.x = 0.3
		_mesh_container.add_child(horn)

	# Eyes (yellow glowing)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 0.9, 0.0)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.85, 0.0)
	eye_mat.emission_energy_multiplier = 2.0
	for x_off in [-0.1, 0.1]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.05
		eye_sphere.height = 0.1
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 1.35, -0.35)
		_mesh_container.add_child(eye)

	# Pupils (slit pupils)
	var pupil_mat := _create_material(Color(0.05, 0.02, 0.02))
	for x_off in [-0.1, 0.1]:
		var pupil := MeshInstance3D.new()
		var pupil_box := BoxMesh.new()
		pupil_box.size = Vector3(0.015, 0.06, 0.01)
		pupil.mesh = pupil_box
		pupil.material_override = pupil_mat
		pupil.position = Vector3(x_off, 1.35, -0.4)
		_mesh_container.add_child(pupil)

	# Mouth fire glow (appears before shooting)
	_mouth_fire = MeshInstance3D.new()
	var fire_sphere := SphereMesh.new()
	fire_sphere.radius = 0.08
	fire_sphere.height = 0.16
	_mouth_fire.mesh = fire_sphere
	_mouth_fire_mat = StandardMaterial3D.new()
	_mouth_fire_mat.albedo_color = Color(1, 0.6, 0.0)
	_mouth_fire_mat.emission_enabled = true
	_mouth_fire_mat.emission = Color(1, 0.5, 0.0)
	_mouth_fire_mat.emission_energy_multiplier = 3.0
	_mouth_fire.material_override = _mouth_fire_mat
	_mouth_fire.position = Vector3(0, 1.22, -0.48)
	_mouth_fire.visible = false
	_mesh_container.add_child(_mouth_fire)

	# Wings (large flat boxes with bone structure)
	var wing_mat := StandardMaterial3D.new()
	wing_mat.albedo_color = Color(0.85, 0.2, 0.12)
	wing_mat.roughness = 0.6

	_left_wing = MeshInstance3D.new()
	var wing_box := BoxMesh.new()
	wing_box.size = Vector3(0.9, 0.03, 0.55)
	_left_wing.mesh = wing_box
	_left_wing.material_override = wing_mat
	_left_wing.position = Vector3(-0.75, 0.75, 0)
	_mesh_container.add_child(_left_wing)

	_right_wing = MeshInstance3D.new()
	_right_wing.mesh = wing_box
	_right_wing.material_override = wing_mat
	_right_wing.position = Vector3(0.75, 0.75, 0)
	_mesh_container.add_child(_right_wing)

	# Wing bone structure (darker colored edges)
	var bone_mat := _create_material(Color(0.5, 0.08, 0.05))
	for wing_node in [_left_wing, _right_wing]:
		# Main bone
		var main_bone := MeshInstance3D.new()
		var main_bone_box := BoxMesh.new()
		main_bone_box.size = Vector3(0.88, 0.04, 0.03)
		main_bone.mesh = main_bone_box
		main_bone.material_override = bone_mat
		main_bone.position = Vector3(0, 0.01, 0.25)
		wing_node.add_child(main_bone)
		# Secondary bones (finger-like)
		for i in range(3):
			var finger := MeshInstance3D.new()
			var finger_box := BoxMesh.new()
			finger_box.size = Vector3(0.03, 0.035, 0.5)
			finger.mesh = finger_box
			finger.material_override = bone_mat
			finger.position = Vector3(-0.3 + i * 0.3, 0.01, 0.0)
			wing_node.add_child(finger)

	# Wing membrane tips (small triangles at edges)
	var membrane_mat := _create_material(Color(0.9, 0.25, 0.15))
	for side in [-1.0, 1.0]:
		var tip := MeshInstance3D.new()
		var tip_cone := CylinderMesh.new()
		tip_cone.top_radius = 0.0
		tip_cone.bottom_radius = 0.15
		tip_cone.height = 0.1
		tip.mesh = tip_cone
		tip.material_override = membrane_mat
		if side < 0:
			tip.position = Vector3(-0.42, 0.0, -0.2)
			_left_wing.add_child(tip)
		else:
			tip.position = Vector3(0.42, 0.0, -0.2)
			_right_wing.add_child(tip)

	# Tail (chain of 3 small spheres trailing behind)
	var tail_mat := _create_material(Color(0.75, 0.12, 0.08))
	var tail_sizes := [0.15, 0.11, 0.07]
	for i in range(3):
		var segment := MeshInstance3D.new()
		var seg_sphere := SphereMesh.new()
		seg_sphere.radius = tail_sizes[i]
		seg_sphere.height = tail_sizes[i] * 2.0
		segment.mesh = seg_sphere
		segment.material_override = tail_mat
		segment.position = Vector3(0, 0.3 - i * 0.06, 0.5 + i * 0.28)
		_mesh_container.add_child(segment)
		_tail_segments.append(segment)

	# Tail spike (small cone at the end)
	var spike := MeshInstance3D.new()
	var spike_cone := CylinderMesh.new()
	spike_cone.top_radius = 0.0
	spike_cone.bottom_radius = 0.04
	spike_cone.height = 0.12
	spike.mesh = spike_cone
	spike.material_override = _create_material(Color(0.5, 0.08, 0.05))
	spike.position = Vector3(0, 0.15, 1.15)
	spike.rotation.x = -PI / 2.0  # Point backward
	_mesh_container.add_child(spike)

var _windup_phase: bool = false  # True during breath windup

func _ai_update() -> void:
	var dist := _get_dist_to_player()
	var dir := _get_dir_to_player()

	# Maintain preferred distance
	if dist < PREFERRED_MIN:
		position -= dir * speed * 0.15  # retreat
	elif dist > PREFERRED_MAX:
		position += dir * speed * 0.15  # approach
	position.y = 0

	# Face the player (rotate mesh_container around Y axis)
	if _mesh_container and dir.length_squared() > 0.001:
		var target_angle := atan2(-dir.x, -dir.z)
		# Smoothly interpolate rotation
		var current := _mesh_container.rotation.y
		var diff := fmod(target_angle - current + PI, TAU) - PI
		_mesh_container.rotation.y += diff * 0.1

	# Wing flap (slower, more majestic)
	if _left_wing and _right_wing:
		var flap := sin(_timer * 0.1) * 0.3
		_left_wing.rotation.z = flap
		_right_wing.rotation.z = -flap

	# Tail sway animation
	for i in range(_tail_segments.size()):
		var seg := _tail_segments[i]
		var sway_offset := float(i) * 0.4
		seg.position.x = sin(_timer * 0.08 + sway_offset) * 0.1 * (i + 1)

	# Fire breath windup and shooting
	_shoot_timer += 1
	var windup_start := SHOOT_COOLDOWN - 20  # 20 frames of windup

	if _shoot_timer >= windup_start and _shoot_timer < SHOOT_COOLDOWN:
		_windup_phase = true
		var windup_progress := float(_shoot_timer - windup_start) / 20.0  # 0.0 -> 1.0

		# Head rears back then thrusts forward
		if _head_mesh:
			if windup_progress < 0.6:
				# Rear back: head tilts up
				var rear := windup_progress / 0.6
				_head_mesh.position.y = 1.3 + rear * 0.2
				_head_mesh.rotation.x = rear * 0.4
			else:
				# Thrust forward: head lunges down
				var thrust := (windup_progress - 0.6) / 0.4
				_head_mesh.position.y = 1.5 - thrust * 0.25
				_head_mesh.rotation.x = 0.4 - thrust * 0.6

		# Mouth fire grows during windup
		if _mouth_fire:
			_mouth_fire.visible = true
			var fire_scale := 0.3 + windup_progress * 1.2
			_mouth_fire.scale = Vector3(fire_scale, fire_scale, fire_scale)
			# Fire glow color shifts from orange to bright yellow
			if _mouth_fire_mat:
				var glow := 2.0 + windup_progress * 5.0
				_mouth_fire_mat.emission_energy_multiplier = glow
				_mouth_fire_mat.emission = Color(1, 0.5 + windup_progress * 0.4, windup_progress * 0.3)

		# Body tenses up (slight scale increase)
		if _mesh_container:
			_mesh_container.scale.y = 1.0 + windup_progress * 0.08

	elif _shoot_timer >= SHOOT_COOLDOWN:
		# FIRE!
		_shoot_timer = 0
		_shoot_fireballs(dir)
		_windup_phase = false

		# Reset head position
		if _head_mesh:
			_head_mesh.position.y = 1.3
			_head_mesh.rotation.x = 0.0
		if _mouth_fire:
			_mouth_fire.visible = false
		if _mesh_container:
			_mesh_container.scale.y = 1.0
	else:
		_windup_phase = false
		# Idle: mouth fire hidden, head normal
		if _mouth_fire:
			_mouth_fire.visible = false
		if _head_mesh:
			# Gentle idle head bob
			_head_mesh.position.y = 1.3 + sin(_timer * 0.06) * 0.02
			_head_mesh.rotation.x = 0.0
		if _mesh_container:
			_mesh_container.scale.y = 1.0

	# Flash on hit
	if _dragon_material:
		if _hit_flash_timer > 0:
			_dragon_material.albedo_color = Color.WHITE
		else:
			_dragon_material.albedo_color = Color(0.8, 0.15, 0.1)

func _shoot_fireballs(base_dir: Vector3) -> void:
	var proj_scene := preload("res://entities/enemies/enemy_projectile.tscn")
	var scene = get_tree().current_scene
	var container = scene.find_child("EnemyProjectiles") if scene else null
	if not container:
		return
	var spread := 0.3  # radians
	for offset in [-spread, 0.0, spread]:
		# Rotate direction around Y axis
		var d := Vector3(
			base_dir.x * cos(offset) - base_dir.z * sin(offset),
			0,
			base_dir.x * sin(offset) + base_dir.z * cos(offset)
		)
		var proj := proj_scene.instantiate()
		proj.setup(position + Vector3(0, 0.5, 0), d * 0.35, damage / 2, Color(1, 0.4, 0.0))
		container.add_child(proj)
