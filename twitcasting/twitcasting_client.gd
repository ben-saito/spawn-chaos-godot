extends Node
## Polls Twitcasting API for live chat comments.

signal comment_received(data: Dictionary)

var _api_key: String = ""
var _movie_id: String = ""
var _last_comment_id: int = 0
var _http_request: HTTPRequest
var _poll_timer: Timer
var _active: bool = false

func setup(api_key: String, movie_id: String) -> void:
	_api_key = api_key
	_movie_id = movie_id
	if api_key == "" or movie_id == "":
		_active = false
		return
	_active = true

	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

	_poll_timer = Timer.new()
	_poll_timer.wait_time = 2.0
	_poll_timer.autostart = true
	_poll_timer.timeout.connect(_poll)
	add_child(_poll_timer)

func _poll() -> void:
	if not _active or _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var url := "https://apiv2.twitcasting.tv/movies/%s/comments" % _movie_id
	var headers := [
		"Authorization: Bearer %s" % _api_key,
		"Accept: application/json",
	]
	_http_request.request(url, headers)

func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		return
	var comments: Array = json.get("comments", [])
	for comment in comments:
		var cid: int = int(comment.get("id", "0"))
		if cid > _last_comment_id:
			_last_comment_id = cid
			var user_data: Dictionary = comment.get("from_user", {})
			comment_received.emit({
				"user_id": str(user_data.get("id", "")),
				"username": user_data.get("name", "Unknown"),
				"message": comment.get("message", ""),
			})

func is_active() -> bool:
	return _active

func update_movie_id(new_movie_id: String) -> void:
	_movie_id = new_movie_id
	_last_comment_id = 0
	if _api_key != "" and _movie_id != "":
		_active = true
		if _http_request == null:
			_http_request = HTTPRequest.new()
			add_child(_http_request)
			_http_request.request_completed.connect(_on_request_completed)
		if _poll_timer == null:
			_poll_timer = Timer.new()
			_poll_timer.wait_time = 2.0
			_poll_timer.autostart = true
			_poll_timer.timeout.connect(_poll)
			add_child(_poll_timer)
	print("TwitcastingClient: movie_id updated to %s" % new_movie_id)
