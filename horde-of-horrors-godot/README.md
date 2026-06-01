# Horde of Horrors – Godot 4 Project

Sinister top-down monster wave survival game. Godot 4 edition for maximum longevity and zero cost.

## Folder Structure
- `scripts/` – GameManager, Player, Enemy, WaveManager, Projectile (GDScript)
- `scenes/` – MainGame.tscn + enemy/projectile scenes
- `assets/` – sprites, sounds, particles
- `autoload/` – (optional) for singletons

## Quick Start
1. Download Godot 4.3+ (https://godotengine.org/download)
2. Open the `horde-of-horrors-godot` folder as a project
3. Create scenes:
   - MainGame (Node2D) with Player, WaveManager, UI
   - Enemy scenes (CharacterBody2D + Sprite2D + CollisionShape2D) – assign script + type
   - Projectile scene (Area2D) – assign script
4. Add enemy PackedScenes to WaveManager export array
5. Run MainGame.tscn

## Controls (Prototype)
- WASD or arrow keys to move
- Mouse aims + auto-fires at nearest enemy
- Touch drag supported via InputEventScreenDrag (extend Player.gd)

## Next Steps
- Add real horror sprites / animations
- Implement wave-complete upgrade menu UI
- Add particle effects (blood, lightning, holy water)
- Mobile export (Android/iOS) + ads/IAP via Godot plugins
- Sound design with free horror SFX packs

The original HTML5 prototype proved the loop. This Godot version gives you full source control and future-proofing.

Let's make it terrifyingly fun. 🩸🌕