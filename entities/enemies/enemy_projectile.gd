extends Area2D
## Generic enemy projectile (bones, fireballs, spores).

var velocity: Vector2 = Vector2.ZERO
var damage: int = 5
var color: Color = Color.WHITE
var lifetime: int = 120
var _timer: int = 0

func setup(pos: Vector2, vel: Vector2, dmg: int, col: Color) -> void:
	position = pos
	velocity = vel
	damage = dmg
	color = col

func _physics_process(_delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	position += velocity
	_timer += 1
	if _timer >= lifetime:
		queue_free()
		return
	# Check screen bounds
	if position.x < -8 or position.x > Config.SCREEN_W + 8 \
		or position.y < -8 or position.y > Config.SCREEN_H + 8:
		queue_free()
		return
	# Check collision with player
	var scene = get_tree().current_scene
	var player_node = scene.find_child("Player") if scene else null
	if player_node and not player_node.invincible:
		if position.distance_to(player_node.position) < 6.0:
			player_node.take_damage(damage)
			queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.0, color)
