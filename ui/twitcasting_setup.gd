extends CanvasLayer
## Twitcasting connection setup using proper UI controls.

var _active: bool = false
var _status_message: String = ""
var _status_ok: bool = false

var _ui_root: Control
var _panel: PanelContainer
var _line_edit: LineEdit
var _status_label: Label
var _connect_btn: Button
var _close_btn: Button

func _ready() -> void:
	visible = false
	_build_ui()
	var saved := _load_saved("twitcasting_user.txt")
	if saved != "":
		_line_edit.text = saved

func _build_ui() -> void:
	# Set Japanese font theme for all UI controls
	var jp_font = load("res://assets/fonts/NotoSansJP-Regular.ttf")
	if jp_font:
		var theme := Theme.new()
		theme.set_default_font(jp_font)
		theme.set_default_font_size(16)
		# Apply to this CanvasLayer's children via a Control wrapper
		var root_control := Control.new()
		root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		root_control.theme = theme
		add_child(root_control)
		# All UI will be added under this root_control
		_ui_root = root_control

	# If _ui_root wasn't created (font missing), use self as parent
	if _ui_root == null:
		_ui_root = Control.new()
		_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_ui_root)

	# Full-screen dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.add_child(overlay)

	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(500, 300)
	_panel.position = Vector2(640 - 250, 360 - 150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = Color(0.4, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	_ui_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Twitcasting 接続設定"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.6, 0.5, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Description
	var desc := Label.new()
	desc.text = "TwitcastingのユーザーIDを入力してください\n（配信ページURL twitcasting.tv/ の後の部分）"
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	# Input field
	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "例: c:username"
	_line_edit.custom_minimum_size = Vector2(0, 40)
	_line_edit.add_theme_font_size_override("font_size", 20)
	_line_edit.text_submitted.connect(_on_text_submitted)
	vbox.add_child(_line_edit)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_connect_btn = Button.new()
	_connect_btn.text = "接続"
	_connect_btn.custom_minimum_size = Vector2(120, 36)
	_connect_btn.add_theme_font_size_override("font_size", 18)
	_connect_btn.pressed.connect(_on_connect_pressed)
	btn_row.add_child(_connect_btn)

	_close_btn = Button.new()
	_close_btn.text = "閉じる"
	_close_btn.custom_minimum_size = Vector2(120, 36)
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(_close_btn)

	# Status
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_status_label)

	# Info
	var info := Label.new()
	info.text = "ユーザーIDを入力するだけで配信に自動接続!\n視聴者は !spawn スライム 等のコマンドで参加"
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

func _get_connector() -> Node:
	var scene = get_tree().current_scene
	if scene:
		return scene.find_child("ChatConnector")
	return null

func show_setup() -> void:
	if OS.has_feature("web"):
		# Web: use browser prompt dialog (most reliable for text input)
		_show_web_prompt()
		return
	_active = true
	visible = true
	_status_label.text = ""
	_status_ok = false
	# Pause entire tree except this node - prevents all other input handling
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	# Focus the text input
	_line_edit.call_deferred("grab_focus")

func _show_web_prompt() -> void:
	var saved := _load_saved("twitcasting_user.txt")
	var js_code := """
	(function() {
		var saved = '%s';
		var result = prompt('Twitcasting ユーザーIDを入力してください\\n(配信ページURL twitcasting.tv/ の後の部分)', saved);
		return result || '';
	})()
	""" % saved.replace("'", "\\'")
	var result = JavaScriptBridge.eval(js_code)
	if result != null and str(result) != "":
		var user_id := str(result).strip_edges()
		_line_edit.text = user_id
		_save_data("twitcasting_user.txt", user_id)
		# Show status in game
		_active = true
		visible = true
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		_do_connect()
	# If cancelled, just return to weapon select

func _on_text_submitted(_text: String) -> void:
	_do_connect()

func _on_connect_pressed() -> void:
	_do_connect()

func _on_close_pressed() -> void:
	_close()

func _close() -> void:
	_active = false
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()

func _do_connect() -> void:
	var user_id := _line_edit.text.strip_edges()
	if user_id == "":
		return
	var connector = _get_connector()
	if connector == null:
		_status_label.text = "エラー: ChatConnectorが見つかりません"
		_status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
		return
	_save_data("twitcasting_user.txt", user_id)
	_status_label.text = "%s の配信を検索中..." % user_id
	_status_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	if not connector.connection_status_changed.is_connected(_on_connection_status):
		connector.connection_status_changed.connect(_on_connection_status)
	connector.connect_to_user(user_id)

func _on_connection_status(connected: bool, message: String) -> void:
	_status_ok = connected
	_status_label.text = message
	if connected:
		_status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.4))
		await get_tree().create_timer(2.0).timeout
		if _active:
			_close()
	else:
		_status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))

func _load_saved(filename: String) -> String:
	var file := FileAccess.open("user://" + filename, FileAccess.READ)
	if file:
		return file.get_as_text().strip_edges()
	return ""

func _save_data(filename: String, data: String) -> void:
	var file := FileAccess.open("user://" + filename, FileAccess.WRITE)
	if file:
		file.store_string(data)
