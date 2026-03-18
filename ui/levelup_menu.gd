extends CanvasLayer
## Level-up upgrade selection screen.

const UPGRADES := {
	"unlock_missile":   { "name": "Magic Missile", "desc": "Unlock homing missile" },
	"unlock_blade":     { "name": "Orbit Blade", "desc": "Unlock rotating blades" },
	"unlock_lightning": { "name": "Lightning", "desc": "Unlock lightning strike" },
	"unlock_holy_water":{ "name": "Holy Water", "desc": "Unlock holy water pools" },
	"aura_damage":      { "name": "Aura Power+", "desc": "Aura damage +10" },
	"aura_range":       { "name": "Aura Range+", "desc": "Aura range +6" },
	"missile_damage":   { "name": "Missile Power+", "desc": "Missile damage +8" },
	"missile_cooldown": { "name": "Missile Speed+", "desc": "Missile cooldown -8" },
	"blade_add":        { "name": "Blade+1", "desc": "Add 1 orbit blade" },
	"blade_damage":     { "name": "Blade Power+", "desc": "Blade damage +5" },
	"lightning_damage":  { "name": "Lightning Power+", "desc": "Lightning damage +15" },
	"lightning_cooldown":{ "name": "Lightning Speed+", "desc": "Lightning cooldown -15" },
	"hw_damage":        { "name": "HolyWater Power+", "desc": "Holy water damage +3" },
	"hw_duration":      { "name": "HolyWater Time+", "desc": "Holy water duration +30" },
	"speed_up":         { "name": "Speed Up", "desc": "Movement speed +0.3" },
	"max_hp":           { "name": "Max HP+", "desc": "Max HP +20" },
	"heal":             { "name": "Heal", "desc": "Restore 30 HP" },
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

func get_available_upgrades(player: CharacterBody2D) -> Array[String]:
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
