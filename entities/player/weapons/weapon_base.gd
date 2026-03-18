extends Node2D
## Base class for all player weapons.

var unlocked: bool = false
var _cooldown_timer: int = 0

func _physics_process(_delta: float) -> void:
	if not unlocked or GameState.state != GameState.State.PLAY:
		return
	if _cooldown_timer > 0:
		_cooldown_timer -= 1
	_weapon_update()

func _weapon_update() -> void:
	pass # Override

func get_enemies() -> Array:
	var scene = get_tree().current_scene
	if scene == null:
		return []
	var container = scene.find_child("Enemies")
	if container:
		return container.get_children()
	return []

func get_player() -> CharacterBody2D:
	var scene = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Player")
