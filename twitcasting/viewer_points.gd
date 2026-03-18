extends RefCounted
## Per-viewer point management.

var _viewers: Dictionary = {}  # user_id -> { "points": int, "total_spent": int, "username": String, "last_recovery": float }

func get_or_create(user_id: String, username: String = "") -> Dictionary:
	if not _viewers.has(user_id):
		_viewers[user_id] = {
			"points": Config.INITIAL_VIEWER_POINTS,
			"total_spent": 0,
			"username": username,
			"last_recovery": Time.get_unix_time_from_system(),
		}
	if username != "":
		_viewers[user_id]["username"] = username
	return _viewers[user_id]

func recover_points(user_id: String) -> void:
	var viewer := get_or_create(user_id)
	var now := Time.get_unix_time_from_system()
	var elapsed: float = now - viewer["last_recovery"]
	if elapsed >= 60.0:
		var ticks := int(elapsed / 60.0)
		viewer["points"] = mini(viewer["points"] + Config.VIEWER_POINTS_RECOVERY * ticks, Config.MAX_VIEWER_POINTS)
		viewer["last_recovery"] = now

func has_enough(user_id: String, cost: int) -> bool:
	var viewer := get_or_create(user_id)
	return viewer["points"] >= cost

func spend(user_id: String, cost: int) -> bool:
	var viewer := get_or_create(user_id)
	if viewer["points"] >= cost:
		viewer["points"] -= cost
		viewer["total_spent"] += cost
		return true
	return false

func get_points(user_id: String) -> int:
	return get_or_create(user_id)["points"]

func reset() -> void:
	_viewers.clear()
