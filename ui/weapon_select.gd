extends CanvasLayer
## Initial weapon selection screen at game start.

const WEAPONS := {
	1: { "id": "aura", "name": "聖剣オーラ", "desc": "近距離の衝撃波攻撃（Spaceキー）", "always": true },
	2: { "id": "missile", "name": "マジックミサイル", "desc": "敵を自動追尾する魔法弾を発射" },
	3: { "id": "blade", "name": "回転刃", "desc": "プレイヤーの周囲を回転する刃" },
	4: { "id": "lightning", "name": "雷撃", "desc": "ランダムな敵に落雷を落とす" },
	5: { "id": "holy_water", "name": "ホーリーウォーター", "desc": "地面にダメージゾーンを設置" },
}

var _draw_node: Node2D

func _ready() -> void:
	_draw_node = $DrawLayer
	EventBus.game_reset.connect(_on_game_reset)

func _on_game_reset() -> void:
	visible = true
	_draw_node.queue_redraw()

var _tc_key_held: bool = false

func _process(_delta: float) -> void:
	if GameState.state != GameState.State.WEAPON_SELECT:
		visible = false
		return
	visible = true
	_draw_node.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if GameState.state != GameState.State.WEAPON_SELECT:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# T, 6, or 0 key: open Twitcasting setup
	if event.keycode == KEY_T or event.keycode == KEY_6 or event.keycode == KEY_0:
		var tc_setup = get_tree().current_scene.find_child("TwitcastingSetup")
		if tc_setup and tc_setup.has_method("show_setup"):
			tc_setup.show_setup()
		get_viewport().set_input_as_handled()
		return

	# Weapon selection (keys 2-5)
	for key_num in [2, 3, 4, 5]:
		var key_code: int = KEY_1 + key_num - 1
		if event.keycode == key_code:
			_select_weapon(key_num)
			get_viewport().set_input_as_handled()
			return

func _select_weapon(key_num: int) -> void:
	var weapon_info: Dictionary = WEAPONS[key_num]
	var weapon_id: String = weapon_info["id"]
	# Unlock the chosen weapon on the player
	var player = get_tree().current_scene.find_child("Player")
	if player:
		var weapons = player.get_node("Weapons")
		match weapon_id:
			"missile":
				weapons.get_node("MissileWeapon").unlocked = true
			"blade":
				var blade = weapons.get_node("OrbitBladeWeapon")
				blade.unlocked = true
				blade.blade_count = 2
			"lightning":
				weapons.get_node("LightningWeapon").unlocked = true
			"holy_water":
				weapons.get_node("HolyWaterWeapon").unlocked = true
	GameState.state = GameState.State.PLAY
	visible = false
