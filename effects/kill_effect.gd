extends Node3D
## Burst of particles when an enemy dies.

var _age: float = 0.0
var _lifetime: float = 0.6
var _particles: Array = []

func setup(pos: Vector3, color: Color, size: float = 0.5) -> void:
	position = pos
	# Create burst of small spheres flying outward
	var particle_count := 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color.lightened(0.3)
	mat.emission_energy_multiplier = 2.0

	for i in range(particle_count):
		var p := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = randf_range(0.05, 0.12) * size
		sphere.height = sphere.radius * 2
		p.mesh = sphere
		p.material_override = mat
		var angle := TAU * i / particle_count + randf_range(-0.3, 0.3)
		var vel := Vector3(cos(angle), randf_range(1.0, 3.0), sin(angle)) * randf_range(1.5, 3.0)
		add_child(p)
		_particles.append({"node": p, "vel": vel})

func _process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	var alpha := 1.0 - (_age / _lifetime)
	for p in _particles:
		var node: MeshInstance3D = p["node"]
		var vel: Vector3 = p["vel"]
		node.position += vel * delta
		p["vel"].y -= 8.0 * delta  # gravity
		node.scale = Vector3.ONE * alpha
