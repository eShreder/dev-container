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

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
