extends CanvasLayer
## Twitcasting connection setup. Token + User ID input, no .env needed.

var _draw_node: Node2D
var _active: bool = false
var _token_input: String = ""
var _user_id_input: String = ""
var _active_field: int = 0  # 0=token, 1=user_id
var _status_message: String = ""
var _status_ok: bool = false
var _cursor_blink: float = 0.0

func _ready() -> void:
	_draw_node = $DrawLayer
	visible = false
	# Load saved values
	_token_input = _load_saved("twitcasting_token.txt")
	_user_id_input = _load_saved("twitcasting_user.txt")

func _get_connector() -> Node:
	var scene = get_tree().current_scene
	if scene:
		return scene.find_child("ChatConnector")
	return null

func show_setup() -> void:
	_active = true
	visible = true
	_status_message = ""
	_status_ok = false
	_active_field = 0 if _token_input == "" else 1

func _process(delta: float) -> void:
	if not _active:
		return
	_cursor_blink += delta
	_draw_node.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if not (event is InputEventKey and event.pressed):
		return

	if event.keycode == KEY_ESCAPE:
		_active = false
		visible = false
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_TAB:
		# Switch between fields
		_active_field = 1 - _active_field
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if _active_field == 0 and _token_input != "":
			_active_field = 1  # Move to user ID field
		elif _user_id_input != "" and _token_input != "":
			_connect()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_BACKSPACE:
		if _active_field == 0:
			if _token_input.length() > 0:
				_token_input = _token_input.substr(0, _token_input.length() - 1)
		else:
			if _user_id_input.length() > 0:
				_user_id_input = _user_id_input.substr(0, _user_id_input.length() - 1)
		get_viewport().set_input_as_handled()
		return

	if event.unicode > 0:
		var ch := char(event.unicode)
		if _active_field == 0:
			# Token: allow most printable chars
			if event.unicode >= 32:
				_token_input += ch
		else:
			# User ID: alphanumeric, underscore, hyphen, colon
			if ch.is_valid_identifier() or ch == "_" or ch == "-" or ch == "@" or ch == ":":
				_user_id_input += ch
		get_viewport().set_input_as_handled()

func _connect() -> void:
	var connector = _get_connector()
	if connector == null:
		_status_message = "エラー: ChatConnectorが見つかりません"
		return
	# Save token and update connector's api_key
	_save_data("twitcasting_token.txt", _token_input)
	_save_data("twitcasting_user.txt", _user_id_input)
	connector._api_key = _token_input
	_status_message = "接続中..."
	_status_ok = false
	if not connector.connection_status_changed.is_connected(_on_connection_status):
		connector.connection_status_changed.connect(_on_connection_status)
	connector.connect_to_user(_user_id_input)

func _on_connection_status(connected: bool, message: String) -> void:
	_status_ok = connected
	_status_message = message
	if connected:
		await get_tree().create_timer(2.0).timeout
		if _active:
			_active = false
			visible = false

func _load_saved(filename: String) -> String:
	var file := FileAccess.open("user://" + filename, FileAccess.READ)
	if file:
		return file.get_as_text().strip_edges()
	return ""

func _save_data(filename: String, data: String) -> void:
	var file := FileAccess.open("user://" + filename, FileAccess.WRITE)
	if file:
		file.store_string(data)
