extends Node3D
## Treasure chest that gives a random skill/upgrade when opened.

var _opened: bool = false
var _player: CharacterBody3D
var _lid: MeshInstance3D
var _body_mesh: MeshInstance3D
var _glow: MeshInstance3D
var _glow_material: StandardMaterial3D
var _shadow: MeshInstance3D
var _sparkle_timer: float = 0.0
var _open_timer: float = 0.0

# Available rewards
const REWARDS := [
	{ "id": "unlock_missile", "name": "マジックミサイル", "type": "weapon" },
	{ "id": "unlock_blade", "name": "回転刃", "type": "weapon" },
	{ "id": "unlock_lightning", "name": "雷撃", "type": "weapon" },
	{ "id": "unlock_holy_water", "name": "ホーリーウォーター", "type": "weapon" },
	{ "id": "aura_damage", "name": "オーラ威力+", "type": "upgrade" },
	{ "id": "aura_range", "name": "オーラ射程+", "type": "upgrade" },
	{ "id": "missile_damage", "name": "ミサイル威力+", "type": "upgrade" },
	{ "id": "blade_add", "name": "回転刃追加", "type": "upgrade" },
	{ "id": "lightning_damage", "name": "雷撃威力+", "type": "upgrade" },
	{ "id": "hw_damage", "name": "聖水威力+", "type": "upgrade" },
	{ "id": "speed_up", "name": "移動速度+", "type": "upgrade" },
	{ "id": "max_hp", "name": "最大HP+", "type": "upgrade" },
	{ "id": "heal", "name": "HP回復", "type": "upgrade" },
]

func setup(pos: Vector3, player_ref: CharacterBody3D) -> void:
	position = pos
	position.y = 0
	_player = player_ref
	_build_mesh()

func _build_mesh() -> void:
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
	add_child(_shadow)

	# Chest body (golden-brown box)
	_body_mesh = MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.6, 0.35, 0.4)
	_body_mesh.mesh = body_box
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.55, 0.35, 0.15)
	body_mat.metallic = 0.2
	body_mat.roughness = 0.6
	_body_mesh.material_override = body_mat
	_body_mesh.position = Vector3(0, 0.18, 0)
	add_child(_body_mesh)

	# Metal bands
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.8, 0.7, 0.2)
	band_mat.metallic = 0.7
	band_mat.roughness = 0.3
	for z_off in [-0.12, 0.12]:
		var band := MeshInstance3D.new()
		var band_box := BoxMesh.new()
		band_box.size = Vector3(0.62, 0.36, 0.04)
		band.mesh = band_box
		band.material_override = band_mat
		band.position = Vector3(0, 0.18, z_off)
		add_child(band)

	# Lock (front)
	var lock := MeshInstance3D.new()
	var lock_box := BoxMesh.new()
	lock_box.size = Vector3(0.08, 0.1, 0.06)
	lock.mesh = lock_box
	lock.material_override = band_mat
	lock.position = Vector3(0, 0.2, -0.23)
	add_child(lock)

	# Lid (top part, will rotate when opened)
	_lid = MeshInstance3D.new()
	var lid_box := BoxMesh.new()
	lid_box.size = Vector3(0.58, 0.08, 0.38)
	_lid.mesh = lid_box
	var lid_mat := StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.6, 0.4, 0.18)
	lid_mat.metallic = 0.2
	lid_mat.roughness = 0.5
	_lid.material_override = lid_mat
	_lid.position = Vector3(0, 0.39, 0)
	add_child(_lid)

	# Glow indicator (floating light above chest)
	_glow = MeshInstance3D.new()
	var glow_sphere := SphereMesh.new()
	glow_sphere.radius = 0.12
	glow_sphere.height = 0.24
	_glow.mesh = glow_sphere
	_glow_material = StandardMaterial3D.new()
	_glow_material.albedo_color = Color(1, 0.9, 0.3)
	_glow_material.emission_enabled = true
	_glow_material.emission = Color(1, 0.85, 0.2)
	_glow_material.emission_energy_multiplier = 3.0
	_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow.material_override = _glow_material
	_glow.position = Vector3(0, 0.7, 0)
	add_child(_glow)

func _process(delta: float) -> void:
	if _opened:
		_open_timer += delta
		# Lid opens (rotates backward)
		if _lid and _open_timer < 0.5:
			_lid.rotation.x = lerpf(_lid.rotation.x, -1.2, 0.1)
		# Fade out after opening
		if _open_timer > 2.0:
			queue_free()
			return
		# Shrink and fade
		if _open_timer > 1.5:
			var fade := 1.0 - (_open_timer - 1.5) / 0.5
			scale = Vector3.ONE * fade
		return

	_sparkle_timer += delta

	# Bobbing glow
	if _glow:
		_glow.position.y = 0.7 + sin(_sparkle_timer * 3.0) * 0.1
		var pulse := 2.0 + sin(_sparkle_timer * 5.0) * 1.0
		if _glow_material:
			_glow_material.emission_energy_multiplier = pulse

	# Check player proximity
	if _player and is_instance_valid(_player):
		var dist := position.distance_to(_player.position)
		if dist < Config.CHEST_PICKUP_RANGE:
			_open_chest()

func _open_chest() -> void:
	_opened = true
	_open_timer = 0.0

	# Trigger slot roulette instead of instant reward
	var slot_roulette = get_tree().current_scene.find_child("SlotRoulette")
	if slot_roulette and slot_roulette.has_method("start_roulette"):
		slot_roulette.start_roulette()
	else:
		# Fallback: instant reward
		var reward: Dictionary = REWARDS[randi() % REWARDS.size()]
		EventBus.upgrade_selected.emit(reward["id"])
		EventBus.event_log_added.emit("宝箱: %s を入手!" % reward["name"])

	# Screen shake (small, celebratory)
	EventBus.screen_shake.emit(0.05, 0.3)

	# Hide glow
	if _glow:
		_glow.visible = false
