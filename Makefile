.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make ios-build       - Build iOS app for simulator"
	@echo "  make ios-build-device - Build iOS app for device"
	@echo "  make ios-clean       - Clean iOS build artifacts"
	@echo "  make ios-run         - Build and run iOS app in simulator"

.PHONY: ios-build
ios-build:
	cd reading-memory-ios && xcodebuild -scheme reading-memory-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug build

.PHONY: ios-build-device
ios-build-device:
	cd reading-memory-ios && xcodebuild -scheme reading-memory-ios -sdk iphoneos -configuration Debug build

.PHONY: ios-clean
ios-clean:
	cd reading-memory-ios && xcodebuild -scheme reading-memory-ios clean

.PHONY: ios-run
ios-run:
	cd reading-memory-ios && xcodebuild -scheme reading-memory-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug build
	xcrun simctl boot "iPhone 15 Pro" || true
	open -a Simulator
	cd reading-memory-ios && xcodebuild -scheme reading-memory-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug install