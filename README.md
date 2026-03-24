# Ralph Mode - GitHub Copilot CLI Edition

These scripts are adapted from the [Ralph technique](https://www.aihero.dev/getting-started-with-ralph) to work with GitHub Copilot CLI instead of Claude Code.

## Prerequisites

### Option 1: Local Installation (Direct)
1. Install GitHub CLI: `brew install gh` (or your package manager)
2. Install GitHub Copilot CLI extension: `gh extension install github/gh-copilot`
3. Authenticate: `gh auth login`

### Option 2: Docker Container (Isolated)
1. Install Docker Desktop 4.50+ from [docker.com](https://docs.docker.com/desktop/)
2. Build the custom template:
   ```bash
   docker build -t ralph-copilot:latest .
   ```
3. Set your GitHub token for runtime:
   ```bash
   export GH_TOKEN=$(gh auth token)
   ```

## Setup

1. Create a PRD (Product Requirements Document) named `prd.json` with your project goals
2. Create an empty progress tracker: `touch progress.txt`
3. Make scripts executable: `chmod +x *.sh`

## Optional: Shell Aliases

For convenience, you can add aliases to your `~/.zshrc` (or `~/.bashrc` for bash):

```bash
# Ralph mode aliases
alias ralph-afk='bash /path/where/repo/was/cloned/ralph-mode/afk-ralph-docker.sh'
alias ralph-once='bash /path/where/repo/was/cloned/ralph-mode/ralph-once-docker.sh'
alias ralph-tasks='node /path/where/repo/was/cloned/ralph-mode/manage-tasks.js'
alias ralph-start='bash /path/where/repo/was/cloned/ralph-mode/ralph-env-start.sh'
alias ralph-shell='bash /path/where/repo/was/cloned/ralph-mode/ralph-env-shell.sh'
alias ralph-stop='bash /path/where/repo/was/cloned/ralph-mode/ralph-env-stop.sh'
alias ralph-env-afk='bash /path/where/repo/was/cloned/ralph-mode/ralph-env-afk.sh'
```

Then reload your shell:
```bash
source ~/.zshrc
```

Now you can use short commands from anywhere:
- `ralph-afk <iterations> [model]` - Run multiple iterations (ephemeral containers)
- `ralph-once [model]` - Run a single iteration
- `ralph-tasks` - View task summary from any directory with a prd.json
- `ralph-start` - Start a persistent environment for the current project
- `ralph-shell` - Open an interactive shell in the running environment
- `ralph-env-afk <iterations> [model]` - Run the afk loop in the persistent environment
- `ralph-stop` - Stop and remove the persistent environment

**Note:** Update the paths in the aliases to match your actual installation directory.

## Usage

### Local Execution (No Isolation)

#### Human-in-the-loop (recommended for first runs)

```bash
./ralph-once.sh [model]
```

You can optionally add extra instructions without editing the scripts:

- Create a file named `ralph-extra.md` in your project folder (auto-loaded if present)
- Or pass inline text via `RALPH_EXTRA` (env var)
- Or pass a one-off extra instruction as the next positional argument

Examples:
```bash
./ralph-once.sh              # Use default model
./ralph-once.sh gpt-4        # Use specific model
RALPH_EXTRA="Focus on adding tests first." ./ralph-once.sh gpt-4
./ralph-once.sh gpt-4 "Prefer minimal diffs; avoid refactors."
```

Run this script, review what happens, then run again. This helps you understand how the loop works.

#### Automated Loop

```bash
./afk-ralph.sh <iterations> [model]
```

Examples:
```bash
./afk-ralph.sh 20            # 20 iterations with default model
./afk-ralph.sh 20 gpt-4      # 20 iterations with GPT-4
RALPH_EXTRA="Run lint before tests; stop on failure." ./afk-ralph.sh 20 gpt-4
./afk-ralph.sh 20 gpt-4 "Keep commits small and descriptive."
```

### Docker Execution (Isolated Sandbox)

#### Human-in-the-loop (single task)

```bash
./ralph-once-docker.sh [model]
```

#### Automated Loop (ephemeral containers)

Each iteration runs in a fresh container that is removed when it finishes.

```bash
./afk-ralph-docker.sh <iterations> [model] [prd_id] [extra_instructions]
```

Examples:
```bash
./afk-ralph-docker.sh 20
./afk-ralph-docker.sh 20 gpt-4o
./afk-ralph-docker.sh 20 gpt-4o "" "Prefer minimal diffs."
./afk-ralph-docker.sh 20 gpt-4o specific-task-id
```

Note: Docker scripts require `GH_TOKEN` to be set (see prerequisites above).

Extra instructions work in Docker mode too (same `ralph-extra.md` and `RALPH_EXTRA` support).

#### Persistent Environment (recommended for active development)

The `ralph-env-*` scripts keep a single named container alive for the duration of your
session so you can tune settings, inspect state, and steer the agent between runs —
without paying the container startup cost on every iteration.

**Start the environment** (run once per session from your project directory):

```bash
./ralph-env-start.sh
```

This creates a container named `ralph-<project>`, authenticates the GitHub CLI inside
it, and installs a `ralph` helper command that you can call from within the container.

**Open an interactive shell** inside the running container:

```bash
./ralph-env-shell.sh
```

From this shell you can:
- Inspect or edit `~/.config/github-copilot/mcp.json` to tune MCP servers
- Verify tools are available (`node --version`, `gh auth status`, `copilot --help`, etc.)
- Run a loop directly: `ralph <iterations> [model] [prd_id]`

**Run the afk loop from the host** (without entering the shell):

```bash
./ralph-env-afk.sh <iterations> [model] [prd_id] [extra_instructions]
```

This executes inside the already-running container, so the environment is already warm.

**Stop and remove the container** when you are done:

```bash
./ralph-env-stop.sh
```

All modes will:
- Pick the next task from your PRD
- Implement it
- Run tests/type checks
- Update progress.txt
- Commit changes
- Stop early if `<promise>COMPLETE</promise>` is detected

**Docker mode benefits:**
- Isolated environment (can't affect your host system)
- Reproducible setup across team members
- Can safely install packages and run tests
- Easy to reset (just rebuild the image)

### Steering the Agent with STEERING.md

Drop a `STEERING.md` file in your project root to guide the agent between loop
iterations — no restart needed. Both `afk-ralph-docker.sh` and the `ralph-env-*`
scripts re-read it at the start of every iteration.

Copy the template from this repo as a starting point:

```bash
cp /path/to/ralph-mode/STEERING.md ./STEERING.md
```

Use the sections to:
- **Current Focus** — tell the agent what to prioritise right now
- **Constraints** — temporary guardrails (e.g. "Do not touch auth module")
- **Style Reminders** — project-specific conventions
- **Notes for the Agent** — hints, known issues, or context

Edit the file at any time while a loop is running. The next iteration will pick up
your changes automatically.

## Available Models

You can specify different AI models when running the scripts. Common models include:

### OpenAI Models
- `gpt-4` - GPT-4 (most capable)
- `gpt-4-turbo` - GPT-4 Turbo (faster, cheaper)
- `gpt-3.5-turbo` - GPT-3.5 Turbo (faster, budget option)

### Claude Models (Anthropic)
- `claude-sonnet-4.5` - Claude 4.5 Sonnet (recommended, balanced performance)
- `claude-3.5-sonnet` - Claude 3.5 Sonnet (recommended, balanced performance)
- `claude-3-opus` - Claude 3 Opus (most capable)
- `claude-3-sonnet` - Claude 3 Sonnet
- `claude-3-haiku` - Claude 3 Haiku (fastest, budget option)

### Usage Examples
```bash
# Use Claude Sonnet
./ralph-once.sh claude-3.5-sonnet
./afk-ralph.sh 20 claude-3.5-sonnet

# Use GPT-4
./ralph-once.sh gpt-4
./afk-ralph-docker.sh 20 gpt-4
```

**Note:** Model availability depends on your GitHub Copilot subscription level. If a model is not available, the script will use the default model or return an error.

## Key Differences from Original Ralph

- Uses `gh copilot suggest` instead of `claude`
- Docker sandbox option available but GitHub Copilot CLI is not officially supported by Docker Sandboxes (we use standard Docker containers instead)
- No `--permission-mode` flag (GitHub Copilot CLI is interactive by default)
- File context passed via `@file` syntax (supports both .md and .json formats)
- Both local and Docker execution modes available
- Uses `prd.json` instead of `PRD.md` for structured task tracking

## Docker Customization

The included `Dockerfile` creates a Ubuntu 22.04 environment with:
- GitHub CLI pre-installed
- GitHub Copilot CLI extension
- Build tools and Git
- Non-root `agent` user for safety

### Customizing the Docker Template

You can modify `Dockerfile` to add:

```dockerfile
# Add Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Add Python tools
RUN apt-get update && apt-get install -y python3-pip \
    && pip3 install pytest black pylint

# Add language-specific tools
RUN npm install -g typescript eslint prettier
```

After making changes, rebuild:
```bash
docker build -t ralph-copilot:latest .
```

### Docker Sandbox Templates (Advanced)

While GitHub Copilot CLI isn't officially supported by Docker Sandboxes, you can explore using the experimental Docker Sandbox features if you want Claude Code-style isolation. See the [Docker Sandboxes docs](https://docs.docker.com/ai/sandboxes/) for more information.

## Tips

- Keep tasks small and specific in your PRD
- Review commits frequently during human-in-the-loop phase
- Use version control - commit your PRD and progress.txt regularly
- Consider running in a feature branch for safety

## Customization

You can modify these scripts to:
- Pull tasks from GitHub Issues
- Create PRs instead of direct commits
- Focus on specific goals (test coverage, linting, refactoring)
- Add additional validation steps

For more tips, see the [original Ralph guide](https://www.aihero.dev/getting-started-with-ralph).
