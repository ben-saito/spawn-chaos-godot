extends Node
## Manages active gimmick timers and effects.

var ice_floor_timer: float = 0.0
var darkness_timer: float = 0.0
var gravity_timer: float = 0.0

var ice_floor_active: bool:
	get: return ice_floor_timer > 0
var darkness_active: bool:
	get: return darkness_timer > 0
var gravity_active: bool:
	get: return gravity_timer > 0

func _ready() -> void:
	EventBus.gimmick_activated.connect(_on_gimmick_activated)
	EventBus.game_reset.connect(_on_game_reset)

func _physics_process(delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return
	if ice_floor_timer > 0:
		ice_floor_timer -= delta
		if ice_floor_timer <= 0:
			EventBus.gimmick_ended.emit("ice_floor")
	if darkness_timer > 0:
		darkness_timer -= delta
		if darkness_timer <= 0:
			EventBus.gimmick_ended.emit("darkness")
	if gravity_timer > 0:
		gravity_timer -= delta
		if gravity_timer <= 0:
			EventBus.gimmick_ended.emit("gravity")

func _on_gimmick_activated(gimmick_key: String, duration: float, _source: String) -> void:
	match gimmick_key:
		"ice_floor":
			ice_floor_timer = duration
		"darkness":
			darkness_timer = duration
		"gravity":
			gravity_timer = duration

func _on_game_reset() -> void:
	ice_floor_timer = 0.0
	darkness_timer = 0.0
	gravity_timer = 0.0
