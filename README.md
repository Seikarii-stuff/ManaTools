# ManaTools

World of Warcraft addon that groups three small quality-of-life features under one addon: **NoWasteCoin**, **CinematicSkip**, and **NoInfo**.

> **Repository / maintenance note:** This README is intentionally written as an implementation-oriented reference for contributors and coding agents. Prefer the source files and `.toc` as the source of truth when behavior differs from this document.

## Project status

- Language: **Lua**
- Addon interface: **120100**
- Current addon version: **1.1.0**
- Author: **Seikarii**
- Saved variables: `ManaToolsDB`
- Entry point: `Bootstrap.lua`
- Load order is defined by `ManaTools.toc`.

## Repository layout

```text
.
├── Bootstrap.lua                 # Shared namespace + SavedVariables initialization
├── ManaTools.toc                  # WoW addon manifest and load order
├── Options.lua                    # Settings UI for all features
├── SlashCmd.lua                   # /mana command handling
├── CinematicSkip/
│   └── cinematicskip.lua           # Cinematic/movie/talking-head skipping
├── NoInfo/
│   └── NoInfo.lua                 # Tooltip filtering + optional Mythic+ rating
├── NoWasteCoin/
│   └── NoWasteCoin.lua             # Bonus Roll spending guard
├── Tests/
│   └── NoInfoTest.lua              # Existing focused test file
├── test/
│   ├── mockwow.lua                 # WoW API mock environment
│   ├── test_all.lua
│   ├── test_cinematic_skip.lua
│   ├── test_mana_coin.lua
│   ├── test_no_info.lua
│   ├── test_no_waste_coin.lua
│   └── test_no_waste_coin_behavior.lua
├── test/perf/
│   └── benchmark.lua               # Performance benchmark
├── test/results/
│   └── benchmark.txt               # Benchmark output
└── docs/
    └── debt.md                     # Known technical debt
```

## Architecture

`Bootstrap.lua` creates the shared `ManaTools` namespace and binds it to the persistent `ManaToolsDB` table. Each feature stores its own configuration below a dedicated key:

```lua
ManaToolsDB.NoWasteCoin
ManaToolsDB.CinematicSkip
ManaToolsDB.NoInfo
```

Feature modules expose their implementation through the shared namespace:

```lua
ManaTools.NoWasteCoin
ManaTools.CinematicSkip
ManaTools.NoInfo
```

Do not introduce unrelated global state when the shared namespace or feature-local state is sufficient.

### Initialization order

`ManaTools.toc` currently loads:

1. `Bootstrap.lua`
2. `NoWasteCoin/NoWasteCoin.lua`
3. `CinematicSkip/cinematicskip.lua`
4. `NoInfo/NoInfo.lua`
5. `Options.lua`
6. `SlashCmd.lua`

This order matters. `Bootstrap.lua` must remain before feature modules, and settings/slash-command code assumes the feature namespaces already exist.

## Features

### NoWasteCoin

Purpose: prevent accidental Bonus Roll spending outside explicitly allowed content.

Default behavior:

- Mythic raids (`difficultyID == 16`) are allowed.
- Heroic raids (`difficultyID == 15`) are blocked unless `allowHeroicRaid` is enabled.
- Mythic+ is blocked unless `allowMythicPlus` is enabled **and** `C_ChallengeMode.IsChallengeModeActive()` is true.
- Non-instance contexts are blocked.

The implementation wraps the Bonus Roll button's `OnClick` handler and also updates its visual enabled/disabled state. The spending barrier is the `OnClick` wrapper; do not remove or weaken it merely because the button is visually disabled.

Relevant public methods:

```lua
ManaTools.NoWasteCoin.Initialize()
ManaTools.NoWasteCoin.IsAllowedContent()
ManaTools.NoWasteCoin.Update()
ManaTools.NoWasteCoin.EnableCurrentRollOverride()
ManaTools.NoWasteCoin.ClearCurrentRollOverride()
```

The `/mana coin` command enables a **one-roll override** when a Bonus Roll frame is currently active. The override is consumed by the next click and then cleared.

Persistent settings:

```lua
ManaToolsDB.NoWasteCoin.allowHeroicRaid = false
ManaToolsDB.NoWasteCoin.allowMythicPlus = false
```

### CinematicSkip

Purpose: automatically skip several presentation interruptions when enabled.

It listens for:

- `CINEMATIC_START` → calls `CinematicFrame_CancelCinematic()` when available.
- `PLAY_MOVIE` → hides `MovieFrame`.
- `TALKINGHEAD_REQUESTED` → hides `TalkingHeadFrame`.

Event registration is dynamically enabled/disabled by `ManaTools.CinematicSkip:UpdateEvents()`.

Persistent setting:

```lua
ManaToolsDB.CinematicSkip.enabled = true
```

### NoInfo

Purpose: suppress unnecessary game tooltips while preserving item tooltips and selected UI exceptions.

When enabled, the module wraps `GameTooltip`'s `OnShow` script. Non-item tooltips are hidden, except for the tooltip owned by `MainMenuMicroButton`.

It also adds a small minimap button. Clicking it cycles inspect mode:

- `0`: normal tooltip filtering; no Mythic+ rating line.
- `1`: normal tooltip filtering with inspect mode enabled.
- `2`: adds the inspected player's current-season Mythic+ rating when available.

Holding **Shift** while clicking sets mode `2` directly.

Mythic+ rating is read with `C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)` and appended as:

```text
Mythic+ Rating: <score>
```

Persistent settings:

```lua
ManaToolsDB.NoInfo.enabled = true
ManaToolsDB.NoInfo.inspectMode = 0 -- valid values: 0, 1, 2
```

The bootstrap normalizes legacy boolean values: `true → 1`, `false → 0`.

## Settings and commands

The addon registers a settings category named **ManaTools**. `Options.lua` exposes toggles for:

- NoWasteCoin → allow Bonus Roll in Heroic raids.
- NoWasteCoin → allow Bonus Roll in Mythic+.
- CinematicSkip → enabled/disabled.
- NoInfo → enabled/disabled.

Slash command:

```text
/mana
```

opens the ManaTools settings panel.

```text
/mana coin
```
enables the current Bonus Roll override if a Bonus Roll is active.

Any unrecognized `/mana <argument>` currently falls back to opening settings. Preserve this behavior unless there is an explicit reason to change the command interface.

## Compatibility and WoW API assumptions

This is an in-game World of Warcraft addon, not standalone Lua. Code may depend on WoW globals such as:

- `CreateFrame`
- `GameTooltip`
- `BonusRollFrame`
- `C_ChallengeMode`
- `C_PlayerInfo`
- `TooltipDataProcessor`
- `Settings`
- `InterfaceOptions_AddCategory`
- WoW event/script APIs

When writing tests outside WoW, extend `test/mockwow.lua` rather than silently replacing production behavior with test-only branches.

The code already contains compatibility checks/fallbacks for some API differences. Preserve those checks when modifying related code.

## Testing

The repository contains Lua tests plus a WoW API mock. Before changing behavior:

1. Read the relevant production module.
2. Read its corresponding test(s).
3. Update/add tests for behavior changes.
4. Run the complete test suite and the relevant focused test(s).
5. For performance-sensitive changes, run the benchmark under `test/perf/` and inspect the result under `test/results/`.

There is no dependency manifest or build system currently documented in the repository, so do not invent a package-manager workflow. If a test runner is not obvious from the repository, inspect the test files and environment before choosing a command.

## Working conventions for agents

### Before editing

- Treat `ManaTools.toc` as authoritative for addon load order and included files.
- Search the repository for usages before renaming exported tables, SavedVariables keys, slash commands, events, or WoW frame globals.
- Check `docs/debt.md` for known technical debt.
- Keep changes scoped: this is a small addon with intentionally separate feature modules.

### When changing persistent data

Saved data lives in `ManaToolsDB`. If a setting is renamed, removed, or changes type:

- preserve compatibility with existing saved data where practical;
- normalize legacy values during bootstrap/module initialization;
- add tests for migration behavior;
- avoid silently discarding user configuration.

### When changing hooks/events

Be careful with duplicate hooks and wrappers. Existing modules track whether hooks have already been installed and/or which frame/button they belong to. Preserve those guards. Avoid repeatedly wrapping an already wrapped `OnClick`/`OnShow` script.

### When changing secure/UI behavior

NoWasteCoin interacts with the Bonus Roll UI and its click handler. Changes must preserve the actual spending barrier, not only the button's appearance. Avoid insecure operations that could taint protected Blizzard UI code.

### When adding a feature

Prefer:

1. a new feature directory/module;
2. a dedicated `ManaToolsDB.<Feature>` configuration table;
3. initialization from `Bootstrap.lua` if defaults/migrations are needed;
4. explicit inclusion in `ManaTools.toc` in dependency order;
5. settings in `Options.lua` only if user configuration is required;
6. tests using the existing mock infrastructure.

## Important implementation details

- `ManaTools.VERSION` is currently hard-coded to `"1.1.0"` in `Bootstrap.lua` and should stay synchronized with the `.toc` version when releasing.
- `ManaTools.toc` targets Interface `120100`.
- `ManaToolsDB` is the SavedVariables table and must not be replaced wholesale during module initialization.
- NoWasteCoin defaults both optional content flags to `false`.
- CinematicSkip defaults to enabled.
- NoInfo defaults to enabled with inspect mode `0`.
- `NoInfo` attempts to support both `TooltipDataProcessor` and the older `GameTooltip:HookScript("OnTooltipSetUnit", ...)` path.
- The code explicitly checks `issecretvalue` around relevant WoW API values; preserve these checks when touching tooltip/unit/rating logic.

## Scope boundaries

ManaTools is currently a collection of independent quality-of-life modules. Avoid coupling features together unless there is a clear lifecycle/configuration reason. In particular, a change to NoInfo should not require NoWasteCoin changes unless they genuinely share infrastructure.

## License

ManaTools is distributed under the **MIT License**. See [`LICENSE`](LICENSE).

## Contribution guidance

Small, focused pull requests are preferred. Describe behavior changes, compatibility implications, and tests performed. For WoW-specific behavior that cannot be fully tested outside the game client, document the manual verification steps and the client/API assumptions involved.
