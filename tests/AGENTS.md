# tests/ - Testing Infrastructure

BATS (Bash Automated Testing System) unit tests for all OCD modules.

## Test Files

| File | Module | Tests | Purpose |
|------|--------|-------|---------|
| `core.bats` | `lib/core.sh` | 10+ | Logging, env loading, version |
| `core_extended.bats` | `lib/core.sh` | 20+ | XDG paths, directory structure |
| `config.bats` | `lib/config.sh` | 18+ | Template creation, port updates |
| `docker.bats` | `lib/docker.sh` | 20+ | Mount args, cache dirs, security |
| `init.bats` | `lib/config.sh` | 15+ | Project/global initialization |
| `port.bats` | `lib/port.sh` | 4 | Port allocation, locking |
| `workspace.bats` | `lib/workspace.sh` | 8 | Git detection, path resolution |
| `workspace_extended.bats` | `lib/workspace.sh` | 15+ | Mount security, edge cases |
| `watcher.bats` | `lib/watcher.sh` | 15+ | IPC, notifications, clipboard |
| `sete.bats` | Multiple | 20+ | `set -e` compatibility |

## Running Tests

```bash
# All tests
bats tests/bats/*.bats

# Single file
bats tests/bats/config.bats

# Filter by name (regex)
bats tests/bats/config.bats -f "template"

# Verbose with timing
bats -t tests/bats/core.bats

# Via script runner
./scripts/run-tests.sh
./scripts/run-tests.sh config
./scripts/run-tests.sh --quick
```

## Test Structure

```bash
#!/usr/bin/env bats

setup() {
  # Runs before each test
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  export TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/config"
}

teardown() {
  # Runs after each test
  rm -rf "$TEST_DIR"
}

@test "function does something" {
  result=$(ocd_function "arg")
  [ "$result" = "expected" ]
}
```

## Test Isolation Pattern

Each test gets isolated environment:
```bash
export TEST_DIR=$(mktemp -d)
export OCD_CONFIG_HOME="$TEST_DIR/config"
export OCD_DATA_HOME="$TEST_DIR/data"
export OCD_STATE_HOME="$TEST_DIR/state"
export OCD_CACHE_HOME="$TEST_DIR/cache"
```

## Mock Functions

Define inline, export for subprocess:
```bash
open() { echo "OPENED: $1" >> "$TEST_DIR/opened.log"; }
export -f open
```

## Assertions

BATS uses bash conditionals:
```bash
[ "$result" = "expected" ]           # Equality
[[ "$result" == *"pattern"* ]]       # Pattern match
[ -f "$file" ]                       # File exists
[ -d "$dir" ]                        # Directory exists
[ "$status" -eq 0 ]                  # Exit code
```

## CI Pipeline

Tests run on **macOS** (not Linux) because:
- `fswatch` required for watcher tests
- macOS-specific path handling

```yaml
# .github/workflows/ci.yml
test:
  runs-on: macos-latest
  steps:
    - run: brew install bats-core jq fswatch
    - run: bats tests/bats/*.bats
```

## Adding a New Test

1. Create `tests/bats/newmodule.bats`
2. Source the module in `setup()`:
   ```bash
   source "$OCD_ROOT/lib/newmodule.sh"
   ```
3. Follow naming: `@test "function_name does X"`
4. Use `TEST_DIR` for temp files
5. Clean up in `teardown()`

## sete.bats (Special)

Tests that all functions work with `set -e` (errexit):
```bash
@test "ocd_function works with set -e" {
  set -e
  result=$(ocd_function "arg")
  set +e
  [ "$result" = "expected" ]
}
```

This catches functions that incorrectly return non-zero.

## Dependencies

Required for running tests:
```bash
brew install bats-core jq fswatch
```

## Debugging Failed Tests

```bash
# Run single test with verbose output
bats -t tests/bats/config.bats -f "specific test name"

# Add debug output in test
echo "# DEBUG: $var" >&3
```
