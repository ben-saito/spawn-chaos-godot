extends Node
## Mutable global game state.

enum State { TUTORIAL, WEAPON_SELECT, PLAY, LEVELUP, GAMEOVER }

var state: State = State.TUTORIAL
var elapsed_frames: int = 0
var score: int = 0

# Countdown timer (starts at GAME_DURATION, counts down)
var remaining_time: float = float(Config.GAME_DURATION)

# Phase (1-3)
var phase: int = 1

# Game result
var game_result: String = "none"  # "none", "streamer_win", "viewer_win"

# Viewer stats
var viewer_total_spawns: int = 0    # total enemies spawned by viewers
var viewer_total_damage: int = 0    # total damage dealt to player by viewer-spawned enemies

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW := 2.0  # seconds to chain kills
var combo_multiplier: float = 1.0

# Helpers
func elapsed_seconds() -> float:
	return float(Config.GAME_DURATION) - remaining_time

func add_kill() -> void:
	combo_count += 1
	combo_timer = COMBO_WINDOW
	# Multiplier: 1x base, +0.1 per combo, max 5x
	combo_multiplier = minf(1.0 + combo_count * 0.1, 5.0)

func update_combo(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_multiplier = 1.0

## Returns the viewer cost multiplier for the current phase.
func get_viewer_cost_multiplier() -> float:
	match phase:
		2:
			return Config.VIEWER_COST_MULT_PHASE2
		3:
			return Config.VIEWER_COST_MULT_PHASE3
		_:
			return Config.VIEWER_COST_MULT_PHASE1

func reset() -> void:
	state = State.WEAPON_SELECT
	elapsed_frames = 0
	score = 0
	remaining_time = float(Config.GAME_DURATION)
	phase = 1
	game_result = "none"
	viewer_total_spawns = 0
	viewer_total_damage = 0
	combo_count = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
