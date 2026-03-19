extends CanvasLayer
## Slot roulette with progressive lane reveal and sound effects.
## Lane 1 always shows. Lane 2 appears mid-spin if Hit. Lane 3 appears later if Jackpot.

var _draw_node: Node2D
var _active: bool = false
var _timer: float = 0.0
var _phase: int = 0  # 4=result display
var _phase_timer: float = 0.0

var _lane_count: int = 1  # current visible count, grows during spin
var _target_lane_count: int = 1  # final count (1/2/3)
var _rarity: int = 0

# Per-lane state
var _lane_speed: Array = [0.0, 0.0, 0.0]
var _lane_offset: Array = [0.0, 0.0, 0.0]
var _lane_result: Array = [0, 0, 0]
var _lane_stopped: Array = [false, false, false]
var _lane_visible: Array = [false, false, false]
var _lane_appear_time: Array = [0.0, 0.0, 0.0]
var _rewards_applied: bool = false

# Sound
var _audio_player: AudioStreamPlayer

const LANE2_APPEAR_TIME := 2.0
const LANE3_APPEAR_TIME := 3.5
const LANE_SPIN_DURATION := 2.0  # how long each lane spins after appearing
const RESULT_DISPLAY := 2.5

const ITEMS := [
	{ "id": "unlock_missile", "name": "マジックミサイル", "color": Color(0.6, 0.3, 1.0) },
	{ "id": "unlock_blade", "name": "回転刃", "color": Color(0.4, 0.6, 1.0) },
	{ "id": "unlock_lightning", "name": "雷撃", "color": Color(1.0, 0.9, 0.2) },
	{ "id": "unlock_holy_water", "name": "ホーリーウォーター", "color": Color(0.3, 0.6, 0.9) },
	{ "id": "aura_damage", "name": "オーラ威力+", "color": Color(0.3, 0.7, 1.0) },
	{ "id": "aura_range", "name": "オーラ射程+", "color": Color(0.3, 0.7, 1.0) },
	{ "id": "missile_damage", "name": "ミサイル威力+", "color": Color(0.6, 0.3, 1.0) },
	{ "id": "blade_add", "name": "回転刃追加", "color": Color(0.4, 0.6, 1.0) },
	{ "id": "lightning_damage", "name": "雷撃威力+", "color": Color(1.0, 0.9, 0.2) },
	{ "id": "hw_damage", "name": "聖水威力+", "color": Color(0.3, 0.6, 0.9) },
	{ "id": "speed_up", "name": "移動速度+", "color": Color(0.2, 0.9, 0.6) },
	{ "id": "max_hp", "name": "最大HP+", "color": Color(0.9, 0.3, 0.3) },
	{ "id": "heal", "name": "HP回復", "color": Color(0.9, 0.5, 0.6) },
]

func _ready() -> void:
	_draw_node = $DrawLayer
	visible = false
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)

func _play_beep(freq: float, duration: float) -> void:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t: float = float(i) / sample_rate
		var envelope: float = 1.0 - t / duration
		var val: float = sin(t * freq * TAU) * envelope * 0.5
		data[i] = int((val + 0.5) * 255)
	audio.data = data
	_audio_player.stream = audio
	_audio_player.play()

func start_roulette() -> void:
	_active = true
	visible = true
	_timer = 0.0
	_phase = 0
	_phase_timer = 0.0
	_rewards_applied = false
	_lane_stopped = [false, false, false]
	_lane_visible = [true, false, false]
	_lane_count = 1

	var roll := randf()
	if roll < 0.10:
		_rarity = 2
		_target_lane_count = 3
	elif roll < 0.40:
		_rarity = 1
		_target_lane_count = 2
	else:
		_rarity = 0
		_target_lane_count = 1

	var used_indices: Array = []
	for i in range(3):
		var idx := randi() % ITEMS.size()
		while idx in used_indices:
			idx = randi() % ITEMS.size()
		used_indices.append(idx)
		_lane_result[i] = idx

	_lane_speed = [16.0, 18.0, 20.0]
	_lane_offset = [randf() * ITEMS.size(), randf() * ITEMS.size(), randf() * ITEMS.size()]
	_lane_appear_time = [0.0, 0.0, 0.0]

	GameState.state = GameState.State.LEVELUP
	_play_beep(440.0, 0.15)

func _get_stop_time(lane_idx: int) -> float:
	return _lane_appear_time[lane_idx] + LANE_SPIN_DURATION

func _process(delta: float) -> void:
	if not _active:
		return
	_timer += delta
	_phase_timer += delta
	_draw_node.queue_redraw()

	# Progressive lane reveal with surprise
	if _target_lane_count >= 2 and not _lane_visible[1] and _timer >= LANE2_APPEAR_TIME:
		_lane_visible[1] = true
		_lane_count = 2
		_lane_appear_time[1] = _timer
		EventBus.screen_shake.emit(0.06, 0.2)
		_play_beep(660.0, 0.2)

	if _target_lane_count >= 3 and not _lane_visible[2] and _timer >= LANE3_APPEAR_TIME:
		_lane_visible[2] = true
		_lane_count = 3
		_lane_appear_time[2] = _timer
		EventBus.screen_shake.emit(0.1, 0.3)
		_play_beep(880.0, 0.25)

	# Update visible lanes
	var all_stopped := true
	for i in range(3):
		if not _lane_visible[i] or _lane_stopped[i]:
			continue
		all_stopped = false
		var stop_time := _get_stop_time(i)
		if _timer >= stop_time:
			var elapsed_since: float = _timer - stop_time
			var decel_duration := 0.8
			if elapsed_since < decel_duration:
				var progress: float = elapsed_since / decel_duration
				_lane_speed[i] = lerpf(_lane_speed[i], 0.0, ease(progress, 2.0) * 0.15)
				_lane_offset[i] += _lane_speed[i] * delta
			else:
				_lane_stopped[i] = true
				_lane_offset[i] = float(_lane_result[i])
				_lane_speed[i] = 0.0
				EventBus.screen_shake.emit(0.04 + i * 0.03, 0.2)
				_play_beep(520.0 + i * 220.0, 0.15)
		else:
			_lane_offset[i] += _lane_speed[i] * delta

	# Check if fully done
	var all_revealed: bool = (_lane_count == _target_lane_count)
	var visible_all_stopped := true
	for i in range(_lane_count):
		if not _lane_stopped[i]:
			visible_all_stopped = false
			break

	if visible_all_stopped and all_revealed and not _rewards_applied:
		_rewards_applied = true
		_phase = 4
		_phase_timer = 0.0

		var reward_names: Array = []
		for i in range(_lane_count):
			var reward: Dictionary = ITEMS[_lane_result[i]]
			EventBus.upgrade_selected.emit(reward["id"])
			reward_names.append(reward["name"])

		match _rarity:
			0:
				EventBus.event_log_added.emit("%s を入手!" % reward_names[0])
				_play_beep(600.0, 0.3)
			1:
				EventBus.event_log_added.emit("当たり! %s + %s!" % [reward_names[0], reward_names[1]])
				EventBus.screen_shake.emit(0.1, 0.4)
				_play_beep(880.0, 0.4)
			2:
				EventBus.event_log_added.emit("大当たり! %s + %s + %s!" % [reward_names[0], reward_names[1], reward_names[2]])
				EventBus.screen_shake.emit(0.2, 0.8)
				_play_beep(1100.0, 0.5)

	if _phase == 4 and _phase_timer >= RESULT_DISPLAY:
		_active = false
		visible = false
		GameState.state = GameState.State.PLAY
