extends Node
## Quest tracking system – manages active/completed quests.

enum QuestType { KILL_COUNT, SURVIVE_TIME, TOTAL_KILLS, COMBO_COUNT }
enum RewardType { POINTS, XP, UPGRADE, HEAL, MAX_HP }

var active_quest: Dictionary = {}  # Currently active quest
var completed_quests: Array[String] = []  # Quest IDs already done
var _kill_tracker: Dictionary = {}  # enemy_key -> count since quest accepted
var _total_kill_tracker: int = 0
var _survive_start: float = 0.0
var _quest_active: bool = false

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

func accept_quest(quest: Dictionary) -> void:
	active_quest = quest.duplicate()
	_kill_tracker.clear()
	_total_kill_tracker = 0
	_survive_start = GameState.elapsed_seconds()
	_quest_active = true
	var quest_text: String = quest.get("description", "")
	EventBus.quest_accepted.emit(quest_text)

func has_active_quest() -> bool:
	return _quest_active

func get_progress() -> Array:
	## Returns [current, target] for display
	if not _quest_active:
		return [0, 0]
	var q_type: int = active_quest.get("type", 0)
	var target_val: int = active_quest.get("target_count", 0)
	match q_type:
		QuestType.KILL_COUNT:
			var enemy_key: String = active_quest.get("enemy_key", "")
			var current: int = _kill_tracker.get(enemy_key, 0)
			return [current, target_val]
		QuestType.TOTAL_KILLS:
			return [_total_kill_tracker, target_val]
		QuestType.SURVIVE_TIME:
			var elapsed: int = int(GameState.elapsed_seconds() - _survive_start)
			return [mini(elapsed, target_val), target_val]
		QuestType.COMBO_COUNT:
			var current_combo: int = GameState.combo_count
			return [mini(current_combo, target_val), target_val]
	return [0, 0]

func check_completion() -> bool:
	if not _quest_active:
		return false
	var progress: Array = get_progress()
	var current: int = progress[0]
	var target: int = progress[1]
	return current >= target

func complete_quest() -> Dictionary:
	## Returns reward info and marks quest complete
	if not _quest_active:
		return {}
	var reward: Dictionary = {
		"type": active_quest.get("reward_type", RewardType.POINTS),
		"value": active_quest.get("reward_value", 0),
		"text": active_quest.get("reward_text", ""),
	}
	var quest_id: String = active_quest.get("id", "")
	completed_quests.append(quest_id)
	var quest_name: String = active_quest.get("description", "")
	var reward_text: String = active_quest.get("reward_text", "")
	_quest_active = false
	active_quest.clear()
	EventBus.quest_completed.emit(quest_name, reward_text)
	return reward

func cancel_quest() -> void:
	_quest_active = false
	active_quest.clear()

func _on_enemy_killed(enemy_key: String, _cost: int) -> void:
	if not _quest_active:
		return
	# Track kills by type
	var prev: int = _kill_tracker.get(enemy_key, 0)
	_kill_tracker[enemy_key] = prev + 1
	# Track total kills
	_total_kill_tracker += 1

func reset() -> void:
	active_quest.clear()
	completed_quests.clear()
	_kill_tracker.clear()
	_total_kill_tracker = 0
	_survive_start = 0.0
	_quest_active = false
