extends Node
## Mutable global game state.

enum State { TUTORIAL, WEAPON_SELECT, PLAY, LEVELUP, GAMEOVER }

var state: State = State.TUTORIAL
var elapsed_frames: int = 0
var score: int = 0
var game_points: int = Config.INITIAL_GAME_POINTS   # keyboard spawns

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW := 2.0  # seconds to chain kills
var combo_multiplier: float = 1.0

# Helpers
func elapsed_seconds() -> float:
	return elapsed_frames / float(Config.PHYSICS_FPS)

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

func reset() -> void:
	state = State.WEAPON_SELECT
	elapsed_frames = 0
	score = 0
	game_points = Config.INITIAL_GAME_POINTS
	combo_count = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
