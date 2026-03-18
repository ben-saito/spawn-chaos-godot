extends Area2D
## Shared enemy logic: HP, damage flash, contact, drawing HP bar.

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
var player: CharacterBody2D

func initialize(enemy_def, player_ref: CharacterBody2D) -> void:
	def_data = enemy_def
	hp = enemy_def.hp
	max_hp = enemy_def.hp
	damage = enemy_def.damage
	speed = enemy_def.speed
	enemy_key = enemy_def.key
	player = player_ref

func _physics_process(_delta: float) -> void:
	if not alive or GameState.state != GameState.State.PLAY:
		return
	_timer += 1
	if _hit_flash_timer > 0:
		_hit_flash_timer -= 1
	_ai_update()
	_check_player_contact()
	queue_redraw()

func _ai_update() -> void:
	pass # Override in AI subclass

func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount
	_hit_flash_timer = 4
	if hp <= 0:
		_die()

func _die() -> void:
	alive = false
	GameState.score += def_data.cost
	EventBus.enemy_killed.emit(enemy_key, def_data.cost)
	# Split handling (e.g., Slime King -> 3 Slimes)
	if def_data.split_on_death and def_data.split_into != "":
		for i in range(def_data.split_count):
			var offset := Vector2(randf_range(-16, 16), randf_range(-16, 16))
			EventBus.enemy_spawned.emit(def_data.split_into, "split")
			# SpawnManager listens and spawns at position + offset
	queue_free()

func _check_player_contact() -> void:
	if player == null or player.invincible:
		return
	var contact_dist: float = (def_data.size + 8) / 2.0
	if position.distance_to(player.position) < contact_dist:
		player.take_damage(damage)

func _get_dir_to_player() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return (player.position - position).normalized()

func _get_dist_to_player() -> float:
	if player == null:
		return 9999.0
	return position.distance_to(player.position)

func _draw() -> void:
	# Base: draw body as colored rect
	var color: Color = def_data.color if def_data != null else Color.RED
	if _hit_flash_timer > 0:
		color = Color.WHITE
	var half: float = def_data.size / 2.0 if def_data != null else 4.0
	draw_rect(Rect2(-half, -half, half * 2, half * 2), color)

	# HP bar above enemy
	if hp < max_hp and alive:
		var bar_w: float = half * 2
		var bar_y: float = -half - 4
		draw_rect(Rect2(-half, bar_y, bar_w, 2), Color(0.3, 0.3, 0.3))
		var hp_ratio := float(hp) / float(max_hp)
		draw_rect(Rect2(-half, bar_y, bar_w * hp_ratio, 2), Color(0.0, 1.0, 0.0))
