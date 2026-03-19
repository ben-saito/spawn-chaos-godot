extends CanvasLayer
## Twitcasting connection setup screen. Accessible from weapon select via T key.

var _draw_node: Node2D
var _active: bool = false
var _user_id_input: String = ""
var _status_message: String = ""
var _status_ok: bool = false
var _cursor_blink: float = 0.0

func _ready() -> void:
	_draw_node = $DrawLayer
	visible = false
	# Load saved user ID
	var connector = _get_connector()
	if connector:
		var saved: String = connector.load_saved_user_id()
		if saved != "":
			_user_id_input = saved

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
	var connector = _get_connector()
	if connector:
		var saved: String = connector.load_saved_user_id()
		if saved != "":
			_user_id_input = saved
		if connector.get_api_key() == "":
			_status_message = "⚠ .envにTWITCASTING_TOKENを設定してください"

func _process(delta: float) -> void:
	if not _active:
		return
	_cursor_blink += delta
	_draw_node.queue_redraw()

	# Escape to close
	if Input.is_key_pressed(KEY_ESCAPE):
		_active = false
		visible = false
		return

	# Enter to connect
	if Input.is_key_pressed(KEY_ENTER) and _user_id_input != "":
		_connect()
		return

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			if _user_id_input.length() > 0:
				_user_id_input = _user_id_input.substr(0, _user_id_input.length() - 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
		elif event.unicode > 0:
			var ch := char(event.unicode)
			# Allow alphanumeric, underscore, hyphen
			if ch.is_valid_identifier() or ch == "_" or ch == "-" or ch == "@":
				_user_id_input += ch
			get_viewport().set_input_as_handled()

func _connect() -> void:
	var connector = _get_connector()
	if connector == null:
		_status_message = "エラー: ChatConnectorが見つかりません"
		return
	_status_message = "接続中..."
	_status_ok = false
	if not connector.connection_status_changed.is_connected(_on_connection_status):
		connector.connection_status_changed.connect(_on_connection_status)
	connector.connect_to_user(_user_id_input)

func _on_connection_status(connected: bool, message: String) -> void:
	_status_ok = connected
	_status_message = message
	if connected:
		# Auto-close after success
		await get_tree().create_timer(2.0).timeout
		if _active:
			_active = false
			visible = false
