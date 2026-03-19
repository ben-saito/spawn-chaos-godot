extends CharacterBody3D
## Player character – movement, HP, invincibility, weapon management.

signal hp_changed(current_hp: int, max_hp: int)
signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal leveled_up(level: int, choices: Array)
signal died()

# Stats
var max_hp: int = 100
var hp: int = 100
var base_speed: float = 2.0
var speed: float = 2.0

# Invincibility
var invincible: bool = false
var _invincible_timer: int = 0
const INVINCIBLE_FRAMES := 30

# XP / Level
var level: int = 1
var xp: int = 0
var xp_to_next: int = Config.BASE_XP_TO_NEXT
var pending_levelup: bool = false

# 3D mesh nodes
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _left_arm: MeshInstance3D
var _right_arm: MeshInstance3D
var _left_leg: MeshInstance3D
var _right_leg: MeshInstance3D
var _collision: CollisionShape3D
var _body_material: StandardMaterial3D
var _head_material: StandardMaterial3D
var _chest_plate: MeshInstance3D
var _nose: MeshInstance3D
var _left_eye: MeshInstance3D
var _right_eye: MeshInstance3D
var _hair: MeshInstance3D
var _shadow: MeshInstance3D
var _character_root: Node3D
var _anim_timer: float = 0.0
var _hit_flash_timer: int = 0

func _ready() -> void:
	_setup_mesh()
	position = Vector3(Config.WORLD_W / 2.0, 0, Config.WORLD_H / 2.0)

func _setup_mesh() -> void:
	# Collision shape
	_collision = CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.3
	capsule_shape.height = 1.0
	_collision.shape = capsule_shape
	_collision.position = Vector3(0, 0.5, 0)
	add_child(_collision)

	# Character root for bobbing animation
	_character_root = Node3D.new()
	_character_root.name = "CharacterRoot"
	add_child(_character_root)

	# Shadow (flat dark ellipse under character)
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.35
	shadow_cyl.bottom_radius = 0.35
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.35)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	add_child(_shadow)  # Shadow stays at ground, not on character_root

	# Body (capsule torso with blue tunic)
	_body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 0.7
	_body_mesh.mesh = capsule
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = Color(0.2, 0.5, 0.9)
	_body_material.metallic = 0.05
	_body_material.roughness = 0.7
	_body_mesh.material_override = _body_material
	_body_mesh.position = Vector3(0, 0.4, 0)
	_character_root.add_child(_body_mesh)

	# Chest plate (silver armor overlay)
	_chest_plate = MeshInstance3D.new()
	var chest_box := BoxMesh.new()
	chest_box.size = Vector3(0.38, 0.3, 0.22)
	_chest_plate.mesh = chest_box
	var chest_mat := StandardMaterial3D.new()
	chest_mat.albedo_color = Color(0.75, 0.78, 0.82)
	chest_mat.metallic = 0.6
	chest_mat.roughness = 0.3
	_chest_plate.material_override = chest_mat
	_chest_plate.position = Vector3(0, 0.45, -0.05)
	_character_root.add_child(_chest_plate)

	# Head (larger sphere for chibi proportions)
	_head_mesh = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.28
	head_sphere.height = 0.56
	_head_mesh.mesh = head_sphere
	_head_material = StandardMaterial3D.new()
	_head_material.albedo_color = Color(1.0, 0.85, 0.72)
	_head_material.roughness = 0.8
	_head_mesh.material_override = _head_material
	_head_mesh.position = Vector3(0, 0.95, 0)
	_character_root.add_child(_head_mesh)

	# Eyes (small dark spheres)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.08, 0.06)
	eye_mat.roughness = 0.2
	_left_eye = MeshInstance3D.new()
	var eye_sphere := SphereMesh.new()
	eye_sphere.radius = 0.045
	eye_sphere.height = 0.09
	_left_eye.mesh = eye_sphere
	_left_eye.material_override = eye_mat
	_left_eye.position = Vector3(-0.1, 0.98, -0.23)
	_character_root.add_child(_left_eye)

	_right_eye = MeshInstance3D.new()
	_right_eye.mesh = eye_sphere
	_right_eye.material_override = eye_mat
	_right_eye.position = Vector3(0.1, 0.98, -0.23)
	_character_root.add_child(_right_eye)

	# Nose (small sphere)
	_nose = MeshInstance3D.new()
	var nose_sphere := SphereMesh.new()
	nose_sphere.radius = 0.035
	nose_sphere.height = 0.07
	_nose.mesh = nose_sphere
	var nose_mat := StandardMaterial3D.new()
	nose_mat.albedo_color = Color(1.0, 0.78, 0.65)
	_nose.material_override = nose_mat
	_nose.position = Vector3(0, 0.93, -0.26)
	_character_root.add_child(_nose)

	# Hair (yellow cone on top of head)
	_hair = MeshInstance3D.new()
	var hair_cone := CylinderMesh.new()
	hair_cone.top_radius = 0.0
	hair_cone.bottom_radius = 0.22
	hair_cone.height = 0.3
	_hair.mesh = hair_cone
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(1.0, 0.85, 0.2)
	hair_mat.roughness = 0.6
	_hair.material_override = hair_mat
	_hair.position = Vector3(0, 1.25, 0.02)
	_character_root.add_child(_hair)

	# Hair side tufts
	var tuft_mat := StandardMaterial3D.new()
	tuft_mat.albedo_color = Color(1.0, 0.82, 0.15)
	tuft_mat.roughness = 0.6
	for x_off in [-0.18, 0.18]:
		var tuft := MeshInstance3D.new()
		var tuft_cone := CylinderMesh.new()
		tuft_cone.top_radius = 0.0
		tuft_cone.bottom_radius = 0.08
		tuft_cone.height = 0.15
		tuft.mesh = tuft_cone
		tuft.material_override = tuft_mat
		tuft.position = Vector3(x_off, 1.12, 0.1)
		tuft.rotation.x = 0.4
		if x_off < 0:
			tuft.rotation.z = 0.3
		else:
			tuft.rotation.z = -0.3
		_character_root.add_child(tuft)

	# Left arm
	_left_arm = MeshInstance3D.new()
	var arm_capsule := CapsuleMesh.new()
	arm_capsule.radius = 0.07
	arm_capsule.height = 0.4
	_left_arm.mesh = arm_capsule
	var arm_mat := StandardMaterial3D.new()
	arm_mat.albedo_color = Color(1.0, 0.85, 0.72)
	arm_mat.roughness = 0.8
	_left_arm.material_override = arm_mat
	_left_arm.position = Vector3(-0.38, 0.5, 0)
	_character_root.add_child(_left_arm)

	# Right arm
	_right_arm = MeshInstance3D.new()
	_right_arm.mesh = arm_capsule
	_right_arm.material_override = arm_mat
	_right_arm.position = Vector3(0.38, 0.5, 0)
	_character_root.add_child(_right_arm)

	# Left leg
	_left_leg = MeshInstance3D.new()
	var leg_cyl := CylinderMesh.new()
	leg_cyl.top_radius = 0.07
	leg_cyl.bottom_radius = 0.06
	leg_cyl.height = 0.25
	_left_leg.mesh = leg_cyl
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.15, 0.35, 0.75)
	leg_mat.roughness = 0.7
	_left_leg.material_override = leg_mat
	_left_leg.position = Vector3(-0.12, 0.12, 0)
	_character_root.add_child(_left_leg)

	# Right leg
	_right_leg = MeshInstance3D.new()
	_right_leg.mesh = leg_cyl
	_right_leg.material_override = leg_mat
	_right_leg.position = Vector3(0.12, 0.12, 0)
	_character_root.add_child(_right_leg)

func _physics_process(_delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return

	_handle_movement()
	_update_invincibility()
	_update_visual()
	_animate()

var gravity_reversed: bool = false

func _handle_movement() -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		dir.z += 1
	# Gravity reversal gimmick
	if gravity_reversed:
		dir.z *= -1

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	velocity = dir * speed * 5.0  # Convert to units/sec for move_and_slide
	move_and_slide()

	# Clamp to world bounds
	position.x = clampf(position.x, 0, Config.WORLD_W)
	position.z = clampf(position.z, 0, Config.WORLD_H)
	position.y = 0  # Keep on ground

func _update_invincibility() -> void:
	if _invincible_timer > 0:
		_invincible_timer -= 1
		if _invincible_timer <= 0:
			invincible = false

func _update_visual() -> void:
	# Flash when invincible
	if invincible and (_invincible_timer % 4 < 2):
		_character_root.visible = false
	else:
		_character_root.visible = true

func _animate() -> void:
	_anim_timer += 1.0
	var spd := velocity.length()
	var is_moving := spd > 0.5

	# Idle bobbing (gentle sin wave)
	if _character_root:
		var bob := sin(_anim_timer * 0.08) * 0.05
		_character_root.position.y = bob if not is_moving else 0.0

	# Arm swing while moving
	if _left_arm and _right_arm:
		if is_moving:
			var swing := sin(_anim_timer * 0.25) * 0.6
			_left_arm.rotation.x = swing
			_right_arm.rotation.x = -swing
		else:
			_left_arm.rotation.x = 0.0
			_right_arm.rotation.x = 0.0

	# Leg walking animation
	if _left_leg and _right_leg:
		if is_moving:
			var leg_swing := sin(_anim_timer * 0.25) * 0.5
			_left_leg.rotation.x = leg_swing
			_right_leg.rotation.x = -leg_swing
		else:
			_left_leg.rotation.x = 0.0
			_right_leg.rotation.x = 0.0

	# Hit flash (red tint)
	if _hit_flash_timer > 0:
		_hit_flash_timer -= 1
		if _body_material:
			_body_material.albedo_color = Color(1.0, 0.3, 0.3)
		if _head_material:
			_head_material.albedo_color = Color(1.0, 0.5, 0.5)
	else:
		if _body_material:
			_body_material.albedo_color = Color(0.2, 0.5, 0.9)
		if _head_material:
			_head_material.albedo_color = Color(1.0, 0.85, 0.72)

func take_damage(amount: int) -> void:
	if invincible:
		return
	hp = maxi(0, hp - amount)
	invincible = true
	_invincible_timer = INVINCIBLE_FRAMES
	_hit_flash_timer = 8
	hp_changed.emit(hp, max_hp)
	EventBus.player_damaged.emit(amount, hp)
	if hp <= 0:
		died.emit()
		EventBus.game_over.emit()

func add_xp(amount: int) -> bool:
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(xp_to_next * Config.XP_GROWTH_RATE)
		pending_levelup = true
		xp_changed.emit(xp, xp_to_next, level)
		leveled_up.emit(level, [])
		EventBus.player_leveled_up.emit(level)
		return true
	xp_changed.emit(xp, xp_to_next, level)
	return false

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

func reset() -> void:
	max_hp = 100
	hp = 100
	base_speed = 2.0
	speed = 2.0
	level = 1
	xp = 0
	xp_to_next = Config.BASE_XP_TO_NEXT
	pending_levelup = false
	invincible = false
	_invincible_timer = 0
	_hit_flash_timer = 0
	gravity_reversed = false
	position = Vector3(Config.WORLD_W / 2.0, 0, Config.WORLD_H / 2.0)
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next, level)
	# Reset weapons to defaults
	if has_node("Weapons"):
		var weapons := get_node("Weapons")
		var aura = weapons.get_node_or_null("AuraWeapon")
		if aura:
			aura.unlocked = true
			aura.aura_damage = 35
			aura.aura_range = 4.0
		var missile = weapons.get_node_or_null("MissileWeapon")
		if missile:
			missile.unlocked = false
			missile.missile_damage = 15
			missile.missile_cooldown = 40
		var blade = weapons.get_node_or_null("OrbitBladeWeapon")
		if blade:
			blade.unlocked = false
			blade.blade_count = 0
			blade.blade_damage = 12
		var lightning = weapons.get_node_or_null("LightningWeapon")
		if lightning:
			lightning.unlocked = false
			lightning.lightning_damage = 40
			lightning.lightning_cooldown = 75
		var hw = weapons.get_node_or_null("HolyWaterWeapon")
		if hw:
			hw.unlocked = false
			hw.hw_damage = 5
			hw.hw_duration = 90
