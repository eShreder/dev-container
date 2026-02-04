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
# Final stage placeholder (to be extended in subsequent tasks)
# ==============================================================================
FROM base AS final

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
