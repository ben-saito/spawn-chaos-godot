extends Node3D
## Shop NPC – merchant that opens shop UI on interaction.

var npc_name: String = "商人"

# Mesh references
var _character_root: Node3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _speech_bubble: Label3D
var _name_label: Label3D
var _interact_label: Label3D
var _hat: MeshInstance3D
var _bag: MeshInstance3D
var _anim_timer: float = 0.0
var _player_nearby: bool = false

func setup(pos: Vector3) -> void:
	position = pos
	_build_mesh()

func _build_mesh() -> void:
	# Shadow
	_shadow = MeshInstance3D.new()
	var shadow_cyl := CylinderMesh.new()
	shadow_cyl.top_radius = 0.4
	shadow_cyl.bottom_radius = 0.4
	shadow_cyl.height = 0.02
	_shadow.mesh = shadow_cyl
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(0, 0.01, 0)
	add_child(_shadow)

	_character_root = Node3D.new()
	_character_root.name = "CharacterRoot"
	add_child(_character_root)

	# Body (capsule - purple robe)
	_body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32
	capsule.height = 0.8
	_body_mesh.mesh = capsule
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.5, 0.2, 0.6)
	body_mat.roughness = 0.7
	_body_mesh.material_override = body_mat
	_body_mesh.position = Vector3(0, 0.42, 0)
	_character_root.add_child(_body_mesh)

	# Head (sphere)
	_head_mesh = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.25
	head_sphere.height = 0.5
	_head_mesh.mesh = head_sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(1.0, 0.85, 0.72)
	head_mat.roughness = 0.8
	_head_mesh.material_override = head_mat
	_head_mesh.position = Vector3(0, 0.95, 0)
	_character_root.add_child(_head_mesh)

	# Eyes
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.08, 0.06)
	eye_mat.roughness = 0.2
	var eye_sphere := SphereMesh.new()
	eye_sphere.radius = 0.04
	eye_sphere.height = 0.08
	for x_off in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		eye.mesh = eye_sphere
		eye.material_override = eye_mat
		eye.position = Vector3(x_off, 0.98, -0.21)
		_character_root.add_child(eye)

	# Merchant hat (cone)
	_hat = MeshInstance3D.new()
	var hat_cone := CylinderMesh.new()
	hat_cone.top_radius = 0.0
	hat_cone.bottom_radius = 0.3
	hat_cone.height = 0.35
	_hat.mesh = hat_cone
	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_color = Color(0.7, 0.5, 0.1)
	hat_mat.metallic = 0.3
	hat_mat.roughness = 0.5
	_hat.material_override = hat_mat
	_hat.position = Vector3(0, 1.3, 0)
	_character_root.add_child(_hat)

	# Backpack (box behind)
	_bag = MeshInstance3D.new()
	var bag_box := BoxMesh.new()
	bag_box.size = Vector3(0.35, 0.35, 0.25)
	_bag.mesh = bag_box
	var bag_mat := StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.55, 0.35, 0.15)
	bag_mat.roughness = 0.8
	_bag.material_override = bag_mat
	_bag.position = Vector3(0, 0.5, 0.25)
	_character_root.add_child(_bag)

	# Name label
	_name_label = Label3D.new()
	_name_label.text = npc_name
	_name_label.font_size = 48
	_name_label.pixel_size = 0.01
	_name_label.position = Vector3(0, 1.6, 0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.modulate = Color(1, 0.9, 0.5)
	_name_label.outline_modulate = Color(0, 0, 0)
	_name_label.outline_size = 8
	_name_label.no_depth_test = true
	add_child(_name_label)

	# Speech bubble (coin icon)
	_speech_bubble = Label3D.new()
	_speech_bubble.text = "$"
	_speech_bubble.font_size = 64
	_speech_bubble.pixel_size = 0.01
	_speech_bubble.position = Vector3(0, 1.9, 0)
	_speech_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_bubble.modulate = Color(1, 0.85, 0)
	_speech_bubble.outline_modulate = Color(0, 0, 0)
	_speech_bubble.outline_size = 10
	_speech_bubble.no_depth_test = true
	add_child(_speech_bubble)

	# Interaction prompt
	_interact_label = Label3D.new()
	_interact_label.text = "[F] ショップ"
	_interact_label.font_size = 36
	_interact_label.pixel_size = 0.01
	_interact_label.position = Vector3(0, 0.2, -0.8)
	_interact_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_interact_label.modulate = Color(0.8, 1.0, 0.8)
	_interact_label.outline_modulate = Color(0, 0, 0)
	_interact_label.outline_size = 6
	_interact_label.no_depth_test = true
	_interact_label.visible = false
	add_child(_interact_label)

func _process(delta: float) -> void:
	_anim_timer += delta
	if _character_root:
		_character_root.position.y = sin(_anim_timer * 2.0) * 0.05
	if _speech_bubble:
		_speech_bubble.position.y = 1.9 + sin(_anim_timer * 3.0) * 0.08

func check_player_distance(player_pos: Vector3) -> bool:
	var dist: float = position.distance_to(player_pos)
	_player_nearby = dist < 2.0
	if _interact_label:
		_interact_label.visible = _player_nearby
	return _player_nearby

func interact() -> Dictionary:
	if not _player_nearby:
		return {}
	return { "action": "open_shop" }
