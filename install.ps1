# Debugging Kit Installer for Windows PowerShell
# Installs the generic debugging/testing skill into a target Godot project
# Usage: .\install.ps1 -TargetProject "C:\path\to\project" [-SkillName "debug-kit"]

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,

    [Parameter(Mandatory=$false)]
    [string]$SkillName
)

$ErrorActionPreference = "Stop"

# Color functions for output
function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️  $Message"
}

# Get script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Validate target project
if (-not (Test-Path $TargetProject -PathType Container)) {
    Write-Error-Custom "Target project directory not found: $TargetProject"
    exit 1
}

$PROJECT_GODOT = Join-Path $TargetProject "project.godot"
if (-not (Test-Path $PROJECT_GODOT)) {
    Write-Error-Custom "project.godot not found in $TargetProject"
    Write-Host "Make sure you're pointing to the Godot project root."
    exit 1
}

Write-Header "Debugging Kit Installer"
Write-Host "Target project: $TargetProject"
Write-Host ""

# Get or prompt for skill name
if ([string]::IsNullOrWhiteSpace($SkillName)) {
    $SkillName = Read-Host "Enter the slash command name (e.g. debug-kit, godot-test)"
}

# Sanitize skill name (keep only alphanumeric, underscore, hyphen)
$SkillName = [System.Text.RegularExpressions.Regex]::Replace($SkillName, '[^a-zA-Z0-9_-]', '')

if ([string]::IsNullOrWhiteSpace($SkillName)) {
    Write-Error-Custom "Skill name cannot be empty"
    exit 1
}

$SKILL_PATH = Join-Path $TargetProject ".claude" "skills" $SkillName

if (Test-Path $SKILL_PATH) {
    Write-Error-Custom "Skill already exists at: $SKILL_PATH"
    exit 1
}

# Step 1: Create skill directory
Write-Header "Step 1: Creating skill directory"
New-Item -ItemType Directory -Path $SKILL_PATH -Force | Out-Null
Write-Success "Created: $SKILL_PATH"

# Step 2: Copy and substitute skill template
Write-Header "Step 2: Copying and substituting skill template"
$TEMPLATE_DIR = Join-Path $SCRIPT_DIR "skill-template"
Get-ChildItem $TEMPLATE_DIR | ForEach-Object {
    $filename = $_.Name
    $source = $_.FullName
    $dest = Join-Path $SKILL_PATH $filename

    if ($filename -eq "SKILL.md") {
        $content = Get-Content $source -Raw
        $content = $content -replace "PUT_SKILL_NAME_HERE", $SkillName
        Set-Content -Path $dest -Value $content -NoNewline
        Write-Success "Copied and substituted: $filename"
    } else {
        Copy-Item $source -Destination $dest
        Write-Success "Copied: $filename"
    }
}

# Step 3: Copy game files
Write-Header "Step 3: Copying game files to target project"
$SCRIPTS_DIR = Join-Path $TargetProject "scripts"
$SCENES_DIR = Join-Path $TargetProject "scenes"

New-Item -ItemType Directory -Path $SCRIPTS_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $SCENES_DIR -Force | Out-Null

$DEBUG_AUTOPLAY = Join-Path $SCRIPT_DIR "game_files" "debug_autoplay.gd"
$DEBUG_TEST_RUNNER = Join-Path $SCRIPT_DIR "game_files" "debug_test_runner.tscn"

Copy-Item $DEBUG_AUTOPLAY -Destination $SCRIPTS_DIR
Write-Success "Copied: scripts/debug_autoplay.gd"

Copy-Item $DEBUG_TEST_RUNNER -Destination $SCENES_DIR
Write-Success "Copied: scenes/debug_test_runner.tscn"

# Step 4: Gather project facts
Write-Header "Step 4: Gathering project facts"

$PLAYER_SCRIPTS = @()
$GROUPS_FOUND = @()
$INPUT_ACTIONS = @()
$AUTOLOADS = @()
$VIEWPORT_WIDTH = 1024
$VIEWPORT_HEIGHT = 600

# Find scripts extending CharacterBody2D or CharacterBody3D
Write-Host "Scanning for player scripts (CharacterBody2D/3D)..."
if (Test-Path $SCRIPTS_DIR) {
    Get-ChildItem $SCRIPTS_DIR -Filter "*.gd" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "extends CharacterBody2D|extends CharacterBody3D") {
            $rel_path = $_.FullName.Substring($TargetProject.Length + 1).Replace('\', '/')
            $PLAYER_SCRIPTS += "res://$rel_path"
        }
    }
}

if ($PLAYER_SCRIPTS.Count -gt 0) {
    Write-Success "Found $($PLAYER_SCRIPTS.Count) player script(s): $($PLAYER_SCRIPTS -join ', ')"
} else {
    Write-Warning-Custom "No scripts extending CharacterBody2D/3D found"
}

# Find groups in scenes
Write-Host "Scanning scenes for groups..."
if (Test-Path $SCENES_DIR) {
    Get-ChildItem $SCENES_DIR -Filter "*.tscn" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $matches = [System.Text.RegularExpressions.Regex]::Matches($content, 'groups = \["([^"]+)"\]')
        foreach ($match in $matches) {
            $group = $match.Groups[1].Value
            if ($group -notin $GROUPS_FOUND) {
                $GROUPS_FOUND += $group
            }
        }
    }
}

if ($GROUPS_FOUND.Count -gt 0) {
    Write-Success "Found groups: $($GROUPS_FOUND -join ', ')"
} else {
    Write-Warning-Custom "No groups found in scenes"
}

# Parse project.godot for input actions
Write-Host "Parsing input actions from project.godot..."
$in_input_section = $false
Get-Content $PROJECT_GODOT | ForEach-Object {
    $line = $_
    if ($line -eq "[input]") {
        $in_input_section = $true
        return
    }
    if ($line -match "^\[") {
        $in_input_section = $false
    }
    if ($in_input_section -and $line -match "=") {
        $action_name = $line -split "=" | Select-Object -First 1
        $action_name = $action_name.Trim()
        if (-not [string]::IsNullOrWhiteSpace($action_name)) {
            $INPUT_ACTIONS += $action_name
        }
    }
}

if ($INPUT_ACTIONS.Count -gt 0) {
    Write-Success "Found $($INPUT_ACTIONS.Count) input action(s)"
} else {
    Write-Warning-Custom "No input actions found"
}

# Parse project.godot for autoloads
Write-Host "Parsing autoloads from project.godot..."
$in_autoload_section = $false
Get-Content $PROJECT_GODOT | ForEach-Object {
    $line = $_
    if ($line -eq "[autoload]") {
        $in_autoload_section = $true
        return
    }
    if ($line -match "^\[") {
        $in_autoload_section = $false
    }
    if ($in_autoload_section -and $line -match "=") {
        $autoload_name = $line -split "=" | Select-Object -First 1
        $autoload_name = $autoload_name.Trim()
        if (-not [string]::IsNullOrWhiteSpace($autoload_name)) {
            $AUTOLOADS += $autoload_name
        }
    }
}

if ($AUTOLOADS.Count -gt 0) {
    Write-Success "Found $($AUTOLOADS.Count) autoload(s): $($AUTOLOADS -join ', ')"
} else {
    Write-Warning-Custom "No autoloads found"
}

# Parse viewport dimensions
$viewport_content = Get-Content $PROJECT_GODOT -Raw
if ($viewport_content -match "window/size/viewport_width\s*=\s*(\d+)") {
    $VIEWPORT_WIDTH = [int]$matches[1]
}
if ($viewport_content -match "window/size/viewport_height\s*=\s*(\d+)") {
    $VIEWPORT_HEIGHT = [int]$matches[1]
}
Write-Success "Viewport size: ${VIEWPORT_WIDTH}x${VIEWPORT_HEIGHT}"

# Step 5: Create debug_config.json
Write-Header "Step 5: Creating debug_config.json"

# Helper function to escape JSON strings
function Escape-JsonString {
    param([string]$String)
    return $String -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
}

# Helper function to build JSON arrays
function Build-JsonArray {
    param([array]$Array)
    $json_items = @()
    foreach ($item in $Array) {
        $escaped = Escape-JsonString $item
        $json_items += "`"$escaped`""
    }
    return "[" + ($json_items -join ", ") + "]"
}

# Try to find godot executable
$GODOT_GUESS = ""
$godot_paths = @(
    "godot.exe",
    (Join-Path $TargetProject "Godot.exe"),
    (Join-Path $TargetProject "godot" "Godot.exe"),
    "C:\Program Files\Godot\Godot.exe",
    "C:\Program Files (x86)\Godot\Godot.exe"
)

foreach ($path in $godot_paths) {
    if ($path -eq "godot.exe") {
        # Check if godot is in PATH
        if (Get-Command godot.exe -ErrorAction SilentlyContinue) {
            $GODOT_GUESS = (Get-Command godot.exe).Source
            break
        }
    } elseif (Test-Path $path) {
        $GODOT_GUESS = $path
        break
    }
}

if ([string]::IsNullOrWhiteSpace($GODOT_GUESS)) {
    $GODOT_GUESS = "PUT_PATH_TO_GODOT_EXECUTABLE_HERE"
}

# Build JSON config
$PLAYER_SCRIPTS_JSON = Build-JsonArray $PLAYER_SCRIPTS
$GROUPS_JSON = Build-JsonArray $GROUPS_FOUND
$ACTIONS_JSON = Build-JsonArray $INPUT_ACTIONS
$AUTOLOADS_JSON = Build-JsonArray $AUTOLOADS
$GODOT_ESCAPED = Escape-JsonString $GODOT_GUESS

$CONFIG_FILE = Join-Path $TargetProject "debug_config.json"

$config = @"
{
  "_detected_candidates": {
    "possible_player_scripts": $PLAYER_SCRIPTS_JSON,
    "groups_found_in_scenes": $GROUPS_JSON,
    "input_actions_defined": $ACTIONS_JSON,
    "autoloads_defined": $AUTOLOADS_JSON,
    "viewport_size": {"width": $VIEWPORT_WIDTH, "height": $VIEWPORT_HEIGHT}
  },
  "_instructions": "Review the _detected_candidates above by reading the actual scripts in your project. Then fill in the fields below with your project-specific choices. Do not guess; open the scripts and understand the actual invariants.",
  "godot_executable": "$GODOT_ESCAPED",
  "player_group": "PUT_GROUP_NAME_HERE",
  "input_actions_to_fuzz": [],
  "invariants": [
    {"property": "position.x", "min": 0, "max": $VIEWPORT_WIDTH, "note": "example: keep player on screen horizontally"}
  ],
  "required_autoloads": [],
  "test_duration_seconds": 20
}
"@

Set-Content -Path $CONFIG_FILE -Value $config -NoNewline
Write-Success "Created: $CONFIG_FILE"

# Completion message
Write-Header "Installation Complete!"
Write-Host ""
Write-Host "📝 Next steps:"
Write-Host "1. Open $CONFIG_FILE"
Write-Host "2. Review the _detected_candidates section"
Write-Host "3. Fill in the remaining placeholder fields based on your actual project:"
Write-Host "   - player_group: The group name your player node is in"
Write-Host "   - input_actions_to_fuzz: Which input actions to test (e.g. ui_left, ui_right, ui_accept)"
Write-Host "   - invariants: Numeric properties to monitor (e.g. energy, health, position)"
Write-Host "   - required_autoloads: Any critical autoloads that must be present"
Write-Host "4. Run Quick mode to verify the install:"
Write-Host "   python $SKILL_PATH\driver.py"
Write-Host ""
Write-Host "✅ Slash command available as: /$SkillName"
Write-Host ""
