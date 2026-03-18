extends Node
## Mutable global game state.

enum State { PLAY, LEVELUP, GAMEOVER }

var state: State = State.PLAY
var elapsed_frames: int = 0
var score: int = 0
var game_points: int = Config.INITIAL_GAME_POINTS   # keyboard spawns

# Helpers
func elapsed_seconds() -> float:
	return elapsed_frames / float(Config.PHYSICS_FPS)

func reset() -> void:
	state = State.PLAY
	elapsed_frames = 0
	score = 0
	game_points = Config.INITIAL_GAME_POINTS
