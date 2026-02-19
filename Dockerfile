# Custom Docker template for GitHub Copilot CLI in a sandbox environment
# Note: Docker Sandboxes officially support Claude Code, but we can create a 
# general-purpose template with gh CLI and run commands inside it

FROM ubuntu:22.04

# Set non-interactive to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    ca-certificates \
    gnupg \
    sudo \
    vim \
    sqlite3 \
    libsqlite3-dev \
    jq \
    # Rust/Tauri build deps
    clang \
    cmake \
    libssl-dev \
    patchelf \
    # Tauri (wry) Linux WebView deps (Ubuntu 22.04 uses WebKitGTK 4.0 + libsoup2)
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev \
    libjavascriptcoregtk-4.0-dev \
    libsoup2.4-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 24.x
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Enable Corepack and preinstall pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install common Node.js development tools globally (as root)
RUN npm install -g \
    typescript \
    eslint \
    prettier \
    ts-node \
    playwright \
    @github/copilot

# Install dependencies for Playwright and headless browsers
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    libwayland-client0 \
    fonts-liberation \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3 and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install common Python development tools
RUN pip3 install --no-cache-dir \
    pytest \
    black \
    pylint \
    ipython

# Install PostgreSQL client and server
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for running the agent
RUN useradd -m -s /bin/bash -G sudo agent && \
    echo 'agent ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set up workspace directory
RUN mkdir -p /workspace && chown agent:agent /workspace

# Initialize PostgreSQL data directory (will be properly initialized when postgres service starts)
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql

USER agent
WORKDIR /workspace

# Rust toolchain (installed as non-root)
ENV CARGO_HOME=/home/agent/.cargo
ENV RUSTUP_HOME=/home/agent/.rustup
ENV PATH="/home/agent/.cargo/bin:/home/agent/.local/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable && \
    rustup component add rustfmt clippy rust-src

# Note: GitHub Copilot CLI extension will be installed at runtime
# This avoids passing sensitive tokens during build

# Install Playwright browsers as agent user
RUN npx playwright install chromium

# Verify Playwright installation
RUN npx playwright --version

# Set default shell
ENV SHELL=/bin/bash

# Add helpful aliases for database management and browser testing
RUN echo 'alias start-postgres="sudo service postgresql start"' >> ~/.bashrc && \
    echo 'alias stop-postgres="sudo service postgresql stop"' >> ~/.bashrc && \
    echo 'export PLAYWRIGHT_BROWSERS_PATH=/home/agent/.cache/ms-playwright' >> ~/.bashrc

CMD ["/bin/bash"]
