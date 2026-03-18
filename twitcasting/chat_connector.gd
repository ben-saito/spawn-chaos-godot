extends Node
## Bridge between Twitcasting/Simulator and game. Manages command queue.

const _CommandParser = preload("res://twitcasting/command_parser.gd")
const _ViewerPoints = preload("res://twitcasting/viewer_points.gd")
const _EnemyFactory = preload("res://spawning/enemy_factory.gd")

var _client: Node  # TwitcastingClient
var _points = null
var _command_queue: Array = []

func _ready() -> void:
	_points = preload("res://twitcasting/viewer_points.gd").new()
	# Load .env
	var env := _load_env()
	var token: String = env.get("TWITCASTING_TOKEN", "")
	var movie_id: String = env.get("TWITCASTING_MOVIE_ID", "")

	# Setup Twitcasting client
	_client = Node.new()
	_client.set_script(preload("res://twitcasting/twitcasting_client.gd"))
	add_child(_client)
	_client.setup(token, movie_id)
	_client.comment_received.connect(_on_comment)

	# Setup UDP simulator
	var sim := Node.new()
	sim.set_script(preload("res://twitcasting/simulator_receiver.gd"))
	add_child(sim)
	sim.message_received.connect(_on_simulator_message)

	EventBus.game_reset.connect(_on_game_reset)

func poll_commands() -> Array:
	var cmds := _command_queue.duplicate()
	_command_queue.clear()
	return cmds

func _on_comment(data: Dictionary) -> void:
	_process_message(data["user_id"], data["username"], data["message"])

func _on_simulator_message(username: String, message: String) -> void:
	_process_message("sim_" + username, username, message)

func _process_message(user_id: String, username: String, message: String) -> void:
	_points.recover_points(user_id)
	_points.get_or_create(user_id, username)

	var cmd = _CommandParser.parse(message, username)
	if cmd == null:
		return

	match cmd["command"]:
		"spawn":
			var cost: int = _EnemyFactory.get_cost(cmd["target"])
			if _points.spend(user_id, cost):
				_command_queue.append(cmd)
			else:
				_command_queue.append({
					"command": "insufficient_points",
					"target": cmd["target"],
					"username": username,
					"points": _points.get_points(user_id),
					"cost": cost,
				})
		"gimmick":
			var cost: int = Config.GIMMICK_COSTS.get(cmd["target"], 0)
			if _points.spend(user_id, cost):
				_command_queue.append(cmd)
			else:
				_command_queue.append({
					"command": "insufficient_points",
					"target": cmd["target"],
					"username": username,
					"points": _points.get_points(user_id),
					"cost": cost,
				})
		"help", "points":
			_command_queue.append(cmd)

func _load_env() -> Dictionary:
	var result := {}
	var file := FileAccess.open("res://.env", FileAccess.READ)
	if file == null:
		# Try user:// path
		file = FileAccess.open("user://.env", FileAccess.READ)
	if file == null:
		return result
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var eq := line.find("=")
		if eq > 0:
			var key := line.substr(0, eq).strip_edges()
			var val := line.substr(eq + 1).strip_edges()
			result[key] = val
	return result

func _on_game_reset() -> void:
	_points.reset()
	_command_queue.clear()
