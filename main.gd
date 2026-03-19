extends Node3D
## Root game controller – state machine, orchestration, wiring.

const _EnemyFactory = preload("res://spawning/enemy_factory.gd")

@onready var game_world: Node3D = $GameWorld
@onready var player: CharacterBody3D = $GameWorld/Player
@onready var enemies_container: Node3D = $GameWorld/Enemies
@onready var player_projectiles: Node3D = $GameWorld/PlayerProjectiles
@onready var enemy_projectiles: Node3D = $GameWorld/EnemyProjectiles
@onready var effects_container: Node3D = $GameWorld/Effects
@onready var spawn_manager_node: Node = $SpawnManager
@onready var gimmick_manager_node: Node = $GimmickManager
@onready var levelup_menu: CanvasLayer = $LevelUpMenu
@onready var chat_connector_node: Node = $ChatConnector

# Point recovery accumulator
var _point_recovery_acc: float = 0.0
var _spawn_key_held: Dictionary = {}
var _gimmick_key_held: Dictionary = {}

# Event flags
var _half_time_triggered: bool = false
var _last_stand_triggered: bool = false

# Auto-spawn
var _next_boss_idx: int = 0

# Fake viewer names for auto-spawned enemies
const FAKE_VIEWERS := [
	"たかし", "ゆうき", "さくら", "はるか", "けんた",
	"みさき", "そうた", "あおい", "りく", "ひなた",
	"こころ", "ゆうと", "れん", "めい", "かいと",
	"ももか", "はやと", "ゆな", "そら", "りこ",
]

# 3D scene nodes
var _camera: Camera3D
var _light: DirectionalLight3D
var _environment: WorldEnvironment
var _ground: MeshInstance3D
var _ground_material: StandardMaterial3D

# Screen shake
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _camera_base_pos: Vector3

# Boss warning
var _boss_warning_timer: float = 0.0
var _boss_warning_name: String = ""

# Effect preloads
var _DamageNumber = preload("res://effects/damage_number.gd")
var _KillEffect = preload("res://effects/kill_effect.gd")
var _XpOrb = preload("res://effects/xp_orb.gd")
var _TreasureChest = preload("res://entities/treasure_chest.gd")

# Treasure chest timer
var _chest_spawn_timer: float = 0.0

func _ready() -> void:
	_setup_japanese_font()
	_setup_3d_scene()

	# Wire up spawn manager (scripts now attached via .tscn)
	spawn_manager_node.setup(player, enemies_container)

	# Connect signals
	EventBus.game_over.connect(_on_game_over)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.upgrade_selected.connect(_on_upgrade_selected)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_death_effect.connect(_on_enemy_death_effect)
	EventBus.screen_shake.connect(_on_screen_shake)
	EventBus.boss_warning.connect(_on_boss_warning)
	EventBus.player_damaged.connect(_on_player_hit)
	player.leveled_up.connect(_on_player_leveled_up)

func _setup_japanese_font() -> void:
	var font := load("res://assets/fonts/NotoSansJP-Regular.ttf") as Font
	if font:
		ThemeDB.fallback_font = font
		print("Japanese font loaded")
	else:
		print("WARNING: Japanese font not found")

func _setup_3d_scene() -> void:
	# Camera: orthographic top-down with slight angle
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 20.0
	_camera.position = Vector3(Config.WORLD_W / 2.0, 30.0, Config.WORLD_H / 2.0 + 15.0)
	_camera.rotation_degrees = Vector3(-60, 0, 0)
	_camera.near = 0.05
	_camera.far = 500.0
	_camera.current = true
	add_child(_camera)

	# Directional light
	_light = DirectionalLight3D.new()
	_light.rotation_degrees = Vector3(-45, -30, 0)
	_light.shadow_enabled = true
	_light.light_energy = 1.2
	add_child(_light)

	# Environment
	_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.4)
	env.ambient_light_energy = 0.8
	env.ssao_enabled = true
	env.fog_enabled = false
	_environment.environment = env
	add_child(_environment)

	# Ground plane
	_ground = MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(Config.WORLD_W, Config.WORLD_H)
	_ground.mesh = plane_mesh
	_ground_material = StandardMaterial3D.new()
	_ground_material.albedo_color = Color(0.12, 0.18, 0.12)
	_ground_material.roughness = 0.9
	_ground.material_override = _ground_material
	_ground.position = Vector3(Config.WORLD_W / 2.0, 0, Config.WORLD_H / 2.0)
	game_world.add_child(_ground)

	# Grid lines on the ground
	_create_grid_lines()

	# Decorate map with grass, trees, rocks, ruins, etc.
	var decorator := Node3D.new()
	decorator.name = "MapDecorations"
	decorator.set_script(preload("res://entities/map_decorator.gd"))
	game_world.add_child(decorator)
	decorator.generate()

func _create_grid_lines() -> void:
	var grid_node := Node3D.new()
	grid_node.name = "GridLines"
	game_world.add_child(grid_node)
	# Create grid using thin box meshes
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.18, 0.28, 0.18, 0.4)
	grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Vertical lines (along Z)
	var step := 4.0
	var x := 0.0
	while x <= Config.WORLD_W:
		var line := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.02, 0.01, Config.WORLD_H)
		line.mesh = box
		line.material_override = grid_mat
		line.position = Vector3(x, 0.005, Config.WORLD_H / 2.0)
		grid_node.add_child(line)
		x += step
	# Horizontal lines (along X)
	var z := 0.0
	while z <= Config.WORLD_H:
		var line := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(Config.WORLD_W, 0.01, 0.02)
		line.mesh = box
		line.material_override = grid_mat
		line.position = Vector3(Config.WORLD_W / 2.0, 0.005, z)
		grid_node.add_child(line)
		z += step

func _physics_process(delta: float) -> void:
	match GameState.state:
		GameState.State.TUTORIAL:
			pass # Tutorial handles input
		GameState.State.WEAPON_SELECT:
			pass # WeaponSelectScreen handles input
		GameState.State.PLAY:
			_update_play(delta)
		GameState.State.LEVELUP:
			pass # LevelUpMenu handles input
		GameState.State.GAMEOVER:
			_update_gameover()
	# Camera follow player
	_update_camera_follow()
	# Update gimmick visuals
	_update_gimmick_visuals()
	# Update screen shake
	_update_screen_shake(1.0 / Config.PHYSICS_FPS)
	# Update combo timer
	if GameState.state == GameState.State.PLAY:
		GameState.update_combo(1.0 / Config.PHYSICS_FPS)
	# Boss warning timer
	if _boss_warning_timer > 0:
		_boss_warning_timer -= 1.0 / Config.PHYSICS_FPS

func _update_play(delta: float) -> void:
	GameState.elapsed_frames += 1

	# Game-point recovery (+5 per second)
	_point_recovery_acc += delta
	if _point_recovery_acc >= 1.0:
		_point_recovery_acc -= 1.0
		GameState.game_points = mini(
			GameState.game_points + Config.GAME_POINTS_RECOVERY,
			Config.MAX_GAME_POINTS
		)

	# Apply gimmick effects to player
	_apply_gimmick_effects()

	# Keyboard spawn input
	_handle_spawn_input()
	# Keyboard gimmick input
	_handle_gimmick_input()

	# Auto-spawn enemies (disabled for testing)
	#_auto_spawn()

	# Spawn treasure chests
	_update_chest_spawn(delta)

	# Process chat commands
	_process_chat_commands()

	# Check events
	_check_events()

func _auto_spawn() -> void:
	var elapsed: int = int(GameState.elapsed_seconds())
	var enemy_count: int = enemies_container.get_child_count()
	# Determine current wave
	var wave: Array = Config.WAVE_TABLE[0]
	for w in Config.WAVE_TABLE:
		if elapsed >= w[0]:
			wave = w
	var interval: int = wave[1]
	var pool: Array = wave[2]
	var count: int = wave[3]
	# Spawn at interval (max 50 enemies)
	if GameState.elapsed_frames % interval == 0 and enemy_count < 50:
		for i in range(count):
			var key: String = pool[randi() % pool.size()]
			var enemy = spawn_manager_node.spawn_from_edge(key)
			if enemy and enemy.has_method("set_summoner"):
				var fake_name: String = FAKE_VIEWERS[randi() % FAKE_VIEWERS.size()]
				enemy.set_summoner(fake_name)
				var disp: String = _EnemyFactory.DISPLAY_NAMES.get(key, key)
				EventBus.spawn_log_added.emit("%s が %s を召喚!" % [fake_name, disp])
	# Boss schedule (with warning 3 sec before)
	if _next_boss_idx < Config.BOSS_SCHEDULE.size():
		var boss_entry: Array = Config.BOSS_SCHEDULE[_next_boss_idx]
		if elapsed >= boss_entry[0]:
			var enemy = spawn_manager_node.spawn_from_edge(boss_entry[1])
			var fake_name: String = FAKE_VIEWERS[randi() % FAKE_VIEWERS.size()]
			if enemy and enemy.has_method("set_summoner"):
				enemy.set_summoner(fake_name)
			var display: String = _EnemyFactory.DISPLAY_NAMES.get(boss_entry[1], boss_entry[1])
			EventBus.boss_warning.emit(display)
			_next_boss_idx += 1

func _update_chest_spawn(delta: float) -> void:
	_chest_spawn_timer += delta
	if _chest_spawn_timer >= Config.CHEST_SPAWN_INTERVAL:
		_chest_spawn_timer = 0.0
		# Count existing chests
		var chest_count := 0
		for child in effects_container.get_children():
			if child.has_method("_open_chest"):
				chest_count += 1
		if chest_count < Config.MAX_CHESTS:
			_spawn_chest()

func _spawn_chest() -> void:
	var chest := Node3D.new()
	chest.set_script(_TreasureChest)
	# Random position within map, at least 5 units from edge
	var pos := Vector3(
		randf_range(5, Config.WORLD_W - 5),
		0,
		randf_range(5, Config.WORLD_H - 5)
	)
	chest.setup(pos, player)
	effects_container.add_child(chest)

func _update_gameover() -> void:
	if Input.is_key_pressed(KEY_R):
		_reset_game()

func _apply_gimmick_effects() -> void:
	if gimmick_manager_node == null:
		return
	# Ice floor: slow player
	if gimmick_manager_node.ice_floor_active:
		player.speed = player.base_speed * 0.5
		# Add jitter on XZ plane
		player.position += Vector3(randf_range(-0.05, 0.05), 0, randf_range(-0.05, 0.05))
	else:
		player.speed = player.base_speed

	# Gravity reversal
	player.gravity_reversed = gimmick_manager_node.gravity_active

func _update_gimmick_visuals() -> void:
	if gimmick_manager_node == null:
		return
	# Ice floor: tint ground blue
	if gimmick_manager_node.ice_floor_active:
		_ground_material.albedo_color = Color(0.15, 0.2, 0.35)
	else:
		_ground_material.albedo_color = Color(0.12, 0.18, 0.12)
	# Darkness: use fog
	if _environment and _environment.environment:
		if gimmick_manager_node.darkness_active:
			_environment.environment.fog_enabled = true
			_environment.environment.fog_light_color = Color(0, 0, 0)
			_environment.environment.fog_density = 0.15
		else:
			_environment.environment.fog_enabled = false

func _handle_spawn_input() -> void:
	for key in Config.SPAWN_KEYS:
		if Input.is_key_pressed(key) and not _spawn_key_held.get(key, false):
			_spawn_key_held[key] = true
			var enemy_key: String = Config.SPAWN_KEYS[key]
			var cost: int = _EnemyFactory.get_cost(enemy_key)
			if GameState.game_points >= cost:
				GameState.game_points -= cost
				spawn_manager_node.spawn_from_edge(enemy_key)
				var display_name: String = _EnemyFactory.DISPLAY_NAMES.get(enemy_key, enemy_key)
				EventBus.spawn_log_added.emit("%s -%dpt" % [display_name, cost])
		elif not Input.is_key_pressed(key):
			_spawn_key_held[key] = false

func _handle_gimmick_input() -> void:
	for key in Config.GIMMICK_KEYS:
		if Input.is_key_pressed(key) and not _gimmick_key_held.get(key, false):
			_gimmick_key_held[key] = true
			var gimmick_key: String = Config.GIMMICK_KEYS[key]
			var cost: int = Config.GIMMICK_COSTS[gimmick_key]
			if GameState.game_points >= cost:
				GameState.game_points -= cost
				var duration: float = Config.GIMMICK_DURATIONS[gimmick_key]
				EventBus.gimmick_activated.emit(gimmick_key, duration, "keyboard")
		elif not Input.is_key_pressed(key):
			_gimmick_key_held[key] = false

func _process_chat_commands() -> void:
	if chat_connector_node == null:
		return
	var commands: Array = chat_connector_node.poll_commands()
	for cmd in commands:
		match cmd.get("command", ""):
			"spawn":
				var enemy = spawn_manager_node.spawn_from_edge(cmd["target"])
				if enemy and enemy.has_method("set_summoner"):
					enemy.set_summoner(cmd["username"])
				var display: String = _EnemyFactory.DISPLAY_NAMES.get(cmd["target"], cmd["target"])
				EventBus.spawn_log_added.emit("%s が %s を召喚!" % [cmd["username"], display])
			"gimmick":
				var duration: float = Config.GIMMICK_DURATIONS.get(cmd["target"], 10.0)
				EventBus.gimmick_activated.emit(cmd["target"], duration, "chat")
				EventBus.spawn_log_added.emit("%s: %s" % [cmd["username"], cmd["target"]])
			"insufficient_points":
				var display: String = _EnemyFactory.DISPLAY_NAMES.get(cmd["target"], cmd["target"])
				EventBus.spawn_log_added.emit("[LACK] %s: %s" % [cmd["username"], display])

func _check_events() -> void:
	var hp_ratio := float(player.hp) / float(player.max_hp)
	if hp_ratio <= 0.5 and not _half_time_triggered:
		_half_time_triggered = true
		GameState.game_points += 100
		EventBus.event_log_added.emit("HALF TIME CHAOS!")
	if hp_ratio <= 0.25 and not _last_stand_triggered:
		_last_stand_triggered = true
		GameState.game_points += 50
		EventBus.event_log_added.emit("LAST STAND!")

func _on_game_over() -> void:
	GameState.state = GameState.State.GAMEOVER

func _on_enemy_killed(enemy_key: String, cost: int) -> void:
	# Combo system
	GameState.add_kill()
	# Score with multiplier
	var bonus: int = int(cost * GameState.combo_multiplier)
	GameState.score += bonus - cost  # extra bonus from multiplier (base cost already added in enemy_base)

	# XP orbs instead of instant XP (more satisfying)
	_spawn_xp_orbs(cost)

func _spawn_xp_orbs(total_xp: int) -> void:
	# Spawn 1-5 orbs depending on XP amount
	var orb_count := clampi(total_xp / 10, 1, 5)
	var per_orb := total_xp / orb_count
	var remainder := total_xp % orb_count
	# Use last known enemy position (approximate - use random nearby position)
	for i in range(orb_count):
		var orb := Node3D.new()
		orb.set_script(_XpOrb)
		var amount := per_orb + (remainder if i == 0 else 0)
		var spawn_pos := player.position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		orb.setup(spawn_pos, amount, player)
		effects_container.add_child(orb)

func _on_player_leveled_up(level: int, _choices: Array) -> void:
	GameState.state = GameState.State.LEVELUP
	player.pending_levelup = false
	var available: Array[String] = levelup_menu.get_available_upgrades(player)
	levelup_menu.show_choices(available)

func _on_upgrade_selected(upgrade_id: String) -> void:
	_apply_upgrade(upgrade_id)

func _apply_upgrade(upgrade_id: String) -> void:
	var weapons := player.get_node("Weapons")
	match upgrade_id:
		"unlock_missile":
			weapons.get_node("MissileWeapon").unlocked = true
		"unlock_blade":
			weapons.get_node("OrbitBladeWeapon").unlock_weapon()
		"unlock_lightning":
			weapons.get_node("LightningWeapon").unlocked = true
		"unlock_holy_water":
			weapons.get_node("HolyWaterWeapon").unlocked = true
		"aura_damage":
			weapons.get_node("AuraWeapon").aura_damage += 10
		"aura_range":
			weapons.get_node("AuraWeapon").aura_range += 1.0
		"missile_damage":
			weapons.get_node("MissileWeapon").missile_damage += 8
		"missile_cooldown":
			weapons.get_node("MissileWeapon").missile_cooldown = maxi(8, weapons.get_node("MissileWeapon").missile_cooldown - 8)
		"blade_add":
			weapons.get_node("OrbitBladeWeapon").blade_count += 1
		"blade_damage":
			weapons.get_node("OrbitBladeWeapon").blade_damage += 5
		"lightning_damage":
			weapons.get_node("LightningWeapon").lightning_damage += 15
		"lightning_cooldown":
			weapons.get_node("LightningWeapon").lightning_cooldown = maxi(15, weapons.get_node("LightningWeapon").lightning_cooldown - 15)
		"hw_damage":
			weapons.get_node("HolyWaterWeapon").hw_damage += 3
		"hw_duration":
			weapons.get_node("HolyWaterWeapon").hw_duration += 30
		"speed_up":
			player.base_speed = minf(player.base_speed + 0.3, 4.0)
			player.speed = player.base_speed
		"max_hp":
			player.max_hp += 20
			player.hp = mini(player.hp + 20, player.max_hp)
		"heal":
			player.heal(30)

# --- Effect handlers ---

func _on_damage_dealt(pos: Vector3, amount: int, is_crit: bool) -> void:
	var dmg_num := Node3D.new()
	dmg_num.set_script(_DamageNumber)
	var color := Color(1, 1, 0) if is_crit else Color(1, 1, 1)
	dmg_num.setup(pos, amount, color, is_crit)
	effects_container.add_child(dmg_num)

func _on_enemy_death_effect(pos: Vector3, color: Color, size: float) -> void:
	var effect := Node3D.new()
	effect.set_script(_KillEffect)
	effect.setup(pos, color, size)
	effects_container.add_child(effect)

func _on_screen_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = 0.0
	if _camera:
		_camera_base_pos = _camera.position

func _on_boss_warning(enemy_name: String) -> void:
	_boss_warning_name = enemy_name
	_boss_warning_timer = 2.5
	EventBus.event_log_added.emit("WARNING: %s 出現!" % enemy_name)
	EventBus.screen_shake.emit(0.15, 1.0)

func _on_player_hit(amount: int, current_hp: int) -> void:
	EventBus.screen_shake.emit(0.1, 0.2)

var _camera_initialized: bool = false

func _update_camera_follow() -> void:
	if _camera == null or player == null:
		return
	var target_x := player.position.x
	var target_z := player.position.z + 15.0  # offset for 60-degree camera angle
	if not _camera_initialized:
		# Snap to player on first frame
		_camera.position.x = target_x
		_camera.position.z = target_z
		_camera_initialized = true
	else:
		_camera.position.x = lerpf(_camera.position.x, target_x, 0.08)
		_camera.position.z = lerpf(_camera.position.z, target_z, 0.08)
	_camera_base_pos = _camera.position

func _update_screen_shake(delta: float) -> void:
	if _shake_duration <= 0 or _camera == null:
		return
	_shake_timer += delta
	if _shake_timer >= _shake_duration:
		_camera.position = _camera_base_pos
		_shake_duration = 0.0
		return
	var decay := 1.0 - (_shake_timer / _shake_duration)
	var offset := Vector3(
		randf_range(-1, 1) * _shake_intensity * decay,
		randf_range(-1, 1) * _shake_intensity * decay * 0.5,
		randf_range(-1, 1) * _shake_intensity * decay
	)
	_camera.position = _camera_base_pos + offset

func _reset_game() -> void:
	GameState.reset()
	_half_time_triggered = false
	_last_stand_triggered = false
	_point_recovery_acc = 0.0
	_next_boss_idx = 0
	_camera_initialized = false
	_chest_spawn_timer = 0.0
	# Remove all dynamic nodes
	for child in enemies_container.get_children():
		child.queue_free()
	for child in player_projectiles.get_children():
		child.queue_free()
	for child in enemy_projectiles.get_children():
		child.queue_free()
	for child in effects_container.get_children():
		child.queue_free()
	# Reset player
	player.reset()
	# Notify listeners (GameOverScreen, GimmickManager, ChatConnector, etc.)
	EventBus.game_reset.emit()
