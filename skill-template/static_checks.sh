#!/bin/bash
# Generic Static Checks for Godot Projects
# Run this before autoplay to catch common mistakes

PROJECT_DIR="$1"
CONFIG_FILE="${PROJECT_DIR}/debug_config.json"

if [ -z "$PROJECT_DIR" ]; then
	echo "Usage: bash static_checks.sh <project-dir>"
	exit 1
fi

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
	echo -e "\n${YELLOW}=== $1 ===${NC}\n"
}

print_success() {
	echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
	echo -e "${RED}✗ $1${NC}"
}

print_header "Running Static Checks"

bugs_found=0

# Check 1: @onready pattern for get_node() calls
echo "Checking @onready caching..."
unset_onready_count=0
while IFS= read -r file; do
	if grep -q "var.*get_node\|var.*get_parent.*get_node" "$file"; then
		if ! grep -B1 "var.*get_node\|var.*get_parent.*get_node" "$file" | grep -q "@onready"; then
			print_error "Missing @onready for get_node() in $(basename "$file")"
			((unset_onready_count++))
			((bugs_found++))
		fi
	fi
done < <(find "$PROJECT_DIR/scripts" -name "*.gd" -type f 2>/dev/null)

if [ $unset_onready_count -eq 0 ]; then
	print_success "@onready caching OK"
fi

# Check 2: Validate UID format (any UID, not hardcoded ones)
echo "Checking UID format in scenes..."
uid_format_errors=0
while IFS= read -r uid; do
	if ! [[ $uid =~ ^uid://[a-z0-9]{13}$ ]]; then
		print_error "Invalid UID format: $uid (expected uid://[a-z0-9]{13})"
		((uid_format_errors++))
		((bugs_found++))
	fi
done < <(grep -oh 'uid="uid://[^"]*"' "$PROJECT_DIR/scenes"/*.tscn 2>/dev/null | sed 's/uid="\(.*\)"/\1/' | sort -u)

if [ $uid_format_errors -eq 0 ]; then
	print_success "UID format OK"
fi

# Check 3: Verify referenced scripts exist
echo "Checking scene script references..."
scene_ref_errors=0
while IFS= read -r script_path; do
	if [ ! -z "$script_path" ] && [ ! -f "$PROJECT_DIR/$script_path" ]; then
		print_error "Referenced script not found: $script_path"
		((scene_ref_errors++))
		((bugs_found++))
	fi
done < <(grep -oh 'path="res://[^"]*\.gd"' "$PROJECT_DIR/scenes"/*.tscn 2>/dev/null | sed 's/path="\(.*\)"/\1/' | sed 's|^res://||' | sort -u)

if [ $scene_ref_errors -eq 0 ]; then
	print_success "Scene references OK"
fi

# Check 4: Validate input actions from config
echo "Checking input actions..."
input_action_errors=0
if [ -f "$CONFIG_FILE" ]; then
	# Extract input_actions_to_fuzz from JSON (simple grep approach)
	input_actions=$(grep -o '"input_actions_to_fuzz":\s*\[.*\]' "$CONFIG_FILE" | sed 's/.*\[//;s/\].*//' | tr ',' '\n' | grep -o '"[^"]*"' | tr -d '"')

	for action in $input_actions; do
		if ! grep -q "^\[$action\]" "$PROJECT_DIR/project.godot" && ! grep -q "^$action =" "$PROJECT_DIR/project.godot"; then
			print_error "Input action not defined in project.godot: $action"
			((input_action_errors++))
			((bugs_found++))
		fi
	done

	if [ $input_action_errors -eq 0 ] && [ ! -z "$input_actions" ]; then
		print_success "Input actions OK"
	fi
else
	echo "⚠️  debug_config.json not found; skipping input action checks"
fi

# Check 5: Validate required autoloads from config
echo "Checking autoloads..."
autoload_errors=0
if [ -f "$CONFIG_FILE" ]; then
	# Extract required_autoloads from JSON
	autoloads=$(grep -o '"required_autoloads":\s*\[.*\]' "$CONFIG_FILE" | sed 's/.*\[//;s/\].*//' | tr ',' '\n' | grep -o '"[^"]*"' | tr -d '"')

	for autoload in $autoloads; do
		if ! grep -q "^$autoload =" "$PROJECT_DIR/project.godot"; then
			print_error "Required autoload not found: $autoload"
			((autoload_errors++))
			((bugs_found++))
		fi
	done

	if [ $autoload_errors -eq 0 ] && [ ! -z "$autoloads" ]; then
		print_success "Autoloads OK"
	fi
fi

# Check 6: GDScript syntax checks
echo "Checking GDScript patterns..."
gd_syntax_errors=0

# Check for invalid match true: pattern with boolean expressions
while IFS= read -r file; do
	if grep -q "match true:" "$file"; then
		if grep -A 1 "match true:" "$file" | grep -qE "^\s*(>|<|>=|<=|==|!=|and |or )"; then
			print_error "Invalid 'match true:' pattern in $(basename "$file") - use if-elif-else instead"
			((gd_syntax_errors++))
			((bugs_found++))
		fi
	fi
done < <(find "$PROJECT_DIR/scripts" -name "*.gd" -type f 2>/dev/null)

# Check for shadowed global identifiers
while IFS= read -r file; do
	if grep -qE "func.*\b(max|min|abs|clamp|pow|sqrt)\b.*:" "$file"; then
		print_error "Parameter shadows builtin function in $(basename "$file")"
		((gd_syntax_errors++))
		((bugs_found++))
	fi
done < <(find "$PROJECT_DIR/scripts" -name "*.gd" -type f 2>/dev/null)

if [ $gd_syntax_errors -eq 0 ]; then
	print_success "GDScript syntax OK"
fi

# Check 7: Scene files referenced in project.godot
echo "Checking scene file existence..."
scene_file_errors=0
while IFS= read -r scene; do
	if [ ! -z "$scene" ] && [ ! -f "$PROJECT_DIR/$scene" ]; then
		print_error "Scene file not found: $scene"
		((scene_file_errors++))
		((bugs_found++))
	fi
done < <(grep -o 'res://[^"]*\.tscn' "$PROJECT_DIR/project.godot" | sed 's|res://||')

if [ $scene_file_errors -eq 0 ]; then
	print_success "Scene files OK"
fi

# Print summary
print_header "Summary"

if [ $bugs_found -eq 0 ]; then
	echo -e "${GREEN}✅ No issues found!${NC}"
	exit 0
else
	echo -e "${RED}❌ Found $bugs_found issue(s)${NC}"
	exit 1
fi
