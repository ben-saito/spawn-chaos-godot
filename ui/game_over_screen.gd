extends CanvasLayer
## Game Over overlay.

var _draw_node: Node2D

func _ready() -> void:
	visible = false
	_draw_node = $DrawLayer
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_reset.connect(_on_game_reset)

func _on_game_over() -> void:
	visible = true
	_draw_node.queue_redraw()

func _on_game_reset() -> void:
	visible = false

func _process(_delta: float) -> void:
	if visible:
		_draw_node.queue_redraw()
