# Dev Container Docker Image
# Multi-stage build for AI agents (claude-code, codex) with Python, Node.js, Go

# ==============================================================================
# Stage 1: Base system with common dependencies
# ==============================================================================
FROM ubuntu:24.04 AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential build tools (includes gcc, g++, make)
    build-essential \
    # Version control
    git \
    git-lfs \
    # Network tools
    curl \
    wget \
    ca-certificates \
    iputils-ping \
    netcat-openbsd \
    # Archive tools
    unzip \
    zip \
    tar \
    # Text processing
    jq \
    # Process management
    procps \
    # SSH client (for git)
    openssh-client \
    # Libraries commonly needed
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    # Editor
    vim \
    nano \
    # Database tools
    sqlite3 \
    libsqlite3-dev \
    postgresql-client \
    # Misc utilities
    less \
    sudo \
    locales \
    gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Generate locale
RUN locale-gen en_US.UTF-8

# ==============================================================================
# Stage 2: Go installation
# ==============================================================================
FROM golang:1.23-bookworm AS golang

# ==============================================================================
# Stage 3: Node.js installation
# ==============================================================================
FROM node:22-bookworm AS nodejs

# ==============================================================================
# Stage: Neovim build from source (release mode, no debug info)
# ==============================================================================
FROM base AS neovim-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    ninja-build \
    gettext \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN git clone --depth 1 https://github.com/neovim/neovim.git /tmp/neovim \
    && cd /tmp/neovim \
    && make CMAKE_BUILD_TYPE=Release \
    && cmake --install build --prefix /usr/local \
    && rm -rf /tmp/neovim

# ==============================================================================
# Final stage (to be extended in subsequent tasks)
# ==============================================================================
FROM base AS final

# Copy Go from official image
COPY --from=golang /usr/local/go /usr/local/go

# Configure Go environment
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/developer/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH

# Copy Node.js from official image
COPY --from=nodejs /usr/local/bin/node /usr/local/bin/node
COPY --from=nodejs /usr/local/lib/node_modules /usr/local/lib/node_modules

# Create symlinks for npm and npx
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install pnpm globally
RUN npm install -g pnpm

# ==============================================================================
# Python 3.12 installation
# Ubuntu 24.04 includes Python 3.12 by default
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create symlinks for python/pip commands (python3 -> python, pip3 -> pip)
RUN ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Install uv (modern Python package installer, much faster than pip)
# Using pip instead of curl|sh for better supply chain security
# Note: pip installs both 'uv' and 'uvx' entry points automatically
RUN pip install --break-system-packages uv

# ==============================================================================
# GitHub CLI (gh) installation
# ==============================================================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ==============================================================================
# Neovim (built from source in release mode)
# ==============================================================================
COPY --from=neovim-builder /usr/local /usr/local

# stylua (Lua formatter, used by none-ls)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then STYLUA_ARCH="x86_64"; else STYLUA_ARCH="aarch64"; fi \
    && STYLUA_VERSION=$(curl -fsSL https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | jq -r '.tag_name') \
    && curl -fsSL "https://github.com/JohnnyMorganz/StyLua/releases/download/${STYLUA_VERSION}/stylua-linux-${STYLUA_ARCH}.zip" \
        -o /tmp/stylua.zip \
    && unzip -o /tmp/stylua.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/stylua \
    && rm /tmp/stylua.zip

# lua-language-server (Lua LSP, used by lspconfig: lua_ls)
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then LUA_LS_ARCH="x64"; else LUA_LS_ARCH="arm64"; fi \
    && LUA_LS_VERSION=$(curl -fsSL https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | jq -r '.tag_name') \
    && curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/lua-language-server-${LUA_LS_VERSION}-linux-${LUA_LS_ARCH}.tar.gz" \
        -o /tmp/lua-ls.tar.gz \
    && mkdir -p /opt/lua-language-server \
    && tar -xzf /tmp/lua-ls.tar.gz -C /opt/lua-language-server \
    && ln -sf /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server \
    && rm /tmp/lua-ls.tar.gz

# ==============================================================================
# Neovim plugin dependencies (system-wide)
# ==============================================================================
# fzf-lua: ripgrep (live grep), fd (file finder), fzf (fuzzy finder)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ripgrep \
    fd-find \
    fzf \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    # Ubuntu packages fd as 'fdfind', create 'fd' symlink
    && ln -sf /usr/bin/fdfind /usr/bin/fd

# LSP servers (used by lspconfig: pyright, ts_ls, dockerls)
# Formatters (used by none-ls: prettier)
RUN npm install -g \
    pyright \
    typescript \
    typescript-language-server \
    dockerfile-language-server-nodejs \
    prettier

# ==============================================================================
# AI Agents (claude-code, codex) are installed at runtime via entrypoint
# into ~/.npm-global so they persist across container rebuilds.
# To update: run `npm install -g @anthropic-ai/claude-code@latest` inside
# the container — the new version will be available in all future containers.
# ==============================================================================

# ==============================================================================
# Ralphex installation (autonomous AI-driven plan execution)
# Install to /usr/local/go-bin so it's available when home is mounted from host
# ==============================================================================
RUN git clone --depth 1 --branch master https://github.com/umputun/ralphex.git /tmp/ralphex \
    && cd /tmp/ralphex \
    && GOPATH=/tmp/go go build -o /usr/local/go-bin/ralphex ./cmd/ralphex \
    && rm -rf /tmp/ralphex /tmp/go

# ==============================================================================
# Playwright (browser automation/testing)
# Install npm package and system browser dependencies (requires root)
# ==============================================================================
RUN npm install -g playwright \
    && npx playwright install --with-deps chromium

# ==============================================================================
# User configuration
# Create non-root user 'developer' with configurable UID/GID
# Home directory will be mounted from host at runtime
# ==============================================================================
ARG USER_UID=1000
ARG USER_GID=1000

# Remove default 'ubuntu' user if it exists (Ubuntu 24.04 creates it with UID 1000)
# Then create 'developer' user with the requested UID/GID
# If a group with USER_GID already exists, reuse it instead of creating a new one
RUN if id ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi \
    && if getent group ubuntu >/dev/null 2>&1; then groupdel ubuntu; fi \
    && (getent group ${USER_GID} >/dev/null 2>&1 || groupadd -g ${USER_GID} developer) \
    && useradd -u ${USER_UID} -g ${USER_GID} -m -d /home/developer -s /bin/bash developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/developer \
    && chmod 0440 /etc/sudoers.d/developer

# Update PATH to include shared Go binaries
ENV PATH=/usr/local/go-bin:$PATH

# Create workspace directory with proper permissions
RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER developer

# Ensure GOPATH points to user's home for any new Go installs at runtime
ENV GOPATH=/home/developer/go
ENV PATH=/home/developer/go/bin:$PATH

# Configure npm global prefix inside home (persists across container rebuilds)
ENV NPM_CONFIG_PREFIX=/home/developer/.npm-global
ENV PATH=/home/developer/.npm-global/bin:$PATH

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

# Default entrypoint installs AI agents if missing, then runs the command
ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/bash"]
