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
    # Essential build tools
    build-essential \
    gcc \
    g++ \
    make \
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

# Create symlinks for python/pip commands (python3 -> python)
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Install uv (modern Python package installer, much faster than pip)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && mv /root/.local/bin/uvx /usr/local/bin/uvx

# ==============================================================================
# AI Agents installation
# ==============================================================================
# Install claude-code (Anthropic's Claude CLI)
RUN npm install -g @anthropic-ai/claude-code

# Install codex (OpenAI's Codex CLI)
RUN npm install -g @openai/codex

# ==============================================================================
# Ralphex installation (autonomous AI-driven plan execution)
# Install to /usr/local/go-bin so it's available when home is mounted from host
# ==============================================================================
RUN GOPATH=/tmp/go go install github.com/umputun/ralphex/cmd/ralphex@latest \
    && mkdir -p /usr/local/go-bin \
    && mv /tmp/go/bin/ralphex /usr/local/go-bin/ \
    && rm -rf /tmp/go

# ==============================================================================
# User configuration
# Create non-root user 'developer' with UID 1000
# Home directory will be mounted from host at runtime
# ==============================================================================
# Rename existing ubuntu user/group to developer (Ubuntu 24.04 has uid/gid 1000 as 'ubuntu')
# This preserves UID 1000 for proper volume permissions with host
RUN usermod -l developer -d /home/developer -m ubuntu 2>/dev/null || true \
    && groupmod -n developer ubuntu 2>/dev/null || true \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/developer \
    && chmod 0440 /etc/sudoers.d/developer

# Update PATH to include shared Go binaries
ENV PATH=/usr/local/go-bin:$PATH

# Create workspace directory with proper permissions
RUN mkdir -p /workspace && chown developer:developer /workspace

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER developer

# Ensure GOPATH points to user's home for any new Go installs at runtime
ENV GOPATH=/home/developer/go
ENV PATH=/home/developer/go/bin:$PATH

# Default command
CMD ["/bin/bash"]
