extends Node2D
## Root game controller – state machine, orchestration, wiring.

const _EnemyFactory = preload("res://spawning/enemy_factory.gd")

@onready var game_world: Node2D = $GameWorld
@onready var player: CharacterBody2D = $GameWorld/Player
@onready var enemies_container: Node2D = $GameWorld/Enemies
@onready var player_projectiles: Node2D = $GameWorld/PlayerProjectiles
@onready var enemy_projectiles: Node2D = $GameWorld/EnemyProjectiles
@onready var effects_container: Node2D = $GameWorld/Effects
@onready var spawn_manager_node: Node = $SpawnManager
@onready var gimmick_manager_node: Node = $GimmickManager
@onready var levelup_menu: CanvasLayer = $LevelUpMenu
@onready var chat_connector_node: Node = $ChatConnector

# Point recovery accumulator
var _point_recovery_acc: float = 0.0

# Event flags
var _half_time_triggered: bool = false
var _last_stand_triggered: bool = false

func _ready() -> void:
	# Attach scripts to manager nodes
	spawn_manager_node.set_script(preload("res://spawning/spawn_manager.gd"))
	gimmick_manager_node.set_script(preload("res://gimmicks/gimmick_manager.gd"))
	chat_connector_node.set_script(preload("res://twitcasting/chat_connector.gd"))

	# Wire up spawn manager
	spawn_manager_node.setup(player, enemies_container)

	# Connect signals
	EventBus.game_over.connect(_on_game_over)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.upgrade_selected.connect(_on_upgrade_selected)
	player.leveled_up.connect(_on_player_leveled_up)

func _physics_process(delta: float) -> void:
	match GameState.state:
		GameState.State.PLAY:
			_update_play(delta)
		GameState.State.LEVELUP:
			pass # LevelUpMenu handles input
		GameState.State.GAMEOVER:
			_update_gameover()
	queue_redraw()

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

	# Process chat commands
	_process_chat_commands()

	# Check events
	_check_events()

func _update_gameover() -> void:
	if Input.is_key_pressed(KEY_R):
		_reset_game()

func _apply_gimmick_effects() -> void:
	if gimmick_manager_node == null:
		return
	# Ice floor: slow player
	if gimmick_manager_node.ice_floor_active:
		player.speed = player.base_speed * 0.5
		# Add jitter
		player.position += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	else:
		player.speed = player.base_speed

	# Gravity reversal
	player.gravity_reversed = gimmick_manager_node.gravity_active

func _handle_spawn_input() -> void:
	for key in Config.SPAWN_KEYS:
		if Input.is_key_pressed(key):
			var enemy_key: String = Config.SPAWN_KEYS[key]
			EventBus.enemy_spawned.emit(enemy_key, "keyboard")

func _handle_gimmick_input() -> void:
	for key in Config.GIMMICK_KEYS:
		if Input.is_key_pressed(key):
			var gimmick_key: String = Config.GIMMICK_KEYS[key]
			var cost: int = Config.GIMMICK_COSTS[gimmick_key]
			if GameState.game_points >= cost:
				GameState.game_points -= cost
				var duration: float = Config.GIMMICK_DURATIONS[gimmick_key]
				EventBus.gimmick_activated.emit(gimmick_key, duration, "keyboard")

func _process_chat_commands() -> void:
	if chat_connector_node == null:
		return
	var commands: Array = chat_connector_node.poll_commands()
	for cmd in commands:
		match cmd.get("command", ""):
			"spawn":
				EventBus.enemy_spawned.emit(cmd["target"], "chat")
				var display: String = _EnemyFactory.DISPLAY_NAMES.get(cmd["target"], cmd["target"])
				EventBus.spawn_log_added.emit("%s: %s" % [cmd["username"], display])
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
	# Add XP to player
	if player.add_xp(cost):
		# Level up handled by signal
		pass

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
			weapons.get_node("AuraWeapon").aura_range += 6
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

func _reset_game() -> void:
	GameState.reset()
	_half_time_triggered = false
	_last_stand_triggered = false
	_point_recovery_acc = 0.0
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

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0.08, 0.08, 0.12))
	# Grid
	var grid_color := Color(0.15, 0.15, 0.2, 0.3)
	for x in range(0, Config.SCREEN_W + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, Config.SCREEN_H), grid_color)
	for y in range(0, Config.SCREEN_H + 1, 32):
		draw_line(Vector2(0, y), Vector2(Config.SCREEN_W, y), grid_color)
	# Ice floor effect
	if gimmick_manager_node and gimmick_manager_node.ice_floor_active:
		draw_rect(Rect2(0, 0, Config.SCREEN_W, Config.SCREEN_H), Color(0.5, 0.7, 1.0, 0.15))
	# Darkness effect
	if gimmick_manager_node and gimmick_manager_node.darkness_active:
		_draw_darkness()

func _draw_darkness() -> void:
	# Draw dark overlay with circular cutout around player
	var radius := 40.0
	# Simple approach: draw dark rects around the circle
	var cx := player.position.x
	var cy := player.position.y
	var overlay_color := Color(0, 0, 0, 0.85)
	# Top
	if cy - radius > 0:
		draw_rect(Rect2(0, 0, Config.SCREEN_W, cy - radius), overlay_color)
	# Bottom
	if cy + radius < Config.SCREEN_H:
		draw_rect(Rect2(0, cy + radius, Config.SCREEN_W, Config.SCREEN_H - cy - radius), overlay_color)
	# Left
	draw_rect(Rect2(0, cy - radius, cx - radius, radius * 2), overlay_color)
	# Right
	draw_rect(Rect2(cx + radius, cy - radius, Config.SCREEN_W - cx - radius, radius * 2), overlay_color)
