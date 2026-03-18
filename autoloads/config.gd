extends Node
## Pure constants – no mutable state.

# Screen
const SCREEN_W := 256
const SCREEN_H := 224

# Physics / frame rate
const PHYSICS_FPS := 30

# Game-points pool (keyboard spawns / gimmicks)
const INITIAL_GAME_POINTS := 200
const GAME_POINTS_RECOVERY := 5        # per second
const MAX_GAME_POINTS := 99999

# Viewer-points (Twitcasting chat)
const INITIAL_VIEWER_POINTS := 100
const MAX_VIEWER_POINTS := 1000
const VIEWER_POINTS_RECOVERY := 15     # per minute

# Gimmick costs
const GIMMICK_COSTS := {
	"ice_floor": 50,
	"darkness": 80,
	"gravity": 120,
}

# Gimmick durations (seconds)
const GIMMICK_DURATIONS := {
	"ice_floor": 30.0,
	"darkness": 20.0,
	"gravity": 10.0,
}

# XP curve
const BASE_XP_TO_NEXT := 30
const XP_GROWTH_RATE := 1.3

# Wave table: [start_sec, interval_frames, pool, count]
const WAVE_TABLE := [
	[0,   60,  ["slime", "slime", "slime", "goblin"], 1],
	[30,  45,  ["slime", "goblin", "goblin", "bat", "mushroom"], 2],
	[60,  40,  ["goblin", "skeleton", "bat", "mushroom", "ogre"], 2],
	[120, 30,  ["skeleton", "ogre", "bat", "mushroom", "goblin"], 3],
	[180, 25,  ["ogre", "skeleton", "bat", "mushroom", "goblin", "slime_king"], 3],
	[240, 20,  ["ogre", "dragon", "slime_king", "wolfpack", "skeleton"], 4],
]

# Boss schedule: [time_sec, enemy_key]
const BOSS_SCHEDULE := [
	[45,  "ogre"],
	[90,  "slime_king"],
	[150, "dragon"],
	[210, "wolfpack"],
	[270, "dragon"],
]

# Enemy key -> keyboard shortcut
const SPAWN_KEYS := {
	KEY_1: "slime",
	KEY_2: "goblin",
	KEY_3: "skeleton",
	KEY_4: "ogre",
	KEY_5: "dragon",
	KEY_6: "bat",
	KEY_7: "mushroom",
	KEY_8: "slime_king",
	KEY_9: "wolfpack",
}

# Gimmick key -> keyboard shortcut
const GIMMICK_KEYS := {
	KEY_Q: "ice_floor",
	KEY_W: "darkness",
	KEY_E: "gravity",
}

# Pyxel 16-colour palette (kept for reference / procedural drawing)
const PALETTE: Array[Color] = [
	Color(0.0,    0.0,    0.0),       # 0  Black
	Color(0.114,  0.169,  0.325),     # 1  Dark Blue
	Color(0.494,  0.145,  0.325),     # 2  Dark Purple
	Color(0.0,    0.529,  0.318),     # 3  Dark Green
	Color(0.671,  0.322,  0.212),     # 4  Brown
	Color(0.373,  0.341,  0.31),      # 5  Dark Gray
	Color(0.761,  0.765,  0.78),      # 6  Light Gray
	Color(1.0,    0.945,  0.91),      # 7  White
	Color(1.0,    0.0,    0.302),     # 8  Red
	Color(1.0,    0.639,  0.0),       # 9  Orange
	Color(1.0,    0.925,  0.153),     # 10 Yellow
	Color(0.0,    0.894,  0.212),     # 11 Green
	Color(0.161,  0.678,  1.0),       # 12 Blue
	Color(0.514,  0.463,  0.612),     # 13 Indigo
	Color(1.0,    0.467,  0.659),     # 14 Pink
	Color(1.0,    0.8,    0.667),     # 15 Peach
]
