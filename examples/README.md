# Example Configurations

This folder contains **game-type examples** for `debug_config.json`. Do not copy-paste them — they show structure and approach. Read your project first, then fill in real values based on your actual game.

## What's Here

- **config_generic_template.json** — A minimal template showing JSON structure (use when no example matches your game type)
- **config_2d_platformer.json** — Movement-based game (platformer, top-down shooter): monitors position, velocity, health
- **config_clicker_game.json** — Click-based game (cookie clicker): monitors score, clicks, resources
- **config_turnbased_puzzle.json** — Turn-based game (puzzle, board game): monitors moves, pieces, score
- **config_card_game.json** — Card game (solitaire, deck builder): monitors hand size, deck, mana

## How to Use It

**For AIs installing this:**
1. Ask the user: "What type of game is this?" (movement, clicker, turn-based, card, etc.)
2. Point them to the matching example above (or generic_template)
3. Have them read their actual project scripts and understand what properties matter
4. Fill in real values: bounds, property names, input actions
5. Verify: `bash .claude/skills/<skill-name>/driver.sh 4`

**For humans:**
1. Find your game type in the list above
2. Look at that config file to see the structure
3. Open your project's scripts and identify numeric properties
4. Fill in `debug_config.json` with YOUR actual values (not the example values)
5. Run: `bash .claude/skills/<skill-name>/driver.sh 4` to validate

## Key Principles

- **Invariants are bounds, not mechanics** — Monitor "health ∈ [0, 100]", not "on-beat damage is 2x"
- **Pick properties that matter** — Health, ammo, position. Not UI colors or animation states
- **Be realistic with bounds** — If your camera can pan, allow position outside viewport
- **All bounds must be numbers** — No testing boolean or string properties

## Common Properties to Monitor by Game Type

### Movement-Based Games (Platformer, Top-Down Shooter)
- `position.x` / `position.y` — Keep player in/near level bounds
- `velocity.x` / `velocity.y` — Reasonable physics ranges (gravity, jump power)
- `health` / `energy` — 0-to-max ranges
- `is_on_floor` — *Can't use this; it's boolean* (test position instead)

### Click-Based Games (Clicker, Idle, Incremental)
- `score` — Non-negative, reasonable max
- `clicks_total` — Never decreases
- `gold` / `currency` — 0 to max
- `upgrades_unlocked` — Progression counter (0-100)

### Turn-Based Games (Puzzle, Board Game)
- `moves_remaining` — Turn counter (0-max)
- `score` — Bounds based on game rules
- `level` / `stage` — Progression (1-max)
- `pieces_remaining` — Board state counter
- `tiles_cleared` — Progress counter

### Card Games (Solitaire, Deck Builder)
- `hand_size` — 0-13 (depends on max hand size)
- `deck_size` — 0-52 (or your deck limit)
- `mana_current` — 0-max_mana per turn
- `cards_played` — Non-negative counter
- `score` — Game-specific bounds

### UI/Menu Games (Visual Novel, Menu Navigator)
- `selected_index` — 0 to (num_options - 1)
- `page_number` — 0-max_pages
- `inventory_count` — 0-capacity
- `gold` / `currency` — 0-max

## Questions?

If you're unsure about a property:
1. Read the player script (`res://scripts/player.gd` or similar)
2. Look for `var` declarations with numeric types (`float`, `int`)
3. Look for `clamp()` calls or `min_value`/`max_value` annotations — those are hints at bounds
4. If still unsure, ask Claude: *"What numeric properties should I monitor in my game?"*

---

**Remember:** These configs are just examples. Your real config should reflect your actual game logic.
