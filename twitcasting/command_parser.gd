extends RefCounted
## Parses chat messages into game commands.

# Enemy name mappings (Japanese -> key)
const ENEMY_ALIASES := {
	"スライム": "slime",
	"slime": "slime",
	"ゴブリン": "goblin",
	"goblin": "goblin",
	"スケルトン": "skeleton",
	"skeleton": "skeleton",
	"バット": "bat",
	"bat": "bat",
	"マッシュルーム": "mushroom",
	"mushroom": "mushroom",
	"オーガ": "ogre",
	"ogre": "ogre",
	"スライムキング": "slime_king",
	"slime_king": "slime_king",
	"ウルフパック": "wolfpack",
	"wolfpack": "wolfpack",
	"ドラゴン": "dragon",
	"dragon": "dragon",
}

# Gimmick name mappings
const GIMMICK_ALIASES := {
	"アイス": "ice_floor",
	"アイスの": "ice_floor",
	"アイスフロア": "ice_floor",
	"ice": "ice_floor",
	"ダーク": "darkness",
	"ダークネス": "darkness",
	"dark": "darkness",
	"darkness": "darkness",
	"重力": "gravity",
	"グラビティ": "gravity",
	"反転": "gravity",
	"gravity": "gravity",
}

## Returns: { "command": String, "target": String, "username": String } or null
static func parse(message: String, username: String) -> Variant:
	var text := message.strip_edges().to_lower()

	# !spawn <enemy>
	if text.begins_with("!spawn ") or text.begins_with("！spawn "):
		var arg := message.strip_edges().substr(7).strip_edges()
		var enemy_key: String = ENEMY_ALIASES.get(arg, ENEMY_ALIASES.get(arg.to_lower(), ""))
		if enemy_key != "":
			return { "command": "spawn", "target": enemy_key, "username": username }

	# !gimmick <type>
	if text.begins_with("!gimmick ") or text.begins_with("！gimmick "):
		var arg := message.strip_edges().substr(9).strip_edges()
		var gimmick_key: String = GIMMICK_ALIASES.get(arg, GIMMICK_ALIASES.get(arg.to_lower(), ""))
		if gimmick_key != "":
			return { "command": "gimmick", "target": gimmick_key, "username": username }

	# !help
	if text == "!help" or text == "!commands" or text == "！help":
		return { "command": "help", "target": "", "username": username }

	# !points
	if text in ["!points", "!pt", "!ポイント", "！points", "！pt"]:
		return { "command": "points", "target": "", "username": username }

	return null
