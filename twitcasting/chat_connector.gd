extends Node
## Bridge between Twitcasting/Simulator and game. Manages command queue.

const _CommandParser = preload("res://twitcasting/command_parser.gd")
const _ViewerPoints = preload("res://twitcasting/viewer_points.gd")
const _EnemyFactory = preload("res://spawning/enemy_factory.gd")

signal connection_status_changed(connected: bool, message: String)

var _client: Node  # TwitcastingClient
var _points = null
var _command_queue: Array = []
var _api_key: String = ""
var _live_http: HTTPRequest

func _ready() -> void:
	print("ChatConnector: _ready() called")
	_points = preload("res://twitcasting/viewer_points.gd").new()
	# Load .env
	var env := _load_env()
	_api_key = env.get("TWITCASTING_TOKEN", "")
	var movie_id: String = env.get("TWITCASTING_MOVIE_ID", "")

	# Setup Twitcasting client
	_client = Node.new()
	_client.set_script(preload("res://twitcasting/twitcasting_client.gd"))
	add_child(_client)
	_client.setup(_api_key, movie_id)
	_client.comment_received.connect(_on_comment)

	# HTTP for live movie lookup
	_live_http = HTTPRequest.new()
	add_child(_live_http)

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
	print("ChatConnector: simulator message from [%s]: %s" % [username, message])
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

## Connect to a Twitcasting user's live stream by user_id
func connect_to_user(user_id: String) -> void:
	if _api_key == "":
		connection_status_changed.emit(false, "APIトークンが未設定です（設定画面で入力してください）")
		return
	connection_status_changed.emit(false, "%s の配信を検索中..." % user_id)
	var url := "https://apiv2.twitcasting.tv/users/%s/current_live" % user_id
	var headers := [
		"Authorization: Bearer %s" % _api_key,
		"Accept: application/json",
	]
	var on_done := func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		if result != HTTPRequest.RESULT_SUCCESS:
			connection_status_changed.emit(false, "通信エラー")
			return
		if code == 404:
			connection_status_changed.emit(false, "%s は現在配信していません" % user_id)
			return
		if code != 200:
			connection_status_changed.emit(false, "APIエラー (code: %d)" % code)
			return
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json == null:
			connection_status_changed.emit(false, "レスポンス解析エラー")
			return
		var movie = json.get("movie", {})
		var movie_id: String = str(movie.get("id", ""))
		if movie_id == "" or movie_id == "0":
			connection_status_changed.emit(false, "ライブ配信が見つかりません")
			return
		# Success! Update client
		_client.update_movie_id(movie_id)
		var title: String = movie.get("title", "")
		connection_status_changed.emit(true, "接続完了! ムービーID: %s\n%s" % [movie_id, title])
		# Save user_id for next time
		_save_user_id(user_id)
	_live_http.request_completed.connect(on_done, CONNECT_ONE_SHOT)
	_live_http.request(url, headers)

func get_api_key() -> String:
	return _api_key

func _save_user_id(user_id: String) -> void:
	var file := FileAccess.open("user://twitcasting_user.txt", FileAccess.WRITE)
	if file:
		file.store_string(user_id)

func load_saved_user_id() -> String:
	var file := FileAccess.open("user://twitcasting_user.txt", FileAccess.READ)
	if file:
		return file.get_as_text().strip_edges()
	return ""
