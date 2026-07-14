#!/bin/bash
# Debugging Kit Installer
# Installs the generic debugging/testing skill into a target Godot project
# Usage: bash install.sh <target-project-path> [skill-name]

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate arguments
if [ -z "$1" ]; then
    print_error "Usage: bash install.sh <target-project-path> [skill-name]"
    echo "  <target-project-path>: Path to the Godot project root (where project.godot lives)"
    echo "  [skill-name]: Optional. If not provided, you will be prompted."
    exit 1
fi

TARGET_PROJECT="$1"

# Validate target project exists and has project.godot
if [ ! -d "$TARGET_PROJECT" ]; then
    print_error "Target project directory not found: $TARGET_PROJECT"
    exit 1
fi

if [ ! -f "$TARGET_PROJECT/project.godot" ]; then
    print_error "project.godot not found in $TARGET_PROJECT"
    echo "Make sure you're pointing to the Godot project root."
    exit 1
fi

print_header "Debugging Kit Installer"
echo "Target project: $TARGET_PROJECT"
echo ""

# Get or prompt for skill name
if [ -z "$2" ]; then
    read -p "Enter the slash command name (e.g. debug-kit, godot-test): " SKILL_NAME
else
    SKILL_NAME="$2"
fi

SKILL_NAME="${SKILL_NAME//[^a-zA-Z0-9_-]/}"  # Sanitize

if [ -z "$SKILL_NAME" ]; then
    print_error "Skill name cannot be empty"
    exit 1
fi

SKILL_PATH="$TARGET_PROJECT/.claude/skills/$SKILL_NAME"

if [ -d "$SKILL_PATH" ]; then
    print_error "Skill already exists at: $SKILL_PATH"
    exit 1
fi

print_header "Step 1: Creating skill directory"
mkdir -p "$SKILL_PATH"
print_success "Created: $SKILL_PATH"

print_header "Step 2: Copying and substituting skill template"
# Copy all skill template files, substituting PUT_SKILL_NAME_HERE with the chosen name
for file in "$SCRIPT_DIR/skill-template"/*; do
    filename=$(basename "$file")
    dest="$SKILL_PATH/$filename"

    # For SKILL.md, substitute the placeholder
    if [ "$filename" = "SKILL.md" ]; then
        sed "s/PUT_SKILL_NAME_HERE/$SKILL_NAME/g" "$file" > "$dest"
        print_success "Copied and substituted: $filename"
    else
        cp "$file" "$dest"
        print_success "Copied: $filename"
    fi

    # Make shell scripts executable
    if [[ "$filename" == *.sh ]]; then
        chmod +x "$dest"
    fi
done

print_header "Step 3: Copying game files to target project"
# Copy debug_autoplay.gd to scripts/ (create if needed)
mkdir -p "$TARGET_PROJECT/scripts"
cp "$SCRIPT_DIR/game_files/debug_autoplay.gd" "$TARGET_PROJECT/scripts/"
print_success "Copied: scripts/debug_autoplay.gd"

# Copy debug_test_runner.tscn to scenes/ (create if needed)
mkdir -p "$TARGET_PROJECT/scenes"
cp "$SCRIPT_DIR/game_files/debug_test_runner.tscn" "$TARGET_PROJECT/scenes/"
print_success "Copied: scenes/debug_test_runner.tscn"

print_header "Step 4: Gathering project facts"

# Initialize arrays
declare -a PLAYER_SCRIPTS
declare -a GROUPS_FOUND
declare -a INPUT_ACTIONS
declare -a AUTOLOADS
VIEWPORT_WIDTH=1024
VIEWPORT_HEIGHT=600

# Find scripts extending CharacterBody2D or CharacterBody3D
echo "Scanning for player scripts (CharacterBody2D/3D)..."
while IFS= read -r script_file; do
    rel_path="${script_file#$TARGET_PROJECT/}"
    PLAYER_SCRIPTS+=("res://${rel_path//\\//\/}")
done < <(find "$TARGET_PROJECT/scripts" -name "*.gd" -type f -exec grep -l "extends CharacterBody2D\|extends CharacterBody3D" {} \; 2>/dev/null)

if [ ${#PLAYER_SCRIPTS[@]} -gt 0 ]; then
    print_success "Found ${#PLAYER_SCRIPTS[@]} player script(s): ${PLAYER_SCRIPTS[*]}"
else
    echo "⚠️  No scripts extending CharacterBody2D/3D found"
fi

# Find groups used in scenes
echo "Scanning scenes for groups..."
while IFS= read -r group; do
    GROUPS_FOUND+=("$group")
done < <(grep -oh 'groups = \["[^"]*"\]' "$TARGET_PROJECT/scenes"/*.tscn 2>/dev/null | sed 's/groups = \["\([^"]*\)"\]/\1/' | sort -u)

if [ ${#GROUPS_FOUND[@]} -gt 0 ]; then
    print_success "Found groups: ${GROUPS_FOUND[*]}"
else
    echo "⚠️  No groups found in scenes"
fi

# Parse project.godot for input actions
echo "Parsing input actions from project.godot..."
in_input_section=false
while IFS= read -r line; do
    if [[ "$line" == "[input]" ]]; then
        in_input_section=true
        continue
    fi
    if [[ "$line" == "["* ]]; then
        in_input_section=false
    fi
    if $in_input_section && [[ "$line" == *"="* ]]; then
        action_name="${line%%=*}"
        action_name="${action_name// /}"  # trim spaces
        if [ ! -z "$action_name" ]; then
            INPUT_ACTIONS+=("$action_name")
        fi
    fi
done < "$TARGET_PROJECT/project.godot"

if [ ${#INPUT_ACTIONS[@]} -gt 0 ]; then
    print_success "Found ${#INPUT_ACTIONS[@]} input action(s)"
else
    echo "⚠️  No input actions found"
fi

# Parse project.godot for autoloads
echo "Parsing autoloads from project.godot..."
in_autoload_section=false
while IFS= read -r line; do
    if [[ "$line" == "[autoload]" ]]; then
        in_autoload_section=true
        continue
    fi
    if [[ "$line" == "["* ]]; then
        in_autoload_section=false
    fi
    if $in_autoload_section && [[ "$line" == *"="* ]]; then
        autoload_name="${line%%=*}"
        autoload_name="${autoload_name// /}"  # trim spaces
        if [ ! -z "$autoload_name" ]; then
            AUTOLOADS+=("$autoload_name")
        fi
    fi
done < "$TARGET_PROJECT/project.godot"

if [ ${#AUTOLOADS[@]} -gt 0 ]; then
    print_success "Found ${#AUTOLOADS[@]} autoload(s): ${AUTOLOADS[*]}"
else
    echo "⚠️  No autoloads found"
fi

# Parse viewport dimensions (if specified in project.godot)
if grep -q "window/size/viewport_width" "$TARGET_PROJECT/project.godot"; then
    VIEWPORT_WIDTH=$(grep "window/size/viewport_width" "$TARGET_PROJECT/project.godot" | sed 's/.*=\s*\([0-9]*\).*/\1/')
fi
if grep -q "window/size/viewport_height" "$TARGET_PROJECT/project.godot"; then
    VIEWPORT_HEIGHT=$(grep "window/size/viewport_height" "$TARGET_PROJECT/project.godot" | sed 's/.*=\s*\([0-9]*\).*/\1/')
fi
print_success "Viewport size: ${VIEWPORT_WIDTH}x${VIEWPORT_HEIGHT}"

print_header "Step 5: Creating debug_config.json"

# Safer JSON escape function
escape_json_string() {
    printf '%s\n' "$1" | sed -e 's/[\"]/\\&/g'
}

# Build arrays as JSON safely
build_json_array() {
    local -n arr=$1
    local first=true
    printf "["
    for item in "${arr[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ", "
        fi
        printf "\"%s\"" "$(escape_json_string "$item")"
    done
    printf "]"
}

# Try to find godot executable
GODOT_GUESS=""
if command -v godot &> /dev/null; then
    GODOT_GUESS=$(which godot)
elif [ -f "$TARGET_PROJECT/Godot" ]; then
    GODOT_GUESS="$TARGET_PROJECT/Godot"
elif [ -f "$TARGET_PROJECT/Godot.exe" ]; then
    GODOT_GUESS="$TARGET_PROJECT/Godot.exe"
elif [ -f "$TARGET_PROJECT/godot/Godot" ]; then
    GODOT_GUESS="$TARGET_PROJECT/godot/Godot"
elif [ -f "$TARGET_PROJECT/godot/Godot.exe" ]; then
    GODOT_GUESS="$TARGET_PROJECT/godot/Godot.exe"
fi

# Set placeholder if not found
if [ -z "$GODOT_GUESS" ]; then
    GODOT_GUESS="PUT_PATH_TO_GODOT_EXECUTABLE_HERE"
fi

# Build the JSON config
CONFIG_FILE="$TARGET_PROJECT/debug_config.json"
PLAYER_SCRIPTS_JSON=$(build_json_array PLAYER_SCRIPTS)
GROUPS_JSON=$(build_json_array GROUPS_FOUND)
ACTIONS_JSON=$(build_json_array INPUT_ACTIONS)
AUTOLOADS_JSON=$(build_json_array AUTOLOADS)

cat > "$CONFIG_FILE" << EOCONFIG
{
  "_detected_candidates": {
    "possible_player_scripts": $PLAYER_SCRIPTS_JSON,
    "groups_found_in_scenes": $GROUPS_JSON,
    "input_actions_defined": $ACTIONS_JSON,
    "autoloads_defined": $AUTOLOADS_JSON,
    "viewport_size": {"width": $VIEWPORT_WIDTH, "height": $VIEWPORT_HEIGHT}
  },
  "_instructions": "Review the _detected_candidates above by reading the actual scripts in your project. Then fill in the fields below with your project-specific choices. Do not guess; open the scripts and understand the actual invariants.",
  "godot_executable": "$(escape_json_string "$GODOT_GUESS")",
  "player_group": "PUT_GROUP_NAME_HERE",
  "input_actions_to_fuzz": [],
  "invariants": [
    {"property": "position.x", "min": 0, "max": $VIEWPORT_WIDTH, "note": "example: keep player on screen horizontally"}
  ],
  "required_autoloads": [],
  "test_duration_seconds": 20
}
EOCONFIG

print_success "Created: $CONFIG_FILE"

print_header "Installation Complete!"
echo ""
echo "📝 Next steps:"
echo "1. Open $TARGET_PROJECT/debug_config.json"
echo "2. Review the _detected_candidates section"
echo "3. Fill in the remaining placeholder fields based on your actual project:"
echo "   - player_group: The group name your player node is in"
echo "   - input_actions_to_fuzz: Which input actions to test (e.g. ui_left, ui_right, ui_accept)"
echo "   - invariants: Numeric properties to monitor (e.g. energy, health, position)"
echo "   - required_autoloads: Any critical autoloads that must be present"
echo "4. Run Quick mode to verify the install:"
echo "   bash $SKILL_PATH/driver.sh"
echo ""
echo "✅ Slash command available as: /$SKILL_NAME"
echo ""
