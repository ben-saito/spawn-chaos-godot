extends CanvasLayer
## Twitcasting connection setup.
## Web: browser prompt() + _draw() status display
## Desktop: LineEdit + buttons with Japanese font theme

var _active: bool = false
var _status_message: String = ""
var _status_ok: bool = false
var _show_status_only: bool = false  # Web: show status with _draw() after prompt

# Desktop UI
var _ui_root: Control
var _panel: PanelContainer
var _line_edit: LineEdit
var _status_label: Label
var _connect_btn: Button
var _close_btn: Button

# Draw status node (for web)
var _draw_node: Node2D

func _ready() -> void:
	visible = false
	_draw_node = Node2D.new()
	_draw_node.set_script(preload("res://ui/twitcasting_status_draw.gd"))
	add_child(_draw_node)
	if not OS.has_feature("web"):
		_build_desktop_ui()
	var saved := _load_saved("twitcasting_user.txt")
	if _line_edit and saved != "":
		_line_edit.text = saved

func _build_desktop_ui() -> void:
	var jp_font = load("res://assets/fonts/NotoSansJP-Regular.ttf")
	var theme := Theme.new()
	if jp_font:
		theme.set_default_font(jp_font)
	theme.set_default_font_size(16)

	_ui_root = Control.new()
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.theme = theme
	add_child(_ui_root)

	# Overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.add_child(overlay)

	# CenterContainer for perfect centering
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = Color(0.4, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Twitcasting 接続設定"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.6, 0.5, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "TwitcastingのユーザーIDを入力"
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "c:username"
	_line_edit.custom_minimum_size = Vector2(0, 40)
	_line_edit.add_theme_font_size_override("font_size", 20)
	_line_edit.text_submitted.connect(func(_t): _do_connect())
	vbox.add_child(_line_edit)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_connect_btn = Button.new()
	_connect_btn.text = "接続"
	_connect_btn.custom_minimum_size = Vector2(120, 36)
	_connect_btn.pressed.connect(_do_connect)
	btn_row.add_child(_connect_btn)

	_close_btn = Button.new()
	_close_btn.text = "閉じる"
	_close_btn.custom_minimum_size = Vector2(120, 36)
	_close_btn.pressed.connect(_close)
	btn_row.add_child(_close_btn)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_status_label)

func _get_connector() -> Node:
	var scene = get_tree().current_scene
	if scene:
		return scene.find_child("ChatConnector")
	return null

func show_setup() -> void:
	if OS.has_feature("web"):
		_show_web_prompt()
		return
	_active = true
	_show_status_only = false
	visible = true
	if _ui_root:
		_ui_root.visible = true
	if _status_label:
		_status_label.text = ""
	_status_ok = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	if _line_edit:
		_line_edit.call_deferred("grab_focus")

func _show_web_prompt() -> void:
	var saved := _load_saved("twitcasting_user.txt")
	var js_code := "prompt('Twitcasting ユーザーIDを入力\\n(twitcasting.tv/ の後の部分)', '%s')" % saved.replace("'", "\\'")
	var result = JavaScriptBridge.eval(js_code)
	if result != null and str(result) != "":
		var user_id := str(result).strip_edges()
		_save_data("twitcasting_user.txt", user_id)
		# Show status overlay
		_active = true
		_show_status_only = true
		visible = true
		if _ui_root:
			_ui_root.visible = false
		_status_message = "%s の配信を検索中..." % user_id
		_status_ok = false
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		# Connect
		var connector = _get_connector()
		if connector:
			if not connector.connection_status_changed.is_connected(_on_connection_status):
				connector.connection_status_changed.connect(_on_connection_status)
			connector.connect_to_user(user_id)

func _close() -> void:
	_active = false
	visible = false
	_show_status_only = false
	get_tree().paused = false

func _process(_delta: float) -> void:
	if _active and _show_status_only:
		_draw_node.queue_redraw()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()

func _do_connect() -> void:
	var user_id := ""
	if _line_edit:
		user_id = _line_edit.text.strip_edges()
	if user_id == "":
		return
	var connector = _get_connector()
	if connector == null:
		_status_message = "エラー"
		return
	_save_data("twitcasting_user.txt", user_id)
	_status_message = "%s の配信を検索中..." % user_id
	_status_ok = false
	if _status_label:
		_status_label.text = _status_message
		_status_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	if not connector.connection_status_changed.is_connected(_on_connection_status):
		connector.connection_status_changed.connect(_on_connection_status)
	connector.connect_to_user(user_id)

func _on_connection_status(connected: bool, message: String) -> void:
	_status_ok = connected
	_status_message = message
	if _status_label:
		_status_label.text = message
		_status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.4) if connected else Color(1, 0.5, 0.3))
	if connected:
		await get_tree().create_timer(2.0).timeout
		if _active:
			_close()
	elif _show_status_only:
		# Web: auto-close after error too
		await get_tree().create_timer(3.0).timeout
		if _active:
			_close()

func _load_saved(filename: String) -> String:
	var file := FileAccess.open("user://" + filename, FileAccess.READ)
	if file:
		return file.get_as_text().strip_edges()
	return ""

func _save_data(filename: String, data: String) -> void:
	var file := FileAccess.open("user://" + filename, FileAccess.WRITE)
	if file:
		file.store_string(data)
