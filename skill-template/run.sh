#!/bin/bash
# Wrapper to run the interactive menu
# Usage: bash run.sh [mode]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
    # No argument - show interactive menu
    python3 "$SCRIPT_DIR/menu.py"
else
    # Mode passed as argument - run directly
    python3 "$SCRIPT_DIR/menu.py" "$1"
fi
