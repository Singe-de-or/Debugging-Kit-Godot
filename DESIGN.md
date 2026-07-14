# Debugging Kit — Design Philosophy

This document explains the "why" behind the Debugging Kit's design choices.

## Problem It Solves

The original `/run-rhythm-game` skill was purpose-built for one specific game project. It contained hardcoded knowledge about:
- Energy system bounds (0-100)
- Specific actions (move, jump, shoot, dash)
- Specific input action names (ui_accept)
- Specific script UIDs and node names
- Specific autoloads (BeatManager)

This meant it could **never work for any other Godot project without a developer manually editing every hardcoded reference.**

## Solution: Configuration-Driven Testing

Instead of embedding game logic, Debugging Kit reads from `debug_config.json`:

```json
{
  "input_actions_to_fuzz": ["ui_left", "ui_right", "ui_accept"],
  "invariants": [
    {"property": "health", "min": 0, "max": 100},
    {"property": "position.x", "min": 0, "max": 1024}
  ],
  "required_autoloads": ["EventBus"]
}
```

A human (or AI) fills this in **once** by reading the actual project, and the engine works for **any** Godot project.

## Key Design Decisions

### 1. Install Script Gathers Facts, AI Decides

Why not have the installer auto-detect everything?

**Problem:** Regex-guessing is fragile and creates false confidence. Example: inferring bounds by regex-matching `clamp()` calls fails when:
- Bounds are set via exported min_value/max_value (not inline clamp)
- Multiple clamps exist (which is the real gameplay bound?)
- A clamp exists but isn't semantically meaningful (clamping alpha, camera zoom, etc.)

**Solution:** The install script gathers *objective facts* (possible player scripts, input actions defined, viewport size) and lists them in `_detected_candidates`. **The AI then reads the actual project and makes the real judgment call.**

This puts semantic understanding where it belongs: with the AI, not a regex.

### 2. Invariants, Not Mechanics

Why test "monitor health stays in [0, 100]" instead of "player took damage when hit by enemy"?

**Problem:** Game mechanics change. A test for "jump height on-beat is +20%" breaks the moment you add a double-jump or a gravity modifier. Maintenance burden grows with every feature.

**Solution:** Test **invariants** — numeric properties that should always stay in valid bounds. This is:
- **Robust to feature additions** — new weapons don't break energy-bounds tests
- **Cheap to maintain** — no test updates when gameplay logic evolves
- **Broadly useful** — applies to any project, not just rhythm games

Example: "health ∈ [0, 100]" is more durable than "perfect jump = +20% height".

### 3. Blind Fuzzing, Not Semantic Actions

Why doesn't the fuzz engine know that jumps need `is_on_floor()`?

**Problem:** Adding semantic knowledge (floor checks, energy gates, cooldown logic) makes the engine game-specific again. We'd have to hardcode "what does a valid action look like?" for every project.

**Solution:** The fuzz engine blindly presses random actions for random durations. It can't fail in interesting ways, but it also doesn't need to understand your game's rules. The **invariants** catch bugs (if health goes to 150, the bound-checking invariant fires).

Limitation: This won't catch "character T-poses during jump" or "animation plays out of order". But it catches state consistency bugs, which are the high-value finds.

### 4. Config File, Not Code Changes

Why not provide a template you edit by adding code?

**Problem:** Asking a user to edit code is a high barrier. Configuration files are simpler, self-documenting, and version-controllable.

**Solution:** All personalization happens in JSON. An AI can read and modify it without touching the engine code. A human can spot-check it for correctness. Version control sees it as data, not code.

### 5. No Central Name

Why isn't the slash command just `/debugging-kit` everywhere?

**Problem:** Users might already have testing commands named that, or want their own conventions. Forcing one name causes conflicts.

**Solution:** Each installer picks a name — could be `/debug-kit`, `/godot-test`, `/analyzer`, etc. The installer substitutes it everywhere (SKILL.md frontmatter, docs, prompts). Zero name collisions.

### 6. Game Files Live in Real Directories

Why are `debug_autoplay.gd` and `debug_test_runner.tscn` not in `.claude/skills/`?

**Problem:** Godot's editor and import system ignore directories starting with a dot. Scripts and scenes placed under `.claude/` won't resolve via `res://` paths or appear in the FileSystem dock. The test scene wouldn't be able to load the fuzz engine.

**Solution:** Copy game files into the real `scripts/` and `scenes/` directories. The installer handles this explicitly so the AI doesn't accidentally "tidy" them into `.claude/` and break them.

## Trade-Offs

### ✅ What We Gain

- Works with any Godot project (no game-specific knowledge)
- Adapts as games evolve (invariants don't break on new features)
- Simple install process (run script, fill config, done)
- Easy for AIs to reason about (configuration is explicit, not inferred)

### ⚠️ What We Give Up

- Can't test game-specific mechanics (e.g. "jump height on-beat is +20%")
- Blind fuzzing won't catch animation/visual bugs
- Requires honest configuration (AI must actually read the project)
- No auto-repair (can't auto-fix detected issues)

These are acceptable tradeoffs for a generic, maintainable tool.

## How This Differs from the Original

| Aspect | `/run-rhythm-game` | `Debugging Kit` |
|--------|-------------------|-----------------|
| **Portability** | Rhythm game only | Any Godot project |
| **Game Logic** | Hardcoded | Config-driven |
| **Installation** | Manual path editing | Installer + AI review |
| **Skill Name** | Fixed | User chooses |
| **Invariants** | Hardcoded (energy [0,100]) | User-defined |
| **Maintenance** | Breaks on feature changes | Survives feature additions |

## Future Directions (Not Implemented)

If this tool grows, consider:
- **GUI config editor** — visual alternative to JSON editing
- **Auto-fix** — automatically patch detected issues (dangerous, skip for v1)
- **Scenario testing** — pre-scripted test sequences, not just blind fuzz (requires per-project semantics)
- **Performance profiling** — track frame time, memory during autoplay (not critical for testing)
- **Regression suite** — save and re-run specific test sequences (useful, but adds complexity)

Start with this version. Keep it simple.

---

**Design by Patrick** for Debugging Kit, built as a public alternative to the rhythm-game-specific `/run-rhythm-game` skill.
