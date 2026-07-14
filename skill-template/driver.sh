#!/bin/bash
# Debugging Kit - Automated Testing Driver
# Runs static checks and optional autoplay testing for any Godot project

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$PROJECT_DIR/debug_config.json"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
	echo -e "\n${YELLOW}=== $1 ===${NC}\n"
}

print_success() {
	echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
	echo -e "${RED}❌ $1${NC}"
}

detect_wsl() {
	if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
		return 0
	fi
	return 1
}

# Get test mode from argument or prompt
if [ -z "$1" ]; then
	# No argument provided - show interactive menu
	print_header "Debugging Kit Test Suite"
	echo "Choose test mode:"
	echo "1. Quick (Static checks only - 3 seconds)"
	echo "2. Autoplay (Gameplay simulation + state validation - 25 seconds)"
	echo "3. Full (Static checks + Autoplay + Deep analysis - 35 seconds)"
	echo "4. Validate config (Check debug_config.json for errors)"
	echo ""
	read -p "Enter choice [1-4] (default: 1): " test_mode
	test_mode=${test_mode:-1}
else
	test_mode="$1"
fi

case $test_mode in
	1|2|3|4)
		;;
	--validate)
		test_mode="4"
		;;
	*)
		print_error "Invalid mode: $test_mode"
		echo "Valid modes: 1 (Quick), 2 (Autoplay), 3 (Full), 4 (Validate), or --validate"
		exit 1
		;;
esac

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
	print_error "debug_config.json not found at: $CONFIG_FILE"
	echo "Run the install script first to set up this project."
	exit 1
fi

# For Validate mode, run config validator and exit
if [ "$test_mode" == "4" ]; then
	print_header "Validating Configuration"
	if command -v python3 &> /dev/null; then
		if python3 "$SKILL_DIR/config_validator.py" "$PROJECT_DIR" "$CONFIG_FILE"; then
			exit 0
		else
			exit 1
		fi
	else
		print_error "Python3 required for config validation"
		exit 1
	fi
fi

# Step 1: Run static checks
print_header "Running Static Checks"

if [ -x "$SKILL_DIR/static_checks.sh" ]; then
	if bash "$SKILL_DIR/static_checks.sh" "$PROJECT_DIR"; then
		print_success "Static checks passed"
	else
		print_error "Static checks found issues"
		# Don't exit, continue to autoplay if requested
	fi
else
	print_error "static_checks.sh not found or not executable"
	exit 1
fi

# For Quick mode, stop here
if [ "$test_mode" == "1" ]; then
	print_header "Quick Test Complete"
	echo "✅ Quick mode finished. To run autoplay testing, use mode 2 or 3."
	exit 0
fi

# Step 2: Launch game with autoplay (modes 2 and 3)
print_header "Launching Game - Autoplay Mode"

# Find Godot executable
GODOT_EXE=""

# Try from config first
if grep -q '"godot_executable"' "$CONFIG_FILE"; then
	GODOT_EXE=$(grep '"godot_executable"' "$CONFIG_FILE" | head -1 | sed 's/.*"godot_executable":\s*"\([^"]*\)".*/\1/')
fi

# If not in config or is a placeholder, try to find it
if [ -z "$GODOT_EXE" ] || [[ "$GODOT_EXE" == *"PUT_"* ]]; then
	# Try which first
	if command -v godot &> /dev/null; then
		GODOT_EXE=$(which godot)
	# Try common Godot locations
	elif [ -f "$PROJECT_DIR/Godot.exe" ]; then
		GODOT_EXE="$PROJECT_DIR/Godot.exe"
	elif [ -f "$PROJECT_DIR/Godot" ]; then
		GODOT_EXE="$PROJECT_DIR/Godot"
	else
		# Search for Godot in subdirectories
		while IFS= read -r file; do
			GODOT_EXE="$file"
			break
		done < <(find "$PROJECT_DIR" -maxdepth 3 -type f \( -name "Godot" -o -name "Godot.exe" \) 2>/dev/null | head -1)
	fi
fi

if [ -z "$GODOT_EXE" ] || [ ! -f "$GODOT_EXE" ]; then
	print_error "Godot executable not found"
	echo "Searched locations:"
	echo "  - \$PATH"
	echo "  - $PROJECT_DIR (and subdirs)"
	echo "Please update 'godot_executable' in debug_config.json"
	exit 1
fi

print_success "Found Godot: $GODOT_EXE"

# Create temp file for Godot output
GODOT_OUTPUT=$(mktemp)

# Cleanup trap
cleanup_godot() {
	# Force kill any Godot processes
	pkill -9 -f "Godot" 2>/dev/null || true
	sleep 0.5
}
trap cleanup_godot EXIT

# Determine scene and timeout
SCENE_TO_RUN="res://scenes/debug_test_runner.tscn"
TEST_TIMEOUT=30

if [ "$test_mode" == "2" ]; then
	TEST_TIMEOUT=35
elif [ "$test_mode" == "3" ]; then
	TEST_TIMEOUT=35
fi

# Launch Godot with autoplay scene
print_success "Launching Godot"

if detect_wsl; then
	# WSL: use Windows interop
	print_success "WSL detected - using Windows interop"

	# Convert WSL path to Windows path
	GODOT_PROJECT_PATH=$(echo "$PROJECT_DIR" | sed 's|/mnt/\([a-zA-Z]\)/|\U\1:/|' | sed 's|/|\\|g')
	GODOT_LOG_FILE="$PROJECT_DIR\.godot_test.log"

	# Run with timeout
	timeout $TEST_TIMEOUT bash -c "\"$GODOT_EXE\" --path \"$GODOT_PROJECT_PATH\" --scene \"$SCENE_TO_RUN\" --max-fps 60" > "$GODOT_OUTPUT" 2>&1 || true

	# Try to kill via Windows if still running
	sleep 0.3
	cmd.exe /c "taskkill /F /IM Godot*.exe" 2>/dev/null || true

else
	# Native Linux/macOS
	timeout $TEST_TIMEOUT "$GODOT_EXE" --path "$PROJECT_DIR" --scene "$SCENE_TO_RUN" --headless > "$GODOT_OUTPUT" 2>&1 || true
fi

# Cleanup temp file
rm -f "$GODOT_OUTPUT"

print_success "✅ Game ran and Godot closed"

# Step 3: Deep analysis (Full mode only)
if [ "$test_mode" == "3" ]; then
	print_header "Deep Test Analysis"

	TEST_LOG="$PROJECT_DIR/.test_log.json"

	if [ -f "$TEST_LOG" ]; then
		print_success "Test log found"

		if command -v python3 &> /dev/null; then
			python3 "$SKILL_DIR/test_analyzer.py" "$TEST_LOG"
		else
			echo "⚠️  Python3 not found - skipping deep analysis"
		fi
	else
		print_error "Test log not found at $TEST_LOG"
		echo "This usually means autoplay didn't run to completion."
	fi
fi

print_header "Test Complete"
echo "✅ All checks finished successfully!"
