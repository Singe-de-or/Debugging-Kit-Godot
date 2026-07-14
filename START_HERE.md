# Debugging Kit — Quick Navigation

Welcome to Debugging Kit — an automated testing and debugging system for any Godot project.

## ⚠️ CRITICAL: You Need the Godot Executable

Before you do *anything* else, understand this: **You need the actual Godot executable in your project folder.** Not the editor. Not the dependencies. Not the assets. The executable. The binary. The thing that runs your game. Yes, the 500MB+ file. Yes, you actually need to have it.

Why? Because the testing system launches Godot headless to run automated tests. It can't do that without the executable. So if you don't have it:
1. Download Godot 4.6 from [godotengine.org](https://godotengine.org)
2. Put the executable somewhere in your project (e.g. `/path/to/project/Godot.exe` or `/path/to/project/godot/Godot.exe`)
3. The installer will find it during setup

If you skip this step, the installer will still run, but Quick/Autoplay modes will fail when they try to launch Godot. Don't say we didn't warn you.

## What are you?

### 👤 I'm a person who wants to use this

**Start here:** Ask an AI to install it into your project.

Copy this and send it to Claude Code:
```
Install the Debugging Kit into my Godot project.
Here's the package: [attach Debugging-Kit folder]
My project is at: /path/to/my/game
```

Then read **`HOW_TO_USER.md`** to learn how to run tests and understand the output.

### 🤖 I'm an AI installing this for someone

Follow **`HOW_TO_CLAUDE.md`** step by step:
1. Run `install.sh`
2. Review and fill the config
3. Test with Quick mode
4. Hand it back to the user

### 📖 I want to understand the whole thing

**`README.md`** has the overview. **`HOW_TO_USER.md`** and **`HOW_TO_CLAUDE.md`** have the detailed workflows.

## Files in this package

| File | Purpose |
|------|---------|
| `README.md` | Overview and quick start |
| `HOW_TO_USER.md` | Instructions for humans using the tool |
| `HOW_TO_CLAUDE.md` | Instructions for AIs installing it |
| `install.sh` | The installer script |
| `skill-template/` | Templates for the slash command (gets copied/renamed during install) |
| `game_files/` | Game-side components (copied into the target project's scripts/ and scenes/) |

## TL;DR

1. **Install:** `bash install.sh /path/to/project [skill-name]`
2. **Configure:** Fill in `debug_config.json` by reading your actual project
3. **Run:** `/slash-command-name` or `bash driver.sh` → choose mode 1/2/3
4. **Read:** Look for "Violations Found: 0" = all good

That's it!

---

Questions? See the appropriate HOW_TO guide above.
