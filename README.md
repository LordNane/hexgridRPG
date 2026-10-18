# Hex RPG

A party-based tactics RPG in pixel art: explore a hand-painted hex overworld, step into caves and
towns, and fight FF Tactics-style battles on 2.5D hex arenas with elevation.

Built with **Godot 4.7** (standard build, not .NET) and typed GDScript.

## Getting started

1. Open the Godot project manager, choose **Import**, and select this folder's `project.godot`.
   Godot 4.7.2 is installed at `%USERPROFILE%\dev\tools\godot\4.7.2\`.
2. Press **F5** to play. The main scene is `game/main.tscn`: a title screen with New Game and
   Continue. Click a hex to walk there, arrow keys step, Enter interacts, Esc stops a walk; WASD or
   a middle-mouse drag looks around, the mouse wheel zooms. The cave mouth in the north-east leads
   into a test cave.
3. Walking through Greenvale and the Thornwood can start random battles against bandits. In
   battle, arrows or the mouse move the cursor, Enter or a click confirms, Esc backs out; each
   turn, move and attack (in either order), then choose which way to face. Win to collect the
   loot and carry on from the same hex; lose and it's back to the title.
4. Tab (Start on a gamepad) opens the party menu: pick a member to change their gear, job and
   abilities, with stat previews, or look through the inventory. Arrows or the D-pad move, Enter
   chooses, Esc or Backspace goes back, Tab closes it.
5. The game autosaves whenever the party enters or leaves a map or wins a battle, and Continue
   loads the latest save. Saves are JSON files in `%APPDATA%\Godot\app_userdata\Hex RPG\saves\`; delete them to
   start fresh.

## Commands

Run these from the project folder in PowerShell:

| Command | What it does |
|---|---|
| `./tools/run_tests.ps1` | Runs every unit test headless. `-Select test_hex` runs matching files; `-Test name` runs matching tests. |
| `./tools/lint.ps1` | Compiles every script with all warnings treated as errors. |
| `godot --headless --path . -s res://tools/gen_placeholder_art.gd` | Regenerates the placeholder art in `assets/`. |
| `godot --headless --path . -s res://tools/gen_placeholder_tilesets.gd` | Rebuilds the TileSets from that art (run an import first; overwrites TileSet edits). |
| `godot --headless --path . -s res://tools/gen_placeholder_font.gd` | Regenerates the placeholder pixel font in `assets/fonts/placeholder/`. |
| `godot --path . -s res://tools/benchmarks/explore_benchmark.gd` | Times exploration on a 200×150 map, including panning. |

The scripts find Godot through `$env:GODOT`, then `PATH`, then the default install location.

## Battle sandbox

Open a battle arena scene, such as `battle/arenas/forest_clearing.tscn`, and run it by itself
(F6) to play a test battle in it with the starting party. `battle/battle_sandbox.tscn` does the
same for any arena and encounter chosen in its inspector; turn on Auto Play to watch the AI fight
for both sides.

## Hex playground

`tools/playgrounds/hex_playground.tscn` is a dev scene for the hex core. Mouse or arrow keys move
the cursor; click or Enter sets the start hex; `1` path, `2` movement range, `3` ring, `4` line,
`R` new terrain.

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the rules every system follows, hex coordinates,
  the folder layout, how to add content, and the roadmap.
- [docs/DECISIONS.md](docs/DECISIONS.md): choices made along the way that you may want to change,
  and where to change them.
