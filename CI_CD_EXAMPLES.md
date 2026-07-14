# Debugging Kit — CI/CD Integration Examples

The Debugging Kit is designed to work in automated pipelines. Here are examples for common CI/CD systems.

## GitHub Actions

### Pre-Commit Hook (Quick Mode)

Runs static checks before every commit — **fast (~3 seconds)**, catches config/syntax errors early.

**.github/workflows/pre-commit-checks.yml:**
```yaml
name: Pre-Commit Debugging Kit Checks

on:
  pull_request:
  push:
    branches:
      - main
      - develop

jobs:
  debug-kit-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Run Debugging Kit Quick Mode
        run: |
          bash ./.claude/skills/debug-kit/driver.sh 1
```

**When to use:** Every PR, every commit. Catches typos and obvious issues fast.

---

### Pre-Release Testing (Autoplay Mode)

Runs full gameplay testing before release — **slower (~20 seconds)**, verifies game stability.

**.github/workflows/release-testing.yml:**
```yaml
name: Release Testing — Debugging Kit Autoplay

on:
  push:
    tags:
      - 'v*'

jobs:
  autoplay-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Godot 4.6
        run: |
          wget -q https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_linux.x86_64.zip
          unzip -q Godot_v4.6-stable_linux.x86_64.zip
          chmod +x Godot_v4.6-stable_linux.x86_64/Godot_v4.6-stable_linux.x86_64
      
      - name: Update debug_config.json with Godot path
        run: |
          python3 << 'EOF'
          import json
          with open('debug_config.json', 'r') as f:
              config = json.load(f)
          config['godot_executable'] = './Godot_v4.6-stable_linux.x86_64/Godot_v4.6-stable_linux.x86_64'
          with open('debug_config.json', 'w') as f:
              json.dump(config, f, indent=2)
          EOF
      
      - name: Run Debugging Kit Autoplay Mode
        run: |
          bash ./.claude/skills/debug-kit/driver.sh 2
      
      - name: Report Results
        if: failure()
        run: |
          echo "❌ Autoplay test failed. Check logs above for invariant violations."
          exit 1
```

**When to use:** Before cutting a release. Ensures the game runs without crashing under random input.

---

### Full Testing (Deep Analysis)

Comprehensive testing — **slowest (~30 seconds)**, for pre-release QA.

**.github/workflows/full-testing.yml:**
```yaml
name: Full Debugging Kit Analysis

on:
  schedule:
    - cron: '0 22 * * *'  # Nightly at 10 PM UTC
  workflow_dispatch:

jobs:
  full-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install Godot 4.6
        run: |
          wget -q https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_linux.x86_64.zip
          unzip -q Godot_v4.6-stable_linux.x86_64.zip
          chmod +x Godot_v4.6-stable_linux.x86_64/Godot_v4.6-stable_linux.x86_64
      
      - name: Update debug_config.json with Godot path
        run: |
          python3 << 'EOF'
          import json
          with open('debug_config.json', 'r') as f:
              config = json.load(f)
          config['godot_executable'] = './Godot_v4.6-stable_linux.x86_64/Godot_v4.6-stable_linux.x86_64'
          with open('debug_config.json', 'w') as f:
              json.dump(config, f, indent=2)
          EOF
      
      - name: Run Debugging Kit Full Mode
        run: |
          bash ./.claude/skills/debug-kit/driver.sh 3
      
      - name: Archive Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: debug-kit-results
          path: debug_kit_results/
```

**When to use:** Nightly builds, scheduled QA runs. Generates deep analysis for archive.

---

## GitLab CI

### Quick Checks on Every Merge Request

**.gitlab-ci.yml:**
```yaml
debug-kit-quick:
  stage: test
  image: python:3.10
  script:
    - bash ./.claude/skills/debug-kit/driver.sh 1
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

**When to use:** Catch errors early in merge requests.

---

## Local Development (Pre-Commit Hook)

### Run Debugging Kit Before Committing

**.git/hooks/pre-commit:**
```bash
#!/bin/bash
# Debugging Kit pre-commit hook

echo "Running Debugging Kit Quick Mode..."
bash ./.claude/skills/debug-kit/driver.sh 1

if [ $? -ne 0 ]; then
    echo "❌ Pre-commit checks failed. Fix issues before committing."
    exit 1
fi

echo "✅ Pre-commit checks passed!"
exit 0
```

**Setup:**
```bash
chmod +x .git/hooks/pre-commit
```

**When to use:** Local development, ensures every commit passes basic checks.

---

## Docker (For Remote CI)

### Dockerfile for Running Debugging Kit

```dockerfile
FROM ubuntu:22.04

# Install Godot 4.6
RUN apt-get update && apt-get install -y wget unzip python3
RUN wget -q https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_linux.x86_64.zip && \
    unzip -q Godot_v4.6-stable_linux.x86_64.zip && \
    chmod +x Godot_v4.6-stable_linux.x86_64/Godot_v4.6-stable_linux.x86_64

WORKDIR /game
COPY . .

# Run Debugging Kit
CMD ["bash", "./.claude/skills/debug-kit/driver.sh", "2"]
```

**Build and run:**
```bash
docker build -t my-game-tests .
docker run my-game-tests
```

---

## Recommended Setup

For most projects, start with:

1. **GitHub Actions + Quick Mode** (PR checks, every commit)
2. **GitHub Actions + Autoplay Mode** (Pre-release tags)
3. **Local pre-commit hook** (Developer convenience)

This catches errors at multiple stages without slowing down the workflow.

---

## Troubleshooting CI Failures

| Error | Solution |
|-------|----------|
| `godot_executable: command not found` | Update `.github/workflows/` to specify Godot path after download |
| `Config file not found` | Ensure `debug_config.json` exists in repo root |
| `Input action not defined` | Check that `debug_config.json` has been configured for your project |
| `Timeout` | Autoplay running too long; reduce `test_duration_seconds` or run Quick mode instead |

---

**Questions?** See HOW_TO_USER.md and HOW_TO_CLAUDE.md for more details.
