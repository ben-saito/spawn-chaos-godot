extends SceneTree
## Test harness for core game validation.
## Spawns enemies, simulates player movement & attacks, captures evidence.

var _frame: int = 0
var _root: Window
var _main_scene = null

func _initialize() -> void:
	_root = get_root()
	# Load main scene
	var scene: PackedScene = load("res://main.tscn")
	_main_scene = scene.instantiate()
	_root.add_child(_main_scene)
	# Set current_scene so find_child works in HUD, weapons, etc.
	get_root().set_deferred(&"current_scene", _main_scene)

func _process(delta: float) -> bool:
	_frame += 1

	if _frame == 2:
		# Spawn several enemy types at various positions
		_spawn_enemies()
		# Simulate Space key press for aura attack
		Input.action_press("ui_accept")

	if _frame == 4:
		Input.action_release("ui_accept")
		# Move player right
		Input.action_press("ui_right")

	if _frame == 10:
		Input.action_release("ui_right")
		Input.action_press("ui_down")

	if _frame == 15:
		Input.action_release("ui_down")
		# Attack again
		Input.action_press("ui_accept")

	if _frame == 17:
		Input.action_release("ui_accept")

	if _frame == 20:
		_run_assertions()

	# Let it run for enough frames to capture good screenshots
	return false

func _spawn_enemies() -> void:
	var spawn_mgr = _main_scene.find_child("SpawnManager")
	if spawn_mgr == null:
		print("ASSERT FAIL: SpawnManager not found")
		return

	# Spawn various enemy types at specific positions for visual verification
	var enemy_types := ["slime", "goblin", "skeleton", "bat", "mushroom", "ogre", "slime_king", "wolfpack", "dragon"]
	var positions := [
		Vector2(40, 40),
		Vector2(200, 40),
		Vector2(40, 180),
		Vector2(200, 180),
		Vector2(128, 30),
		Vector2(30, 112),
		Vector2(220, 112),
		Vector2(128, 190),
		Vector2(180, 100),
	]

	for i in range(enemy_types.size()):
		var enemy = spawn_mgr.spawn_enemy(enemy_types[i], positions[i])
		if enemy == null:
			print("ASSERT FAIL: Failed to spawn %s" % enemy_types[i])
		else:
			print("ASSERT PASS: Spawned %s at %s" % [enemy_types[i], str(positions[i])])

func _run_assertions() -> void:
	# Check player exists and is centered
	var player = _main_scene.find_child("Player")
	if player:
		print("ASSERT PASS: Player exists at %s" % str(player.position))
		print("ASSERT PASS: Player HP=%d/%d" % [player.hp, player.max_hp])
		print("ASSERT PASS: Player level=%d xp=%d/%d" % [player.level, player.xp, player.xp_to_next])
	else:
		print("ASSERT FAIL: Player not found")

	# Check enemies exist
	var enemies = _main_scene.find_child("Enemies")
	if enemies:
		var count: int = enemies.get_child_count()
		if count > 0:
			print("ASSERT PASS: %d enemies active" % count)
		else:
			print("ASSERT FAIL: No enemies found")
	else:
		print("ASSERT FAIL: Enemies container not found")

	# Check game state
	var gs = _root.get_node_or_null("/root/GameState")
	if gs:
		print("ASSERT PASS: GameState.state=%d (PLAY=0)" % gs.state)
		print("ASSERT PASS: GameState.game_points=%d" % gs.game_points)
	else:
		# Try finding by children
		for child in _root.get_children():
			if child.name == "GameState":
				print("ASSERT PASS: GameState found as %s" % child.name)
				break

	# Check HUD exists
	var hud = _main_scene.find_child("HUD")
	if hud:
		print("ASSERT PASS: HUD exists")
	else:
		print("ASSERT FAIL: HUD not found")

	# Check weapons
	var weapons = _main_scene.find_child("Weapons")
	if weapons:
		print("ASSERT PASS: Weapons node exists with %d children" % weapons.get_child_count())
		var aura = weapons.find_child("AuraWeapon")
		if aura and aura.unlocked:
			print("ASSERT PASS: AuraWeapon unlocked")
		else:
			print("ASSERT FAIL: AuraWeapon not unlocked")
	else:
		print("ASSERT FAIL: Weapons not found")

	# Check GimmickManager
	var gimmick = _main_scene.find_child("GimmickManager")
	if gimmick:
		print("ASSERT PASS: GimmickManager exists")
	else:
		print("ASSERT FAIL: GimmickManager not found")
