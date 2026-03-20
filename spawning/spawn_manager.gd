extends Node
## Handles enemy spawning from world edges.

const _EnemyFactory = preload("res://spawning/enemy_factory.gd")

var player: CharacterBody3D
var enemies_container: Node3D

func _ready() -> void:
	EventBus.enemy_spawned.connect(_on_enemy_spawned)

func setup(player_ref: CharacterBody3D, container: Node3D) -> void:
	player = player_ref
	enemies_container = container

func spawn_enemy(enemy_key: String, pos: Vector3 = Vector3(-1, -1, -1)) -> Node:
	if player == null or enemies_container == null:
		return null
	var enemy = _EnemyFactory.create_enemy(enemy_key, player)
	if enemy == null:
		return null
	if pos == Vector3(-1, -1, -1):
		pos = _random_edge_position()
	enemy.position = pos
	enemies_container.add_child(enemy)
	return enemy

func spawn_from_edge(enemy_key: String) -> Node:
	return spawn_enemy(enemy_key, _random_edge_position())

func _on_enemy_spawned(enemy_key: String, source: String) -> void:
	if source == "split":
		spawn_enemy(enemy_key, _random_edge_position())
	elif source == "chat":
		var enemy = spawn_from_edge(enemy_key)
		if enemy:
			var display_name: String = _EnemyFactory.DISPLAY_NAMES.get(enemy_key, enemy_key)
			EventBus.spawn_log_added.emit(display_name)

func _random_edge_position() -> Vector3:
	var edge := randi() % 4
	match edge:
		0: return Vector3(randf_range(0, Config.WORLD_W), 0, -1.0)
		1: return Vector3(randf_range(0, Config.WORLD_W), 0, Config.WORLD_H + 1.0)
		2: return Vector3(-1.0, 0, randf_range(0, Config.WORLD_H))
		3: return Vector3(Config.WORLD_W + 1.0, 0, randf_range(0, Config.WORLD_H))
	return Vector3.ZERO
