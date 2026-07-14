---
name: PUT_SKILL_NAME_HERE
description: Automated testing and debugging for Godot projects - static checks + configurable autoplay
tags: [testing, godot, debugging]
---

# PUT_SKILL_NAME_HERE

Automated testing and debugging for any Godot project. Verifies code quality with static checks, then runs a configurable autoplay fuzzing test to detect state violations and edge cases.

## Quick Start

**Invoke the interactive menu in Claude Code:**
```
/PUT_SKILL_NAME_HERE
```

I'll show you an interactive menu (arrow-key navigation) to select a mode. Then the test runs automatically.

**Or run a specific mode directly:**

1. **Quick** — Static checks only (~3 seconds)
   - Scans GDScript for common mistakes (@onready patterns, shadowed names, scene references)
   - Validates Godot project configuration (input actions, autoloads, UIDs)

2. **Autoplay** — Gameplay simulation + state validation (~20 seconds)
   - Fuzzes input actions defined in your config
   - Continuously monitors game state invariants (properties you care about)
   - Logs all actions and state changes

3. **Full** — All of the above + deep analysis (~30 seconds)
   - Runs all checks
   - Analyzes test log for patterns, violations, performance metrics

**Direct commands:**
- "Run mode 1" / "Run mode 2" / "Run mode 3" — Ask me to run a specific mode
- `python3 .claude/skills/PUT_SKILL_NAME_HERE/menu.py` — Manual interactive menu
- `bash .claude/skills/PUT_SKILL_NAME_HERE/driver.sh 1` — Run mode 1 directly (mode = 1, 2, or 3)

✅ Works in WSL with automatic Windows interop
✅ Configurable per-project (no hardcoded game logic)
✅ Adapts to new features without test updates

## How It Works

### Configuration

Before running, you configure the testing system for your specific game via `debug_config.json` (created during install):

**Movement-based game (platformer, shooter):**
```json
{
  "player_group": "player",
  "target_node": "",
  "input_actions_to_fuzz": ["ui_left", "ui_right", "ui_accept"],
  "invariants": [
    {"property": "position.x", "min": 0, "max": 1024},
    {"property": "health", "min": 0, "max": 100}
  ],
  "test_duration_seconds": 20
}
```

**Non-movement game (clicker, puzzle, card game):**
```json
{
  "player_group": "",
  "target_node": "GameState",
  "input_actions_to_fuzz": ["ui_accept"],
  "invariants": [
    {"property": "score", "min": 0, "max": 999999},
    {"property": "moves_remaining", "min": 0, "max": 100}
  ],
  "test_duration_seconds": 20
}
```

- **player_group** — (Movement games) Group your player node belongs to
- **target_node** — (Other games) Name of the node that tracks game state
- **input_actions_to_fuzz** — Which input actions to randomly simulate
- **invariants** — Numeric properties to monitor for violations
- **test_duration_seconds** — How long to run autoplay simulation

### Mode Behavior

**Mode 1 (Quick):**
- Scans all `.gd` scripts for patterns:
  - Missing `@onready` on `get_node()` calls
  - Invalid `match true:` constructs
  - Shadowed builtin names (`max`, `min`, `abs`)
  - Scene references that don't exist
- Validates `project.godot`:
  - All UID references have correct format
  - All required input actions are defined
  - All required autoloads are present
- ⏱️ **Duration:** ~3 seconds

**Mode 2 (Autoplay):**
- Launches your game with a test scene that auto-plays
- Randomly fuzzes the configured input actions
- Samples game state at fixed intervals
- Checks each invariant: does the property stay in bounds?
- Logs all actions and violations
- ⏱️ **Duration:** ~20 seconds

**Mode 3 (Full):**
- Runs Quick mode checks
- Runs Autoplay (20 seconds)
- Analyzes the test log with deep validation:
  - Invariant checks (all properties stayed in bounds)
  - Event sequence analysis (did the right actions happen)
  - Performance metrics (average values, min/max observed)
- ⏱️ **Duration:** ~30 seconds

### Expected Output

**Mode 1 (Quick):**
```
=== Running Static Checks ===

✓ @onready caching OK
✓ Scene references OK
✓ Input actions OK
✓ Autoloads OK
✓ GDScript syntax OK

All checks passed!
```

**Mode 2 (Autoplay):**
```
🧪 TEST AUTOPLAY STARTED - Duration: 20s

==================================================
🧪 TEST RESULTS
==================================================
Duration: 20.05s

Actions Performed:
  ui_left: 5
  ui_right: 6
  ui_accept: 4
  Total Actions: 15

Invariants Checked:
  position.x: OK (range 45-1000, bounds [0, 1024])
  health: OK (range 25-100, bounds [0, 100])

Violations Found: 0
Events Logged: 127
==================================================
✅ No bugs detected!
```

**Mode 3 (Full):**
```
[Quick checks output...]
[Autoplay output...]

============================================================
🔬 DEEP TEST ANALYSIS
============================================================

✅ No state violations detected

📋 Invariant Checks:
  ✅ position.x always in bounds [0, 1024]
  ✅ health always in bounds [0, 100]

🎮 Action Sequences:
  ✅ 15 actions performed (expected range)
     - ui_left: 5
     - ui_right: 6
     - ui_accept: 4

⚙️  Performance Metrics:
  ✅ Ran for 20.05s
  ✅ Sampled 200 times (10.0 Hz)
  ✅ Average health: 67.3/100

============================================================
📊 SUMMARY
============================================================
✅ All tests passed! Game is stable.
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Godot executable not found` | Update `godot_executable` in `debug_config.json` or ensure `godot` is in your PATH |
| `Player not found in group` | You're using `player_group`; verify the player node is in that group in your scene |
| `Target node not found` | You're using `target_node`; verify the node name matches exactly (case-sensitive) |
| `Neither player_group nor target_node configured` | Fill in at least one: `player_group` (movement games) or `target_node` (other games) |
| Input actions don't run | Check `input_actions_to_fuzz` matches actions defined in `project.godot` |
| Invariants not logged | Ensure property paths (e.g. `position.x`, `score`) exist and are accessible on your node |
| Test log not found | Autoplay didn't complete; check for errors in Godot output or invariant violations |
| Analysis fails | Run `python3 test_analyzer.py <log_file>` directly to see detailed errors |

## How This Adapts to New Features

The system works with any new features because it validates **invariants** (numeric bounds) instead of mechanics:

**Movement games:**
- **New weapon?** — Invariants check properties stay in bounds
- **New animation?** — Doesn't matter; we monitor state, not visuals
- **Camera changes?** — Adjust position bounds if needed
- **New level?** — Position bounds may change; update if needed

**Clicker/Puzzle games:**
- **New upgrade?** — Autoplay keeps fuzzing; state properties stay monitored
- **New level type?** — Invariants still apply (moves, score, pieces)
- **UI changes?** — Only affects input actions; invariants unchanged

You rarely need to update tests when adding features. Occasionally adjust invariant bounds in `debug_config.json` if new max values change, then autoplay keeps working.

## Files

- `.claude/skills/PUT_SKILL_NAME_HERE/driver.sh` — Main automation script
- `.claude/skills/PUT_SKILL_NAME_HERE/menu.py` — Interactive mode picker
- `.claude/skills/PUT_SKILL_NAME_HERE/static_checks.sh` — Static analysis script
- `.claude/skills/PUT_SKILL_NAME_HERE/test_analyzer.py` — Log analyzer for Full mode
- `debug_config.json` — Project-specific configuration (created during install)
- `scripts/debug_autoplay.gd` — Autoplay fuzz engine (copied into your scripts dir)
- `scenes/debug_test_runner.tscn` — Test scene (copied into your scenes dir)
