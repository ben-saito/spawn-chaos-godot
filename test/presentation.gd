extends SceneTree
## Presentation video script — ~30s cinematic showcasing gameplay.
## Spawns enemies, simulates movement, triggers weapons & gimmicks, shows level-up.

var _frame: int = 0
var _root: Window
var _main_scene = null

# Autoload references (cannot use names directly in SceneTree scripts)
var _event_bus = null
var _game_state = null

# Scene node references
var _spawn_mgr = null
var _player = null

func _initialize() -> void:
	_root = get_root()
	# Load main scene
	var scene: PackedScene = load("res://main.tscn")
	_main_scene = scene.instantiate()
	_root.add_child(_main_scene)
	_root.set_deferred(&"current_scene", _main_scene)

	# Find autoloads by name
	for child in _root.get_children():
		if child.name == "EventBus":
			_event_bus = child
		elif child.name == "GameState":
			_game_state = child

func _process(delta: float) -> bool:
	_frame += 1

	# Cache references after scene is ready
	if _spawn_mgr == null and _main_scene != null:
		_spawn_mgr = _main_scene.find_child("SpawnManager")
	if _player == null and _main_scene != null:
		_player = _main_scene.find_child("Player")

	# Keep player alive: heal periodically and grant invincibility frames
	if _player and _frame % 15 == 0:
		if _player.hp < _player.max_hp * 0.6:
			_player.hp = mini(_player.hp + 20, _player.max_hp)
			_player.hp_changed.emit(_player.hp, _player.max_hp)

	# --- PHASE 1 (frames 1-90, ~3s): Opening — first enemies spawn and approach ---
	if _frame == 2:
		# Boost player HP for presentation so they survive the full 30s
		if _player:
			_player.max_hp = 500
			_player.hp = 500
			_player.hp_changed.emit(_player.hp, _player.max_hp)

	if _frame == 3:
		# Spawn initial wave of enemies at specific positions near viewport
		_spawn_at("slime", Vector2(20, 20))
		_spawn_at("slime", Vector2(230, 30))
		_spawn_at("goblin", Vector2(30, 190))

	if _frame == 15:
		# Move player right
		Input.action_press("ui_right")

	if _frame == 30:
		# Aura attack
		Input.action_press("ui_accept")
		_spawn_at("skeleton", Vector2(200, 50))
		_spawn_at("bat", Vector2(50, 100))

	if _frame == 32:
		Input.action_release("ui_accept")

	if _frame == 45:
		Input.action_release("ui_right")
		Input.action_press("ui_down")

	if _frame == 55:
		# Another aura attack
		Input.action_press("ui_accept")

	if _frame == 57:
		Input.action_release("ui_accept")

	if _frame == 60:
		Input.action_release("ui_down")
		_spawn_at("mushroom", Vector2(40, 160))
		_spawn_at("goblin", Vector2(220, 140))
		_spawn_at("slime", Vector2(128, 200))

	if _frame == 75:
		Input.action_press("ui_left")
		Input.action_press("ui_up")

	if _frame == 85:
		Input.action_press("ui_accept")

	if _frame == 87:
		Input.action_release("ui_accept")

	# --- PHASE 2 (frames 90-210, ~4s): Unlock weapons, show combat ---
	if _frame == 90:
		Input.action_release("ui_left")
		Input.action_release("ui_up")
		# Unlock missile weapon
		_unlock_weapon("missile")
		# Move to center
		Input.action_press("ui_left")
		# More enemies for missile to target
		_spawn_at("slime", Vector2(30, 50))
		_spawn_at("goblin", Vector2(220, 50))
		_spawn_at("skeleton", Vector2(30, 170))

	if _frame == 105:
		Input.action_release("ui_left")
		Input.action_press("ui_down")

	if _frame == 115:
		# Unlock orbit blades
		_unlock_weapon("blade")
		_spawn_at("bat", Vector2(200, 100))
		_spawn_at("mushroom", Vector2(60, 130))

	if _frame == 125:
		Input.action_release("ui_down")
		Input.action_press("ui_right")
		Input.action_press("ui_up")

	if _frame == 140:
		_spawn_at("ogre", Vector2(40, 40))
		_spawn_at("skeleton", Vector2(210, 180))
		_spawn_at("bat", Vector2(128, 20))

	if _frame == 155:
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_press("ui_left")

	if _frame == 165:
		Input.action_press("ui_accept")

	if _frame == 167:
		Input.action_release("ui_accept")

	if _frame == 175:
		Input.action_release("ui_left")
		# Unlock lightning
		_unlock_weapon("lightning")
		_spawn_at("goblin", Vector2(200, 80))
		_spawn_at("slime", Vector2(50, 80))
		_spawn_at("bat", Vector2(180, 180))

	if _frame == 190:
		Input.action_press("ui_right")
		Input.action_press("ui_down")

	if _frame == 200:
		_spawn_at("skeleton", Vector2(128, 30))
		_spawn_at("mushroom", Vector2(220, 112))

	# --- PHASE 3 (frames 210-330, ~4s): Show level-up menu briefly, then unlock holy water ---
	if _frame == 210:
		Input.action_release("ui_right")
		Input.action_release("ui_down")
		# Force level-up to show the menu
		_force_levelup_show()

	if _frame == 270:
		# Dismiss level-up after ~2s of display
		_dismiss_levelup()

	if _frame == 275:
		# Unlock holy water
		_unlock_weapon("holy_water")
		Input.action_press("ui_down")
		Input.action_press("ui_left")
		_spawn_at("dragon", Vector2(220, 50))
		_spawn_at("ogre", Vector2(40, 180))
		_spawn_at("slime_king", Vector2(210, 180))

	if _frame == 300:
		Input.action_release("ui_down")
		Input.action_release("ui_left")
		Input.action_press("ui_right")

	if _frame == 310:
		Input.action_press("ui_accept")

	if _frame == 312:
		Input.action_release("ui_accept")

	if _frame == 320:
		_spawn_at("wolfpack", Vector2(30, 112))
		_spawn_at("bat", Vector2(200, 40))
		_spawn_at("skeleton", Vector2(60, 50))

	# --- PHASE 4 (frames 330-510, ~6s): Ice floor gimmick + intense combat ---
	if _frame == 330:
		Input.action_release("ui_right")
		# Activate ice floor gimmick
		if _event_bus:
			_event_bus.gimmick_activated.emit("ice_floor", 6.0, "presentation")

	if _frame == 340:
		Input.action_press("ui_right")
		Input.action_press("ui_down")
		_spawn_at("slime", Vector2(30, 30))
		_spawn_at("slime", Vector2(220, 30))
		_spawn_at("goblin", Vector2(30, 190))
		_spawn_at("skeleton", Vector2(220, 190))

	if _frame == 360:
		Input.action_press("ui_accept")

	if _frame == 362:
		Input.action_release("ui_accept")

	if _frame == 375:
		Input.action_release("ui_right")
		Input.action_release("ui_down")
		Input.action_press("ui_left")
		_spawn_at("bat", Vector2(200, 60))
		_spawn_at("mushroom", Vector2(50, 150))
		_spawn_at("ogre", Vector2(128, 20))

	if _frame == 400:
		Input.action_release("ui_left")
		Input.action_press("ui_up")
		Input.action_press("ui_right")

	if _frame == 415:
		Input.action_press("ui_accept")

	if _frame == 417:
		Input.action_release("ui_accept")

	if _frame == 430:
		Input.action_release("ui_up")
		Input.action_release("ui_right")
		_spawn_at("dragon", Vector2(40, 100))
		_spawn_at("goblin", Vector2(200, 160))
		_spawn_at("slime", Vector2(128, 200))

	if _frame == 450:
		Input.action_press("ui_down")
		Input.action_press("ui_left")

	if _frame == 470:
		Input.action_press("ui_accept")

	if _frame == 472:
		Input.action_release("ui_accept")

	if _frame == 480:
		Input.action_release("ui_down")
		Input.action_release("ui_left")
		_spawn_at("slime_king", Vector2(200, 50))
		_spawn_at("wolfpack", Vector2(50, 50))
		_spawn_at("skeleton", Vector2(128, 190))

	if _frame == 500:
		Input.action_press("ui_up")
		Input.action_press("ui_right")

	# --- PHASE 5 (frames 510-720, ~7s): All weapons, lots of enemies ---
	if _frame == 510:
		Input.action_release("ui_up")
		Input.action_release("ui_right")
		# Big wave
		_spawn_at("dragon", Vector2(30, 30))
		_spawn_at("ogre", Vector2(220, 30))
		_spawn_at("slime_king", Vector2(30, 190))
		_spawn_at("wolfpack", Vector2(220, 190))
		_spawn_at("skeleton", Vector2(128, 30))
		_spawn_at("bat", Vector2(128, 190))

	if _frame == 525:
		Input.action_press("ui_right")

	if _frame == 540:
		Input.action_press("ui_accept")
		_spawn_at("goblin", Vector2(60, 100))
		_spawn_at("slime", Vector2(190, 100))
		_spawn_at("mushroom", Vector2(128, 60))

	if _frame == 542:
		Input.action_release("ui_accept")

	if _frame == 560:
		Input.action_release("ui_right")
		Input.action_press("ui_down")
		Input.action_press("ui_left")

	if _frame == 580:
		_spawn_at("bat", Vector2(210, 40))
		_spawn_at("skeleton", Vector2(40, 170))
		_spawn_at("ogre", Vector2(200, 120))

	if _frame == 600:
		Input.action_release("ui_down")
		Input.action_release("ui_left")
		Input.action_press("ui_up")
		Input.action_press("ui_right")
		Input.action_press("ui_accept")

	if _frame == 602:
		Input.action_release("ui_accept")

	if _frame == 620:
		_spawn_at("dragon", Vector2(128, 200))
		_spawn_at("slime_king", Vector2(40, 112))
		_spawn_at("wolfpack", Vector2(220, 112))

	if _frame == 640:
		Input.action_release("ui_up")
		Input.action_release("ui_right")
		Input.action_press("ui_left")
		Input.action_press("ui_down")

	if _frame == 660:
		Input.action_press("ui_accept")

	if _frame == 662:
		Input.action_release("ui_accept")
		_spawn_at("goblin", Vector2(200, 40))
		_spawn_at("bat", Vector2(40, 40))
		_spawn_at("slime", Vector2(128, 30))
		_spawn_at("mushroom", Vector2(128, 190))

	if _frame == 680:
		Input.action_release("ui_left")
		Input.action_release("ui_down")
		Input.action_press("ui_right")

	if _frame == 700:
		Input.action_release("ui_right")
		Input.action_press("ui_up")

	# --- PHASE 6 (frames 720-900, ~6s): Grand finale chaos ---
	if _frame == 720:
		Input.action_release("ui_up")
		# Final chaos wave
		_spawn_at("dragon", Vector2(30, 30))
		_spawn_at("dragon", Vector2(220, 180))
		_spawn_at("slime_king", Vector2(128, 20))
		_spawn_at("wolfpack", Vector2(128, 200))
		_spawn_at("ogre", Vector2(30, 112))
		_spawn_at("ogre", Vector2(220, 112))

	if _frame == 735:
		Input.action_press("ui_right")
		Input.action_press("ui_up")

	if _frame == 750:
		Input.action_press("ui_accept")

	if _frame == 752:
		Input.action_release("ui_accept")

	if _frame == 760:
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_press("ui_down")
		_spawn_at("skeleton", Vector2(60, 30))
		_spawn_at("bat", Vector2(190, 30))
		_spawn_at("goblin", Vector2(60, 190))
		_spawn_at("slime", Vector2(190, 190))

	if _frame == 780:
		Input.action_release("ui_down")
		Input.action_press("ui_left")

	if _frame == 800:
		Input.action_press("ui_accept")
		_spawn_at("dragon", Vector2(128, 30))
		_spawn_at("wolfpack", Vector2(128, 190))

	if _frame == 802:
		Input.action_release("ui_accept")

	if _frame == 810:
		Input.action_release("ui_left")
		Input.action_press("ui_right")
		Input.action_press("ui_up")

	if _frame == 830:
		_spawn_at("slime_king", Vector2(40, 40))
		_spawn_at("ogre", Vector2(210, 40))
		_spawn_at("skeleton", Vector2(128, 180))

	if _frame == 850:
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_press("ui_accept")

	if _frame == 852:
		Input.action_release("ui_accept")

	if _frame == 870:
		Input.action_press("ui_down")
		Input.action_press("ui_right")

	if _frame == 890:
		Input.action_release("ui_down")
		Input.action_release("ui_right")

	# Do NOT call quit — movie writer handles exit via --quit-after
	return false


# --- Helper functions ---

func _spawn_at(enemy_key: String, pos: Vector2) -> void:
	if _spawn_mgr and _spawn_mgr.has_method("spawn_enemy"):
		_spawn_mgr.spawn_enemy(enemy_key, pos)

func _force_levelup_show() -> void:
	if _player == null:
		return
	_player.xp = _player.xp_to_next - 1
	_player.add_xp(1)

func _dismiss_levelup() -> void:
	if _game_state:
		_game_state.state = _game_state.State.PLAY
	var levelup = _main_scene.find_child("LevelUpMenu") if _main_scene else null
	if levelup:
		levelup.visible = false
		levelup.choices.clear()

func _unlock_weapon(weapon_key: String) -> void:
	if _player == null:
		return
	var weapons = _player.get_node_or_null("Weapons")
	if weapons == null:
		return
	match weapon_key:
		"missile":
			var w = weapons.get_node_or_null("MissileWeapon")
			if w:
				w.unlocked = true
		"blade":
			var w = weapons.get_node_or_null("OrbitBladeWeapon")
			if w:
				w.unlock_weapon()
		"lightning":
			var w = weapons.get_node_or_null("LightningWeapon")
			if w:
				w.unlocked = true
		"holy_water":
			var w = weapons.get_node_or_null("HolyWaterWeapon")
			if w:
				w.unlocked = true
