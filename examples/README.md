# Example Configurations

This folder contains completed `debug_config.json` examples for different game types. Use these as reference when filling in your own config.

## What's Here

- **config_2d_platformer.json** — A 2D platformer game with position bounds, velocity limits, and health tracking
- **config_rhythm_game.json** — A rhythm/action game with energy system, weapon levels, and beat-based mechanics
- **config_puzzle_game.json** — A turn-based puzzle game with move counters and score tracking

## How to Use These

1. **Read the file that matches your game type** — It has comments explaining each invariant
2. **Copy the structure, not the values** — Your game will have different bounds and properties
3. **Modify for your project:**
   - Change `godot_executable` to your actual Godot path
   - Change `player_group` to match your player node's group
   - Update `input_actions_to_fuzz` to match your actual input actions
   - Replace invariants with properties from your actual player script
4. **Test with config validation:**
   ```bash
   bash .claude/skills/<your-skill-name>/driver.sh 4
   ```

## Key Principles

- **Invariants are bounds, not mechanics** — Monitor "health ∈ [0, 100]", not "on-beat damage is 2x"
- **Pick properties that matter** — Health, ammo, position. Not UI colors or animation states
- **Be realistic with bounds** — If your camera can pan, allow position outside viewport
- **All bounds must be numbers** — No testing boolean or string properties

## Common Properties to Monitor

### 2D Movement Games
- `position.x` / `position.y` — Screen bounds
- `velocity.x` / `velocity.y` — Reasonable physics ranges
- `is_on_floor` — *Can't use this; it's boolean* (test via position instead)

### Inventory / Resource Games
- `health` / `energy` / `ammo` — 0-to-max ranges
- `inventory_size` — Item counts
- `level` / `stage` — Progression bounds

### Puzzle Games
- `moves_remaining` — Turn counter
- `score` — Non-negative, reasonable max
- `board_state` — *Can't test directly; test via position of pieces instead*

## Questions?

If you're unsure about a property:
1. Read the player script (`res://scripts/player.gd` or similar)
2. Look for `var` declarations with numeric types (`float`, `int`)
3. Look for `clamp()` calls or `min_value`/`max_value` annotations — those are hints at bounds
4. If still unsure, ask Claude: *"What numeric properties should I monitor in my game?"*

---

**Remember:** These configs are just examples. Your real config should reflect your actual game logic.
