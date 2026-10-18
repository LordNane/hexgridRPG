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

### Caves, towns and other locations

A location is just another exploration map (`explore/maps/test_cave.tscn` is the example). To
connect one:

1. Make its map as above. Its `start` entry is where the party arrives by default; add more
   `EntryMarker`s for other ways in.
2. On the map it's entered from, add a POI whose actions include an `EnterMapAction` naming the
   map and the entry, like `content/data/pois/cave_mouth.tres`.
3. Inside, add a POI with an `ExitMapAction`, like `cave_exit.tres`. It takes the party back to the
   hex it entered from, once that POI's actions finish.

`test_game_content.gd` checks that every `EnterMapAction` names an entry its map has. Paint cave
walls with `cave_wall` terrain: it blocks movement and sight, so walls are revealed as the party
walks.

## Modes, sessions and saving

- **`game/main.tscn`** is the main scene. It hands its `ModeRouter` to the `Game` autoload, which
  shows the title screen and runs the game's flows: `new_game()`, `continue_game()`, `enter_map()`,
  `exit_map()`, `start_battle()` and `autosave()`.
- **`ModeRouter`** is a stack of modes: the title screen, `ExploreMode` and `BattleMode`.
  Only the top mode is in the scene tree. The ones below stay alive out of the tree, so they're
  hidden, paused and deaf to input with no code of their own, and their cameras step aside.
  `await router.push(mode)` returns what `router.pop(result)` passes, so the POI script that
  started a cave or battle carries on afterwards. `switch_to(modes)` replaces the whole stack (title
  to game, loading a save). Changes fade through black and ignore input meanwhile.
- **`GameSession`** is one playthrough: inventory, gold, flags and per-map state (`WorldState`,
  `MapState`), the clock, the RNG, and the **map stack**, one `MapPosition` per map the party is
  inside, the current one on top. `Exploration` moves the top position as the party steps; leaving a
  map pops back to the position below, which still holds the hex the party left from.
- **`SaveService`** writes JSON save slots to `user://saves/<slot>.json`, stamped with the save
  format version. `Game` autosaves to the `autosave` slot whenever the party arrives on a map or
  leaves one, and after every won battle. Continue loads the most recent slot and rebuilds one `ExploreMode` per map-stack
  entry; the ones below the top build when they're revealed.
- **Changing the save format:** when saved data changes shape, write a migration function that
  turns the previous version's data into the new shape, and add it to `Game.migrations()`, the
  list `Game` passes to `SaveService.new()`. The version is one more than the number of migrations,
  so the two can't drift apart. Version 2 added the party; `Game._add_starting_party` is the
  example. A new field that `from_dict` can fill with a default, like `encounter_grace`, needs no
  migration.

## Characters, jobs and stats

- **Stats** (`core/stats/`): every character has the `Stat.Id` stats. Final stats come from one
  function, `StatBlock.compute(base, modifiers)`: `(base + flat) × (1 + percent / 100) ×
  multipliers`, rounded. Gear, equipped abilities and, from Phase 6, statuses all feed it
  `StatModifier`s.
- **The base, FF Tactics-style:** each `Character` has their own stats, which grow by the current
  job's `stat_growth` at each level-up, so the jobs a character levels in shape them for good.
  Their current job scales those by its `stat_multipliers` and sets Move, Jump and Evasion
  outright (`JobDef.base_stats`).
- **`Character`** holds the level, the job, a `JobProgress` per job (JP and learned abilities),
  `Equipment`, an `AbilityLoadout` and HP/MP, and emits `changed`. Change it only through its
  methods (`equip`, `change_job`, `set_secondary`, `equip_ability`…). They apply the rules, move
  gear to and from the inventory, and return why a change was refused as a sentence for the
  player, or `""`. Each has a preview (`preview_equip`, `preview_job`, `preview_ability`) that makes
  the same change on a copy, so a preview always matches the result.
- **Gear rules** are `EquipRules.can_equip(character, item, slot)`: gear goes in its own slot; its
  `equip_tag` must be in the job's `equip_tags`, or an equipped ability's (Equip Swords); and a
  two-handed weapon leaves no hand for a shield. Gear a change makes unusable, such as a sword
  after changing to Black Mage, goes back to the inventory.
- **The loadout:** the job's learned actions are the main command, another job's learned actions
  can be the secondary command, plus one reaction, one support and one movement ability learned
  in any job.
- **`Party`** is the session's ordered list of characters. A new game builds it from the
  `CharacterDef`s named in `Game.START_PARTY`, and gives it `Game.START_ITEMS`.
- Content files store `Stat.Id` and `EquipmentDef.Slot` values as numbers, so add new stats and
  slots at the end of their enums. Saves store their names.
- Job unlocks are `Condition`s; `is_met(session, character)` gets the character changing jobs, so a
  condition can ask about their levels (Phase 8's `JobLevelCondition`).

## Menus

- `ui/theme/pixel_theme.tres` styles every screen, the HUD and the title screen; edit it in the
  Theme editor to restyle them all. Its type variations (`HeaderLabel`, `DimLabel`,
  `WarningLabel`, `UpLabel`/`DownLabel`, `DimButton`, `InsetPanel`) cover the special cases.
- **Fonts:** the theme's default font is a placeholder pixel font, generated by
  `tools/gen_placeholder_font.gd` (`assets/fonts/placeholder/`). To use another font, set it as
  the theme's default font and adjust the font sizes; a bitmap font's sizes must be whole
  multiples of its own size (8 for the placeholder: 8 body, 16 headers, 24 title), which
  `test_pixel_theme.gd` checks, along with every character the game shows being in the font.
- `ScreenStack` shows `MenuScreen`s one over another, with only the top one in the tree. It does the
  keyboard and gamepad focus (each screen focuses its default control; closing one puts the focus
  back where it was), cancel (back one step) and the menu button (close everything).
  `ExploreMode` opens the party menu on Tab or Start.
- Screens build their controls in code from `MenuList`, `StatsPanel` and `CharacterCard`, and only
  call model methods. The party menu: Party → a member → Equip / Jobs / Abilities, plus Inventory.

## Battles

### Arenas

An arena is a scene whose root uses `BattleArena` (`battle/arenas/forest_clearing.tscn` is the
example), with three TileMapLayers sharing `assets/tilesets/overworld_tileset.tres` and a `Markers`
node:

1. **Terrain:** terrain tiles, as on exploration maps. Each terrain tile also holds the `cliff`
   texture drawn under raised hexes.
2. **Heights:** the 0–9 tiles (atlas source 3, from `height_digits.png`); their `height` custom
   data is the elevation. Unpainted hexes are at 0. Hidden while playing.
3. **Props:** trees and rocks (source 4), named by `prop_id` custom data (`PropDef`s).
4. **Markers:** `PartySpawn` and `EnemySpawn` nodes, each with a facing. Units take their side's
   spawns in scene order; the editor numbers them.

In the editor the arena is drawn in 2.5D beside the painted layers, updating as you paint. Running
the arena scene by itself (F6) plays a test battle in it through `battle/battle_sandbox.tscn`.
For random battles, add the arena to a terrain's or feature's `battle_arenas`, or an encounter's
`arenas`; `test_game_content.gd` checks every arena builds cleanly with enough spawns.

### Model, view and control

- **`Battle`** holds the `BattleMap` (terrain, height and prop per hex, from `BattleMapBuilder`),
  the `BattleUnit`s (each wraps a `Character`: enemies are Characters too, made from `EnemyDef`s),
  the `CtScheduler`, a `SeededRng` and the `BattleOutcome`s. Each turn is `start_turn()`, then
  `execute(action)` with a `MoveAction`, an `AbilityAction` and finally a `WaitAction`; each returns
  the `BattleEvent`s that happened. `check(action)` gives the reason an action isn't allowed.
- **Rules live in small classes:** `BattleMovement` (Move, Jump, terrain costs, who blocks),
  `Targeting` (range and vertical reach from an ability's `TargetingDef`), `CombatMath` (every
  formula) and `Effect` subclasses such as `DamageEffect`. Abilities work in battle once they
  have a `TargetingDef` and effects.
- **`BattleView`** draws a `CellView` per hex and a `UnitView` per unit, all placed on their hex's
  ground point under a y-sorted node, so they draw back to front. Every hex-to-screen conversion
  goes through `BattleProjection.project()`, and `CellPicker` finds the hex under the mouse front
  to back. `play(events)` runs one handler per event type.
- **`BattleMode`** runs the turn as a state machine (`battle/control/states/`): Start → TurnStart →
  Command → SelectMove or SelectTarget → Resolve → … → Facing → TurnStart, with AiTurn for
  enemies (`PlaceholderAi` until Phase 7) and End for the result. `BattleHud` shows the turn
  order, unit cards, the command menu and the result.

### Getting into battles

- **Random battles:** a `RegionDef` names an `EncounterTable` (chance per step, weighted
  `EncounterDef`s). `Exploration.step_to` rolls on it through `EncounterRoller`, after a grace
  period of quiet steps, and the arena comes from the encounter's pool, else the feature's, else the
  terrain's.
- **On purpose:** a POI with a `StartBattleAction`.
- **`Game.start_battle(encounter, arena)`** pushes a `BattleMode` with a `BattleRequest`. A victory
  pops back with a `BattleResult`: loot added, party restored, grace reset, autosaved, the party on
  the same hex. A defeat goes back to the title, and the call never returns, so tests must bound
  any wait on it.

## Tools

- `tools/run_tests.ps1`, `tools/lint.ps1`: tests and the zero-warnings check.
- `tools/gen_placeholder_art.gd`, then an import, then `tools/gen_placeholder_tilesets.gd`:
  regenerate placeholder art and the TileSets built from it (this overwrites TileSet edits). The
  one hex TileSet holds terrain, feature, region, height and prop tiles for every map.
- `tools/gen_placeholder_font.gd`: regenerates the placeholder pixel font from the glyph patterns
  in the script.
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
| Weapon / armor / accessory | `WeaponDef` (with an attack `AbilityDef`) / `EquipmentDef` .tres | none |
| Consumable | `ConsumableDef` .tres + the `AbilityDef` it uses | none |
| Spell built from existing mechanics | `AbilityDef` .tres combining targeting + effects | none |
| New spell mechanic | one `Effect` subclass | 1 file |
| Job | `JobDef` .tres + sprite/palette; its abilities go in its `abilities` with JP costs | none |
| Premade character | `CharacterDef` .tres; for the starting party, add its id to `Game.START_PARTY` | none |
| Menu screen | one `MenuScreen` subclass, pushed on a `ScreenStack` | 1 file |
| Status effect | `StatusDef` .tres | none |
| Terrain or nature feature | Def .tres + tiles tagged with `terrain_id` / `feature_id` | none |
| POI (chest, shrine, NPC, door) | `PoiDef` combining actions; a new behavior is one `PoiAction` subclass | 0–1 file |
| Cave / town | map scene + `MapDef` + a POI with `EnterMapAction`, and one with `ExitMapAction` inside | none |
| Battle arena | `BattleArena` scene added to a terrain's, feature's or encounter's arena pool | none |
| Battle prop (tree, rock…) | `PropDef` .tres + a prop tile with its `prop_id` | none |
| Enemy / enemy behavior | `EnemyDef` + `AiProfile` .tres; new logic is one `Consideration` | 0–1 file |
| Encounter | `EncounterDef` .tres, listed in a region's `EncounterTable` or a `StartBattleAction` | none |
| Win/lose condition | one `BattleOutcome` subclass | 1 file |
| Animation for a new event type | one handler in `BattleView`'s event→handler table | 1 method |

## Roadmap

Each phase ends with something playable or testable.

- [x] **0 Foundation:** project settings, input map, autoloads, tests, lint, placeholder art.
      Hex size locked at 32×16 px with 8 px elevation steps. *Open:* palette and pixel font.
- [x] **1 Hex core:** `Hex`, `HexLayout`, `HexPathfinder`, utilities, hex playground.
- [x] **2 Content framework + overworld exploration:** `ContentDB`, validator, terrain, features,
      regions, POIs with actions and conditions, fog of war, test overworld, 200×150 benchmark.
- [x] **3 Session, mode flow, locations, saving:** `ModeRouter` mode stack with fades, `Game`
      flows and title screen, the map stack in `GameSession`, `EnterMapAction`/`ExitMapAction` and
      a test cave, versioned JSON save slots with autosave on map change.
- [x] **4 Party, jobs, equipment, abilities:** `Stat`/`StatModifier`/`StatBlock.compute`,
      `Character` and `Party` in the session (save format 2), jobs, gear and abilities as data
      with `EquipRules` and an FFT-style loadout, pixel theme and `ScreenStack` menus (Party,
      Equip, Jobs, Abilities, Inventory), starter content: 4 jobs, 17 items, 20 abilities and 4
      starting characters, placeholder pixel font. Choices to revisit are in DECISIONS.md.
- [x] **5 Battle core:** arenas painted with height and prop tiles and a live 2.5D preview,
      `Battle` with CT turns, move/attack/wait actions, events and outcomes, the 2.5D view and
      cursor, `BattleMode` states and HUD, random encounters with a grace period, POI battles,
      loot and the return to the same hex; defeat ends the game.
- [ ] **6** Combat depth: spells, targeting, status, positioning
- [ ] **7** Enemy AI
- [ ] **8** Progression & economy
- [ ] **9** Presentation & polish
- [ ] **10** Content & release
