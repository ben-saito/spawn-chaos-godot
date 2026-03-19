extends Node3D
## Procedurally places grass, trees, rocks, ruins, and bushes across the map.

var _rng := RandomNumberGenerator.new()

func generate() -> void:
	_rng.seed = 12345  # Fixed seed for consistent map layout
	_place_grass_patches(300)
	_place_trees(40)
	_place_bushes(60)
	_place_rocks(35)
	_place_ruins(8)
	_place_fences(12)
	_place_paths()

# --- Grass ---
func _place_grass_patches(count: int) -> void:
	var grass_container := Node3D.new()
	grass_container.name = "Grass"
	add_child(grass_container)
	var grass_colors := [
		Color(0.15, 0.35, 0.1),
		Color(0.2, 0.4, 0.12),
		Color(0.18, 0.32, 0.08),
		Color(0.25, 0.45, 0.15),
	]
	for i in range(count):
		var pos := Vector3(
			_rng.randf_range(1, Config.WORLD_W - 1),
			0,
			_rng.randf_range(1, Config.WORLD_H - 1)
		)
		var patch := Node3D.new()
		patch.position = pos
		# 3-5 grass blades per patch
		var blade_count := _rng.randi_range(3, 6)
		var col: Color = grass_colors[i % grass_colors.size()]
		for j in range(blade_count):
			var blade := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = _rng.randf_range(0.03, 0.06)
			cone.height = _rng.randf_range(0.15, 0.35)
			blade.mesh = cone
			var mat := StandardMaterial3D.new()
			mat.albedo_color = col.darkened(_rng.randf_range(0, 0.15))
			blade.material_override = mat
			blade.position = Vector3(
				_rng.randf_range(-0.2, 0.2), cone.height / 2.0,
				_rng.randf_range(-0.2, 0.2)
			)
			blade.rotation.z = _rng.randf_range(-0.15, 0.15)
			patch.add_child(blade)
		grass_container.add_child(patch)

# --- Trees ---
func _place_trees(count: int) -> void:
	var tree_container := Node3D.new()
	tree_container.name = "Trees"
	add_child(tree_container)
	for i in range(count):
		var pos := Vector3(
			_rng.randf_range(3, Config.WORLD_W - 3),
			0,
			_rng.randf_range(3, Config.WORLD_H - 3)
		)
		var tree := _create_tree(pos)
		tree_container.add_child(tree)

func _create_tree(pos: Vector3) -> Node3D:
	var tree := Node3D.new()
	tree.position = pos
	var trunk_h := _rng.randf_range(1.0, 2.0)
	var canopy_r := _rng.randf_range(0.6, 1.2)

	# Shadow
	var shadow := MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = canopy_r
	shadow_cyl.bottom_radius = canopy_r
	shadow_cyl.height = 0.02
	shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.2)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shadow_mat
	shadow.position = Vector3(0, 0.01, 0)
	tree.add_child(shadow)

	# Trunk
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.08
	trunk_mesh.bottom_radius = 0.12
	trunk_mesh.height = trunk_h
	trunk.mesh = trunk_mesh
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.12)
	trunk_mat.roughness = 0.9
	trunk.material_override = trunk_mat
	trunk.position = Vector3(0, trunk_h / 2.0, 0)
	tree.add_child(trunk)

	# Canopy (layered spheres for fullness)
	var canopy_colors := [Color(0.1, 0.4, 0.08), Color(0.15, 0.45, 0.1), Color(0.08, 0.35, 0.06)]
	for j in range(3):
		var canopy := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		var r := canopy_r * (1.0 - j * 0.2)
		sphere.radius = r
		sphere.height = r * 2
		canopy.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = canopy_colors[j]
		mat.roughness = 0.8
		canopy.material_override = mat
		canopy.position = Vector3(
			_rng.randf_range(-0.15, 0.15),
			trunk_h + r * 0.6 + j * 0.2,
			_rng.randf_range(-0.15, 0.15)
		)
		tree.add_child(canopy)
	return tree

# --- Bushes ---
func _place_bushes(count: int) -> void:
	var bush_container := Node3D.new()
	bush_container.name = "Bushes"
	add_child(bush_container)
	for i in range(count):
		var pos := Vector3(
			_rng.randf_range(1, Config.WORLD_W - 1),
			0,
			_rng.randf_range(1, Config.WORLD_H - 1)
		)
		var bush := _create_bush(pos)
		bush_container.add_child(bush)

func _create_bush(pos: Vector3) -> Node3D:
	var bush := Node3D.new()
	bush.position = pos
	var bush_colors := [Color(0.12, 0.35, 0.08), Color(0.18, 0.4, 0.1), Color(0.1, 0.3, 0.06)]
	var sphere_count := _rng.randi_range(2, 4)
	for i in range(sphere_count):
		var s := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		var r := _rng.randf_range(0.2, 0.4)
		sphere.radius = r
		sphere.height = r * 2
		s.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = bush_colors[i % bush_colors.size()]
		mat.roughness = 0.85
		s.material_override = mat
		s.position = Vector3(
			_rng.randf_range(-0.2, 0.2),
			r * 0.7,
			_rng.randf_range(-0.2, 0.2)
		)
		bush.add_child(s)
	# Small flowers on some bushes
	if _rng.randf() < 0.4:
		var flower_colors := [Color(1, 0.3, 0.4), Color(1, 0.9, 0.2), Color(0.6, 0.3, 1), Color(1, 0.6, 0.8)]
		for _f in range(_rng.randi_range(1, 3)):
			var flower := MeshInstance3D.new()
			var fs := SphereMesh.new()
			fs.radius = 0.06
			fs.height = 0.12
			flower.mesh = fs
			var fmat := StandardMaterial3D.new()
			fmat.albedo_color = flower_colors[_rng.randi() % flower_colors.size()]
			fmat.emission_enabled = true
			fmat.emission = fmat.albedo_color
			fmat.emission_energy_multiplier = 0.5
			flower.material_override = fmat
			flower.position = Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.3, 0.6), _rng.randf_range(-0.3, 0.3))
			bush.add_child(flower)
	return bush

# --- Rocks ---
func _place_rocks(count: int) -> void:
	var rock_container := Node3D.new()
	rock_container.name = "Rocks"
	add_child(rock_container)
	for i in range(count):
		var pos := Vector3(
			_rng.randf_range(2, Config.WORLD_W - 2),
			0,
			_rng.randf_range(2, Config.WORLD_H - 2)
		)
		var rock := _create_rock(pos)
		rock_container.add_child(rock)

func _create_rock(pos: Vector3) -> Node3D:
	var rock := Node3D.new()
	rock.position = pos
	var rock_count := _rng.randi_range(1, 3)
	for i in range(rock_count):
		var r := MeshInstance3D.new()
		var box := BoxMesh.new()
		var sx := _rng.randf_range(0.2, 0.6)
		var sy := _rng.randf_range(0.15, 0.4)
		var sz := _rng.randf_range(0.2, 0.5)
		box.size = Vector3(sx, sy, sz)
		r.mesh = box
		var mat := StandardMaterial3D.new()
		var gray := _rng.randf_range(0.3, 0.5)
		mat.albedo_color = Color(gray, gray * 0.95, gray * 0.9)
		mat.roughness = 0.95
		r.material_override = mat
		r.position = Vector3(_rng.randf_range(-0.2, 0.2), sy / 2.0, _rng.randf_range(-0.2, 0.2))
		r.rotation.y = _rng.randf_range(0, TAU)
		rock.add_child(r)
	return rock

# --- Ruins / Buildings ---
func _place_ruins(count: int) -> void:
	var ruins_container := Node3D.new()
	ruins_container.name = "Ruins"
	add_child(ruins_container)
	for i in range(count):
		var pos := Vector3(
			_rng.randf_range(8, Config.WORLD_W - 8),
			0,
			_rng.randf_range(8, Config.WORLD_H - 8)
		)
		var ruin := _create_ruin(pos)
		ruins_container.add_child(ruin)

func _create_ruin(pos: Vector3) -> Node3D:
	var ruin := Node3D.new()
	ruin.position = pos
	ruin.rotation.y = _rng.randf_range(0, TAU)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.45, 0.4, 0.35)
	wall_mat.roughness = 0.95
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.5, 0.25, 0.15)
	roof_mat.roughness = 0.8

	var w := _rng.randf_range(2.0, 3.5)
	var d := _rng.randf_range(1.5, 2.5)
	var h := _rng.randf_range(1.5, 2.5)

	# Walls (box)
	var walls := MeshInstance3D.new()
	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(w, h, d)
	walls.mesh = wall_box
	walls.material_override = wall_mat
	walls.position = Vector3(0, h / 2.0, 0)
	ruin.add_child(walls)

	# Roof (pyramid-ish: flat box angled)
	var roof := MeshInstance3D.new()
	var roof_box := BoxMesh.new()
	roof_box.size = Vector3(w + 0.3, 0.15, d + 0.3)
	roof.mesh = roof_box
	roof.material_override = roof_mat
	roof.position = Vector3(0, h + 0.1, 0)
	ruin.add_child(roof)

	# Roof peak
	var peak := MeshInstance3D.new()
	var peak_mesh := CylinderMesh.new()
	peak_mesh.top_radius = 0.0
	peak_mesh.bottom_radius = w / 2.0 * 0.8
	peak_mesh.height = 0.8
	peak.mesh = peak_mesh
	peak.material_override = roof_mat
	peak.position = Vector3(0, h + 0.5, 0)
	ruin.add_child(peak)

	# Door (dark rectangle)
	var door := MeshInstance3D.new()
	var door_box := BoxMesh.new()
	door_box.size = Vector3(0.5, 0.9, 0.05)
	door.mesh = door_box
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.15, 0.1, 0.08)
	door.material_override = door_mat
	door.position = Vector3(0, 0.45, -d / 2.0 - 0.03)
	ruin.add_child(door)

	# Windows (small dark boxes)
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.2, 0.25, 0.35)
	win_mat.emission_enabled = true
	win_mat.emission = Color(0.3, 0.35, 0.5)
	win_mat.emission_energy_multiplier = 0.5
	for x_off in [-w * 0.3, w * 0.3]:
		var win := MeshInstance3D.new()
		var win_box := BoxMesh.new()
		win_box.size = Vector3(0.3, 0.3, 0.05)
		win.mesh = win_box
		win.material_override = win_mat
		win.position = Vector3(x_off, h * 0.6, -d / 2.0 - 0.03)
		ruin.add_child(win)
	return ruin

# --- Fences ---
func _place_fences(count: int) -> void:
	var fence_container := Node3D.new()
	fence_container.name = "Fences"
	add_child(fence_container)
	var fence_mat := StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.45, 0.3, 0.18)
	fence_mat.roughness = 0.9
	for i in range(count):
		var pos := Vector3(
			_rng.randf_range(5, Config.WORLD_W - 5),
			0,
			_rng.randf_range(5, Config.WORLD_H - 5)
		)
		var fence := Node3D.new()
		fence.position = pos
		fence.rotation.y = _rng.randf_range(0, TAU)
		var post_count := _rng.randi_range(3, 6)
		for j in range(post_count):
			# Post
			var post := MeshInstance3D.new()
			var post_cyl := CylinderMesh.new()
			post_cyl.top_radius = 0.04
			post_cyl.bottom_radius = 0.05
			post_cyl.height = 0.6
			post.mesh = post_cyl
			post.material_override = fence_mat
			post.position = Vector3(j * 0.8, 0.3, 0)
			fence.add_child(post)
			# Rail between posts
			if j > 0:
				var rail := MeshInstance3D.new()
				var rail_box := BoxMesh.new()
				rail_box.size = Vector3(0.8, 0.04, 0.04)
				rail.mesh = rail_box
				rail.material_override = fence_mat
				rail.position = Vector3(j * 0.8 - 0.4, 0.45, 0)
				fence.add_child(rail)
		fence_container.add_child(fence)

# --- Paths (dirt roads) ---
func _place_paths() -> void:
	var path_container := Node3D.new()
	path_container.name = "Paths"
	add_child(path_container)
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = Color(0.3, 0.22, 0.12)
	path_mat.roughness = 0.95

	# Main horizontal path through center
	var h_path := MeshInstance3D.new()
	var h_box := BoxMesh.new()
	h_box.size = Vector3(Config.WORLD_W * 0.8, 0.01, 2.0)
	h_path.mesh = h_box
	h_path.material_override = path_mat
	h_path.position = Vector3(Config.WORLD_W / 2.0, 0.005, Config.WORLD_H / 2.0)
	path_container.add_child(h_path)

	# Vertical crossroad
	var v_path := MeshInstance3D.new()
	var v_box := BoxMesh.new()
	v_box.size = Vector3(2.0, 0.01, Config.WORLD_H * 0.8)
	v_path.mesh = v_box
	v_path.material_override = path_mat
	v_path.position = Vector3(Config.WORLD_W / 2.0, 0.005, Config.WORLD_H / 2.0)
	path_container.add_child(v_path)

	# A few random side paths
	for _i in range(4):
		var side := MeshInstance3D.new()
		var side_box := BoxMesh.new()
		var length := _rng.randf_range(10, 25)
		side_box.size = Vector3(length, 0.01, 1.5)
		side.mesh = side_box
		side.material_override = path_mat
		side.position = Vector3(
			_rng.randf_range(15, Config.WORLD_W - 15),
			0.005,
			_rng.randf_range(15, Config.WORLD_H - 15)
		)
		side.rotation.y = _rng.randf_range(-0.4, 0.4)
		path_container.add_child(side)
