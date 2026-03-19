extends Area3D
## Shared enemy logic: HP, damage flash, contact, 3D mesh HP bar.

var def_data
var hp: int
var max_hp: int
var damage: int
var speed: float
var enemy_key: String
var alive: bool = true

# Timers
var _timer: int = 0
var _hit_flash_timer: int = 0

# Reference to player (set by factory)
var player: CharacterBody3D

# 3D visuals
var _mesh_container: Node3D
var _hp_bar_bg: MeshInstance3D
var _hp_bar_fill: MeshInstance3D
var _hp_bar_fill_material: StandardMaterial3D
var _collision_shape: CollisionShape3D
var _summoner_label: Label3D
var summoner_name: String = ""  # Set by spawn_manager when spawned via chat

func initialize(enemy_def, player_ref: CharacterBody3D) -> void:
	def_data = enemy_def
	hp = enemy_def.hp
	max_hp = enemy_def.hp
	damage = enemy_def.damage
	speed = enemy_def.speed
	enemy_key = enemy_def.key
	player = player_ref
	# Setup collision
	_collision_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = def_data.size / 8.0
	_collision_shape.shape = sphere
	_collision_shape.position = Vector3(0, 0.3, 0)
	add_child(_collision_shape)
	# Setup mesh container
	_mesh_container = Node3D.new()
	_mesh_container.name = "MeshContainer"
	add_child(_mesh_container)
	# Setup HP bar
	_setup_hp_bar()
	# Setup summoner name label (hidden until set)
	_setup_summoner_label()
	# Let subclass create its mesh
	_setup_mesh()

func _setup_mesh() -> void:
	pass # Override in AI subclass

func _setup_hp_bar() -> void:
	var bar_height: float = def_data.size / 6.0 + 1.2
	# Background
	_hp_bar_bg = MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(1.0, 0.08)
	_hp_bar_bg.mesh = bg_quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.3, 0.3, 0.3)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hp_bar_bg.material_override = bg_mat
	_hp_bar_bg.position = Vector3(0, bar_height, 0)
	_hp_bar_bg.visible = false
	add_child(_hp_bar_bg)

	# Fill
	_hp_bar_fill = MeshInstance3D.new()
	var fill_quad := QuadMesh.new()
	fill_quad.size = Vector2(1.0, 0.08)
	_hp_bar_fill.mesh = fill_quad
	_hp_bar_fill_material = StandardMaterial3D.new()
	_hp_bar_fill_material.albedo_color = Color(0.0, 1.0, 0.0)
	_hp_bar_fill_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bar_fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hp_bar_fill.material_override = _hp_bar_fill_material
	_hp_bar_fill.position = Vector3(0, bar_height, 0.001)
	_hp_bar_fill.visible = false
	add_child(_hp_bar_fill)

func _setup_summoner_label() -> void:
	_summoner_label = Label3D.new()
	_summoner_label.font_size = 96
	_summoner_label.outline_size = 20
	_summoner_label.outline_modulate = Color(0, 0, 0, 0.9)
	_summoner_label.modulate = Color(1, 0.85, 0.3)
	_summoner_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_summoner_label.no_depth_test = true
	var label_height: float = def_data.size / 6.0 + 2.0
	_summoner_label.position = Vector3(0, label_height, 0)
	_summoner_label.visible = false
	add_child(_summoner_label)

func set_summoner(viewer_name: String) -> void:
	summoner_name = viewer_name
	if _summoner_label and viewer_name != "":
		_summoner_label.text = viewer_name
		_summoner_label.visible = true

func _physics_process(_delta: float) -> void:
	if not alive or GameState.state != GameState.State.PLAY:
		return
	_timer += 1
	if _hit_flash_timer > 0:
		_hit_flash_timer -= 1
	_ai_update()
	_check_player_contact()
	_update_hp_bar()

func _ai_update() -> void:
	pass # Override in AI subclass

func take_damage(amount: int) -> void:
	if not alive:
		return
	# Critical hit chance (10%)
	var is_crit := randf() < 0.1
	var final_amount := amount * 2 if is_crit else amount
	hp -= final_amount
	_hit_flash_timer = 4
	# Floating damage number
	EventBus.damage_dealt.emit(position + Vector3(0, 0.5, 0), final_amount, is_crit)
	if hp <= 0:
		_die()

func _die() -> void:
	alive = false
	GameState.score += def_data.cost
	EventBus.enemy_killed.emit(enemy_key, def_data.cost)
	# Death explosion effect
	var death_color: Color = def_data.color if def_data else Color.RED
	var death_size: float = def_data.size / 8.0 if def_data else 0.5
	EventBus.enemy_death_effect.emit(position + Vector3(0, 0.3, 0), death_color, death_size)
	# Split handling (e.g., Slime King -> 3 Slimes)
	if def_data.split_on_death and def_data.split_into != "":
		for i in range(def_data.split_count):
			EventBus.enemy_spawned.emit(def_data.split_into, "split")
	queue_free()

func _check_player_contact() -> void:
	if player == null or player.invincible:
		return
	var contact_dist: float = (def_data.size / 8.0 + 0.3)  # enemy radius + player radius
	var dx: float = position.x - player.position.x
	var dz: float = position.z - player.position.z
	var dist: float = sqrt(dx * dx + dz * dz)
	if dist < contact_dist:
		player.take_damage(damage)

func _get_dir_to_player() -> Vector3:
	if player == null:
		return Vector3.ZERO
	var dir := Vector3(player.position.x - position.x, 0, player.position.z - position.z)
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return dir.normalized()

func _get_dist_to_player() -> float:
	if player == null:
		return 9999.0
	var dx: float = position.x - player.position.x
	var dz: float = position.z - player.position.z
	return sqrt(dx * dx + dz * dz)

func _update_hp_bar() -> void:
	if hp < max_hp and alive:
		_hp_bar_bg.visible = true
		_hp_bar_fill.visible = true
		var ratio := float(hp) / float(max_hp)
		_hp_bar_fill.scale = Vector3(ratio, 1, 1)
		# Offset to keep left-aligned
		_hp_bar_fill.position.x = -(1.0 - ratio) * 0.5
	else:
		_hp_bar_bg.visible = false
		_hp_bar_fill.visible = false

func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
