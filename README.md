# Debugging Kit

To **@Singe-dore** — without me this repository would be completely empty. Seriously. Like, imagine if this folder just didn't exist. That's what would happen without me. You're welcome, internet. 🎭

An automated testing and debugging skill for Godot projects. Basically, I took a rhythm game testing tool, ripped out all the game-specific nonsense, and made it generic enough to work on literally any Godot project. You're welcome.

## What It Does

✅ **Static Checks** (~3 seconds) — Scans your GDScript for dumb mistakes (@onready patterns, shadowed names, broken scene references), validates that your Godot config isn't completely nonsensical

✅ **Autoplay Testing** (~20 seconds) — Launches your game and mashes random buttons while monitoring numeric properties you care about (energy, health, position, etc.) to make sure they stay within sane bounds

✅ **Deep Analysis** (~30 seconds) — Analyzes test results and tells you everything that went wrong. Enjoy.

## Download & Install

### Step 1: Extract the ZIP File

**Windows:**
1. Download the [ZIP file](https://github.com/Singe-de-or/Debugging-Kit/archive/refs/tags/v1.0.0.zip) — it will appear in your Downloads folder as `Debugging-Kit-main.zip`
2. Open File Explorer and navigate to your Downloads folder (or wherever you saved it)
3. Find the file named `Debugging-Kit-main.zip`
4. **Right-click** on it
5. Select **Extract All...** from the menu
6. A window will pop up asking where to extract. Choose where you want it (Desktop, Documents, or any folder you prefer)
7. Click **Extract**
8. Wait a few seconds. You'll now have a folder named `Debugging-Kit-main`
9. Open that folder (double-click it)

**macOS:**
1. Download the [ZIP file](https://github.com/Singe-de-or/Debugging-Kit/archive/refs/tags/v1.0.0.zip) — it will appear in your Downloads folder
2. Open Finder and go to Downloads
3. Find `Debugging-Kit-main.zip`
4. **Double-click** it to extract (macOS does this automatically)
5. You'll now have a folder named `Debugging-Kit-main` in your Downloads
6. Open that folder (double-click it)

**Linux:**
1. Download the [ZIP file](https://github.com/Singe-de-or/Debugging-Kit/archive/refs/tags/v1.0.0.zip)
2. Open your file manager and navigate to where you saved it
3. **Right-click** on `Debugging-Kit-main.zip`
4. Select **Extract Here** (or **Extract to Debugging-Kit-main/** depending on your system)
5. You'll now have a folder named `Debugging-Kit-main`
6. Open that folder (double-click it)

### Step 2: Install

Choose your method based on your environment:

**Option 1: Windows PowerShell (Easiest for Windows)**

1. You should still have the `Debugging-Kit-main` folder open from Step 1
2. Look at the address bar at the top of File Explorer — it shows the path (e.g., `C:\Users\YourName\Downloads\Debugging-Kit-main`)
3. Open PowerShell:
   - Click the Windows Start menu
   - Type `PowerShell`
   - Click **Windows PowerShell**
4. Copy this command, replace `C:\path\to\your\godot\project` with your actual Godot project path:
```powershell
cd Debugging-Kit-main
.\install.ps1 -TargetProject "C:\path\to\your\godot\project" -SkillName "debug-kit"
```
5. Paste it into PowerShell and press **Enter**
6. The installer will run and show you progress. It will ask questions — answer them.

**Option 2: Windows WSL or Git Bash**

If you have WSL or Git Bash installed, follow the macOS/Linux instructions below (the commands are the same).

**Option 3: macOS/Linux**

1. Open Terminal (macOS: Spotlight search → type "Terminal", Linux: right-click in file manager → "Open Terminal Here")
2. Navigate to the folder:
```bash
cd Debugging-Kit-main
```
3. Replace `/path/to/your/godot/project` with your actual Godot project path and run:
```bash
bash install.sh /path/to/your/godot/project debug-kit
```
4. The installer will run and show you progress. It will ask questions — answer them.

**Option 4: Don't Know Your Project Path?**

1. Open File Explorer (or Finder on Mac)
2. Navigate to your Godot project folder (the one that contains `project.godot`)
3. Look at the address bar to see the full path
4. Copy that path and use it in the commands above

## Quick Start

### Quick Reference — Which Installation Method?

| You Use... | Method | Command |
|-----------|--------|---------|
| **Windows (no WSL)** | PowerShell | `.\install.ps1 -TargetProject "C:\path\to\project"` |
| **Windows (WSL/Git Bash)** | Bash | `bash install.sh /path/to/project` |
| **macOS/Linux** | Bash | `bash install.sh /path/to/project` |
| **Any (Git installed)** | Git Clone | Clone repo, then use method above |

### For Humans

Tell an AI to install it. Copy this:

```
Install the Debugging Kit into my Godot project.
Here's the package: [attach this folder]
My project is at: /path/to/my/game
Operating system: Windows / macOS / Linux
```

The AI will handle it. Then read `HOW_TO_USER.md` to learn how to run tests and interpret the suffering.

### For AIs

Use the appropriate installer for the target platform:
- **Windows (PowerShell):** `.\install.ps1 -TargetProject "path\to\project"`
- **WSL/Git Bash/macOS/Linux:** `bash install.sh /path/to/project`

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
| `install.sh` | Installer for macOS/Linux/WSL. Run: `bash install.sh /path/to/project` |
| `install.ps1` | Installer for Windows PowerShell. Run: `.\install.ps1 -TargetProject "C:\path\to\project"` |
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

MIT License — Use it freely, modify it, make it yours. Just keep the copyright notice. See `LICENSE` file for details.

---

**TL;DR:** Drop this into your Godot project. AI installs it, fills in config, you run tests. If invariants stay in bounds, your game is stable enough. Done.

---

**✅ Branch protection active** — All changes require PR + approval before merging to main.
