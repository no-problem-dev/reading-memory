# Reading Memory iOS Project Makefile

# Default destination for iOS Simulator
DESTINATION = platform=iOS Simulator,id=AFE6EC08-FC0C-4CD1-AEB7-2263DACB021B
PROJECT = reading-memory-ios.xcodeproj
SCHEME = reading-memory-ios

# Build the project
.PHONY: build
build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build

# Build and extract errors efficiently
.PHONY: build-check
build-check:
	@echo "Building project and extracting errors..."
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build 2>&1 | tee build.log
	@echo "\n=== BUILD ERRORS ==="
	@grep -E "(error:|warning:)" build.log | head -20 || echo "No errors found"

# Quick error check without full build log
.PHONY: errors
errors:
	@echo "Checking for build errors..."
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build 2>&1 | grep -E "(error:|warning:)" | head -10 || echo "No errors found"

# Clean build
.PHONY: clean
clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -f build.log

# List available iOS simulators
.PHONY: simulators
simulators:
	xcrun simctl list devices available

# Run tests (when implemented)
.PHONY: test
test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' test

# Build for release
.PHONY: release
release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release build

# Format code (if swiftformat is available)
.PHONY: format
format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat reading-memory-ios/; \
	else \
		echo "swiftformat not installed. Install with: brew install swiftformat"; \
	fi

# Lint code (if swiftlint is available)
.PHONY: lint
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint reading-memory-ios/; \
	else \
		echo "swiftlint not installed. Install with: brew install swiftlint"; \
	fi

# Help
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  build        - Build the project"
	@echo "  build-check  - Build and show detailed error log"
	@echo "  errors       - Quick error check"
	@echo "  clean        - Clean build artifacts"
	@echo "  simulators   - List available iOS simulators"
	@echo "  test         - Run tests"
	@echo "  release      - Build for release"
	@echo "  format       - Format Swift code (requires swiftformat)"
	@echo "  lint         - Lint Swift code (requires swiftlint)"
	@echo "  help         - Show this help"