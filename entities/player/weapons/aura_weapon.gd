extends "res://entities/player/weapons/weapon_base.gd"
## Holy Sword Aura – manual melee attack with Space bar.

var aura_damage: int = 35
var aura_range: float = 24.0
const ATTACK_COOLDOWN := 10

var _attack_timer: int = 0    # visual: counts down from 8
var _attacking: bool = false

func _ready() -> void:
	unlocked = true  # Always available

func _weapon_update() -> void:
	if _attack_timer > 0:
		_attack_timer -= 1
		queue_redraw()

	if _cooldown_timer > 0:
		return

	if Input.is_action_just_pressed("ui_accept"):  # Space
		_perform_attack()

func _perform_attack() -> void:
	_attacking = true
	_attack_timer = 8
	_cooldown_timer = ATTACK_COOLDOWN
	var player_pos: Vector2 = get_parent().get_parent().position  # Player node
	# Hit all enemies in range
	for enemy in get_enemies():
		if enemy.has_method("take_damage") and enemy.alive:
			if player_pos.distance_to(enemy.position) < aura_range:
				enemy.take_damage(aura_damage)
	queue_redraw()

func _draw() -> void:
	if _attack_timer > 0:
		# Expanding ring effect
		var progress := 1.0 - (_attack_timer / 8.0)
		var radius := aura_range * progress
		var alpha := 0.6 * (1.0 - progress)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.3, 0.7, 1.0, alpha), 2.0)
		# Inner ring
		draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 16, Color(1.0, 1.0, 1.0, alpha * 0.5), 1.0)
