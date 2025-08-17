# Reading Memory Makefile
# Cloud Functions operations

.PHONY: help install build lint deploy functions-serve functions-logs clean

# Default target
help:
	@echo "Reading Memory - Cloud Functions Commands"
	@echo "========================================"
	@echo "make install        - Install dependencies"
	@echo "make build          - Build TypeScript"
	@echo "make lint           - Run ESLint"
	@echo "make deploy         - Deploy to Firebase"
	@echo "make functions-serve - Run local emulator"
	@echo "make functions-logs  - View function logs"
	@echo "make clean          - Clean build files"

# Install dependencies
install:
	@echo "Installing Cloud Functions dependencies..."
	cd functions && npm install

# Build TypeScript
build:
	@echo "Building Cloud Functions..."
	cd functions && npm run build

# Run linter
lint:
	@echo "Running ESLint..."
	cd functions && npx eslint src --ext .ts

# Deploy functions
deploy: build
	@echo "Deploying Cloud Functions to Firebase..."
	firebase deploy --only functions

# Run local emulator
functions-serve: build
	@echo "Starting Firebase emulator..."
	cd functions && npm run serve

# View logs
functions-logs:
	@echo "Fetching Cloud Functions logs..."
	firebase functions:log

# Clean build artifacts
clean:
	@echo "Cleaning build files..."
	rm -rf functions/lib
	@echo "Clean complete!"

# Combined commands
all: install lint build
	@echo "All tasks completed!"

# Deploy with pre-checks
safe-deploy: install lint build deploy
	@echo "Safe deployment completed!"