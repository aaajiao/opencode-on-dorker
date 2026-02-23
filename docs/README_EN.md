```
  ██████╗  ██████╗██████╗
 ██╔═══██╗██╔════╝██╔══██╗
 ██║   ██║██║     ██║  ██║
 ██║   ██║██║     ██║  ██║
 ╚██████╔╝╚██████╗██████╔╝
  ╚═════╝  ╚═════╝╚═════╝
```

[![Version](https://img.shields.io/badge/version-0.7.1-blue.svg)](../CHANGELOG.md)
[![中文](https://img.shields.io/badge/lang-中文-red.svg)](../README.md)

Run [OpenCode](https://opencode.ai) AI programming assistant in macOS + OrbStack environment, with [oh-my-opencode](https://github.com/1msoft/oh-my-opencode) plugin integration.

## Features

- One-command container launch (`ocd`)
- Multi-window support (auto port allocation + lock mechanism)
- macOS integration (desktop notifications, clipboard bridge, auto-open links)
- oh-my-opencode multi-agent collaboration
- MCP servers (Playwright, etc.)
- Persistent configuration (user-owned, OCD won't overwrite)

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
nano .env  # Fill in API keys
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

Detailed installation: [GETTING_STARTED.md](./GETTING_STARTED.md)

## Usage

```bash
ocd                  # Launch in project directory (auto-detect workspace)
ocd -p 5000          # Specify port
ocd --here           # Mount current directory only
ocd -r               # Rebuild image
ocd init             # Initialize project config
ocd config           # View config status
```

Full CLI reference: [CLI_REFERENCE.md](./CLI_REFERENCE.md)

## Environment Variables

`.env` format (pure KEY=VALUE, no quotes, no comments):

```bash
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key
```

## Documentation

| Document | Description |
|----------|-------------|
| [Getting Started](./GETTING_STARTED.md) | Detailed installation |
| [CLI Reference](./CLI_REFERENCE.md) | Complete command reference |
| [Configuration](./CONFIGURATION.md) | Directory structure, config lifecycle |
| [Architecture](./ARCHITECTURE.md) | Mac/Docker mapping |
| [Developer Guide](./OPENCODE_CONFIG_GUIDE.md) | Extension and customization |
| [Agent Guide](./OH_MY_OPENCODE.md) | oh-my-opencode multi-agent collaboration |

## oh-my-opencode Agents

| Scenario | Agent | Example |
|----------|-------|---------|
| Complex tasks | Sisyphus (default) | Just type the task |
| Architecture/Debug | `@oracle` | `@oracle analyze this deadlock` |
| Find docs | `@librarian` | `@librarian React 18 concurrency` |
| Find code | `@explore` | `@explore where is user auth` |
| Large refactor | `ulw:` | `ulw: refactor auth module` |

Full guide: [docs/OH_MY_OPENCODE.md](./OH_MY_OPENCODE.md)

## Requirements

- macOS
- [OrbStack](https://orbstack.dev/) (recommended) or Docker Desktop
- jq, fswatch, terminal-notifier

## License

MIT
