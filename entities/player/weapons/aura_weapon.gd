extends "res://entities/player/weapons/weapon_base.gd"
## Holy Sword Aura – manual melee attack with Space bar.

var aura_damage: int = 35
var aura_range: float = 4.0
const ATTACK_COOLDOWN := 10

var _attack_timer: int = 0    # visual: counts down from 8
var _attacking: bool = false
var _aura_mesh: MeshInstance3D
var _aura_material: StandardMaterial3D

func _ready() -> void:
	unlocked = true  # Always available

func _weapon_update() -> void:
	if _attack_timer > 0:
		_attack_timer -= 1
		_update_aura_visual()

	if _cooldown_timer > 0:
		return

	if Input.is_action_just_pressed("ui_accept"):  # Space
		_perform_attack()

func _perform_attack() -> void:
	_attacking = true
	_attack_timer = 8
	_cooldown_timer = ATTACK_COOLDOWN
	var player_node := get_player()
	if player_node == null:
		return
	var player_pos: Vector3 = player_node.position
	# Hit all enemies in range (XZ distance)
	for enemy in get_enemies():
		if enemy.has_method("take_damage") and enemy.alive:
			var dx: float = player_pos.x - enemy.position.x
			var dz: float = player_pos.z - enemy.position.z
			if sqrt(dx * dx + dz * dz) < aura_range:
				enemy.take_damage(aura_damage)
	# Create visual
	_create_aura_visual(player_pos)

func _create_aura_visual(pos: Vector3) -> void:
	# Remove old
	if _aura_mesh and is_instance_valid(_aura_mesh):
		_aura_mesh.queue_free()
	_aura_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	_aura_mesh.mesh = sphere
	_aura_material = StandardMaterial3D.new()
	_aura_material.albedo_color = Color(0.3, 0.7, 1.0, 0.6)
	_aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aura_material.emission_enabled = true
	_aura_material.emission = Color(0.3, 0.7, 1.0)
	_aura_material.emission_energy_multiplier = 1.0
	_aura_mesh.material_override = _aura_material
	_aura_mesh.position = Vector3(0, 0.5, 0)
	var scene = get_tree().current_scene
	var effects = scene.find_child("Effects") if scene else null
	if effects:
		effects.add_child(_aura_mesh)
		_aura_mesh.global_position = Vector3(pos.x, 0.5, pos.z)

func _update_aura_visual() -> void:
	if _aura_mesh and is_instance_valid(_aura_mesh):
		var progress := 1.0 - (_attack_timer / 8.0)
		var radius := aura_range * progress
		_aura_mesh.scale = Vector3(radius / 0.1, radius / 0.1, radius / 0.1)
		if _aura_material:
			var alpha := 0.6 * (1.0 - progress)
			_aura_material.albedo_color = Color(0.3, 0.7, 1.0, alpha)
		if _attack_timer <= 0:
			_aura_mesh.queue_free()
			_aura_mesh = null
