extends Node3D
## Base NPC – friendly character with speech bubble and interaction.

const _QuestSystem = preload("res://entities/quest_system.gd")

var npc_name: String = "NPC"
var npc_type: String = "quest"  # "quest" or "shop"
var quest_pool: Array = []  # Array of quest Dictionaries
var _current_quest_offer: Dictionary = {}

# Mesh references
var _character_root: Node3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _speech_bubble: Label3D
var _name_label: Label3D
var _body_color: Color = Color(0.2, 0.7, 0.3)
var _head_color: Color = Color(1.0, 0.85, 0.72)

# Interaction state
var _player_nearby: bool = false
var _interact_label: Label3D
var _anim_timer: float = 0.0

# Reference to quest system (set by main.gd)
var quest_system: Node = null

func setup(pos: Vector3, p_name: String, body_color: Color, quests: Array) -> void:
	position = pos
	npc_name = p_name
	_body_color = body_color
	quest_pool = quests
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

	# Body (capsule)
	_body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 0.75
	_body_mesh.mesh = capsule
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = _body_color
	body_mat.roughness = 0.7
	_body_mesh.material_override = body_mat
	_body_mesh.position = Vector3(0, 0.4, 0)
	_character_root.add_child(_body_mesh)

	# Head (sphere)
	_head_mesh = MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.25
	head_sphere.height = 0.5
	_head_mesh.mesh = head_sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = _head_color
	head_mat.roughness = 0.8
	_head_mesh.material_override = head_mat
	_head_mesh.position = Vector3(0, 0.9, 0)
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
		eye.position = Vector3(x_off, 0.93, -0.21)
		_character_root.add_child(eye)

	# Name label above head
	_name_label = Label3D.new()
	_name_label.text = npc_name
	_name_label.font_size = 48
	_name_label.pixel_size = 0.01
	_name_label.position = Vector3(0, 1.5, 0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.modulate = Color(1, 1, 0.8)
	_name_label.outline_modulate = Color(0, 0, 0)
	_name_label.outline_size = 8
	_name_label.no_depth_test = true
	add_child(_name_label)

	# Speech bubble (! or ?)
	_speech_bubble = Label3D.new()
	_speech_bubble.text = "!"
	_speech_bubble.font_size = 64
	_speech_bubble.pixel_size = 0.01
	_speech_bubble.position = Vector3(0, 1.8, 0)
	_speech_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_bubble.modulate = Color(1, 1, 0)
	_speech_bubble.outline_modulate = Color(0, 0, 0)
	_speech_bubble.outline_size = 10
	_speech_bubble.no_depth_test = true
	add_child(_speech_bubble)

	# Interaction prompt (hidden by default)
	_interact_label = Label3D.new()
	_interact_label.text = "[F] 話す"
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

	# Idle bobbing
	if _character_root:
		_character_root.position.y = sin(_anim_timer * 2.0) * 0.05

	# Speech bubble bounce
	if _speech_bubble:
		_speech_bubble.position.y = 1.8 + sin(_anim_timer * 3.0) * 0.08

	# Update speech bubble icon
	_update_speech_bubble()

func _update_speech_bubble() -> void:
	if _speech_bubble == null:
		return
	if quest_system and quest_system.has_active_quest():
		# Quest in progress
		_speech_bubble.text = "?"
		_speech_bubble.modulate = Color(0.5, 0.8, 1.0)
	else:
		# Has quest available
		_speech_bubble.text = "!"
		_speech_bubble.modulate = Color(1, 1, 0)

func check_player_distance(player_pos: Vector3) -> bool:
	var dist: float = position.distance_to(player_pos)
	_player_nearby = dist < 2.0
	if _interact_label:
		_interact_label.visible = _player_nearby
	return _player_nearby

func interact(player: CharacterBody3D) -> Dictionary:
	## Called when player presses F near this NPC. Returns action info.
	if not _player_nearby:
		return {}

	# If quest system has active quest, check completion
	if quest_system and quest_system.has_active_quest():
		if quest_system.check_completion():
			var reward: Dictionary = quest_system.complete_quest()
			return { "action": "quest_complete", "reward": reward }
		else:
			var progress: Array = quest_system.get_progress()
			return { "action": "quest_progress", "current": progress[0], "target": progress[1] }

	# Offer new quest from pool
	if quest_pool.size() > 0:
		_current_quest_offer = _pick_quest()
		return { "action": "quest_offer", "quest": _current_quest_offer }

	return {}

func accept_current_quest() -> void:
	if quest_system and _current_quest_offer.size() > 0:
		quest_system.accept_quest(_current_quest_offer)
		_current_quest_offer.clear()

func _pick_quest() -> Dictionary:
	# Pick a random quest from pool that hasn't been completed
	var available: Array = []
	for q in quest_pool:
		var q_id: String = q.get("id", "")
		if quest_system == null or not quest_system.completed_quests.has(q_id):
			available.append(q)
	if available.size() == 0:
		# All done, recycle
		available = quest_pool.duplicate()
	return available[randi() % available.size()]
