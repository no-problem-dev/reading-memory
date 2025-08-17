.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make ios-build       - Build iOS app for simulator"
	@echo "  make ios-build-device - Build iOS app for device"
	@echo "  make ios-clean       - Clean iOS build artifacts"
	@echo "  make ios-run         - Build and run iOS app in simulator"

.PHONY: ios-build
ios-build:
	xcodebuild -project reading-memory-ios/reading-memory-ios.xcodeproj -scheme reading-memory-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug build

.PHONY: ios-build-device
ios-build-device:
	xcodebuild -project reading-memory-ios/reading-memory-ios.xcodeproj -scheme reading-memory-ios -sdk iphoneos -configuration Debug build

.PHONY: ios-clean
ios-clean:
	xcodebuild -project reading-memory-ios/reading-memory-ios.xcodeproj -scheme reading-memory-ios clean

.PHONY: ios-run
ios-run:
	xcodebuild -project reading-memory-ios/reading-memory-ios.xcodeproj -scheme reading-memory-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug build
	xcrun simctl boot "iPhone 15 Pro" || true
	open -a Simulator
	xcodebuild -project reading-memory-ios/reading-memory-ios.xcodeproj -scheme reading-memory-ios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug install