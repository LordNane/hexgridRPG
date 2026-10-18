# Hex RPG — notes for Claude

A party-based pixel-art tactics RPG: hand-painted hex overworld, hex-step caves/towns, FF
Tactics-style 2.5D hex battles with elevation. Godot 4.7.2, typed GDScript, Windows.

## Start here
- **Rules, conventions, hex coordinates, map authoring, progress checkboxes:** `docs/ARCHITECTURE.md`.
- **What each upcoming phase builds and its "Done when":** `docs/ROADMAP.md`.
- Work one phase at a time; finish its Done-when, tick its box in ARCHITECTURE.md, then stop and
  report. Next up: **Phase 3**.

## Commands (PowerShell, from the project folder)
- `./tools/run_tests.ps1` (optionally `-Select test_hex`): GUT tests, headless. Must pass.
- `./tools/lint.ps1`: compiles every script with warnings as errors. Must say "no warnings".
- Godot: `C:\Users\caden\dev\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`
  (`$env:GODOT` overrides). Visual checks: `--write-movie <dir>\frame.png --quit-after N` with a
  scratch `-s` script driving the scene, then look at the frames.

## Working agreements
- The user usually has the Godot editor open. Don't edit `project.godot` then (the editor
  overwrites it); ask the user to change settings in the editor. Creating/editing other files is fine.
- The user paints maps and makes final art; Claude writes code, tests, tools and placeholder art.
- Commit only when asked. Content is data: new content = `.tres` files, new mechanics = small subclasses.

## Gotchas already hit (don't rediscover them)
- Write files without a UTF-8 BOM (PowerShell 5.1 `Set-Content -Encoding utf8` adds one; Godot
  then misreads the first key). Use the Write tool or `[IO.File]::WriteAllText`.
- PowerShell 5.1: don't combine `$ErrorActionPreference = "Stop"` with redirecting Godot's stderr.
- `-s` scripts compile before autoloads exist: don't name `ContentDB`, `Game`, or classes that use
  them (e.g. `ExploreMode`); use `root.get_node("Game")` and start work on the second frame.
- Awaiting an overridable method (`PoiAction.run`, `PoiHost.say`) needs
  `@warning_ignore("redundant_await")` with a comment; that's the only accepted exception.
- Array literals inside `a if cond else b` stay untyped; assign typed arrays in plain if/else.
- When saving resources from scripts, call `resource.take_over_path(path)` after
  `ResourceSaver.save` so later saves reference the file instead of embedding a copy
  (`test_game_content.gd` catches embedded copies).
- A typed Dictionary's `keys()`/`values()` come back untyped: use `typed_array.assign(...)`.
- Exploration can't target unexplored hexes (by design); scripted walks must step hex by hex.
