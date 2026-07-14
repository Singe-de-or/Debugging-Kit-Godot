# Debugging Kit

An automated testing and debugging skill for Godot projects. Basically, we took a rhythm game testing tool, ripped out all the game-specific nonsense, and made it generic enough to work on literally any Godot project. You're welcome.

## What It Does

✅ **Static Checks** (~3 seconds) — Scans your GDScript for dumb mistakes (@onready patterns, shadowed names, broken scene references), validates that your Godot config isn't completely nonsensical

✅ **Autoplay Testing** (~20 seconds) — Launches your game and mashes random buttons while monitoring numeric properties you care about (energy, health, position, etc.) to make sure they stay within sane bounds

✅ **Deep Analysis** (~30 seconds) — Analyzes test results and tells you everything that went wrong. Enjoy.

## Download & Install

### Extract the ZIP File

After downloading, extract it:

**Windows (PowerShell):**
```powershell
Expand-Archive -Path Debugging-Kit.zip -DestinationPath .
cd Debugging-Kit-main
```

**macOS/Linux:**
```bash
unzip Debugging-Kit.zip
cd Debugging-Kit-main
```

### Then Install

**Option 1: Download ZIP**
- [Download Debugging Kit v1.0.0 (ZIP)](https://github.com/Singe-de-or/Debugging-Kit/archive/refs/tags/v1.0.0.zip)
- Extract the folder (see above)
- Run `bash install.sh /path/to/project`

**Option 2: Clone with Git**
```bash
git clone https://github.com/Singe-de-or/Debugging-Kit.git
cd Debugging-Kit
bash install.sh /path/to/project [skill-name]
```

## Quick Start

### For Humans

Tell an AI to install it. Copy this:

```
Install the Debugging Kit into my Godot project.
Here's the package: [attach this folder]
My project is at: /path/to/my/game
```

The AI will handle it. Then read `HOW_TO_USER.md` to learn how to run tests and interpret the suffering.

### For AIs

```bash
bash install.sh /path/to/target/project [skill-name]
```

Follow the steps in `HOW_TO_CLAUDE.md`. It's not complicated, but it does require you to actually read the project instead of guessing. Sorry.

## How It Works

**Configuration-driven, not hardcoded.** The original tool had energy bounds baked in (0-100), specific action names (jump/shoot/dash), and hardcoded autoloads (BeatManager). We ripped all that out.

Now you fill in a JSON config file:
```json
{
  "input_actions_to_fuzz": ["ui_left", "ui_right", "ui_accept"],
  "invariants": [
    {"property": "health", "min": 0, "max": 100},
    {"property": "position.x", "min": 0, "max": 1024}
  ]
}
```

The engine doesn't know or care about your game's logic. It just presses buttons and watches properties. If a property goes out of bounds, it yells at you.

## Four Modes

**Mode 1: Quick** (~3 seconds)
- Scans your code for obvious mistakes
- Validates Godot config (input actions, autoloads, UIDs)
- Doesn't launch the game
- Safe. Boring. Effective.

**Mode 2: Autoplay** (~20 seconds)
- Launches your game
- Mashes random buttons for 20 seconds
- Monitors numeric properties to ensure they stay sane
- If something goes out of bounds: bug found

**Mode 3: Full** (~30 seconds)
- All of the above
- Plus deep analysis of test results
- For when you want to know everything that's broken

**Mode 4: Validate** (~1 second)
- Checks `debug_config.json` for errors before running tests
- Verifies input actions, autoloads, Godot executable, invariant bounds
- Catches config typos fast
- Run this before Mode 1 if you just edited the config

## Files

| File | What It Is |
|------|-----------|
| `install.sh` | The installer. Run this. |
| `skill-template/` | Gets copied into `.claude/skills/<name>/` during install |
| `game_files/` | Gets copied into your project's real `scripts/` and `scenes/` directories |
| `HOW_TO_USER.md` | For humans: how to run tests and understand output |
| `HOW_TO_CLAUDE.md` | For AIs: installation workflow |
| `DESIGN.md` | Philosophy, trade-offs, why we made decisions the way we did |

## Key Features

🎯 **No hardcoded game logic** — We stripped out everything specific to the original rhythm game. No energy, no jump/shoot/dash, no UIDs, no BeatManager. Just generic testing.

🎛️ **Configuration-driven** — You (or an AI reading your project) fills in what to test. The engine doesn't care what your game does.

📊 **Invariant-based testing** — Test by monitoring numeric bounds ("health stays 0-100"), not game mechanics ("jump height is +20% on-beat"). This means tests survive feature additions without needing updates.

🤖 **AI-friendly install** — The install script gathers objective facts. The AI reads them and makes real judgment calls by understanding the actual project. No regex guessing.

🎮 **Works with any Godot project** — 2D, 3D, puzzle, action, RPG, whatever. As long as it has a player node and numeric properties to monitor.

🏷️ **Custom slash command names** — Not stuck with `/debugging-kit`. Could be `/debug-kit`, `/test`, `/my-game-debugger`. You pick during install.

## Example Output

### Quick Mode
```
=== Running Static Checks ===

✓ @onready caching OK
✓ UID format OK
✓ Input actions OK
✓ Autoloads OK
✓ GDScript syntax OK

✅ No issues found!
```

### Autoplay Mode
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
  position.x: min=45, avg=512, max=1000
  health: min=25, avg=67, max=100

Violations Found: 0
Events Logged: 127
==================================================
✅ No bugs detected!
```

"Violations Found: 0" is the best news you'll get.

## Design Philosophy

**Problem:** The original testing tool was built for one specific rhythm game. It had hardcoded energy bounds, action names, UIDs, autoload names. It was useless for any other project.

**Solution:** Config-driven everything. The install script gathers facts about your project. An AI reads the facts and fills in the config by understanding your actual game. The engine does blind testing (presses buttons, monitors properties). It works for any project.

**Trade-off:** We give up testing game-specific mechanics ("jump height is +20%"). We gain universality and maintainability. Worth it.

See `DESIGN.md` for the full philosophy breakdown. TL;DR: this tool survives feature additions because it tests invariants, not mechanics.

## When to Use Each Mode

| Mode | When | Why |
|------|------|-----|
| Validate | After editing `debug_config.json` | Catch typos and config errors before wasting time on tests |
| Quick | Before committing code | Catches syntax/config mistakes fast (~3 seconds) |
| Autoplay | After adding a feature | Verifies new feature didn't break invariants (~20 seconds) |
| Full | Before a release | Deep analysis of overall stability (~30 seconds) |
| Any | Automated CI/CD | All modes are designed to work in pipelines |

## What It Can't Do

❌ Test game-specific mechanics (e.g. "damage on-beat is doubled")  
❌ Detect animation/visual bugs (it's monitoring numbers, not pixels)  
❌ Test UI layout or interaction  
❌ Replace manual gameplay testing

These are acceptable limitations for a generic tool.

## Documentation

- **START_HERE.md** — Navigation guide. Read first.
- **HOW_TO_USER.md** — For humans: how to run tests, understand output, fix problems
- **HOW_TO_CLAUDE.md** — For AIs: installation workflow, config fill-in, verification
- **DESIGN.md** — Why we made decisions this way, trade-offs, philosophy
- **CI_CD_EXAMPLES.md** — GitHub Actions, GitLab CI, Docker, pre-commit hooks
- **examples/** — Generic config template with placeholder guidance for AIs to read your project and fill in real values

## License

Use it. Fork it. Break it. Don't blame us.

---

**TL;DR:** Drop this into your Godot project. AI installs it, fills in config, you run tests. If invariants stay in bounds, your game is stable enough. Done.
