extends CanvasLayer
## Level-up upgrade selection screen.

const UPGRADES := {
	"unlock_missile":   { "name": "マジックミサイル", "desc": "自動追尾弾を解放" },
	"unlock_blade":     { "name": "回転刃", "desc": "周囲を回る刃を解放" },
	"unlock_lightning": { "name": "雷撃", "desc": "自動落雷を解放" },
	"unlock_holy_water":{ "name": "ホーリーウォーター", "desc": "設置型ダメージゾーンを解放" },
	"aura_damage":      { "name": "オーラ威力+", "desc": "オーラのダメージ+10" },
	"aura_range":       { "name": "オーラ射程+", "desc": "オーラの射程+1.0" },
	"missile_damage":   { "name": "ミサイル威力+", "desc": "ミサイルのダメージ+8" },
	"missile_cooldown": { "name": "ミサイル速射", "desc": "発射間隔短縮" },
	"blade_add":        { "name": "回転刃追加", "desc": "刃を1枚追加" },
	"blade_damage":     { "name": "回転刃威力+", "desc": "刃のダメージ+5" },
	"lightning_damage":  { "name": "雷撃威力+", "desc": "落雷のダメージ+15" },
	"lightning_cooldown":{ "name": "雷撃速射", "desc": "落雷の間隔短縮" },
	"hw_damage":        { "name": "聖水威力+", "desc": "聖水のダメージ+3" },
	"hw_duration":      { "name": "聖水持続+", "desc": "聖水の持続時間延長" },
	"speed_up":         { "name": "移動速度+", "desc": "移動速度アップ" },
	"max_hp":           { "name": "最大HP+", "desc": "最大HP+20" },
	"heal":             { "name": "HP回復", "desc": "HPを30回復" },
}

var choices: Array[String] = []
var _draw_node: Node2D

func _ready() -> void:
	visible = false
	_draw_node = $DrawLayer
	EventBus.game_reset.connect(_on_game_reset)

func _on_game_reset() -> void:
	visible = false
	choices.clear()

func show_choices(available: Array[String]) -> void:
	# Pick 3 random from available
	available.shuffle()
	choices = []
	for i in range(mini(3, available.size())):
		choices.append(available[i])
	visible = true
	_draw_node.queue_redraw()

func _process(_delta: float) -> void:
	if not visible:
		return
	for i in range(choices.size()):
		var key_code: int = KEY_1 + i
		if Input.is_key_pressed(key_code):
			var upgrade_id := choices[i]
			EventBus.upgrade_selected.emit(upgrade_id)
			visible = false
			GameState.state = GameState.State.PLAY
			break

func get_available_upgrades(player: CharacterBody3D) -> Array[String]:
	var available: Array[String] = []
	var weapons = player.get_node("Weapons") if player.has_node("Weapons") else null
	# Always offer stat upgrades
	available.append("speed_up")
	available.append("max_hp")
	available.append("heal")
	# Weapon unlocks (if not yet unlocked)
	if weapons:
		var missile = weapons.find_child("MissileWeapon")
		var blade = weapons.find_child("OrbitBladeWeapon")
		var lightning = weapons.find_child("LightningWeapon")
		var hw = weapons.find_child("HolyWaterWeapon")
		if missile and not missile.unlocked:
			available.append("unlock_missile")
		elif missile and missile.unlocked:
			available.append("missile_damage")
			available.append("missile_cooldown")
		if blade and not blade.unlocked:
			available.append("unlock_blade")
		elif blade and blade.unlocked:
			available.append("blade_add")
			available.append("blade_damage")
		if lightning and not lightning.unlocked:
			available.append("unlock_lightning")
		elif lightning and lightning.unlocked:
			available.append("lightning_damage")
			available.append("lightning_cooldown")
		if hw and not hw.unlocked:
			available.append("unlock_holy_water")
		elif hw and hw.unlocked:
			available.append("hw_damage")
			available.append("hw_duration")
		# Aura always available
		available.append("aura_damage")
		available.append("aura_range")
	return available
