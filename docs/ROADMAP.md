# Roadmap

The build order, phase by phase. Each phase ends with something playable or testable; finish its
**Done when** before starting the next. Progress is tracked with the checkboxes in
[ARCHITECTURE.md](ARCHITECTURE.md#roadmap). Phases 0–2 are done; their details are in the code.

## Phase 3 — Session, mode flow, locations, saving
- **`GameSession`** (exists, minimal) grows: party, gold, a map stack with positions.
  - The `Game` autoload holds the current session; systems receive it as a parameter where practical.
- **`ModeRouter`**: a stack of game modes with `push`, `pop(result)` and fade transitions.
  - Lower modes stay alive but paused and hidden, so `await router.run_battle(request)` resumes
    the POI script that started the battle.
  - Replaces `ExploreMode`'s exported `map_id`/`entry_name`.
- **Locations reuse the explore system as-is:**
  - `MapDef` already covers overworld and caves/towns.
  - New POI actions: `EnterMapAction(map, entry)` pushes a map; `ExitMapAction` pops back to the
    same overworld hex. `EntryMarker` names arrival points. NPCs, doors and stairs are POIs.
  - Swap `cave_mouth`'s placeholder message for `EnterMapAction` into a test cave.
- **`SaveService`:** JSON save slots in `user://saves/` with a version number and migration
  functions; autosave on map change; a title screen with New and Continue. Every stateful class
  already has `to_dict()` / `from_dict()`.
- **Done when:** enter a cave from its hex, open a chest, exit to the same hex; after save, quit and
  load you're in the same place, the chest is still open, and explored fog stays explored.

## Phase 4 — Party, jobs, equipment, abilities (data + menus)
- **Stats:** `Stat` enum (HP, MP, ATTACK, DEFENSE, MAGIC, RESIST, SPEED, MOVE, JUMP, EVASION…),
  `StatModifier` (flat / percent / multiply), `StatBlock.compute(base, modifiers)` as one pure
  function that job, level, gear, passives and statuses all feed.
- **Runtime:** `Character` (level, current job, per-job `JobProgress` with JP and learned abilities,
  `Equipment`, `AbilityLoadout`, HP/MP, `changed` signal), `Party`. `Inventory` exists.
- **Defs:** `JobDef` (stat multipliers/growth, equippable tags, abilities with JP costs, unlock
  `Condition`s, sprite + palette); `ItemDef` → `EquipmentDef` (slot, equip tag, modifiers, granted
  tags) → `WeaponDef` (its basic attack is an `AbilityDef`); `ConsumableDef` (uses an `AbilityDef`);
  `AbilityDef` (used in battle from Phase 5).
- **FFT-style loadout:** primary command set from the job, plus secondary, reaction, support and
  movement slots.
- **`EquipRules.can_equip(character, item, slot) -> String`:** empty if allowed, else the reason.
- **UI:** pixel `Theme`, `ScreenStack` (push/pop, gamepad focus), Party / Equip (stat-delta preview
  via `StatBlock.compute`) / Jobs / Abilities / Inventory screens. UI calls model methods only.
- **Starter content:** 4 jobs (Squire, Archer, White Mage, Black Mage), ~15 items, ~12 abilities.
- **Done when:** changing jobs or gear updates stats live, unusable gear is refused with a reason,
  and Character/Party save round-trips pass.

## Phase 5 — Battle core: the vertical slice
- **Arena authoring:** `BattleArena` @tool scene with `TerrainLayer`, `HeightLayer` (paint the
  0–9 tiles from `height_digits.png`, read via `height` custom data, hidden at runtime),
  `PropLayer` (trees/rocks blocking movement or sight), `PartySpawn`/`EnemySpawn` markers, and a
  live 2.5D preview. `BattleMapBuilder` → `BattleMap` (terrain, height, prop per cell). Running an
  arena scene directly opens it in `battle_sandbox.tscn`.
- **Model:** `Battle` (map, units, scheduler, RNG, outcomes). `BattleUnit` wraps a `Character`
  (team, hex, facing, CT, statuses); enemies are Characters too, via `EnemyDef`. `CtScheduler`:
  speed fills CT, act at 100, turn cost depends on moved/acted. Command-pattern actions:
  `MoveAction` (budget, terrain, jump vs height; enemies block, allies pass), `AbilityAction`
  (weapon attack with `DamageEffect`), `WaitAction` (facing). Outcomes `DefeatAllEnemies`,
  `PartyDefeated`. `battle.execute(action)` returns `Array[BattleEvent]`; `await view.play(events)`.
- **2.5D view:** a `CellView` per hex (top face raised by `height × elevation_step`, cliff segments
  from `cliff_faces.png` below); units and props sorted by ground row, a unit right after its cell;
  `CellPicker` tests outlines front to back; keyboard/gamepad cursor; range highlights; all
  hex→screen goes through one `project()` so camera rotation can come later.
- **Control:** `BattleMode` state machine (TurnStart → SelectCommand → SelectMove/SelectTarget →
  Resolve → Facing → TurnEnd → … → BattleEnd) using `core/util/state_machine.gd`; placeholder AI.
- **Glue:** `EncounterDef`, `EncounterTable` (per region/terrain), `EncounterRoller` on overworld
  steps with a grace period (hook it into `Exploration.step_to`), `StartBattleAction`,
  `BattleResult` applied to the session; defeat → game over → title.
- **HUD:** turn-order timeline (`CtScheduler.preview`), unit card, command menu.
- **Done when:** walk the overworld, get a random encounter, fight on a hand-made forest arena with
  elevation, win, collect loot, end up back on the same hex.

## Phase 6 — Combat depth: spells, targeting, status, positioning
- `TargetingDef` (range min/max; disc, line, ring or self; area shape; vertical tolerance; line of
  sight; target filter) + `Targeting` service + area preview.
- Effects: `Damage`, `Heal`, `ApplyStatus`, `RemoveStatus`, `Push` (fall damage), `Teleport`,
  `Revive`, `RestoreMp`.
- `StatusDef`: duration, modifiers, flags (stun/silence/sleep), per-turn `Effect` hooks.
- `CombatMath`, the single source for formulas (damage, elements, height, facing table, crits,
  seeded variance), shared by the forecast panel and the AI.
- Charge-time spells resolve later in the scheduler. Items in battle, reactions, supports, tags
  (`&"flying"`, `&"ignore_height"`), manual deploy screen.
- **Done when:** CombatMath/Targeting/status tests pass; a charged area spell resolves on schedule,
  poison ticks, a rear attack forecasts a higher hit chance.

## Phase 7 — Enemy AI
- `AiPlanner` scores (move × ability × target) options with an `AiProfile` of weighted
  `Consideration` resources (damage, kill chance, healing, threat, approach, high ground,
  backstab). Profiles as data: Brute, Archer, Healer, Caster. Debug overlay shows top options.
- **Done when:** 100 seeded headless AI-vs-AI battles produce no invalid actions within a per-turn
  time budget, and the AI visibly uses height and focus fire.

## Phase 8 — Progression & economy
- XP/JP per action, level-ups from job growth, job unlocks (`JobLevelCondition`), learning
  abilities with JP, loot tables, shops (`ShopDef` gated by conditions), inn/rest and recruit POIs.
- **Done when:** leveling one job unlocks another, a learned secondary ability works in battle,
  and buying/selling survives save/load.

## Phase 9 — Presentation & polish
- Final art (tiles, features, icons; job sprites with two facings mirrored to six; palette-swap
  shader), animations, spell VFX, damage numbers, screen shake, `AudioManager`, occluder fading,
  optional 60° battle camera rotation, options menu, dialogue via the Dialogue Manager plugin
  behind a `DialogueAction`.

## Phase 10 — Content & release
- Paint the full overworld, build locations and per-terrain arena pools, fill encounter tables,
  write the story, balance with the AI sim, playtest, export a Windows build.
