# Hex RPG

A party-based tactics RPG in pixel art: explore a hand-painted hex overworld, step into caves and
towns, and fight FF Tactics-style battles on 2.5D hex arenas with elevation.

Built with **Godot 4.7** (standard build, not .NET) and typed GDScript.

## Getting started

1. Open the Godot project manager, choose **Import**, and select this folder's `project.godot`.
   Godot 4.7.2 is installed at `%USERPROFILE%\dev\tools\godot\4.7.2\`.
2. Open `explore/view/explore_mode.tscn` and press **F6** to explore the test overworld. Click a
   hex to walk there, arrow keys step, Enter interacts, Esc stops a walk; WASD or a middle-mouse
   drag looks around, the mouse wheel zooms. To make it what **F5** runs, right-click the scene in
   the FileSystem dock and choose **Set as Main Scene**.

## Commands

Run these from the project folder in PowerShell:

| Command | What it does |
|---|---|
| `./tools/run_tests.ps1` | Runs every unit test headless. `-Select test_hex` runs matching files; `-Test name` runs matching tests. |
| `./tools/lint.ps1` | Compiles every script with all warnings treated as errors. |
| `godot --headless --path . -s res://tools/gen_placeholder_art.gd` | Regenerates the placeholder art in `assets/`. |
| `godot --headless --path . -s res://tools/gen_placeholder_tilesets.gd` | Rebuilds the TileSets from that art (run an import first; overwrites TileSet edits). |
| `godot --path . -s res://tools/benchmarks/explore_benchmark.gd` | Times exploration on a 200×150 map, including panning. |

The scripts find Godot through `$env:GODOT`, then `PATH`, then the default install location.

## Hex playground

`tools/playgrounds/hex_playground.tscn` is a dev scene for the hex core. Mouse or arrow keys move
the cursor; click or Enter sets the start hex; `1` path, `2` movement range, `3` ring, `4` line,
`R` new terrain.

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the rules every system follows, hex coordinates,
  the folder layout, how to add content, and the roadmap.
