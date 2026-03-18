extends CanvasLayer
## Main HUD – draws all in-game UI elements.

var spawn_log: Array[String] = []
const MAX_LOG := 5

func _ready() -> void:
	EventBus.spawn_log_added.connect(_on_spawn_log)
	EventBus.event_log_added.connect(_on_event_log)
	EventBus.game_reset.connect(_on_game_reset)

var _event_text: String = ""
var _event_timer: float = 0.0

func _on_spawn_log(entry: String) -> void:
	var time_str := _format_time(GameState.elapsed_seconds())
	spawn_log.push_back("[%s] %s" % [time_str, entry])
	if spawn_log.size() > MAX_LOG:
		spawn_log.pop_front()

func _on_event_log(entry: String) -> void:
	_event_text = entry
	_event_timer = 3.0

func _process(delta: float) -> void:
	if _event_timer > 0:
		_event_timer -= delta
	$DrawLayer.queue_redraw()

func _on_game_reset() -> void:
	spawn_log.clear()
	_event_text = ""
	_event_timer = 0.0

func _format_time(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	return "%02d:%02d" % [m, s]
