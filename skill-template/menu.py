#!/usr/bin/env python3
"""
Interactive menu for Debugging Kit testing.
In Claude Code: uses AskUserQuestion for arrow-key menu
Fallback: text-based menu for direct shell invocation
"""
import subprocess
import sys
import os
import json

def is_claude_code():
    """Detect if running in Claude Code context."""
    return os.environ.get("CLAUDE_CODE") == "true" or os.environ.get("CLAUDE_INTERACTIVE") == "true"

def show_claude_code_menu():
    """Signal Claude to show AskUserQuestion menu. Returns selected mode."""
    # When running in Claude Code, the harness should have already called AskUserQuestion
    # If we get here, print instructions for Claude
    print("\n🧪 DEBUGGING KIT - Mode Selection\n")
    print("Claude: Please select a test mode using the menu above, then run the selected test.")
    print("\nAvailable modes:")
    print("  1. Quick   — Static checks only (~3 seconds)")
    print("  2. Autoplay — Gameplay + state validation (~20 seconds)")
    print("  3. Full    — All checks + deep analysis (~30 seconds)")
    sys.exit(0)

def show_menu():
    """Fallback text-based menu for direct shell invocation."""
    print("\n" + "="*60)
    print("🧪 DEBUGGING KIT TEST SUITE")
    print("="*60 + "\n")

    print("Choose test mode:\n")
    print("1. Quick      - Static checks only (~3 seconds)")
    print("2. Autoplay   - Gameplay simulation + state validation (~20 seconds)")
    print("3. Full       - All checks + autoplay + deep analysis (~30 seconds)")
    print()

    while True:
        try:
            choice = input("Enter choice [1-3] (default: 1): ").strip() or "1"
            if choice in ["1", "2", "3"]:
                return choice
            else:
                print("Invalid choice. Please enter 1, 2, or 3.")
        except (EOFError, KeyboardInterrupt):
            print("\nExiting...")
            sys.exit(0)

def run_test(mode):
    """Run the driver script with the selected mode."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    driver_script = os.path.join(script_dir, "driver.sh")

    try:
        result = subprocess.run(
            ["bash", driver_script, mode],
            cwd=os.path.dirname(script_dir)
        )
        sys.exit(result.returncode)
    except Exception as e:
        print(f"Error running test: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # If mode passed as argument, use it directly
        mode = sys.argv[1]
        if mode not in ["1", "2", "3"]:
            print(f"Invalid mode: {mode}")
            print("Usage: python3 menu.py [1|2|3]")
            sys.exit(1)
    else:
        # Show interactive menu
        if is_claude_code():
            show_claude_code_menu()
        else:
            mode = show_menu()

    print(f"\nStarting test mode {mode}...\n")
    run_test(mode)
