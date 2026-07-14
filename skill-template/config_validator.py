#!/usr/bin/env python3
"""
Config Validator for Debugging Kit
Validates debug_config.json for correctness and logical errors
"""

import json
import sys
import os

def load_config(config_path):
    """Load and parse the config file"""
    try:
        with open(config_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ Config file not found: {config_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in config: {e}")
        return None

def validate_config(config, project_dir):
    """Validate the config against the actual project"""
    errors = []
    warnings = []

    # Check required fields
    if "player_group" not in config:
        errors.append("Missing 'player_group' field")
    elif not config["player_group"] or config["player_group"] == "PUT_GROUP_NAME_HERE":
        errors.append("'player_group' is not filled in")

    if "input_actions_to_fuzz" not in config:
        errors.append("Missing 'input_actions_to_fuzz' field")
    elif not isinstance(config["input_actions_to_fuzz"], list):
        errors.append("'input_actions_to_fuzz' must be an array")
    elif len(config["input_actions_to_fuzz"]) == 0:
        warnings.append("'input_actions_to_fuzz' is empty (autoplay will do nothing)")

    if "invariants" not in config:
        errors.append("Missing 'invariants' field")
    elif not isinstance(config["invariants"], list):
        errors.append("'invariants' must be an array")

    if "godot_executable" not in config:
        errors.append("Missing 'godot_executable' field")
    elif not config["godot_executable"] or "PUT_PATH" in config["godot_executable"]:
        errors.append("'godot_executable' is not set (needed for Autoplay mode)")
    else:
        godot_path = config["godot_executable"]
        if not os.path.exists(godot_path):
            errors.append(f"Godot executable not found at: {godot_path}")

    # Validate input actions against project.godot
    project_godot = os.path.join(project_dir, "project.godot")
    if os.path.exists(project_godot):
        with open(project_godot, 'r') as f:
            content = f.read()

        for action in config.get("input_actions_to_fuzz", []):
            if f"[{action}]" not in content and f"{action} =" not in content:
                errors.append(f"Input action not defined in project.godot: {action}")

    # Validate autoloads
    if os.path.exists(project_godot):
        with open(project_godot, 'r') as f:
            content = f.read()

        for autoload in config.get("required_autoloads", []):
            if f"{autoload} =" not in content:
                errors.append(f"Required autoload not found in project.godot: {autoload}")

    # Validate invariant structure
    for idx, invariant in enumerate(config.get("invariants", [])):
        if not isinstance(invariant, dict):
            errors.append(f"Invariant #{idx}: must be an object, got {type(invariant).__name__}")
            continue

        prop = invariant.get("property")
        min_val = invariant.get("min")
        max_val = invariant.get("max")

        if not prop:
            errors.append(f"Invariant #{idx}: missing 'property' field")
        elif not isinstance(prop, str):
            errors.append(f"Invariant #{idx}: 'property' must be a string")

        if min_val is None:
            errors.append(f"Invariant '{prop}': missing 'min' bound")
        elif not isinstance(min_val, (int, float)):
            errors.append(f"Invariant '{prop}': 'min' must be a number")

        if max_val is None:
            errors.append(f"Invariant '{prop}': missing 'max' bound")
        elif not isinstance(max_val, (int, float)):
            errors.append(f"Invariant '{prop}': 'max' must be a number")

        if isinstance(min_val, (int, float)) and isinstance(max_val, (int, float)):
            if min_val > max_val:
                errors.append(f"Invariant '{prop}': invalid bounds (min={min_val} > max={max_val})")

    return errors, warnings

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 config_validator.py <path-to-project> [config-file]")
        sys.exit(1)

    project_dir = sys.argv[1]
    config_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(project_dir, "debug_config.json")

    if not os.path.isdir(project_dir):
        print(f"❌ Project directory not found: {project_dir}")
        sys.exit(1)

    config = load_config(config_path)
    if config is None:
        sys.exit(1)

    errors, warnings = validate_config(config, project_dir)

    if warnings:
        print("\n⚠️  Warnings:")
        for w in warnings:
            print(f"  - {w}")

    if errors:
        print("\n❌ Errors found:")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print("\n✅ Config is valid!")
        sys.exit(0)

if __name__ == "__main__":
    main()
