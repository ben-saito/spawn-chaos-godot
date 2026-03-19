extends "res://entities/player/weapons/weapon_base.gd"
## Orbit Blade – blades rotate around the player, damaging enemies on contact.

var blade_count: int = 0
var blade_damage: int = 12
const ORBIT_RADIUS := 3.5
const ORBIT_SPEED := 0.2
const HIT_COOLDOWN := 15

var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}  # enemy instance_id -> frames remaining
var _blade_meshes: Array = []  # MeshInstance3D nodes

func _weapon_update() -> void:
	if blade_count <= 0:
		return
	_angle += ORBIT_SPEED
	# Tick down hit cooldowns
	var to_remove := []
	for eid in _hit_cooldowns:
		_hit_cooldowns[eid] -= 1
		if _hit_cooldowns[eid] <= 0:
			to_remove.append(eid)
	for eid in to_remove:
		_hit_cooldowns.erase(eid)
	# Update blade meshes
	_update_blade_meshes()
	# Check collisions
	var player_node := get_player()
	if player_node == null:
		return
	for i in range(blade_count):
		var angle := _angle + (TAU / blade_count) * i
		var blade_pos := Vector3(
			player_node.position.x + cos(angle) * ORBIT_RADIUS,
			0.5,
			player_node.position.z + sin(angle) * ORBIT_RADIUS
		)
		for enemy in get_enemies():
			if enemy.has_method("take_damage") and enemy.alive:
				var eid: int = enemy.get_instance_id()
				if _hit_cooldowns.has(eid):
					continue
				var dx: float = blade_pos.x - enemy.position.x
				var dz: float = blade_pos.z - enemy.position.z
				if sqrt(dx * dx + dz * dz) < 1.0:
					enemy.take_damage(blade_damage)
					_hit_cooldowns[eid] = HIT_COOLDOWN

func _update_blade_meshes() -> void:
	var player_node := get_player()
	if player_node == null:
		return
	# Ensure correct number of blade meshes
	while _blade_meshes.size() < blade_count:
		var blade := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.1, 0.6, 0.3)
		blade.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.85, 1.0)
		mat.metallic = 0.8
		mat.roughness = 0.2
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.7, 1.0)
		mat.emission_energy_multiplier = 0.3
		blade.material_override = mat
		var scene = get_tree().current_scene
		var effects = scene.find_child("Effects") if scene else null
		if effects:
			effects.add_child(blade)
			_blade_meshes.append(blade)
	# Remove extra
	while _blade_meshes.size() > blade_count:
		var extra = _blade_meshes.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()
	# Position blades
	for i in range(blade_count):
		if i >= _blade_meshes.size():
			break
		var blade_mesh = _blade_meshes[i]
		if not is_instance_valid(blade_mesh):
			continue
		var angle := _angle + (TAU / blade_count) * i
		blade_mesh.global_position = Vector3(
			player_node.position.x + cos(angle) * ORBIT_RADIUS,
			0.5,
			player_node.position.z + sin(angle) * ORBIT_RADIUS
		)
		blade_mesh.rotation.y = angle

func unlock_weapon() -> void:
	unlocked = true
	blade_count = 2
