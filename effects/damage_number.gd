extends Node3D
## Floating damage number that pops up and fades.

var _label: Label3D
var _velocity: Vector3
var _lifetime: float = 0.8
var _age: float = 0.0

func setup(pos: Vector3, amount: int, color: Color = Color.WHITE, is_crit: bool = false) -> void:
	position = pos + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.3, 0.3))
	_velocity = Vector3(randf_range(-0.5, 0.5), 3.0, randf_range(-0.5, 0.5))

	_label = Label3D.new()
	_label.text = str(amount)
	if is_crit:
		_label.text += "!"
		_label.font_size = 48
	else:
		_label.font_size = 32
	_label.modulate = color
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.outline_size = 8
	_label.outline_modulate = Color(0, 0, 0, 0.8)
	add_child(_label)

func _process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	position += _velocity * delta
	_velocity.y -= 5.0 * delta  # gravity
	var alpha := 1.0 - (_age / _lifetime)
	if _label:
		_label.modulate.a = alpha
		# Scale up then down
		var t := _age / _lifetime
		var s := 1.0 + sin(t * PI) * 0.3
		_label.scale = Vector3(s, s, s)
