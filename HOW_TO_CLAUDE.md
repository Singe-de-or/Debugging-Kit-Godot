# Installation Guide for Claude and Other AIs

This guide is for you if you're installing Debugging Kit into someone's Godot project.

## Overview

Your job has three phases:

1. **Run `install.sh`** — It does the mechanical work (copy, name substitution, project scanning)
2. **Review and fill `debug_config.json`** — It gathered facts; you make the judgment calls
3. **Verify with Quick mode** — Confirm it works before handing it back

You are **not** guessing or trying to infer. You are reading the project, understanding its logic, and filling in real answers.

## Phase 1: Run the Installer

### Ask the user (if needed)

If the user hasn't told you, ask:
- "What is the full path to your Godot project?" (where `project.godot` lives)
- "What would you like to call this slash command?" (e.g. `debug-kit`, `godot-test`, `analyzer`)

### Run install.sh

```bash
bash /path/to/Debugging-Kit/install.sh /path/to/target/project [skill-name]
```

Example:
```bash
bash ~/Debugging-Kit/install.sh ~/my-game debug-kit
```

The script will:
1. Create `.claude/skills/<skill-name>/` with all skill files (name substituted everywhere)
2. Copy `debug_autoplay.gd` → `target/scripts/`
3. Copy `debug_test_runner.tscn` → `target/scenes/`
4. Scan the project for input actions, autoloads, viewport size, possible player scripts
5. Generate `target/debug_config.json` with `_detected_candidates` + placeholders

Expected output ends with:
```
✅ Installation Complete!
Next steps:
1. Open /path/to/target/debug_config.json
2. Review the _detected_candidates section
3. Fill in the remaining placeholder fields...
```

## Phase 2: Interview the User (if needed)

Before filling the config, understand the game type. Ask:

**If the game looks unfamiliar:**

1. "Describe your game in one sentence" — Is it movement-based (platformer, top-down shooter), turn-based (puzzle, clicker), UI-driven (visual novel, deck builder)?
2. "What's the main thing that changes during gameplay?" — Is it the player's position, a resource counter (gold, health, score), remaining turns, inventory size?
3. "What should stay in valid bounds?" — What numeric properties matter for correctness?

**Why ask?** The config depends on game type:
- **Movement game:** Monitor `position.x`, `position.y`, `velocity`
- **Click/Clicker:** Monitor `score`, `clicks`, `resources`, `level`
- **Turn-based:** Monitor `turns_remaining`, `moves`, `board_state` (via piece positions)
- **UI/Menu:** Monitor `selected_index`, `menu_state`, `gold`, `inventory_count`

**Example responses to expect:**
- "It's a tower defense game" → Monitor tower positions, health, gold
- "It's a clicker" → Monitor score, clicks per second, upgrades unlocked
- "It's a card game" → Monitor hand size, deck size, mana available
- "It's a 2D platformer" → Monitor position, velocity, health

## Phase 2.5: Review and Fill the Config

### Open debug_config.json

The generated file looks like:
```json
{
  "_detected_candidates": {
    "possible_player_scripts": ["res://scripts/player.gd"],
    "groups_found_in_scenes": ["player"],
    "input_actions_defined": ["ui_left", "ui_right", "ui_up", "ui_accept"],
    "autoloads_defined": ["BeatManager"],
    "viewport_size": {"width": 1024, "height": 600}
  },
  "_instructions": "Review the _detected_candidates above...",
  "godot_executable": "PUT_PATH_TO_GODOT_EXECUTABLE_HERE",
  "player_group": "PUT_GROUP_NAME_HERE",
  "input_actions_to_fuzz": [],
  "invariants": [],
  "required_autoloads": [],
  "test_duration_seconds": 20
}
```

The `_detected_candidates` is the installer's best guess. Your job is to **review and fill in the actual fields** by reading the project.

### Step 1: Identify the Node to Monitor

This is the key decision. The "player" could mean different things:
- **Movement game:** An actual player character (CharacterBody2D in a scene)
- **Clicker:** A GameManager or MainLoop singleton
- **Puzzle:** A Board manager or GameState node
- **Card game:** A CardGame or HandManager node

**For movement games:**
- Look at `_detected_candidates.possible_player_scripts` (scripts extending CharacterBody2D/3D)
- **Read the first one** and ask: Is this the player? If unsure, ask the user.
- Verify the player node is in a group (check `scenes/main.tscn`, select Player node, check Groups panel)
- **Fill in:** `"player_group": "player"` (or whatever group it's in)

**For non-movement games (clicker, puzzle, turn-based):**
- Look at `_detected_candidates.possible_target_scripts` (all scripts with numeric properties)
- Ask the user: *"Which script tracks game state? Is it a GameManager, MainLoop, or something else?"*
- You can use `target_node` instead: `"target_node": "GameManager"` (looks for any node by name, not by group)
- **Fill in:** `"target_node": "GameManager"` and leave `player_group` empty or use whichever applies

### Step 3: Choose Input Actions to Fuzz

Look at `_detected_candidates.input_actions_defined`. These are all actions in `project.godot`.

**Read the player script.** Which actions does the game respond to? Typically movement (left/right/up), jump, shoot, dash, etc.

**Fill in:** Choose the actions that make gameplay sense. Examples:
```json
{
  "input_actions_to_fuzz": ["ui_left", "ui_right", "ui_up", "ui_accept"],
}
```

**Do not include:** Actions that never get pressed in gameplay (menu navigation, pause, etc.) — they won't meaningfully test the game.

### Step 4: Define Invariants

**This is the core of the testing system.** Invariants are numeric properties that should stay in specific bounds.

**⚠️ DO NOT copy-paste from examples.** Read the actual project code first. The `examples/config_generic_template.json` is a structure template, not a blueprint for your specific game.

**Read the player script carefully.** Look for:
- Numeric variables with `clamp()` calls → suggests bounds
- Exported `float` or `int` fields with `min_value`/`max_value` annotations → real bounds
- Position-related fields → often bounded to viewport or level size

**Examples:**

For a game with energy/health:
```gdscript
var energy: float = 100.0

func _ready():
    energy = clamp(energy, 0.0, 100.0)
```

→ Fill in:
```json
{
  "invariants": [
    {"property": "energy", "min": 0, "max": 100}
  ]
}
```

For a platformer with position bounds:
```gdscript
var viewport_width = 1024  # from project.godot
```

→ Add:
```json
{
  "invariants": [
    {"property": "position.x", "min": 0, "max": 1024},
    {"property": "position.y", "min": -100, "max": 1200}
  ]
}
```

**Rules for invariants:**
- Pick properties that matter to correctness (position, velocity, health, resources — whatever your game actually has)
- Not UI-only (HUD color, animation state)
- Should have numeric bounds (not boolean, string, enum)
- Dotted paths work: `position.x`, `velocity.y` (as long as they're navigable)

### Step 5: Verify Required Autoloads

Look at `_detected_candidates.autoloads_defined`. Are any of these critical to the game?

**Example:** If `BeatManager` is listed and the game can't run without it, add it:
```json
{
  "required_autoloads": ["BeatManager"]
}
```

Usually this is empty (the game can run even if an autoload is missing, it just won't work right). Only add if the game will crash without it.

### Step 6: Update Godot Executable Path (if needed)

If `godot_executable` is still a `PUT_PATH_...` placeholder, the installer couldn't find Godot.

Ask the user: *"Where is your Godot executable?"* or suggest:
- System PATH: `godot` (already filled if `which godot` worked)
- Inside project: `/path/to/project/Godot.exe`
- Installed system-wide: `/usr/bin/godot` (Linux) or `/Applications/Godot.app/Contents/MacOS/Godot` (macOS)

**Fill in the full path.**

### Step 7: Adjust Test Duration (Optional)

The default is 20 seconds. If you want shorter/longer tests:
```json
{
  "test_duration_seconds": 30
}
```

20 seconds is usually enough. Don't go under 10 (too little data) or over 60 (too long for CI).

## Phase 3: Validate the Config

Before running the actual tests, validate the config for errors:

```bash
bash /path/to/target/.claude/skills/debug-kit/driver.sh 4
```

or use the shorthand:

```bash
bash /path/to/target/.claude/skills/debug-kit/driver.sh --validate
```

**Expected output:**

```
=== Validating Configuration ===

✅ Config is valid!
```

If validation fails, you'll see errors like:
- `Input action not defined in project.godot: ui_foo` — Remove or fix the action
- `Godot executable not found at: /path/to/Godot` — Update the path
- `Invariant 'health': invalid bounds (min=100 > max=50)` — Swap min/max

**Fix any errors before proceeding to Quick mode.**

## Phase 4: Verify with Quick Mode

Now test it:

```bash
bash /path/to/target/.claude/skills/debug-kit/driver.sh 1
```

(Replace `debug-kit` with whatever name was chosen.)

**Expected output:**

Quick mode does NOT launch the game. It just scans:
```
=== Running Static Checks ===

✓ @onready caching OK
✓ UID format OK
✓ Input actions OK
✓ Autoloads OK
✓ GDScript syntax OK

✅ No issues found!
```

If any check fails, the error message tells you what to fix:

| Error | Fix |
|-------|-----|
| `Input action not defined: ui_foo` | `ui_foo` isn't in `project.godot`; remove it from config |
| `Required autoload not found: Bar` | `Bar` isn't an autoload; remove it from config or ask user to add it |
| `Missing @onready for get_node()` | Project has a code quality issue unrelated to your config (user can fix or ignore) |

## Phase 5: Hand It Back

Tell the user:

```
✅ Debugging Kit installed as /debug-kit

Next steps:
1. Run /debug-kit and choose a mode:
   - Quick (3s): Static checks, no game launch
   - Autoplay (20s): Game fuzzing + state validation
   - Full (30s): All checks + deep analysis

2. On your first run:
   - Quick mode should find no issues (or report code-quality stuff)
   - Autoplay should launch your game, run random inputs for 20s, then close
   - Check the output for "Violations Found: 0" = all good

3. If something fails:
   - Re-run with /debug-kit and choose the same mode to see details
   - Or send me the error and I can help diagnose
```

## Troubleshooting Your Install

| Issue | Solution |
|-------|----------|
| `install.sh: command not found` | Ensure it's executable: `chmod +x install.sh` |
| `debug_config.json` is blank or malformed | Re-run install.sh; if that fails, tell the user to check the target path |
| Quick mode says input action not defined | The action in config doesn't match `project.godot`; fix the config |
| Autoplay doesn't launch | `godot_executable` path is wrong; ask the user where Godot actually is |
| Player script not found during Autoplay | `player_group` is wrong; verify the player node is in that group |

## Key Rules

✅ **DO:**
- Read the actual project files (scripts, scenes, project.godot)
- Ask the user if you're unsure
- Fill in real answers based on understanding
- Test Quick mode before handing back

❌ **DON'T:**
- Guess which script is the player (ask or read the scene)
- Assume bounds from regex-matching `clamp()` (read the actual logic)
- Leave placeholders in the config (fill them all in or ask the user)
- Nest game_files/ under .claude/ (Godot can't import from dot-folders)

## One More Thing: Game Files Location

During install, two files are copied to the **target's real directories**, not under `.claude/`:

- `scripts/debug_autoplay.gd` — The fuzz engine (must be in real `scripts/` so Godot can load it)
- `scenes/debug_test_runner.tscn` — The test scene (must be in real `scenes/` for `res://` paths to work)

Godot's editor and import system ignore directories starting with a dot (`.`), so putting these under `.claude/skills/...` would break them. This is by design.

If the user asks "Why isn't it in .claude/?" explain: *Godot ignores dot-prefixed directories for imports. The `.tscn` file needs to resolve `res://scripts/debug_autoplay.gd` at runtime, which only works if both are in the real project hierarchy.*

---

You're done! The user now has a working testing skill.
