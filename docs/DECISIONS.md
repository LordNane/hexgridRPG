# Decisions to revisit

Choices made while building the game that you may want to change. They're defaults, placeholders
and judgment calls, not requirements. Each entry gives the choice and where to change it; the phase
that made it is in brackets. Claude adds to this list as each phase lands. Once the roadmap is
done, we go through it together and tweak.

## Look and feel

- **Resolution:** a 640×360 viewport scaled up by whole numbers, in a 1280×720 window. [0]
  *Change:* Project Settings → Display → Window.
- **Hex size:** 32×16 px top faces, 8 px per elevation level. [0] *Change:* `HexLayout.cell_size`
  and `elevation_step`, then regenerate the placeholder art and tilesets. Painted maps would need
  repainting.
- **Hex orientation:** flat-top hexes in axial coordinates, matching Godot's "Stairs Down" hex
  layout. [1] Changing this means rebuilding the TileSet and every map.
- **One TileSet for every map:** exploration and battle tiles live together in
  `overworld_tileset.tres`, despite the name; renaming it means updating the maps that use it.
  [5]
- **Battles in 2.5D:** each hex is drawn at its height with cliff art below; units are the job
  figures with a colored ring and a small HP bar. [5]
- **Placeholder art:** every sprite, tile and icon comes from `tools/gen_placeholder_art.gd`, to be
  replaced by your art. [0–4]
- **Placeholder font:** a generated pixel font (7 px capitals, 2 px descenders, proportional
  widths) from `tools/gen_placeholder_font.gd`. Body text is its native size 8, headers 16 (2×),
  the title 24 (3×). [4] *Change:* the default font in `ui/theme/pixel_theme.tres` (and its font
  sizes). Bitmap fonts should only use multiples of their size; a test checks this.
- **UI colors:** dark navy panels, gold borders and highlight, green and red for stat changes. [4]
  *Change:* `ui/theme/pixel_theme.tres` in the Theme editor.
- **Menu backdrop:** the map dims to 45% black behind menus. [4] *Change:*
  `ScreenStack.BACKDROP_COLOR`.
- **Fades:** 0.25 s out and 0.25 s in when switching modes (title, maps, caves). [3] *Change:*
  `ModeRouter.fade_seconds`.
- **Camera:** two zoom levels (1× and 2×), keyboard pan at 220 px/s, never past the map's edges.
  [2] *Change:* `MapCamera` exports.
- **Walking speed:** the party token takes 0.14 s per hex. [2] *Change:* `PartyToken.step_time`.
- **Region banner:** shows for 1.8 s when entering a region. [2] *Change:*
  `ExploreHud.BANNER_SECONDS`.
- **Job looks:** a character looks like their job (all Squires look alike); there's no per-person
  appearance yet. `JobDef.palette` is unused until Phase 9's palette-swap shader. [4]

## Controls

- **Keys and buttons:** arrows / D-pad / left stick move the cursor; Enter, Space or A confirm;
  Esc, Backspace, right-click or B cancel; Tab or Start opens the menu; WASD or the right stick pan
  the camera; the wheel, +/- or the shoulder buttons zoom; F3 is the debug overlay. [0]
  *Change:* Project Settings → Input Map.
- **Arrow keys on the map** step one hex in the screen direction pressed; clicking a hex walks
  there and interacts with what's there. [2]
- **Menus:** hovering an option with the mouse highlights it, so mouse and keyboard share one
  highlight. Esc goes back one screen; Tab closes the whole menu. [4]
- **Battles:** arrows or the mouse move the cursor, Enter or a click confirms, Esc or right-click
  backs out of choosing a move or target. The turn ends after choosing a facing. [5]

## Exploration

- **Travel time:** a move cost of 1 takes an hour; the journey starts on day 1 at 08:00. [2]
  *Change:* each `TerrainDef.move_cost`, `GameSession.START_HOUR`.
- **Terrain costs:** grass and dirt 1, sand and stone 1.5, snow and swamp 2; forests and hills add
  1; water, mountains and cave walls block. [2] *Change:* `content/data/terrain/` and `features/`.
- **Sight:** fog of war with a vision radius of 3 (2 in the test cave); hills see 1 further;
  forests, mountains and cave walls block sight. Seen hexes stay shown under a lighter fog. [2]
  *Change:* each `MapDef`, `FeatureDef`, `TerrainDef`.
- **Unexplored hexes can't be clicked to walk to;** the party walks into the unknown hex by hex. [2]
- **POIs:** most trigger when a walk ends on them or confirm is pressed there; "on enter" POIs stop
  a walk the moment it reaches them; blocking POIs (signs, people) are used from a neighboring
  hex. One-time POIs count as used only after all their actions finish. [2]
- **Caves and towns:** leaving one puts the party back on the hex it entered from. [3]
- **HUD:** day, hour and region top left; gold and "Tab: party" top right; the hovered hex's
  details bottom left. Phase 4 replaced the list of carried items with just the gold. [2, 4]

## Saving

- **Autosave only:** one "autosave" slot, written whenever the party enters or leaves a map.
  There's no manual saving yet, and changes made in the menu are saved at the next map change. [3]
  *Change:* `Game.autosave()` callers, `Game.AUTOSAVE_SLOT`.
- **Continue** loads the most recently written slot. [3]
- **Old saves** are upgraded by migrations; version 2 gives saves from before Phase 4 the starting
  party. [3, 4]
- **New games** take their random seed from the clock. [3]

## Characters and stats

- **The stat list:** HP, MP, Attack, Defense, Magic, Resist, Speed, Move, Jump, Evasion. No
  accuracy, luck or critical-hit stat (yet). [4] *Change:* `Stat.Id` (add at the end only).
- **Stat math:** (base + flat bonuses) × (1 + percent bonuses / 100) × multipliers, rounded to the
  nearest whole number; HP never below 1. [4] *Change:* `StatBlock.compute`.
- **Growth, FF Tactics-style:** each character has their own stats, which grow by their current
  job's growth at each level-up, so the jobs a character levels in shape them for good. The
  simpler alternative is stats set by job and level alone. [4] *Change:* `Character.level_up`,
  `JobDef.base_stats`.
- **Jobs scale stats, gear adds on top:** a job's multipliers apply to the character's own stats;
  gear bonuses aren't multiplied. Move, Jump and Evasion come from the job alone. [4]
- **No free healing:** changing jobs or gear never restores HP or MP; they're only capped at the new
  maximum. Switching to a low-MP job and back costs MP until the party rests (inns arrive in Phase
  8). A level-up raises current HP and MP by as much as their maximums rise. [4] *Change:*
  `Character._refresh`, `Character.level_up`.
- **Evasion** is a plain number (5 for most jobs, 10 for Archers) whose effect is decided in Phase 6.
  [4]

## Jobs, gear and abilities

- **Starting jobs:** Squire, Archer, White Mage and Black Mage, all unlocked from the start. Squires
  move 4 hexes, the others 3; Archers jump 4 levels and dodge best. [4] *Change:*
  `content/data/jobs/`.
- **All numbers are placeholder balance:** stat multipliers and growth, JP costs, item bonuses and
  prices. [4] *Change:* the `.tres` files in `content/data/`.
- **Gear slots:** Weapon, Shield, Head, Body, Accessory. The off hand only holds shields: no dual
  wielding. [4] *Change:* `EquipmentDef.Slot`, `EquipRules`.
- **Gear kinds:** sword, knife, bow, staff, rod, shield, hat, armor, robe; each job lists the kinds
  it can use. Accessories have no kind, so anyone can wear them. [4]
- **Two-handed weapons:** equipping one sends the shield back to the inventory; picking a shield
  while holding one is refused, not swapped. [4] *Change:* `EquipRules`.
- **Changing jobs** takes off gear the new job can't use and puts it in the inventory (FF Tactics
  does the same). [4]
- **Equip abilities:** support abilities such as Equip Swords let any job use a gear kind; taking the
  ability off takes that gear off too. [4]
- **The loadout:** the current job's command, one second command (from another job the character
  has learned an action in), and one reaction, one support and one movement ability from any job.
  [4] *Change:* `AbilityLoadout`, `Character`.
- **One teacher per ability:** each ability is taught by exactly one job; a content test checks. [4]
- **Basic attacks** come from the weapon: Attack for melee weapons, Shoot for bows. What an
  unarmed character does is undecided (Phase 5). [4]
- **Learning abilities with JP** isn't in the game until Phase 8, so the starting characters come
  with some abilities already learned. [4]
- **Items can't be used from the menu** until item effects exist (Phases 5–6). [4]
- **Refusals are sentences,** such as "Dara can't use the Bronze Sword as a Black Mage." Text is
  English only; there's no translation support. [4]

## The start of the game

- **Starting party:** Alden (Squire, level 3), Brin (Archer, 2), Cass (White Mage, 2) and Dara (Black
  Mage, 2). Their names, descriptions and stats are placeholders. Alden already knows Cure, so
  White Magic can be his second command. [4] *Change:* `content/data/characters/`,
  `Game.START_PARTY`.
- **Starting items:** 3 Potions, an Iron Sword, a Dagger and Sprint Shoes, and no gold. [4]
  *Change:* `Game.START_ITEMS`.
- **Starting place:** the `start` entry of the test overworld. [3] *Change:* `Game.START_MAP`,
  `Game.START_ENTRY`.

## Menus

- **Flow:** Party → a member → Equip, Jobs or Abilities; the Inventory opens from Party. There's
  no switching between members inside Equip, Jobs or Abilities (FF Tactics uses the shoulder
  buttons for that). [4]
- **One screen at a time:** opening a screen hides the one below rather than stacking windows. [4]
- **Previews:** highlighting gear, a job or an ability shows the stat changes; gear the character
  can't use is listed dimmed, with the reason, and shows no preview. [4]
- **Ordering:** jobs alphabetically; the inventory by kind (Items, Weapons, Shields, Head, Body,
  Accessories), then in the order items were found. [4]

## Battles

- **Turn order:** charge time fills by Speed each tick and a unit acts at 100. A turn costs 100 CT
  after moving and acting, 80 after one of the two, 60 after neither. Everyone starts at 0, and
  ties go to the party. [5] *Change:* `CtScheduler`.
- **Placeholder damage:** (Attack × 1.5 − Defense × 0.5) × the ability's power, ±10%, at least 1;
  magic uses Magic and Resist. Every attack hits: evasion, height, facing and elements arrive
  with Phase 6's combat math. [5] *Change:* `CombatMath`.
- **Attacks:** swords and other melee weapons reach 1 hex and at most 2 levels up or down; bows
  shoot 2 to 4 hexes at any height but can't hit a neighbor; an unarmed punch is a weaker melee
  attack (power 0.8). [5] *Change:* `content/data/abilities/weapons/`.
- **Commands:** Move, Attack and Wait only. Job commands such as Fire or Cure work once Phase 6
  gives them targeting and effects. [5]
- **Movement:** each step costs its terrain's battle move cost (swamp 2, the rest 1) out of
  Move, and can't climb or drop more levels than Jump. There's no fall damage. Allies can be
  walked past; foes block. [5] *Change:* `BattleMovement`, `TerrainDef.battle_move_cost`.
- **Facing** is chosen at the end of every turn but does nothing until Phase 6. [5]
- **Fallen units** fade out and free their hex; there's no reviving them yet. [5]
- **After a victory** the whole party is fully restored, the fallen included, as in FF Tactics.
  That makes HP worries between battles small, and inns (Phase 8) less useful; the alternative
  is to keep the damage and revive the fallen at 1 HP. [5] *Change:* `BattleResult.apply_to`.
- **Losing** shows "Defeat..." and returns to the title; Continue picks up from the last autosave,
  so a lost battle is retried from before it. [5] *Change:* `Game._on_battle_finished`.
- **Winning autosaves** as well as changing maps. [5]
- **Everyone fights:** all party members take the arena's party spawns, up to its count (4 in the
  forest arena). There's no deploy screen until Phase 6. [5]
- **The enemy's pace:** the AI pauses 0.3 s before each action so you can follow it. [5]
  *Change:* `AiTurnState.THINK_SECONDS`.
- **Placeholder AI:** enemies hit the weakest foe in reach, else walk toward the nearest one.
  Phase 7 replaces it. [5]
- **Battle camera:** 1× zoom (the whole forest arena fits), following the cursor; the mouse wheel
  zooms. [5]

## Encounters

- **Random battles** happen on 12% of steps in Greenvale and the Thornwood, after a grace of 6 quiet
  steps at the start of the journey and after every battle. The Frost Reach has none yet. A step
  that triggers a POI never starts one too. [5] *Change:* `greenvale_encounters.tres`,
  `EncounterRoller.GRACE_STEPS`, each region's `encounters`.
- **Encounters:** a Bandit Patrol (two bandits and an archer) three times as often as Bandit
  Scouts (two archers). [5]
- **Enemies are bandits** using the party's jobs and gear, tinted red; there are no monsters yet.
  They drop gold and sometimes a Potion or Phoenix Down. [5] *Change:* `content/data/enemies/`.
- **One arena for now:** every terrain and the forest and hills features fight in the generated
  forest clearing. An encounter's own arenas come first, then the feature's, then the terrain's.
  [5] *Change:* each Def's arena list; paint more arenas (Phase 10).
- **POI battles:** `StartBattleAction` works (an ambush or a guarded chest), but no POI on the maps
  uses one yet. [5]

## Already planned for later phases

These come from the roadmap; confirm or change them before their phase starts.

- **Combat** uses facing (rear attacks hit more often), height, elements and seeded damage variance,
  with spells that take time to charge. The party is deployed by hand before battle. [6]
- **Enemy AI** scores each option with weighted considerations (damage, kill chance, healing,
  threat, high ground, backstabs), with profiles such as Brute, Archer, Healer and Caster. [7]
- **Progression:** XP and JP per action, job unlocks by job level, shops gated by conditions, inns
  and recruits. [8]
- **Presentation:** job sprites drawn in two facings and mirrored to six, a palette-swap shader,
  optional 60° battle camera rotation, and dialogue through the Dialogue Manager plugin. [9]
- **Release:** a Windows build. [10]
