extends Node
## Central signal hub – keeps systems decoupled.

# Enemies
signal enemy_spawned(enemy_key: String, source: String)
signal enemy_killed(enemy_key: String, cost: int)

# Player
signal player_damaged(amount: int, current_hp: int)
signal player_leveled_up(level: int)
signal upgrade_selected(upgrade_id: String)

# Gimmicks
signal gimmick_activated(gimmick_key: String, duration: float, source: String)
signal gimmick_ended(gimmick_key: String)

# Chat / commands
signal chat_command_received(command: Dictionary)

# UI
signal spawn_log_added(entry: String)
signal event_log_added(entry: String)

# Lifecycle
signal game_over()
signal game_reset()
