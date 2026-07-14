---
name: PUT_SKILL_NAME_HERE
description: Automated testing and debugging for Godot projects - static checks + configurable autoplay
tags: [testing, godot, debugging]
---

# PUT_SKILL_NAME_HERE

Automated testing and debugging for any Godot project. Verifies code quality with static checks, then runs a configurable autoplay fuzzing test to detect state violations and edge cases.

## Quick Start

**To start testing, run one of three modes:**

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

Ask me to run a specific mode with: "Run mode 1", "Run mode 2", or "Run mode 3".

Or run the interactive menu yourself:
```bash
python3 .claude/skills/PUT_SKILL_NAME_HERE/menu.py
```

Or run specific mode directly:
```bash
bash .claude/skills/PUT_SKILL_NAME_HERE/driver.sh
```

✅ Works in WSL with automatic Windows interop
✅ Configurable per-project (no hardcoded game logic)
✅ Adapts to new features without test updates

## How It Works

### Configuration

Before running, you configure the testing system for your specific game via `debug_config.json` (created during install):

```json
{
  "player_group": "player",
  "input_actions_to_fuzz": ["ui_left", "ui_right", "ui_accept"],
  "invariants": [
    {"property": "position.x", "min": 0, "max": 1024},
    {"property": "health", "min": 0, "max": 100}
  ],
  "required_autoloads": ["EventBus"],
  "test_duration_seconds": 20
}
```

- **player_group** — Group your player node belongs to (for finding it during testing)
- **input_actions_to_fuzz** — Which input actions to randomly simulate
- **invariants** — Numeric properties to monitor for violations (e.g. health should stay in bounds)
- **required_autoloads** — Any critical autoloads that must exist
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
| `Player not found` | Verify your player node is in the group specified in `debug_config.json` |
| Input actions don't run | Check `input_actions_to_fuzz` in config matches actions defined in `project.godot` |
| Invariants not logged | Ensure the property path (e.g. `position.x`, `health`) is correct and accessible on the player node |
| Test log not found | Check that autoplay ran to completion (watch for "✅ Test complete!" message) |
| Analysis fails | Run `python3 test_analyzer.py <log_file>` directly to see detailed parsing errors |

## How This Adapts to New Features

The system works with any new features because it validates **invariants** instead of hardcoded mechanics:

- **New weapon type?** — Autoplay fuzzes input actions blindly, invariants validate numeric properties stay in bounds
- **New movement?** — Position tracking validates player stays in world
- **New UI?** — Invariants can monitor any numeric field
- **New game mode?** — As long as player node exists, autoplay keeps fuzzing

You never need to update tests when adding features — just adjust `debug_config.json` if new invariants matter, and autoplay keeps working with the same engine.

## Files

- `.claude/skills/PUT_SKILL_NAME_HERE/driver.sh` — Main automation script
- `.claude/skills/PUT_SKILL_NAME_HERE/menu.py` — Interactive mode picker
- `.claude/skills/PUT_SKILL_NAME_HERE/static_checks.sh` — Static analysis script
- `.claude/skills/PUT_SKILL_NAME_HERE/test_analyzer.py` — Log analyzer for Full mode
- `debug_config.json` — Project-specific configuration (created during install)
- `scripts/debug_autoplay.gd` — Autoplay fuzz engine (copied into your scripts dir)
- `scenes/debug_test_runner.tscn` — Test scene (copied into your scenes dir)
