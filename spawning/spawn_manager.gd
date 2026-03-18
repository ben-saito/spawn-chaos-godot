extends Node
## Handles enemy spawning from screen edges.

const _EnemyFactory = preload("res://spawning/enemy_factory.gd")

var player: CharacterBody2D
var enemies_container: Node2D

func _ready() -> void:
	EventBus.enemy_spawned.connect(_on_enemy_spawned)

func setup(player_ref: CharacterBody2D, container: Node2D) -> void:
	player = player_ref
	enemies_container = container

func spawn_enemy(enemy_key: String, pos: Vector2 = Vector2(-1, -1)) -> Node:
	if player == null or enemies_container == null:
		return null
	var enemy = _EnemyFactory.create_enemy(enemy_key, player)
	if enemy == null:
		return null
	if pos == Vector2(-1, -1):
		pos = _random_edge_position()
	enemy.position = pos
	enemies_container.add_child(enemy)
	return enemy

func spawn_from_edge(enemy_key: String) -> Node:
	return spawn_enemy(enemy_key, _random_edge_position())

func _on_enemy_spawned(enemy_key: String, source: String) -> void:
	if source == "split":
		spawn_enemy(enemy_key, _random_edge_position())
	elif source == "keyboard":
		var cost: int = _EnemyFactory.get_cost(enemy_key)
		if GameState.game_points >= cost:
			GameState.game_points -= cost
			var enemy = spawn_from_edge(enemy_key)
			if enemy:
				var display_name: String = _EnemyFactory.DISPLAY_NAMES.get(enemy_key, enemy_key)
				var entry: String = "%s -%dpt" % [display_name, cost]
				EventBus.spawn_log_added.emit(entry)
	elif source == "chat":
		var enemy = spawn_from_edge(enemy_key)
		if enemy:
			var display_name: String = _EnemyFactory.DISPLAY_NAMES.get(enemy_key, enemy_key)
			EventBus.spawn_log_added.emit(display_name)

func _random_edge_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, Config.SCREEN_W), -8)
		1: return Vector2(randf_range(0, Config.SCREEN_W), Config.SCREEN_H + 8)
		2: return Vector2(-8, randf_range(0, Config.SCREEN_H))
		3: return Vector2(Config.SCREEN_W + 8, randf_range(0, Config.SCREEN_H))
	return Vector2.ZERO
