extends CanvasLayer
## Shop UI overlay – buy items with game points.

var _is_open: bool = false
var _player: CharacterBody3D = null
var _draw_node: Node2D = null
var _message: String = ""
var _message_timer: float = 0.0

const SHOP_ITEMS := [
	{ "name": "HP回復 (30HP)", "cost": 100, "id": "heal_30" },
	{ "name": "HP全回復", "cost": 300, "id": "heal_full" },
	{ "name": "最大HP+20", "cost": 500, "id": "max_hp" },
	{ "name": "移動速度+", "cost": 400, "id": "speed_up" },
	{ "name": "オーラ威力+", "cost": 300, "id": "aura_damage" },
	{ "name": "ミサイル速射", "cost": 400, "id": "missile_cooldown" },
	{ "name": "回転刃追加", "cost": 500, "id": "blade_add" },
]

func _ready() -> void:
	layer = 10
	visible = false
	_draw_node = Node2D.new()
	_draw_node.set_script(preload("res://ui/shop_ui_draw.gd"))
	add_child(_draw_node)

func open_shop(player_ref: CharacterBody3D) -> void:
	_player = player_ref
	_is_open = true
	visible = true
	_message = ""
	_message_timer = 0.0
	EventBus.shop_opened.emit()

func close_shop() -> void:
	_is_open = false
	visible = false
	EventBus.shop_closed.emit()

func is_open() -> bool:
	return _is_open

func _process(delta: float) -> void:
	if not _is_open:
		return
	if _message_timer > 0:
		_message_timer -= delta
	_draw_node.queue_redraw()
	_handle_input()

func _handle_input() -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		close_shop()
		return
	for i in range(SHOP_ITEMS.size()):
		var key_code: int = KEY_1 + i
		if Input.is_key_pressed(key_code):
			_try_buy(i)
			return

func _try_buy(index: int) -> void:
	if index < 0 or index >= SHOP_ITEMS.size():
		return
	var item: Dictionary = SHOP_ITEMS[index]
	var cost: int = item["cost"]
	if GameState.game_points < cost:
		_message = "ポイント不足!"
		_message_timer = 1.5
		return

	GameState.game_points -= cost
	_apply_item(item["id"])
	var item_name: String = item["name"]
	_message = "%s を購入!" % item_name
	_message_timer = 1.5
	EventBus.event_log_added.emit("購入: %s" % item_name)

func _apply_item(item_id: String) -> void:
	if _player == null:
		return
	match item_id:
		"heal_30":
			_player.heal(30)
		"heal_full":
			_player.hp = _player.max_hp
			_player.hp_changed.emit(_player.hp, _player.max_hp)
		"max_hp":
			_player.max_hp += 20
			_player.hp = mini(_player.hp + 20, _player.max_hp)
			_player.hp_changed.emit(_player.hp, _player.max_hp)
		"speed_up":
			_player.base_speed = minf(_player.base_speed + 0.3, 4.0)
			_player.speed = _player.base_speed
		"aura_damage":
			var weapons := _player.get_node("Weapons")
			if weapons:
				var aura = weapons.get_node_or_null("AuraWeapon")
				if aura:
					aura.aura_damage += 10
		"missile_cooldown":
			var weapons := _player.get_node("Weapons")
			if weapons:
				var missile = weapons.get_node_or_null("MissileWeapon")
				if missile:
					missile.missile_cooldown = maxi(8, missile.missile_cooldown - 8)
		"blade_add":
			var weapons := _player.get_node("Weapons")
			if weapons:
				var blade = weapons.get_node_or_null("OrbitBladeWeapon")
				if blade:
					blade.blade_count += 1
