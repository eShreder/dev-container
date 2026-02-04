# Dev Container Makefile
# Build and run AI-powered development container

# Use bash for recipe commands ($RANDOM is bash-specific)
SHELL := /bin/bash

IMAGE_NAME := dev-container
CONTAINER_NAME := dev-container
HOME_DIR := $(CURDIR)/home
PROJECT ?= $(CURDIR)

.PHONY: build run shell test init clean help

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME) .

# Run container with mounted volumes
# - ./home -> /home/developer (persistent home for credentials, configs)
# - PROJECT -> /workspace (project to work on)
run: init
	docker run -it --rm \
		--name $(CONTAINER_NAME)-$$(date +%s)-$$RANDOM \
		-v "$(HOME_DIR):/home/developer" \
		-v "$(PROJECT):/workspace" \
		$(IMAGE_NAME)

# Start an interactive shell in the container
shell: init
	docker run -it --rm \
		--name $(CONTAINER_NAME)-shell-$$(date +%s)-$$RANDOM \
		-v "$(HOME_DIR):/home/developer" \
		-v "$(PROJECT):/workspace" \
		$(IMAGE_NAME) \
		/bin/bash

# Run smoke tests to verify all tools are installed
test: init
	docker run --rm \
		--name $(CONTAINER_NAME)-test-$$(date +%s)-$$RANDOM \
		-v "$(HOME_DIR):/home/developer" \
		-v "$(CURDIR):/workspace" \
		$(IMAGE_NAME) \
		/workspace/scripts/smoke-test.sh

# Initialize home directory if it doesn't exist
init:
	@mkdir -p "$(HOME_DIR)"
	@mkdir -p "$(HOME_DIR)/go"
	@echo "Home directory ready: $(HOME_DIR)"

# Remove the Docker image
clean:
	docker rmi $(IMAGE_NAME) 2>/dev/null || true

# Show help
help:
	@echo "Dev Container Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build    - Build the Docker image"
	@echo "  make run      - Run container (current dir as workspace)"
	@echo "  make shell    - Start interactive shell in container"
	@echo "  make test     - Run smoke tests"
	@echo "  make init     - Create home directory if needed"
	@echo "  make clean    - Remove the Docker image"
	@echo ""
	@echo "Variables:"
	@echo "  PROJECT=/path/to/project  - Mount a different project as workspace"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make run"
	@echo "  make run PROJECT=/path/to/myproject"
