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
# AI Agents installation
# Note: Using @latest intentionally - AI agents receive frequent updates
# and this dev container prioritizes latest features over strict reproducibility.
# ==============================================================================
# Install claude-code (Anthropic's Claude CLI)
RUN npm install -g @anthropic-ai/claude-code@latest

# Install codex (OpenAI's Codex CLI)
RUN npm install -g @openai/codex@latest

# ==============================================================================
# Ralphex installation (autonomous AI-driven plan execution)
# Install to /usr/local/go-bin so it's available when home is mounted from host
# ==============================================================================
RUN git clone --depth 1 --branch master https://github.com/umputun/ralphex.git /tmp/ralphex \
    && cd /tmp/ralphex \
    && GOPATH=/tmp/go go build -o /usr/local/go-bin/ralphex ./cmd/ralphex \
    && rm -rf /tmp/ralphex /tmp/go

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

# Default command
CMD ["/bin/bash"]
