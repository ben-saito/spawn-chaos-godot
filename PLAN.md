# Game Plan: Spawn Chaos

## Game Description

Spawn Chaos - a vampire survivors-like (バンサバライク) 2D top-down game with Twitcasting live streaming integration. The streamer controls the main character, and viewers spawn enemies and activate gimmicks via Twitcasting chat commands.

Key features:
- Player character with 5 weapons: Aura (melee, Space key), Magic Missile (auto homing), Orbit Blade (rotating around player), Lightning Strike (random target), Holy Water (DOT zone)
- 9 enemy types with unique AI: Slime (bouncy hop), Goblin (zigzag + knife), Skeleton (ranged bones), Bat (wave motion), Mushroom (4-way spores), Ogre (charge attack), Slime King (4-way shots, splits into 3 slimes on death), Wolfpack (orbit + dash), Dragon (distance control + 3-way fireballs)
- Level-up system: XP from kills, 3-choice upgrade selection screen (16 upgrades: weapon unlocks + stat boosts)
- 3 gimmicks activated by viewers: Ice Floor (slow + jitter), Darkness (limited vision), Gravity Reversal (invert UP/DOWN)
- Twitcasting API integration: HTTP polling every 2s, JWT Bearer auth, chat commands (!spawn スライム, !gimmick アイス, !help, !points)
- Per-viewer point system (initial 100pt, max 1000pt, recovery +15/min)
- Local UDP simulator for testing without Twitcasting API
- Keyboard controls: arrows=move, space=aura attack, 1-9=spawn enemies (costs game points), Q/W/E=activate gimmicks
- Game states: PLAY, LEVELUP, GAMEOVER (R to retry)
- HUD: HP bar, timer, game points, enemy count, spawn log, XP bar, level indicator, spawn guide
- Game points pool: start 200, +5/sec recovery, spent on keyboard spawns/gimmicks
- Events: "HALF TIME CHAOS!" at HP<=50% (+100pt), "LAST STAND!" at HP<=25% (+50pt)
- 256x224 viewport scaled 3x to window, modern visuals (not retro pixel art)
- Engine: Godot 4.x with GDScript, gl_compatibility renderer

## 1. Core Game — Player, Enemies, Weapons, and Game Loop
- **Depends on:** (none)
- **Status:** done
- **Targets:** project.godot, scenes/main.tscn, scenes/player.tscn, scripts/player.gd, scripts/enemy_base.gd, scripts/enemy_factory.gd, scripts/spawn_manager.gd, scripts/weapons/aura.gd, scripts/weapons/missile.gd, scripts/weapons/orbit_blade.gd, scripts/weapons/lightning.gd, scripts/weapons/holy_water.gd, scripts/enemies/slime.gd, scripts/enemies/goblin.gd, scripts/enemies/skeleton.gd, scripts/enemies/bat.gd, scripts/enemies/mushroom.gd, scripts/enemies/ogre.gd, scripts/enemies/slime_king.gd, scripts/enemies/wolfpack.gd, scripts/enemies/dragon.gd, scripts/enemy_projectile.gd
- **Goal:** Implement the complete core gameplay: player movement with 5 weapons, 9 enemy types with unique AI behaviors, enemy projectile system, keyboard spawning (keys 1-9), game points pool (start 200, +5/sec), collision and damage, XP/level-up system with 16 upgrades and 3-choice selection screen, 3 gimmick effects (ice floor, darkness, gravity reversal via Q/W/E), HP events ("HALF TIME CHAOS!", "LAST STAND!"), game states (PLAY, LEVELUP, GAMEOVER with R to retry), and full HUD (HP bar, timer, points, enemy count, spawn log, XP bar, level indicator, spawn guide).
- **Requirements:**
  - 256x224 viewport scaled 3x, gl_compatibility renderer, 30 physics ticks
  - Player moves with arrow keys, attacks with Space (Aura weapon always available)
  - 4 additional weapons unlock via level-up: Magic Missile (auto homing), Orbit Blade (rotating), Lightning Strike (random target), Holy Water (DOT zone)
  - 9 enemy types each with distinct AI: Slime bounces, Goblin zigzags, Skeleton throws bones at range, Bat uses wave motion, Mushroom shoots 4-way spores, Ogre charges, Slime King shoots 4-way and splits into 3 slimes on death, Wolfpack orbits then dashes, Dragon maintains distance and fires 3-way fireballs
  - Keyboard keys 1-9 spawn enemies at screen edge (costs game points matching enemy cost)
  - Q/W/E activate gimmicks: Ice Floor (50pt, 30s, slows+jitter), Darkness (80pt, 20s, limited vision), Gravity Reversal (120pt, 10s, inverts UP/DOWN)
  - Level-up pauses game, shows 3 random upgrade choices, player picks with keys 1/2/3
  - HUD shows HP bar (color-coded by ratio), timer, game points, enemy count, spawn log (last 5), XP bar, level, spawn guide
  - Game over screen shows score and time, R to retry
  - Modern stylized 2D visuals with procedural drawing (draw_rect, draw_circle, draw_line) — not pixel art
- **Verify:** Screenshot shows player character in center of grid arena surrounded by multiple enemy types. HUD elements visible at screen edges. Multiple weapon effects active (rotating blades, projectiles). Enemy HP bars visible above damaged enemies.

## 2. Twitcasting Chat Integration
- **Depends on:** 1
- **Status:** done
- **Targets:** scripts/twitcasting/twitcasting_client.gd, scripts/twitcasting/command_parser.gd, scripts/twitcasting/viewer_points.gd, scripts/twitcasting/chat_connector.gd, scripts/twitcasting/simulator_receiver.gd
- **Goal:** Integrate Twitcasting live chat so viewers can spawn enemies and activate gimmicks via commands. Includes per-viewer point system and local UDP simulator for testing.
- **Requirements:**
  - HTTPRequest-based polling of Twitcasting API every 2 seconds with JWT Bearer auth
  - Parse commands: !spawn <enemy_name>, !gimmick <type>, !help, !points (with Japanese aliases: スライム, ゴブリン, アイス, etc.)
  - Per-viewer point system: initial 100pt, max 1000pt, recovery +15pt/min, cost deducted on spawn/gimmick
  - Insufficient points logged as [LACK] in spawn log with viewer name
  - Local UDP simulator on port 19876 for testing (receives "username\tmessage" format)
  - .env file loading for TWITCASTING_TOKEN and TWITCASTING_MOVIE_ID
  - Chat commands create same effects as keyboard spawning but attributed to viewer name in spawn log
- **Verify:** With UDP simulator running, sending "!spawn スライム" spawns a slime from screen edge. Spawn log shows viewer name and enemy type. Sending "!gimmick アイス" activates ice floor effect.

## 3. Presentation Video
- **Depends on:** 1, 2
- **Status:** pending
- **Targets:** test/presentation.gd, screenshots/presentation/gameplay.mp4
- **Goal:** Create a ~30-second cinematic video showcasing the completed game.
- **Requirements:**
  - Write test/presentation.gd — a SceneTree script (extends SceneTree)
  - Showcase representative gameplay via simulated input: player moving, enemies spawning, weapons firing, level-up selection, gimmick activation
  - ~900 frames at 30 FPS (30 seconds)
  - Use Video Capture from godot-capture (AVI via --write-movie, convert to MP4 with ffmpeg)
  - Output: screenshots/presentation/gameplay.mp4
  - Camera pans and smooth scrolling, zoom transitions between overview and close-up, trigger representative gameplay sequences, tight viewport framing
- **Verify:** A smooth MP4 video showing polished gameplay with no visual glitches.
