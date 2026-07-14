# How to Use Debugging Kit — User Guide

So you have the Debugging Kit. Congratulations. Here's how to not mess it up.

## How to Ask an AI to Install It

If you haven't installed it yet, here's what you tell Claude Code. Copy-paste. Don't improvise. AIs are literal creatures; they will do exactly what you ask and nothing else.

### The Bare Minimum

```
Install the Debugging Kit into my Godot project.
Here's the package: [attach or point to the Debugging-Kit folder]
My project folder is: /path/to/my/game
```

That's it. The AI will handle the rest. Or ask you clarifying questions. Lots of them. But it will eventually install it.

### If You Want to Be Specific (And Sound Smart)

```
Set up Debugging Kit for my Godot project.
Project location: /path/to/my/game
Skill command name: debug-kit (becomes /debug-kit)

Please:
1. Run install.sh
2. Review the generated debug_config.json and its detected_candidates
3. Fill in the config based on my actual game logic (ask me if unsure)
4. Run Quick mode to verify
```

The AI will appreciate the clarity. It might even respect you a little bit. Don't count on it.

## How to Run Tests

Once installed, you have a slash command. Whatever you named it during install (e.g. `/debug-kit`, `/test`, `/my-favorite-automated-demon`).

In Claude Code:
```
/debug-kit
```

Claude will ask you which mode you want. Think carefully. Or don't. It doesn't matter; you can run it again if you pick wrong.

Or if you're a terminal person who doesn't trust slash commands:
```bash
bash .claude/skills/debug-kit/driver.sh
```

Or get fancy and specify the mode directly (hardcore mode):
```bash
bash .claude/skills/debug-kit/driver.sh 1    # Quick
bash .claude/skills/debug-kit/driver.sh 2    # Autoplay
bash .claude/skills/debug-kit/driver.sh 3    # Full
```

## Understanding Test Output

### Mode 1 (Quick) — Static Checks

The TL;DR mode. Doesn't launch your game. Just reads your code and yells at you if something's obviously broken. Like a code review from someone who's had 6 cups of coffee and no patience.

Output:
```
=== Running Static Checks ===

✓ @onready caching OK
✓ UID format OK
✓ Input actions OK
✓ Autoloads OK
✓ GDScript syntax OK

✅ No issues found!
```

**Translation:**
- ✓ = Your code follows basic patterns. Gold star. 🌟
- ❌ = Something's wrong. Read the error message. It's not that hard.

Duration: ~3 seconds. No game launch. No risk. Very safe. Boring, even.

### Mode 2 (Autoplay) — Gameplay Simulation

This is the one that actually respects your game enough to try to break it. Launches your game and mashes random buttons for 20 seconds like a toddler, while monitoring whether things stay reasonable.

Output:
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

**Translation:**
- The game survived 20 seconds of random button mashing. That's... actually pretty good.
- It performed 15 chaotic actions (left, right, accept, repeat)
- Monitored numeric properties (position, health, etc.) to make sure they stayed sane
- **Violations Found: 0** = All your invariants held up. Congratulations, your game has basic stability.
- **Violations Found: N** = Something broke its bounds. That's a bug. Go fix it.

Duration: ~20 seconds. Your game launches in a window. It might actually work. Fingers crossed.

### Mode 3 (Full) — Deep Analysis

Runs Quick + Autoplay, then analyzes the results with the forensic detail of a crime scene investigator. For when you want to know *everything* that went wrong (or right, but that's less common).

```
[Quick output...]
[Autoplay output...]

============================================================
🔬 DEEP TEST ANALYSIS
============================================================

📋 Invariant Checks:
  ✅ position.x: min=45, avg=512, max=1000
  ✅ health: min=25, avg=67, max=100

🎮 Action Sequences:
  ✅ 15 actions performed
     - ui_left: 5
     - ui_right: 6
     - ui_accept: 4

⚙️  Performance Metrics:
  ✅ Ran for 20.05s
  ✅ Sampled 200 times (10.0 Hz)

============================================================
📊 SUMMARY
============================================================
✅ All checks passed! Game is stable.
```

Duration: ~30 seconds. Enough time to grab a coffee and convince yourself your code is fine.

## Troubleshooting

### "Godot executable not found"

The kit can't find Godot. This is actually impressive; it's like losing a 4GB application.

**Fix:** Open `debug_config.json` and update `"godot_executable"` to point to the thing that's definitely sitting on your hard drive somewhere:
```json
{
  "godot_executable": "/path/to/Godot.exe",
  ...
}
```

Try again. It'll probably work this time.

### "Player not found in group: X"

Your player isn't in the group you said it was. Either you lied, or your project is weirder than we thought.

**Fix:** Make sure your player node is actually in the group:
```json
{
  "player_group": "player",
  ...
}
```

In Godot editor: select your player node, find the Node panel on the right, add it to a group. Yes, this is a thing you have to do. Yes, it's annoying.

### "Input action not defined: ui_left"

An action in `input_actions_to_fuzz` doesn't exist in your project. Did you make this up? No judgment, but...

**Fix:** Open `debug_config.json` and verify against what's actually in `project.godot`:
```json
{
  "input_actions_to_fuzz": ["ui_left", "ui_right", "ui_accept"],
  ...
}
```

Go to Project → Project Settings → Input Map. Are those actions there? If not, remove them from the config. Simple as that.

### "Invariant violated: health out of bounds [0, 100]: value was 125"

During autoplay, something had the audacity to go outside its configured bounds. How rude.

**Example:**
```
health out of bounds [0, 100]: value was 125
```

**Fix:** Two options:
1. Your game has a bug (health shouldn't teleport to 125) — go fix it
2. You configured the bound wrong — update `debug_config.json`:
   ```json
   {
     "invariants": [
       {"property": "health", "min": 0, "max": 150}
     ]
   }
   ```

One of these is a bug. The other is a configuration mistake. Figure out which before blaming the toolkit

### Test log not found

Autoplay tried to run but didn't finish. It crashed. Or timed out. Or achieved sentience and wandered off.

**Fix:** Check that `scripts/debug_autoplay.gd` and `scenes/debug_test_runner.tscn` actually got copied into your project during install. If they're missing, your install was incomplete. Tell Claude to re-run it. Maybe it'll work this time.

## When to Use Each Mode

| Mode | When | What Probably Happens |
|------|------|---|
| Quick | Before committing code | Either "✓ All good" or a list of things you're doing wrong |
| Autoplay | After adding a feature | Either "✅ No violations" or "❌ Health went to 999999" |
| Full | Before a release | Either everything passes or you get therapy-grade analysis of your mistakes |

## When to Edit the Config

Edit `debug_config.json` when:
- You add a new property to monitor (add to `invariants`)
- You add a new input action (add to `input_actions_to_fuzz`)
- You add an autoload that matters (add to `required_autoloads`)
- You move Godot and it vanishes (update `godot_executable`)

You usually do **not** need to edit it when:
- Adding new game features (the fuzz engine doesn't care what your game does)
- Changing gameplay logic (it just presses buttons like a confused player)
- Changing UI (invariants only care about numbers, not pixels)
- Having existential questions about your life choices (that's on you)

## Summary

1. Install with an AI
2. Run Quick to see if you've committed crimes against code
3. Run Autoplay to see if your game can survive chaos
4. Read the output — "Violations Found: 0" is the best thing you'll hear all week
5. Fix whatever broke
6. Run again
7. Accept that the computer now finds your bugs before your players do.
8. Move on

---

For more help, ask Claude Code or read `HOW_TO_CLAUDE.md`. For what this thing actually does (philosophically), read `README.md`. For why we made it this way (so you can understand our pain), read `DESIGN.md`.
