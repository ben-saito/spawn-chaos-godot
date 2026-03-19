extends Area3D
## Generic enemy projectile (bones, fireballs, spores).

var velocity: Vector3 = Vector3.ZERO
var damage: int = 5
var color: Color = Color.WHITE
var lifetime: int = 120
var _timer: int = 0

var _mesh: MeshInstance3D
var _collision: CollisionShape3D

func setup(pos: Vector3, vel: Vector3, dmg: int, col: Color) -> void:
	position = pos
	velocity = vel
	damage = dmg
	color = col

func _ready() -> void:
	# Create mesh
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	_mesh.material_override = mat
	add_child(_mesh)

	# Create collision
	_collision = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	_collision.shape = shape
	add_child(_collision)

func _physics_process(_delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	position += velocity
	_timer += 1
	if _timer >= lifetime:
		queue_free()
		return
	# Check world bounds
	if position.x < -1 or position.x > Config.WORLD_W + 1 \
		or position.z < -1 or position.z > Config.WORLD_H + 1:
		queue_free()
		return
	# Check collision with player
	var scene = get_tree().current_scene
	var player_node = scene.find_child("Player") if scene else null
	if player_node and not player_node.invincible:
		var dx: float = position.x - player_node.position.x
		var dz: float = position.z - player_node.position.z
		if sqrt(dx * dx + dz * dz) < 0.5:
			player_node.take_damage(damage)
			queue_free()
