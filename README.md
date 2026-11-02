# ZenJewel

A relaxing match-3 puzzle game built with Godot 4. No timers, no lives, no stress.
Just play, match, and collect gems at your own pace.

**[Play it here](https://trancemeli.github.io/ZenJewel/)** (runs in your browser, no install needed)

<p align="left">
  <img src="https://img.shields.io/badge/Godot-4.x-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white" />
  <img src="https://img.shields.io/badge/GDScript-Script-478CBF?style=for-the-badge" />
  <a href="https://trancemeli.github.io/ZenJewel/"><img src="https://img.shields.io/badge/Play-in%20browser-1D9E75?style=for-the-badge" /></a>
  <img src="https://img.shields.io/badge/Version-0.2-1D9E75?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-Work%20In%20Progress-EF9F27?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-All%20Rights%20Reserved-E24B4A?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Made%20with-Aseprite-7F77DD?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Music-FL%20Studio-1D9E75?style=for-the-badge" />
</p>

---

## Preview

![Game Preview](images/zenjewel_screen.png)

| Start menu | Pause menu |
| :---: | :---: |
| ![Start menu](images/screen_menu.png) | ![Pause menu](images/screen_pause.png) |

| Shop |
| :---: |
| ![Shop](images/screen_shop.png) |

## About

ZenJewel is a solo indie project built as a portfolio piece demonstrating full-stack game development: core engine programming, game systems design, pixel art, and original music production.

The design philosophy is **Zen Mode only**. No losing conditions, no time pressure. The player collects score and gems by matching jewels, levels up through score thresholds, and spends gems on decorations for the meadow in the in-game shop.

> All visual assets and music are currently in development. The screenshots and audio in this README will be updated as production progresses.

---

## Features

**Gameplay**

- 8×8 match-3 board with cascade combos and gravity
- Safe board generation (no matches on start)
- Combo multiplier system with an on-screen combo counter
- Score and gems are based on the length of each matched row (3, 4, 5+)
- The board reshuffles automatically when no move is left, so you never get stuck

**Special Jewels** created automatically through larger matches

- Line H/V (4-match) clears an entire row or column
- Bomb (5-match) clears a 3×3 area
- Color/Rainbow (6+-match) clears all jewels of the same type

**Progression**

- Level system with scaling score goals (×1.4 per level), overflow points carry over
- Gem currency collected through matches
- Persistent save: score, level, gems, player name, sound setting, owned and placed decorations

**Shop and Decorations**

- Buy decorations with gems (mushroom, tree trunk, rocket, more planned)
- Place them on the meadow with a click, remove them with a right click
- Items stay where you put them between sessions
- All cosmetics are purely visual, no gameplay advantage

**Interface**

- Start menu with continue, optional player name and saved progress
- HUD with level badge and progress bar, score, gems and a menu button
- Pause menu (Esc) with resume, shop, sound toggle and main menu
- Interface text is in English, using the original pixel font

**Visual & Audio** _(in development)_

- Pixel-style particle effects: jewel pops, special bursts, level-up confetti, ambient motes on the meadow, shop sparkles and dust puffs
- Line flash, bomb burst and jewel highlight effects
- Original soundtrack produced in FL Studio
- Original pixel art assets created in Aseprite

---

## Controls

| Action                    | Input                              |
| ------------------------- | ---------------------------------- |
| Select and swap jewels    | Left click two neighboring jewels  |
| Open or close the menu    | `Esc` or the Menu button           |
| Place a decoration        | Left click on the meadow           |
| Remove a decoration       | Right click on it (placing mode)   |
| Leave placing mode        | `Esc` or the Done button           |

---

## Tech Stack

| Tool               | Purpose                |
| ------------------ | ---------------------- |
| Godot 4 (GDScript) | Engine and scripting   |
| Aseprite           | Pixel art assets       |
| FL Studio          | Music and sound design |
| Affinity Designer  | UI layout and mockups  |
| VS Code            | Code editing           |

---

## Project Structure

```
res://
├── assets/
├── font/
├── main_menu.gd           Start menu logic
├── scene/
│   ├── main_menu.tscn    Start screen
│   ├── main.tscn         Main game scene
│   ├── jewel0-5.tscn     Standard jewel scenes
│   ├── jewel_bomb.tscn   Special jewel scenes
│   ├── jewel_line_h.tscn
│   ├── jewel_line_v.tscn
│   ├── jewel_color.tscn
│   └── ui.tscn           HUD, pause menu and level-up overlay
└── script/
    ├── board.gd           Board coordinator, input locks, scoring
    ├── board_effects.gd   Visual effects
    ├── board_gravity.gd   Falling and refill logic
    ├── board_ui_bridge.gd UI and LevelManager connection
    ├── match_finder.gd    Pure match detection logic
    ├── special_handler.gd Special jewel activation
    ├── special_types.gd   Shared Special enum
    ├── jewel.gd           Jewel data and input
    ├── level_manager.gd   Score, level, gems, cosmetics, settings (Autoload)
    ├── cosmetics.gd       Catalog of decorations
    ├── decorations.gd     Placed decorations and placing mode
    ├── shop.gd            Shop overlay
    ├── ui.gd              HUD and pause menu logic
    ├── ui_style.gd        Shared colors and button styles
    ├── fx.gd              Particle effect helpers
    └── main.gd            Scene root, decorations and ambient effects
```

---

## Architecture

ZenJewel uses composition over inheritance. `board.gd` acts as a coordinator and delegates to specialized modules:

```
board.gd  (coordinator)
├── match_finder.gd     stateless pure logic, receives grid, returns matches and run lengths
├── special_handler.gd  activation logic for all 4 special types
├── board_effects.gd    visual only, particles via fx.gd and Tween effects
├── board_gravity.gd    falling animation and refill
└── board_ui_bridge.gd  connects LevelManager signals to UI labels

LevelManager  (Autoload)
└── saves and loads score, level, gems, name, sound, owned and placed
    cosmetics to user://save.json (debounced, written atomically)

Cosmetics     (global class_name)
└── catalog of decorations: name, price, atlas region, category

Decorations   (created by main.gd)
└── draws placed items and runs the placing mode

SpecialType   (global class_name)
└── single source of truth for the Special enum
```

Overlays such as the pause menu, the level-up screen and the placing mode lock the board through a counter (`lock_input` / `unlock_input`), so they never interfere with a running cascade.

### Adding a decoration

Add an entry to `CATALOG` in `script/cosmetics.gd` with a name, price, atlas region in `assets/zenjewel_environment.png` and a category. The shop and placing mode pick it up automatically.

---

## Planned Features

- Highlights screen (personal bests: highest score, longest combo, biggest match)
- More decorations, including items for the sky
- Alternative jewel skin themes and a skin manager for full visual theme switching

---

## License

This project and all its assets (code, art, music) may not be copied, modified,
distributed or used without explicit written permission from the author.

Built with [Godot Engine](https://godotengine.org) (MIT License).
