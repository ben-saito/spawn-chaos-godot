extends CharacterBody2D
## Player character – movement, HP, invincibility, weapon management.

signal hp_changed(current_hp: int, max_hp: int)
signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal leveled_up(level: int, choices: Array)
signal died()

# Stats
var max_hp: int = 100
var hp: int = 100
var base_speed: float = 2.0
var speed: float = 2.0

# Invincibility
var invincible: bool = false
var _invincible_timer: int = 0
const INVINCIBLE_FRAMES := 30

# XP / Level
var level: int = 1
var xp: int = 0
var xp_to_next: int = Config.BASE_XP_TO_NEXT
var pending_levelup: bool = false

# Appearance
const BODY_SIZE := 8
const BODY_COLOR := Color(0.2, 0.6, 1.0)
const BODY_COLOR_FLASH := Color(1.0, 1.0, 1.0, 0.6)

func _ready() -> void:
	position = Vector2(Config.SCREEN_W / 2.0, Config.SCREEN_H / 2.0)

func _physics_process(_delta: float) -> void:
	if GameState.state != GameState.State.PLAY:
		return

	_handle_movement()
	_update_invincibility()
	queue_redraw()

var gravity_reversed: bool = false

func _handle_movement() -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	# Gravity reversal gimmick
	if gravity_reversed:
		dir.y *= -1

	if dir != Vector2.ZERO:
		dir = dir.normalized()

	velocity = dir * speed * 60  # Convert to pixels/sec for move_and_slide
	move_and_slide()

	# Clamp to screen bounds
	position.x = clampf(position.x, 0, Config.SCREEN_W)
	position.y = clampf(position.y, 0, Config.SCREEN_H)

func _update_invincibility() -> void:
	if _invincible_timer > 0:
		_invincible_timer -= 1
		if _invincible_timer <= 0:
			invincible = false

func take_damage(amount: int) -> void:
	if invincible:
		return
	hp = maxi(0, hp - amount)
	invincible = true
	_invincible_timer = INVINCIBLE_FRAMES
	hp_changed.emit(hp, max_hp)
	EventBus.player_damaged.emit(amount, hp)
	if hp <= 0:
		died.emit()
		EventBus.game_over.emit()

func add_xp(amount: int) -> bool:
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(xp_to_next * Config.XP_GROWTH_RATE)
		pending_levelup = true
		xp_changed.emit(xp, xp_to_next, level)
		leveled_up.emit(level, [])
		EventBus.player_leveled_up.emit(level)
		return true
	xp_changed.emit(xp, xp_to_next, level)
	return false

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

func reset() -> void:
	max_hp = 100
	hp = 100
	base_speed = 2.0
	speed = 2.0
	level = 1
	xp = 0
	xp_to_next = Config.BASE_XP_TO_NEXT
	pending_levelup = false
	invincible = false
	_invincible_timer = 0
	gravity_reversed = false
	position = Vector2(Config.SCREEN_W / 2.0, Config.SCREEN_H / 2.0)
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next, level)
	# Reset weapons to defaults
	if has_node("Weapons"):
		var weapons := get_node("Weapons")
		var aura = weapons.get_node_or_null("AuraWeapon")
		if aura:
			aura.unlocked = true
			aura.aura_damage = 35
			aura.aura_range = 24.0
		var missile = weapons.get_node_or_null("MissileWeapon")
		if missile:
			missile.unlocked = false
			missile.missile_damage = 15
			missile.missile_cooldown = 40
		var blade = weapons.get_node_or_null("OrbitBladeWeapon")
		if blade:
			blade.unlocked = false
			blade.blade_count = 0
			blade.blade_damage = 12
		var lightning = weapons.get_node_or_null("LightningWeapon")
		if lightning:
			lightning.unlocked = false
			lightning.lightning_damage = 40
			lightning.lightning_cooldown = 75
		var hw = weapons.get_node_or_null("HolyWaterWeapon")
		if hw:
			hw.unlocked = false
			hw.hw_damage = 5
			hw.hw_duration = 90

func _draw() -> void:
	# Flash when invincible
	var show := true
	if invincible and (_invincible_timer % 4 < 2):
		show = false

	if show:
		# Body
		var rect := Rect2(-BODY_SIZE / 2.0, -BODY_SIZE / 2.0, BODY_SIZE, BODY_SIZE)
		draw_rect(rect, BODY_COLOR)
		# Eyes
		draw_rect(Rect2(-2, -2, 2, 2), Color.WHITE)
		draw_rect(Rect2(1, -2, 2, 2), Color.WHITE)
