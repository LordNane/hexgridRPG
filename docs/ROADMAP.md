# Roadmap

The build order, phase by phase. Each phase ends with something playable or testable; finish its
**Done when** before starting the next. Progress is tracked with the checkboxes in
[ARCHITECTURE.md](ARCHITECTURE.md#roadmap). Phases 0–5 are done; their details are in the code and
in ARCHITECTURE.md.

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
- Go through [DECISIONS.md](DECISIONS.md) together and tweak whatever should change.
