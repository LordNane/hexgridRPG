# Architecture

How the code is organized and the rules every system follows. The goal: new content is a data
file, and a new mechanic is a small, separate script.

## Rules

1. **Rules and visuals stay separate.** Game rules live in plain `RefCounted` classes with no
   Nodes; Nodes only draw and read input. Rules can then be unit-tested, simulated by the AI, and
   restyled without changes.
2. **Content is data.** Terrain, features, POIs, items, jobs, abilities, statuses, enemies,
   encounters and maps are `.tres` Resources extending `Def` (`id`, `display_name`,
   `description`, `icon`). Defs are read-only at runtime because Resources are shared; state that
   changes during play lives in runtime classes (`Character`, `BattleUnit`, `StatusInstance`).
3. **Behavior is composed from small parts.** Each extension point is an `@abstract` base class
   with one small subclass per behavior, combined in the inspector:
   abilities = targeting + `Array[Effect]`, POIs = `Array[PoiAction]`, statuses = modifiers +
   effect hooks, AI = weighted `Consideration`s, requirements = `Condition`s.
4. **One hex library** (`core/hex`) serves the overworld, locations and battles.
5. **Every map follows Scene → Builder → Model → View.** Maps are authored as scenes
   (TileMapLayers + marker nodes); a Builder reads the scene into a model; a View draws the model.
6. **Rules return events; views play them.** `battle.execute(action)` changes the model
   immediately and returns `Array[BattleEvent]`; `await view.play(events)` animates them.
7. **Modes hand off explicitly.** A battle takes a `BattleRequest` and returns a `BattleResult`;
   no mode reaches into another's internals.
8. **Randomness is seeded.** Use a `SeededRng`, never `randi()`, `randf()` or `Array.shuffle()`.
9. **Saves store IDs and state**, never node or resource paths. Every stateful class has
   `to_dict()` / `from_dict()` and a round-trip test.

## Conventions

- Follow the official GDScript style guide: tabs, `snake_case` files, `PascalCase` classes,
  past-tense signals (`hp_changed`), `_private` members, `##` doc comments on public API.
- One class per file with a `class_name`. **Exception:** autoload scripts (`game/game.gd`,
  `content_db.gd`, `event_bus.gd`) have no `class_name`, since a global class with the
  autoload's name would hide the autoload.
- Static typing is enforced: the `untyped_declaration` warning is an error. Use `:=` or explicit
  types, and type loop variables (`for hex: Vector2i in hexes:`).
- Zero warnings: `tools/lint.ps1` must pass. `integer_division` is ignored project-wide because
  integer math is intentional throughout the hex code.
- Wire nodes with their own signals; use the `EventBus` autoload only for game-wide broadcasts.
- Tests mirror the source tree: `core/hex/hex.gd` → `tests/core/hex/test_hex.gd`.

## Hex coordinates

- A hex is a `Vector2i(q, r)` in **axial** coordinates, flat-top. Directions are `Hex.Dir`
  values stored as `int`: SE (1, 0), NE (1, -1), N (0, -1), NW (-1, 0), SW (-1, 1), S (0, 1).
- `Hex` is pure math with no pixels. `HexLayout` is the only place hexes become pixels:
  32×16 px top faces and 8 px per elevation level by default.
- Paint maps with a TileSet set to **Hexagon** shape, **Vertical** offset axis, **Stairs Down**
  layout and tile size = `HexLayout.cell_size`. Its TileMapLayer coordinates *are* axial
  coordinates (`test_tilemap_coordinates_are_axial` proves it), so editor maps and game logic
  agree without conversion.
- Movement rules plug into `HexPathfinder` as a step-cost function
  `(from: Vector2i, to: Vector2i) -> float`, where `INF` means impassable.

## Exploration maps

The overworld, caves and towns are all exploration maps: one system, different content. On these
maps the painted tile layers and marker nodes draw themselves; `ExploreMode` only adds what changes
during play (fog, the party, the route preview). The rules live in `Exploration`, which returns a
`StepOutcome` for each step, the same way battles will return events.

To make a new map:

1. Duplicate `explore/maps/test_overworld.tscn`, or make a scene whose root uses
   `ExploreMapScene` with three TileMapLayers (`Terrain`, `Features`, `Regions`) sharing
   `assets/tilesets/overworld_tileset.tres`, plus a `Markers` node. Assign them in the root's inspector.
2. Paint terrain from atlas source 0 (select several variants and turn on random tile placement to
   scatter them), nature features from source 1, and regions from source 2. Hide the `Regions`
   layer while painting the rest; it's hidden in-game anyway.
3. Under `Markers`, add `PoiMarker` nodes (assign a `PoiDef` from `content/data/pois/`) and an
   `EntryMarker` named `start`. Markers snap to hex centers.
4. Add a `MapDef` in `content/data/maps/` pointing at the scene.
5. Run the tests: `test_game_content.gd` checks that every map builds cleanly and that every POI
   can be reached from `start`.

A tile's terrain, feature or region comes from its custom data (`terrain_id`, `feature_id`,
`region_id`), so new art never needs code: add tiles to the TileSet and set their ids.

## Tools

- `tools/run_tests.ps1`, `tools/lint.ps1`: tests and the zero-warnings check.
- `tools/gen_placeholder_art.gd`, then an import, then `tools/gen_placeholder_tilesets.gd`:
  regenerate placeholder art and the TileSets built from it (this overwrites TileSet edits).
- `tools/benchmarks/explore_benchmark.gd`: exploration timings on a 200×150 map.
- Scripts run with `-s` compile before the autoloads exist, so they must not name `ContentDB`,
  `Game` or classes that use them; reach those at runtime with `root.get_node(...)` and start
  work from the second frame.

## Layout

| Folder | Holds |
|---|---|
| `core/` | Engine-agnostic building blocks: hex math, stats, utilities, saving |
| `content/` | Def classes, effects, POI actions, conditions; `content/data/` holds the `.tres` content |
| `game/` | Autoloads, the game session and mode switching |
| `explore/` | Overworld **and** locations: one exploration system |
| `party/` | Characters, party, inventory, equipment, jobs |
| `battle/` | Battle model, AI, controller states, 2.5D view, arenas |
| `ui/` | Theme, menu screens, battle HUD |
| `assets/` | Sprites, tilesets, fonts, audio, shaders |
| `tools/` | Test/lint scripts, generators, dev playgrounds |
| `tests/` | GUT unit tests |

## Adding things

| To add… | Do this | New code? |
|---|---|---|
| Weapon / armor / accessory | `EquipmentDef` .tres | none |
| Spell built from existing mechanics | `AbilityDef` .tres combining targeting + effects | none |
| New spell mechanic | one `Effect` subclass | 1 file |
| Job | `JobDef` .tres + sprite/palette | none |
| Status effect | `StatusDef` .tres | none |
| Terrain or nature feature | Def .tres + tiles tagged with `terrain_id` / `feature_id` | none |
| POI (chest, shrine, NPC, door) | `PoiDef` combining actions; a new behavior is one `PoiAction` subclass | 0–1 file |
| Cave / town | map scene + `MapDef` + a POI with `EnterMapAction` | none |
| Battle arena | arena scene added to a terrain's or encounter's pool | none |
| Enemy / enemy behavior | `EnemyDef` + `AiProfile` .tres; new logic is one `Consideration` | 0–1 file |
| Win/lose condition | one `BattleOutcome` subclass | 1 file |
| Animation for a new event type | one handler in `BattleView`'s event→handler table | 1 method |

## Roadmap

Each phase ends with something playable or testable.

- [x] **0 Foundation:** project settings, input map, autoloads, tests, lint, placeholder art.
      Hex size locked at 32×16 px with 8 px elevation steps. *Open:* palette and pixel font.
- [x] **1 Hex core:** `Hex`, `HexLayout`, `HexPathfinder`, utilities, hex playground.
- [x] **2 Content framework + overworld exploration:** `ContentDB`, validator, terrain, features,
      regions, POIs with actions and conditions, fog of war, test overworld, 200×150 benchmark.
- [ ] **3** Session, mode flow, locations, saving
- [ ] **4** Party, jobs, equipment, abilities (data + menus)
- [ ] **5** Battle core: the vertical slice (explore → encounter → battle → reward)
- [ ] **6** Combat depth: spells, targeting, status, positioning
- [ ] **7** Enemy AI
- [ ] **8** Progression & economy
- [ ] **9** Presentation & polish
- [ ] **10** Content & release
