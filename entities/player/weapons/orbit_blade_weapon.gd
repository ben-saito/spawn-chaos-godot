extends "res://entities/player/weapons/weapon_base.gd"
## Orbit Blade – blades rotate around the player, damaging enemies on contact.

var blade_count: int = 0
var blade_damage: int = 12
const ORBIT_RADIUS := 28.0
const ORBIT_SPEED := 0.06
const HIT_COOLDOWN := 15

var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}  # enemy instance_id -> frames remaining

func _weapon_update() -> void:
	if blade_count <= 0:
		return
	_angle += ORBIT_SPEED
	# Tick down hit cooldowns
	var to_remove := []
	for eid in _hit_cooldowns:
		_hit_cooldowns[eid] -= 1
		if _hit_cooldowns[eid] <= 0:
			to_remove.append(eid)
	for eid in to_remove:
		_hit_cooldowns.erase(eid)
	# Check collisions
	var player_node := get_player()
	if player_node == null:
		return
	for i in range(blade_count):
		var angle := _angle + (TAU / blade_count) * i
		var blade_pos := player_node.position + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS
		for enemy in get_enemies():
			if enemy.has_method("take_damage") and enemy.alive:
				var eid: int = enemy.get_instance_id()
				if _hit_cooldowns.has(eid):
					continue
				if blade_pos.distance_to(enemy.position) < 8.0:
					enemy.take_damage(blade_damage)
					_hit_cooldowns[eid] = HIT_COOLDOWN
	queue_redraw()

func _draw() -> void:
	if blade_count <= 0:
		return
	for i in range(blade_count):
		var angle := _angle + (TAU / blade_count) * i
		var blade_pos := Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS
		# Blade shape
		var perp := Vector2(-sin(angle), cos(angle)) * 4.0
		draw_line(blade_pos - perp, blade_pos + perp, Color(0.8, 0.85, 1.0), 2.0)
		draw_circle(blade_pos, 2.0, Color(0.6, 0.7, 1.0))

func unlock_weapon() -> void:
	unlocked = true
	blade_count = 2
