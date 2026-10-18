# Hex RPG — notes for Claude

A party-based pixel-art tactics RPG: hand-painted hex overworld, hex-step caves/towns, FF
Tactics-style 2.5D hex battles with elevation. Godot 4.7.2, typed GDScript, Windows.

## Start here
- **Rules, conventions, hex coordinates, map authoring, progress checkboxes:** `docs/ARCHITECTURE.md`.
- **What each upcoming phase builds and its "Done when":** `docs/ROADMAP.md`.
- **Choices the user may want to change later:** `docs/DECISIONS.md`.
- Work one phase at a time; finish its Done-when, tick its box in ARCHITECTURE.md, then stop and
  report. Next up: **Phase 6**.

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
- Keep `docs/DECISIONS.md` current: whenever a phase makes a choice the user may want to change
  (rules, numbers, UI flow, placeholders, defaults), add it there with where to change it. Mention
  new entries when reporting a phase. After the last roadmap phase, present the whole list so the
  user can start tweaking.

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
- `JSON.stringify` sorts dictionary keys unless `sort_keys` is false. `SaveService` turns it off so
  order-dependent data (the inventory's acquisition order) survives saving.
- GUT counts `queue_free()`d nodes as orphans until the frame ends: tests where the `ModeRouter`
  discards modes wait a frame in `after_each`.
- `set_meta(name, null)` erases the entry, and `get_meta(name, null)` still errors when it's
  missing (a null default counts as none): check `has_meta` first.
- GDScript's `==` errors on mismatched types (`Object == StringName`), so menu values that mix
  types are compared after a type check (`MenuList.option_for`) or an `is` test.
- `Game.start_battle` never returns after a defeat (the game resets to the title), so a test that
  awaits a battle must bound the wait (`wait_until`) and use a fixed seed. Battles started by
  `BattleMode` begin a frame after it's added, and with `instant` the AI acts a frame apart.
- Scratch `-s` scripts can't name `BattleMode`, `BattleSandbox` or the screens, which use autoloads:
  reach them untyped (`node.get("battle")`). The model classes (`Battle`, `BattleUnit`…) are fine.
- Run long test batches under a timeout (`timeout 400 powershell -File ./tools/run_tests.ps1`): once,
  a run hung right after the engine error "BUG: Unreferenced static string to 0:
  Physics2DConstraintSolveIslands" (an engine race; it hasn't come back since).
- End-to-end checks: a scratch `-s` script can add `game/main.tscn` to the root on frame 2, point
  `Game.saves` at a throwaway folder, send keys with `Input.parse_input_event`, and screenshot with
  `root.get_texture().get_image()` (windowed, not headless).
