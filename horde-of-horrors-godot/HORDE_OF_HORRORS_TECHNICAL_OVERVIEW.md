# Horde of Horrors - Technical Overview

A 2D top-down wave-based survival shooter built in **Godot 4.3** (Mobile renderer, portrait orientation 720x1280). Features seven playable characters, a primary/secondary weapon system, 10+ power-ups, enemy waves with mini-bosses, and a full upgrade shop.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Core Architecture](#core-architecture)
3. [Game Flow](#game-flow)
4. [Player System](#player-system)
5. [Weapon System](#weapon-system)
6. [Enemy System](#enemy-system)
7. [Wave & Environment System](#wave--environment-system)
8. [Power-Up System](#power-up-system)
9. [Input System](#input-system)
10. [UI/HUD System](#uihud-system)
11. [Audio System](#audio-system)
12. [Scene Reference](#scene-reference)
13. [Recent Fixes & Known Issues](#recent-fixes--known-issues)

---

## Project Structure

```
horde-of-horrors-godot/
├── project.godot              # Godot project config
├── scripts/                   # ~50 GDScript files
│   ├── GameManager.gd         # Global singleton (autoload)
│   ├── UIManager.gd           # Global singleton (autoload)
│   ├── AudioManager.gd        # Global singleton (autoload)
│   ├── PoolManager.gd         # Global singleton (autoload)
│   ├── MainGame.gd            # Main gameplay controller
│   ├── Player.gd              # Primary player controller (2D)
│   ├── Player3D.gd            # 3D player variant
│   ├── WaveManager.gd         # Enemy spawning & wave logic
│   ├── Enemy.gd               # Base 2D enemy (werewolves, vampires, etc.)
│   ├── Enemy3D.gd             # 3D enemy variant
│   ├── UpgradeShop.gd         # Pause-menu upgrade shop logic
│   ├── PauseMenu.gd           # Pause/Trade menu controller
│   ├── Joystick.gd            # Virtual on-screen joystick
│   ├── JoystickLayer.gd       # Touch input layer manager
│   ├── Minimap.gd             # Mini-map renderer
│   ├── Projectile.gd          # Crossbow bolt / stake projectile
│   ├── GarlicProjectile.gd    # Garlic bomb projectile
│   ├── GarlicCloud.gd         # Garlic AoE damage cloud
│   ├── HolyWaterProjectile.gd # Holy water grenade arc projectile
│   ├── SanctifiedZone.gd      # Holy water damage zone
│   ├── MoonlightArrow.gd      # Bow arrow projectile
│   ├── StakeProjectile.gd     # Stake launcher projectile
│   ├── LightningChain.gd      # Lightning rod chain effect
│   ├── PowerUpData.gd         # Resource class for power-up types
│   ├── PowerUpDrop.gd         # Dropped power-up in world
│   ├── PowerUpHealth.gd       # Health pickup (special case)
│   ├── CharacterSelect.gd     # Character selection screen
│   ├── MainMenu.gd            # Main menu screen
│   ├── AdvancedCameraController.gd  # Camera follow + shake
│   ├── Camera2DShake.gd       # Camera shake effect
│   ├── DirectionalSprite3D.gd # 3D billboard sprite with facing
│   ├── AbilityIcon.gd         # Ability cooldown UI icon
│   ├── DamageNumber.gd        # Floating damage text
│   ├── BloodDecal.gd          # Blood splatter decal
│   ├── BloodOrb.gd            # Blood orb visual effect
│   ├── BloodSplatter.gd       # Blood particle effect
│   ├── ProjectileHitEffect.gd # Hit spark particles
│   ├── CoverObstacle.gd       # Cover/obstacle in world
│   ├── ForceFieldArena.gd     # Arena boundary forcefield
│   └── ... (boss scripts: RevenantFrankenstein.gd, VampireMatriarch.gd, LichHighPriest.gd, AlphaWerewolf.gd)
├── scenes/
│   ├── MainGame.tscn          # Root gameplay scene
│   ├── Player.tscn            # Player CharacterBody2D
│   ├── Player3D.tscn          # 3D player variant
│   ├── PauseMenu.tscn         # Pause/Trade menu overlay
│   ├── UIManager.tscn         # HUD + active items bar + minimap
│   ├── Joystick.tscn          # Virtual joystick scene
│   ├── AbilityIcon.tscn       # Ability cooldown icon scene
│   ├── Projectile.tscn        # Crossbow bolt scene
│   ├── PowerUpDrop.tscn     # Power-up drop item
│   ├── CharacterSelect.tscn   # Character selection UI
│   ├── MainMenu.tscn         # Main menu
│   ├── environments/          # Level environments
│   │   ├── ForsakenVillageOutskirts.tscn
│   │   └── ...
│   └── ... (weapon scenes, enemy scenes, effect scenes)
├── resources/
│   ├── powerups/              # PowerUpData .tres files
│   │   ├── TimeSlowData.tres
│   │   └── ...
│   └── ...
├── assets/
│   ├── sprites/               # All game sprites
│   │   ├── player/            # Character sprites
│   │   ├── enemies/           # Enemy sprites
│   │   ├── ui/                # UI icons, powerup_icons, weapon_icons
│   │   ├── weapons/           # Weapon sprites
│   │   └── projectiles/       # Projectile sprites
│   └── audio/                 # Music & SFX
└── ...
```

---

## Core Architecture

### Autoload Singletons (Global Scripts)

Four scripts are registered as autoloads in `project.godot`:

| Singleton | Purpose |
|-----------|---------|
| **GameManager** | Game state, score, currency, wave data, character selection, weapon database, upgrade tracking, enemy spawning signals |
| **UIManager** | HUD updates, health bar, active items bar, minimap, score/gold display, ability cooldown UI |
| **AudioManager** | Background music, SFX playback with pooling, bus mixing |
| **PoolManager** | Object pooling for projectiles, hit effects, blood decals |

### Communication Pattern

- **Signals** — Primary inter-system communication. `GameManager` emits signals like `enemy_despawned`, `wave_changed`, `score_updated`, `health_changed`. UI and other systems connect to these.
- **Direct References** — `GameManager.player` holds a reference to the active player instance. `Joystick.gd` writes to `GameManager.player.move_input` directly.
- **Node Paths** — UI nodes reference each other via `$NodePath` in scripts.

---

## Game Flow

```
project.godot (run/main_scene)
    └─> scenes/MainMenu.tscn
         └─> Start Game
              └─> scenes/CharacterSelect.tscn
                   └─> Select Character (7 options)
                        └─> scenes/MainGame.tscn
                             └─> WaveManager starts wave 1
                                  └─> Environment loaded
                                  └─> Enemies spawn
                                  └─> Player fights / collects drops / opens Pause Menu
```

### Pause Menu (Trade/Inventory)

The Pause Menu (`scenes/PauseMenu.tscn` + `scripts/PauseMenu.gd`) is a Control overlay that toggles with **ESC** or the **PAUSE** button. It has three sections:

- **Inventory Section** (left) — Shows:
  - **Active Passives** — Damage, Fire Rate, Health, Speed, Sinister Pact upgrade levels
  - **Temporary Effects** — Current active boosts (Damage Boost, Speed Boost, Shield)
  - **Secondary Weapons** — Equipped secondary weapons with levels
- **Market Section** (right) — Buy buttons for power-ups:
  - Fury (damage), Blood Rush (speed), Iron Skin (shield), Vampire's Kiss (heal), Time Slow
  - Swap buttons: Speed↔Damage conversion

---

## Player System

**Script:** `scripts/Player.gd` (attached to `scenes/Player.tscn`)

`Player` extends `CharacterBody2D` and is the core gameplay actor.

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `move_speed` | `float` | Base movement speed |
| `move_input` | `Vector2` | Normalized input direction (set by Joystick or keyboard) |
| `current_health` / `max_health` | `int` | HP tracking |
| `secondary_weapons` | `Array[Node2D]` | Active secondary weapon instances |
| `weapon_levels` | `Dictionary` | `{weapon_id: level}` mapping (max 5) |
| `is_shielded` | `bool` | Shield status from Iron Skin |
| `damage_boost_flat` | `int` | Flat damage increase from Fury |
| `speed_boost_multiplier` | `float` | Speed multiplier from Blood Rush |
| `purchased_upgrades` | `Dictionary` | Passive upgrade counts (damage, fire_rate, health, speed, pact) |

### Input Handling

- **Keyboard:** `Input.get_vector("move_left", "move_right", "move_up", "move_down")`
- **Touch/Joystick:** `Joystick.gd` sets `GameManager.player.move_input` directly
- **Auto-fire:** Primary weapon fires automatically at nearest enemy within range
- **Secondary:** Button press or active item slot triggers secondary weapon
- **Ability:** Dedicated ability button per character class

### Weapon Attachment Logic

When a secondary weapon is unlocked (`change_weapon`):
1. Loads weapon scene from `GameManager.WEAPONS[weapon_id]["scene"]`
2. Instantiates and adds as child to Player
3. Sets meta `"weapon_id"`
4. **Visuals hiding:** If character is Victor/Serena (baked weapon) OR weapon is `garlic_bomb` (thrown, not held), the `Visuals` node is hidden
5. Sets weapon level if `set_level()` method exists

### Death

When `current_health <= 0`:
- Spawns blood particles
- Plays death SFX
- Emits `player_died` signal
- `queue_free()` (pending Game Over screen — currently just removes player)

---

## Weapon System

### Primary Weapon

All characters start with **Silver Crossbow** as primary. It auto-fires bolts at the nearest enemy.

### Secondary Weapons

Defined in `GameManager.WEAPONS` constant dictionary:

| ID | Name | Scene | Type |
|----|------|-------|------|
| `rifle` | Silver Rifle | `scenes/Rifle.tscn` | Rapid-fire hitscan |
| `stake_launcher` | Stake Launcher | `scenes/StakeLauncher.tscn` | Piercing projectile |
| `holy_water` | Holy Grenade | `scenes/HolyWaterGrenade.tscn` | Arc projectile + sanctified zone |
| `garlic_bomb` | Garlic Bomb | `scenes/GarlicBomb.tscn` | Thrown bomb + garlic cloud AoE |
| `longbow` | Moonlight Longbow | `scenes/MoonlightLongbow.tscn` | Charged arrow |
| `greatsword` | Blessed Greatsword | `scenes/SilverGreatsword.tscn` | Melee sweep |
| `staff` | Crystal Staff | `scenes/CrystalStaff.tscn` | Magic projectile |
| `lightning_rod` | Lightning Rod | `scenes/LightningRod.tscn` | Chain lightning |

Weapons can be upgraded to **Level 5** via drops or shop. Higher levels increase damage, radius, or add effects (e.g., Garlic Bomb at Level 2+ spawns a persistent `GarlicCloud` AoE).

### Weapon Visuals Hiding

Some weapons should not display a sprite attached to the player:
- **Victor / Serena** — Their characters have baked-in weapon sprites
- **garlic_bomb** — It's a thrown bomb, not a held weapon

The `Player.gd` script handles this by finding the `Visuals` node on the weapon instance and setting `visible = false`.

---

## Enemy System

**Script:** `scripts/Enemy.gd` (base class for all 2D enemies)

`Enemy` extends `CharacterBody2D`.

### Enemy Types

| Enemy | Behavior | Special |
|-------|----------|---------|
| **Werewolf** (basic) | Melee chase, lunges | None |
| **Vampire** | Melee, can enter **bat form** to escape | Bat form: becomes untargetable, flies to opposite quadrant |
| **Alpha Werewolf** | Faster, more health | Mini-boss |
| **Revenant Frankenstein** | Slow, high health, charge attack | Boss |
| **Vampire Matriarch** | Ranged blood orb attacks, spawns adds | Boss |
| **Lich High Priest** | Spell casting, summons | Boss |

### State Machine

Enemies use a simple state system within `_physics_process`:
1. **Knockback** — Applied if `knockback_velocity > 0`
2. **Stun** — If `is_stunned`, skip movement/attack
3. **Bat Form** — If `is_bat_form`, fly toward `escape_target`
4. **Charge Attack** — If `is_charging`, dash in `charge_dir`
5. **Normal** — Pathfind toward player, attack if in range

### Attacks

- **Melee** — `_on_body_entered` triggers `player.take_damage(damage)`
- **Ranged** — `_perform_ranged_attack()` spawns a `Projectile.tscn`
- **Charge** — `_perform_charge_attack(charge_dir)` dashes at player

### Death & Drops

On death (`_die()`):
- Spawns blood decal (`BloodDecal.tscn`)
- Spawns blood particles
- 25% chance (guaranteed for mini-bosses) to drop a power-up via `PowerUpDrop.tscn`
- Drops use weighted table: Health (30%), Speed (15%), Shield (15%), Damage (15%), Holy Nova (7%), Time Slow (6%), Double Shot (6%), Ghost Form (4%), Blood Moon Rage (3%)
- Awards score, kill count, and gold

---

## Wave & Environment System

**Script:** `scripts/WaveManager.gd`

### Wave Flow

1. `start_wave(wave_number)` called
2. Calculates enemy count: scales with wave number
3. Picks enemy composition based on wave tier
4. Spawns enemies over time at spawn points
5. Tracks `active_enemies` array
6. When all enemies dead → `wave_cleared` signal emitted
7. `GameManager` increments wave and starts next

### Environment Swapping

`MainGame.gd` handles environment transitions:
- Each wave can load a different `Environment.tscn`
- Old environment is `queue_free()`-d
- New environment added to scene tree
- Navigation mesh is rebuilt for new environment obstacles

### Spawn Points

Enemies spawn at predefined `Marker2D` nodes in the environment scene, chosen randomly.

---

## Power-Up System

**Resource Class:** `scripts/PowerUpData.gd`

```gdscript
enum PowerUpType {
    HEAL, SHIELD, DAMAGE_BOOST, SPEED_BOOST,
    FURY, BLOOD_RUSH, IRON_SKIN, VAMPIRES_KISS,
    TIME_SLOW, HOLY_NOVA, DOUBLE_SHOT, GHOST_FORM, BLOOD_MOON_RAGE
}
```

### Power-Up Types

| Name | Effect | Duration |
|------|--------|----------|
| **Vampire's Kiss** | Heal 25% max HP | Instant |
| **Iron Skin** | Shield (absorbs 1 hit) | Until hit |
| **Fury** | +flat damage | Wave duration |
| **Blood Rush** | +speed multiplier | Wave duration |
| **Holy Nova** | AoE damage burst | Instant |
| **Time Slow** | Slows all enemies | 5 seconds |
| **Double Shot** | Fire two projectiles | Wave duration |
| **Ghost Form** | Brief invulnerability | 3 seconds |
| **Blood Moon Rage** | Big damage boost | 10 seconds |

### Drop System

`PowerUpDrop.gd` (Area2D):
- Sprite displays icon based on `PowerUpData.icon` or type-based tint
- On player body enter: calls `player.apply_powerup(data)`, then `call_deferred("queue_free")`

### Active Items Bar

`UIManager.gd` creates an active items bar at the bottom of the screen showing consumed power-ups with charges:
- Dash / Blood Rush charges shown with `[1]`, `[2]`, `[3]` key labels
- Icons loaded from `res://assets/sprites/ui/powerup_icons/*.png`

---

## Input System

### Keyboard (Debug/Desktop)

| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| ESC | Pause / Unpause |
| 1-3 | Use active power-up |
| Space | Use ability |
| L | Debug: unlock all weapons |
| K | Debug: skip forward 10 waves |
| N | Debug: next wave |

### Touch / Mobile

| UI Element | Script | Function |
|------------|--------|----------|
| **Virtual Joystick** (bottom-left) | `Joystick.gd` | Movement vector → `GameManager.player.move_input` |
| **ABILITY** button (bottom-right) | `UIManager.gd` | Triggers character ability |
| **PAUSE** button (top-right) | `UIManager.gd` | Toggles pause menu |
| **Active Items Bar** (bottom) | `UIManager.gd` | Tap to consume power-up |
| **Secondary Weapon Button** | `UIManager.gd` | Fires secondary weapon |

---

## UI/HUD System

**Scene:** `scenes/UIManager.tscn` + **Script:** `scripts/UIManager.gd`

### HUD Elements

| Element | Position | Updates Via |
|---------|----------|-------------|
| **Score** | Top-left | `score_updated` signal |
| **Kills** | Top-left | `kill_added` signal |
| **Gold** | Top-left | `currency_updated` signal |
| **Wave** | Top-center | `wave_changed` signal |
| **Timer** | Top-center | Wave countdown |
| **Minimap** | Top-right | `Minimap.gd` — tracks player + enemy blips |
| **Ability Status** | Left-center | "Ability: READY" or cooldown |
| **Active Items** | Bottom-center | Consumable power-up buttons |
| **Health Bar** | Bottom-center | `update_player_health()` |
| **Pause Button** | Top-right | Toggles `PauseMenu` |

### Pause Menu (Trade Menu)

**Scene:** `scenes/PauseMenu.tscn` + **Script:** `scripts/PauseMenu.gd`

Three-column layout:
- **InventorySection** (left) — RichTextLabels showing:
  - UpgradesList (Active Passives)
  - EffectsList (Temporary Effects)
  - SecondaryList (Equipped secondaries)
- **MarketSection** (right) — Buy buttons with icons and prices
- **GoldLabel** (top) — Current gold with coin icon

### Upgrade Shop

**Script:** `scripts/UpgradeShop.gd`

Defines `ICONS` dictionary mapping weapon IDs to SVG icon paths for the shop UI. Buy buttons populate dynamically.

---

## Audio System

**Script:** `scripts/AudioManager.gd`

### Features

- **Music Player** — Single `AudioStreamPlayer` for background music
  - Tracks: `battle_theme`, `menu_theme`, `boss_theme`
  - Crossfades between tracks
- **SFX Pool** — Object pool of `AudioStreamPlayer` nodes for sound effects
  - `play_sfx(sound_name)` plays from pool
  - Warning: "Audio pool exhausted!" appears when all players are busy
- **Bus Mixing** — Separate buses for Music and SFX with volume control

### Known Missing SFX

- `throw` — Garlic bomb throw
- `bomb_impact` — Explosion impact

---

## Scene Reference

### Core Scenes

| Scene | Root Node | Purpose |
|-------|-----------|---------|
| `MainGame.tscn` | Node2D | Gameplay root. Manages environment, spawns player, connects signals |
| `Player.tscn` | CharacterBody2D | Player avatar with Sprite2D, collision, weapon attach points |
| `Player3D.tscn` | CharacterBody3D | 3D variant using DirectionalSprite3D |
| `UIManager.tscn` | CanvasLayer | HUD overlay. Contains labels, minimap, buttons, active items container |
| `PauseMenu.tscn` | Control | Pause overlay with trade/inventory panels |
| `Joystick.tscn` | Control | Virtual joystick with base + nub sprites |

### Weapon Scenes

| Scene | Fires | Projectile Scene |
|-------|-------|------------------|
| `SilverCrossbow.tscn` | Auto at nearest enemy | `Projectile.tscn` |
| `Rifle.tscn` | Rapid burst | Hitscan (no projectile scene) |
| `StakeLauncher.tscn` | On trigger | `StakeProjectile.tscn` |
| `HolyWaterGrenade.tscn` | Arc throw | `HolyWaterProjectile.tscn` → `SanctifiedZone.tscn` |
| `GarlicBomb.tscn` | Thrown bomb | `GarlicProjectile.tscn` → `GarlicCloud.tscn` (Lv2+) |
| `MoonlightLongbow.tscn` | Charged shot | `MoonlightArrow.tscn` |
| `SilverGreatsword.tscn` | Melee sweep | None (instant hit) |
| `CrystalStaff.tscn` | Magic bolt | `Projectile.tscn` (tinted) |
| `LightningRod.tscn` | Chain lightning | `LightningChain.gd` effect |

---

## Recent Fixes & Known Issues

### Recently Fixed (This Session)

1. **Missing Player Script** — `Player.gd` was not attached to `Player.tscn`, causing:
   - Blue square (default polygon visible)
   - No movement
   - Non-functional joystick
   - **Fix:** Added script reference in scene file

2. **Weapon Icon Extensions** — `UpgradeShop.gd` referenced `.png` icons but files were `.svg`
   - **Fix:** Updated all paths to `.svg`

3. **Powerup Buy Button Icons** — `PauseMenu.gd` used old generic `ui/icons/` paths instead of new `ui/powerup_icons/`
   - **Fix:** Updated all buy button icon paths

4. **Pause Menu Icon Consistency** — Active Passives, Temporary Effects, and Swap Passives text used old icons
   - **Fix:** Updated all RichTextLabel `[img=...]` tags to use `powerup_icons/`

5. **Pause Button Emoji** — `PAUSE ⏸️` rendered as broken character
   - **Fix:** Removed emoji, now just "PAUSE"

6. **`self_modulate` on Sprite3D** — `DirectionalSprite3D.gd` used `self_modulate` which doesn't exist on `Sprite3D`
   - **Fix:** Removed `self_modulate` references

7. **Physics Callback `queue_free()`** — Multiple scripts called `queue_free()` inside `_on_body_entered` or during physics, causing:
   - `ERROR: Removing a CollisionObject node during a physics callback`
   - Game freeze/crash
   - **Fix:** Changed to `call_deferred("queue_free")` in:
     - `PowerUpDrop.gd`
     - `PowerUpHealth.gd`
     - `Enemy.gd`
     - `Enemy3D.gd`
     - `GarlicProjectile.gd`
     - `HolyWaterProjectile.gd`
     - `RevenantFrankenstein.gd`
     - `VampireMatriarch.gd`
     - `GameManager.gd` (wave skip)
     - `WaveManager.gd`
     - `Player.gd` (weapon swap)

8. **Garlic Bomb Visual** — `garlic_bomb` secondary weapon showed a floating weapon sprite on player
   - **Fix:** Added `weapon_id == "garlic_bomb"` to the visual-hiding logic alongside Victor/Serena

### Known Issues

1. **Audio Pool Exhausted** — SFX pool runs out during heavy combat. Consider increasing `num_players` in `AudioManager.gd`

2. **Missing SFX Files** — `throw` and `bomb_impact` sound files not found. Place in `assets/audio/sfx/`

3. **Navigation Mesh Errors** — `NavigationPolygon: Convex partition failed!` on some environments. Outlines may overlap.

4. **Deprecated Navigation API** — `make_polygons_from_outlines()` is deprecated. Should migrate to `NavigationServer2D.parse_source_geometry_data()` + `bake_from_source_geometry_data()`

5. **3D Scripts Parse Errors** — `DirectionalSprite3D.gd` had `self_modulate` errors. Fixed but other 3D scripts may have similar issues if they reference 2D-only properties.

6. **ObjectDB Instances Leaked** — On exit: "ObjectDB instances leaked at exit". Likely from nodes not being freed properly or circular references.

7. **CharacterSelect Node Not Found** — `VBoxMain/LeftPanel/CharacterList` path missing in `CharacterSelect.tscn`. Non-fatal but may cause UI issues.

8. **Blood Decal Persistence** — `BloodDecal.gd` uses `queue_free()` after timer. Should verify this doesn't cause physics issues if decal has collision.

---

## Character Roster

| Character | Class | Primary Weapon | Ability |
|-----------|-------|----------------|---------|
| **Hunter** | Ranged | Silver Crossbow | Roll/Dodge |
| **Werewolf** | Melee | Claws | Transform |
| **Vampire** | Life-steal | Blood Whip | Bat Form |
| **Frankenstein** | Tank | Electric Fists | Stomp |
| **Elias** | Mage | Fireball | Teleport |
| **Serena** | Support | Holy Crossbow | Heal Aura |
| **Victor** | Engineer | Auto-Turret | Turret Deploy |

Character selection sets `GameManager.selected_character` which affects:
- Player scene loaded (some may use `Player3D.tscn`)
- Starting stats
- Ability function
- Weapon visual hiding behavior (Victor/Serena have baked weapons)

---

## Key File Paths

```
# Core Scripts
res://scripts/GameManager.gd
res://scripts/UIManager.gd
res://scripts/AudioManager.gd
res://scripts/Player.gd
res://scripts/WaveManager.gd
res://scripts/Enemy.gd

# Core Scenes
res://scenes/MainGame.tscn
res://scenes/Player.tscn
res://scenes/UIManager.tscn
res://scenes/PauseMenu.tscn

# Powerup Icons (new style)
res://assets/sprites/ui/powerup_icons/fury.png
res://assets/sprites/ui/powerup_icons/blood_rush.png
res://assets/sprites/ui/powerup_icons/iron_skin.png
res://assets/sprites/ui/powerup_icons/vampires_kiss.png
res://assets/sprites/ui/powerup_icons/time_slow.png
res://assets/sprites/ui/powerup_icons/holy_nova.png
res://assets/sprites/ui/powerup_icons/double_shot.png
res://assets/sprites/ui/powerup_icons/health_pack.png
res://assets/sprites/ui/powerup_icons/ghost_form.png
res://assets/sprites/ui/powerup_icons/blood_moon_rage.png

# Weapon Icons (SVG)
res://assets/sprites/ui/weapon_icons/rifle_icon.svg
res://assets/sprites/ui/weapon_icons/stake_launcher_icon.svg
res://assets/sprites/ui/weapon_icons/holy_grenade_icon.svg
res://assets/sprites/ui/weapon_icons/garlic_bomb_icon.svg
res://assets/sprites/ui/weapon_icons/moonlight_bow_icon.svg
res://assets/sprites/ui/weapon_icons/greatsword_icon.svg
res://assets/sprites/ui/weapon_icons/crystal_staff_icon.svg
res://assets/sprites/ui/weapon_icons/lightning_rod_icon.svg
```

---

*Generated for Grok import. This document represents the codebase state as of the latest fixes.*
