```
  ██████╗  ██████╗██████╗
 ██╔═══██╗██╔════╝██╔══██╗
 ██║   ██║██║     ██║  ██║
 ██║   ██║██║     ██║  ██║
 ╚██████╔╝╚██████╗██████╔╝
  ╚═════╝  ╚═════╝╚═════╝
```

[![Version](https://img.shields.io/badge/version-0.7.2-blue.svg)](./CHANGELOG.md)
[![中文](https://img.shields.io/badge/lang-中文-red.svg)](./docs/README_CN.md)

Run [OpenCode](https://opencode.ai) AI coding agent in a macOS + OrbStack Docker environment, powered by [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) multi-agent orchestration.

## Features

- One-command launch (`ocd`) with auto workspace detection
- Multi-window support (auto port allocation + lock mechanism)
- macOS integration (desktop notifications, clipboard bridge, auto-open links)
- Multi-agent collaboration via oh-my-opencode (Sisyphus, Oracle, Hephaestus, etc.)
- MCP servers & Playwright browser automation
- Persistent user-owned configuration (OCD never overwrites)

## Quick Start

### 1. Install Dependencies

```bash
brew install jq fswatch terminal-notifier
```

### 2. Clone and Configure

```bash
git clone https://github.com/aaajiao/opencode-on-dorker.git ~/opencode
cd ~/opencode
cp env.example .env
nano .env  # Fill in your API keys
```

### 3. Add to PATH

```bash
echo 'export PATH="$HOME/opencode/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 4. First Build

```bash
ocd -r
```

Detailed setup: [docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)

## Usage

```bash
ocd                  # Launch in project dir (auto-detect workspace)
ocd -p 5000          # Custom port
ocd --here           # Mount current directory only
ocd -r               # Rebuild image
ocd init             # Initialize project config
ocd config           # View config status
ocd scan             # Scan and register git projects
```

Full reference: [docs/CLI_REFERENCE.md](./docs/CLI_REFERENCE.md)

## Environment Variables

`.env` format (pure KEY=VALUE — no quotes, no comments):

```
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key
```

## oh-my-opencode Agents

| Scenario | Agent | Example |
|----------|-------|---------|
| Complex tasks | Sisyphus (default) | Just type the task |
| Deep autonomous work | Hephaestus | `deep:` prefix or delegated |
| Architecture / Debug | `@oracle` | `@oracle analyze this deadlock` |
| Find docs & examples | `@librarian` | `@librarian React 18 concurrency` |
| Codebase search | `@explore` | `@explore where is user auth` |
| Task planning | `@prometheus` | `@prometheus plan auth refactor` |
| Large refactor | `ulw:` | `ulw: refactor auth module` |

Full guide: [docs/OH_MY_OPENCODE.md](./docs/OH_MY_OPENCODE.md)

## Documentation

| Document | Description |
|----------|-------------|
| [Getting Started](./docs/GETTING_STARTED.md) | Installation & first build |
| [CLI Reference](./docs/CLI_REFERENCE.md) | All flags, subcommands, examples |
| [Configuration](./docs/CONFIGURATION.md) | Directory structure, config lifecycle |
| [Architecture](./docs/ARCHITECTURE.md) | Mac/Docker mapping, IPC |
| [Developer Guide](./docs/OPENCODE_CONFIG_GUIDE.md) | Extension & customization |
| [Agent Guide](./docs/OH_MY_OPENCODE.md) | oh-my-opencode multi-agent system |

## Requirements

- macOS
- [OrbStack](https://orbstack.dev/) (recommended) or Docker Desktop
- jq, fswatch, terminal-notifier

## License

MIT
