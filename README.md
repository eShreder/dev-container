# Dev Container

Docker image for AI agents (claude-code, codex) to work on any project. Includes complete development environment for Python, Node.js, and Go with pre-installed ralphex.

## Features

- **claude-code** - Anthropic's CLI for working with Claude
- **codex** - OpenAI's CLI for working with GPT
- **Python 3.12** - with pip, venv, uv (modern package manager)
- **Node.js 22 LTS** - with npm, pnpm
- **Go 1.23** - for building Go projects
- **ralphex** - autonomous plan execution tool

## Quick Start

```bash
# Build the image
make build

# Run container (current directory as workspace)
make run

# First time: authenticate AI agents
claude login
codex login
```

## Persistent Home Directory

The container uses a persistent home directory that survives container restarts. All credentials, configs, shell history, and settings are stored in `./home` on the host and mounted to `/home/developer` in the container.

### First-Time Setup

1. Build and run the container:
   ```bash
   make build
   make run
   ```

2. Inside the container, authenticate your AI agents:
   ```bash
   # Authenticate Claude (required)
   claude login

   # Authenticate Codex (optional)
   codex login
   ```

3. Exit the container. Your credentials are now saved in `./home/.claude/`, `./home/.codex/`, etc.

4. On subsequent runs, authentication is preserved - no need to log in again.

### What Gets Persisted

The `./home` directory maps to `/home/developer` and stores:

| Path | Purpose |
|------|---------|
| `.claude/` | Claude credentials and settings |
| `.codex/` | Codex credentials and settings |
| `.config/` | Application configs (ralphex, etc.) |
| `.gitconfig` | Git configuration |
| `.ssh/` | SSH keys (if you add them) |
| `.bash_history` | Shell command history |
| `go/` | Go packages installed at runtime |

## Mounting Projects

The container expects a project to be mounted at `/workspace`. By default, Makefile mounts the current directory.

### Mount Current Directory

```bash
# Standard: current directory becomes /workspace
make run

# Or explicitly:
docker run -it --rm \
  -v $(pwd)/home:/home/developer \
  -v $(pwd):/workspace \
  dev-container
```

### Mount a Specific Project

```bash
# Using PROJECT variable
make run PROJECT=/path/to/your/project

# Or with docker run:
docker run -it --rm \
  -v $(pwd)/home:/home/developer \
  -v /path/to/your/project:/workspace \
  dev-container
```

### Mount Multiple Projects

For working with multiple projects, mount them under /workspace:

```bash
docker run -it --rm \
  -v $(pwd)/home:/home/developer \
  -v /path/to/project1:/workspace/project1 \
  -v /path/to/project2:/workspace/project2 \
  dev-container
```

## Usage Examples

### Example 1: Python Project

```bash
# Navigate to your Python project
cd /path/to/my-python-app

# Run the dev container
make -C /path/to/dev-container run PROJECT=$(pwd)

# Inside container: use claude-code to work on the project
claude

# Or use Python tools directly
python -m venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

### Example 2: Node.js Project

```bash
cd /path/to/my-node-app
make -C /path/to/dev-container run PROJECT=$(pwd)

# Inside container
pnpm install
claude
```

### Example 3: Go Project

```bash
cd /path/to/my-go-project
make -C /path/to/dev-container run PROJECT=$(pwd)

# Inside container
go mod download
go build ./...
claude
```

### Example 4: Using ralphex for Autonomous Execution

```bash
# Inside container with a project that has a plan file
ralphex -plan docs/plans/my-feature.md
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make build` | Build the Docker image |
| `make run` | Run container with current directory as workspace |
| `make shell` | Start interactive shell in container |
| `make test` | Run smoke tests to verify all tools |
| `make init` | Create home directory if it doesn't exist |
| `make clean` | Remove the Docker image |

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT` | Current directory | Path to mount as /workspace |
| `HOME_DIR` | `./home` | Path for persistent home directory |

## Smoke Test

Verify all tools are installed correctly:

```bash
make test
```

This runs `scripts/smoke-test.sh` which checks:
- Core system tools (git, curl, make, gcc, jq)
- Go installation and version
- Node.js, npm, pnpm
- Python, pip, uv
- AI agents (claude, codex)
- Ralphex
- User permissions and workspace access

## Container Details

### User

The container runs as a non-root user `developer` (UID 1000) with sudo privileges. This matches common host user IDs for seamless file permission handling.

### Directory Structure

```
/
├── home/developer/      # Mounted from host ./home
│   ├── .claude/         # Claude credentials
│   ├── .config/         # App configs
│   └── go/              # Go packages (GOPATH)
├── workspace/           # Mounted project directory
└── usr/local/
    ├── go/              # Go installation
    ├── bin/             # Node.js, npm binaries
    └── go-bin/          # ralphex binary
```

### Environment Variables

| Variable | Value |
|----------|-------|
| `GOROOT` | `/usr/local/go` |
| `GOPATH` | `/home/developer/go` |
| `PATH` | Includes Go, Node.js, Python, ralphex binaries |

## Troubleshooting

### Permission Denied on Mounted Volumes

If you encounter permission issues, ensure your host user has UID 1000, or adjust file ownership:

```bash
# On host, fix permissions for home directory
sudo chown -R 1000:1000 ./home
```

### Claude/Codex Not Authenticated

Credentials are stored in the persistent home directory. If they're missing:

1. Run `make run` or `make shell`
2. Execute `claude login` and/or `codex login`
3. Credentials will be saved to `./home/.claude/` etc.

### Tool Not Found

Run the smoke test to diagnose:

```bash
make test
```

If a tool is missing, rebuild the image:

```bash
make clean
make build
```

## Security Notes

- The `./home` directory contains sensitive credentials - add it to `.gitignore`
- Never commit the `./home` directory to version control
- The container has sudo access - this is intentional for development convenience

## License

MIT
