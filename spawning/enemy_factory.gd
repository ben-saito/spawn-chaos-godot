extends RefCounted
## Creates enemy instances from key names.

const _EnemyBaseScript = preload("res://entities/enemies/enemy_base.gd")
const _EnemyDefScript = preload("res://resources/enemy_def.gd")

# Map enemy key -> AI script
const AI_SCRIPTS := {
	"slime": preload("res://entities/enemies/behaviors/slime_ai.gd"),
	"goblin": preload("res://entities/enemies/behaviors/goblin_ai.gd"),
	"skeleton": preload("res://entities/enemies/behaviors/skeleton_ai.gd"),
	"bat": preload("res://entities/enemies/behaviors/bat_ai.gd"),
	"mushroom": preload("res://entities/enemies/behaviors/mushroom_ai.gd"),
	"ogre": preload("res://entities/enemies/behaviors/ogre_ai.gd"),
	"slime_king": preload("res://entities/enemies/behaviors/slime_king_ai.gd"),
	"wolfpack": preload("res://entities/enemies/behaviors/wolfpack_ai.gd"),
	"dragon": preload("res://entities/enemies/behaviors/dragon_ai.gd"),
}

# Enemy definitions (inline – no .tres files needed)
const ENEMY_DEFS := {
	"slime":      { "hp": 30,  "speed": 0.8, "damage": 5,  "size": 6,  "cost": 10,  "color": "2db82d", "split": false },
	"goblin":     { "hp": 50,  "speed": 1.2, "damage": 10, "size": 7,  "cost": 20,  "color": "994d1a", "split": false },
	"skeleton":   { "hp": 70,  "speed": 1.0, "damage": 15, "size": 8,  "cost": 30,  "color": "d9d9cc", "split": false },
	"bat":        { "hp": 40,  "speed": 1.5, "damage": 12, "size": 6,  "cost": 25,  "color": "663380", "split": false },
	"mushroom":   { "hp": 50,  "speed": 0.5, "damage": 8,  "size": 7,  "cost": 15,  "color": "b3804d", "split": false },
	"ogre":       { "hp": 150, "speed": 0.6, "damage": 25, "size": 10, "cost": 80,  "color": "805933", "split": false },
	"slime_king": { "hp": 400, "speed": 0.5, "damage": 30, "size": 14, "cost": 150, "color": "1abf1a", "split": true, "split_into": "slime", "split_count": 3 },
	"wolfpack":   { "hp": 200, "speed": 1.4, "damage": 40, "size": 8,  "cost": 300, "color": "80808c", "split": false },
	"dragon":     { "hp": 400, "speed": 0.8, "damage": 40, "size": 12, "cost": 500, "color": "cc261a", "split": false },
}

# Display names (Japanese)
const DISPLAY_NAMES := {
	"slime": "スライム",
	"goblin": "ゴブリン",
	"skeleton": "スケルトン",
	"bat": "バット",
	"mushroom": "マッシュルーム",
	"ogre": "オーガ",
	"slime_king": "スライムキング",
	"wolfpack": "ウルフパック",
	"dragon": "ドラゴン",
}

static func get_cost(enemy_key: String) -> int:
	if ENEMY_DEFS.has(enemy_key):
		return ENEMY_DEFS[enemy_key]["cost"]
	return 0

static func create_enemy(enemy_key: String, player_ref: CharacterBody2D) -> Area2D:
	if not AI_SCRIPTS.has(enemy_key) or not ENEMY_DEFS.has(enemy_key):
		return null

	var data: Dictionary = ENEMY_DEFS[enemy_key]
	var def = _EnemyDefScript.new()
	def.key = enemy_key
	def.display_name = DISPLAY_NAMES.get(enemy_key, enemy_key)
	def.hp = data["hp"]
	def.speed = data["speed"]
	def.damage = data["damage"]
	def.size = data["size"]
	def.cost = data["cost"]
	def.color = Color(data["color"])
	def.split_on_death = data.get("split", false)
	def.split_into = data.get("split_into", "")
	def.split_count = data.get("split_count", 0)

	var enemy = Area2D.new()
	enemy.set_script(AI_SCRIPTS[enemy_key])
	enemy.initialize(def, player_ref)
	return enemy
