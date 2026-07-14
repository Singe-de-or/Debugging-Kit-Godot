# Debugging Kit — Updates for Multi-Game-Type Support

This document summarizes the changes made to support any game type (not just movement-based games).

## What Changed

The Debugging Kit now supports **any Godot game**, not just movement-based games like platformers.

### For Movement Games (Platformer, Top-Down Shooter)
- Use `player_group: "player"` to find the player node
- Monitor `position.x`, `position.y`, `velocity`, `health`

### For Non-Movement Games (Clicker, Puzzle, Card Game)
- Use `target_node: "GameManager"` to find the game state node
- Monitor any numeric properties: `score`, `moves`, `hand_size`, etc.

---

## Files Modified

### 1. **HOW_TO_CLAUDE.md** — Installation guide for AIs
- ✅ Added **Phase 2: Interview the User** — asks game type before filling config
- ✅ Updated **Step 1** to explain both `player_group` (movement) and `target_node` (other games)
- ✅ Removed assumption that player must be CharacterBody2D

### 2. **install.sh** — Installer script
- ✅ Added scanning for **all scripts with numeric properties** (not just CharacterBody2D/3D)
- ✅ Added `possible_target_scripts` to `_detected_candidates` output
- ✅ Config now includes both `player_group` and `target_node` fields (empty by default)
- ✅ Updated final instructions to mention both approaches

### 3. **config_validator.py** — Configuration validator
- ✅ Now accepts either `player_group` OR `target_node` (at least one must be set)
- ✅ Validates that at least one is filled in (no more required-player-group error)

### 4. **debug_autoplay.gd** — Game-side test engine
- ✅ Tries to find target by `player_group` (movement games) first
- ✅ Falls back to `target_node` (other games) if player_group not set
- ✅ Error messages clear about which approach failed and why

### 5. **SKILL.md** — User-facing skill documentation
- ✅ Shows config examples for both movement and non-movement games
- ✅ Updated "How This Adapts" section to explain both game types
- ✅ Updated Troubleshooting to address both `player_group` and `target_node` issues

### 6. **examples/config_generic_template.json** — Generic template
- ✅ Clarified both fields and when to use each
- ✅ Removed example values that misled users
- ✅ Links to game-type-specific examples

### 7. **examples/README.md** — Examples guide
- ✅ Added references to new game-type examples
- ✅ Expanded "Common Properties to Monitor" by game type
- ✅ Updated instructions for AI installers

### 8. **HOW_TO_USER.md** — User installation guide
- ✅ Updated "Be Specific" example to mention game type
- ✅ Added "Understanding Your Config" section with table of game types
- ✅ Clarified that AI will ask about game type

### 9. **New Example Configs** — Game-type-specific templates
- ✅ `config_2d_platformer.json` — Movement-based game
- ✅ `config_clicker_game.json` — Click-based game
- ✅ `config_turnbased_puzzle.json` — Turn-based puzzle game
- ✅ `config_card_game.json` — Card game example

---

## Key Design Decisions

### Why Both `player_group` and `target_node`?
- **`player_group`** works well for movement games where the player is a scene node in a group
- **`target_node`** is more flexible for games where state is tracked in a manager/singleton/game controller

### Why Ask About Game Type?
- Different games need different invariants to monitor
- Claude (the AI) can ask good follow-up questions once it knows the game type
- Helps the AI avoid assuming "position" and "health" are always the right properties

### Why Scan All Scripts (Not Just CharacterBody)?
- Movement games might use CharacterBody3D, CharacterBody2D, or custom base classes
- Non-movement games use whatever makes sense (Node, Control, game manager singletons)
- Giving Claude all the options lets it make informed decisions

---

## What This Enables

✅ **Clicker games** — Monitor score, clicks, gold, upgrades
✅ **Puzzle games** — Monitor moves, level, pieces, score
✅ **Card games** — Monitor hand size, deck size, mana
✅ **Rhythm games** — Monitor energy, beat timing, weapon level
✅ **Board games** — Monitor board state (via piece positions), turns
✅ **UI-driven games** — Monitor menu navigation, selections
✅ **Any game with numeric state** — Configure what matters and bounds

---

## Backward Compatibility

✅ **Existing movement game configs still work** — If `player_group` is filled, it works as before
✅ **No breaking changes** — Old configs without `target_node` field still validate
✅ **Graceful degradation** — If config is incomplete, error message is clear

---

## Testing Checklist

When using the updated kit:

- [ ] Ask Claude what game type it is (movement vs other)
- [ ] Check that Claude picked the right example config
- [ ] Verify `player_group` OR `target_node` is filled (not both empty)
- [ ] Run Validate mode to catch typos early
- [ ] Check that invariants match your actual game properties
- [ ] Run Quick mode to verify basic setup
- [ ] Run Autoplay to see it actually test your game

---

**Result:** One testing system, infinite game types. 🎮✅
