# Spawn Chaos

## Dimension: 2D

## Input Actions

| Action | Keys |
|--------|------|
| ui_left | Left Arrow |
| ui_right | Right Arrow |
| ui_up | Up Arrow |
| ui_down | Down Arrow |
| ui_accept | Space |

## Scenes

### Main
- **File:** res://main.tscn
- **Root type:** Node2D
- **Children:** GameWorld (Node2D), SpawnManager (Node), GimmickManager (Node), ChatConnector (Node), HUD (CanvasLayer), LevelUpMenu (CanvasLayer), GameOverScreen (CanvasLayer)

### GameWorld
- **Children:** Player, Enemies (Node2D), PlayerProjectiles (Node2D), EnemyProjectiles (Node2D), Effects (Node2D)

### Player
- **Root type:** CharacterBody2D
- **Children:** Weapons (Node2D) containing AuraWeapon, MissileWeapon, OrbitBladeWeapon, LightningWeapon, HolyWaterWeapon

## Scripts

### main.gd
- **Extends:** Node2D
- **Attaches to:** Main:Main
- **Signals received:** EventBus.game_over, EventBus.enemy_killed, EventBus.upgrade_selected, Player.leveled_up

### player.gd
- **Extends:** CharacterBody2D
- **Attaches to:** GameWorld:Player
- **Signals emitted:** hp_changed, xp_changed, leveled_up, died

### enemy_base.gd
- **Extends:** Area2D
- **Base class for all enemy AIs

### enemy_factory.gd
- **Extends:** RefCounted
- **Static factory creating enemies from key names

### spawn_manager.gd
- **Extends:** Node
- **Signals received:** EventBus.enemy_spawned

### weapons/weapon_base.gd → aura.gd, missile.gd, orbit_blade.gd, lightning.gd, holy_water.gd
- **Extends:** Node2D

### twitcasting/twitcasting_client.gd
- **Extends:** Node
- **Signals emitted:** comment_received

### twitcasting/chat_connector.gd
- **Extends:** Node
- **Orchestrates:** client → parser → points → command queue

### twitcasting/simulator_receiver.gd
- **Extends:** Node
- **Signals emitted:** message_received

## Autoloads

- Config = res://autoloads/config.gd (constants)
- GameState = res://autoloads/game_state.gd (mutable state)
- EventBus = res://autoloads/event_bus.gd (signal hub)

## Signal Map

- EventBus.enemy_spawned → SpawnManager._on_enemy_spawned
- EventBus.game_over → main._on_game_over, GameOverScreen._on_game_over
- EventBus.enemy_killed → main._on_enemy_killed
- EventBus.upgrade_selected → main._on_upgrade_selected
- EventBus.gimmick_activated → GimmickManager._on_gimmick_activated
- EventBus.spawn_log_added → HUD._on_spawn_log
- EventBus.game_reset → GimmickManager._on_game_reset, ChatConnector._on_game_reset
- Player.leveled_up → main._on_player_leveled_up
- TwitcastingClient.comment_received → ChatConnector._on_comment
- SimulatorReceiver.message_received → ChatConnector._on_simulator_message

## Collision Layers

Not used — all collision detection is distance-based (matching original Pyxel implementation).

## Asset Hints

- No external image assets needed — all visuals are procedurally drawn via _draw() calls
- Characters use draw_rect, draw_circle, draw_line, draw_arc for modern styled shapes
- UI uses ThemeDB.fallback_font with draw_string
