# Makefile for TakeARest - macOS Pomodoro Timer
# Simple, clean build system using Swift Package Manager

.PHONY: help build build-debug clean test run run-debug install dmg bundle

APP_NAME := TakeARest
BUILD_DIR := .build
RELEASE_BIN := $(BUILD_DIR)/release/$(APP_NAME)
DEBUG_BIN := $(BUILD_DIR)/debug/$(APP_NAME)
BUNDLE_DIR := $(BUILD_DIR)/$(APP_NAME).app
DMG_FILE := $(BUILD_DIR)/$(APP_NAME).dmg

# Default target
help:
	@echo "$(APP_NAME) - Pomodoro Timer for macOS"
	@echo ""
	@echo "Available commands:"
	@echo "  make build       Build app (Release mode)"
	@echo "  make build-debug Build app (Debug mode)"
	@echo "  make run         Build and run app (Release)"
	@echo "  make run-debug   Build and run app (Debug)"
	@echo "  make test        Run tests"
	@echo "  make bundle      Create .app bundle"
	@echo "  make dmg         Create DMG installer"
	@echo "  make install     Install to /Applications"
	@echo "  make clean       Clean build artifacts"

# Build release
build:
	@echo "🔨 Building $(APP_NAME) (Release)..."
	@swift build -c release 2>&1 | grep -v "^warning:" || true
	@echo "✅ Build complete"

# Build debug
build-debug:
	@echo "🔨 Building $(APP_NAME) (Debug)..."
	@swift build -c debug
	@echo "✅ Build complete"

# Run release
run: build
	@echo "🚀 Running $(APP_NAME)..."
	@$(RELEASE_BIN)

# Run debug
run-debug: build-debug
	@echo "🚀 Running $(APP_NAME) (Debug)..."
	@$(DEBUG_BIN)

# Run tests
test:
	@echo "🧪 Running tests..."
	@swift test

# Create .app bundle
bundle: build
	@echo "📦 Creating app bundle..."
	@mkdir -p $(BUNDLE_DIR)/Contents/{MacOS,Resources}
	@cp $(RELEASE_BIN) $(BUNDLE_DIR)/Contents/MacOS/$(APP_NAME)
	@chmod +x $(BUNDLE_DIR)/Contents/MacOS/$(APP_NAME)
	@cp -f Sources/TakeARest/Resources/AppIcon.icns $(BUNDLE_DIR)/Contents/Resources/
	@cp -f Sources/TakeARest/Info.plist $(BUNDLE_DIR)/Contents/Info.plist
	@echo "✅ Bundle created: $(BUNDLE_DIR)"

# Create DMG installer
dmg: bundle
	@echo "💿 Creating DMG installer..."
	@if ! command -v create-dmg &> /dev/null; then \
		echo "⚠️  create-dmg not found. Installing..."; \
		brew install create-dmg; \
	fi
	@mkdir -p $(BUILD_DIR)/dmg-temp
	@cp -R $(BUNDLE_DIR) $(BUILD_DIR)/dmg-temp/
	@create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 800 400 \
		--icon-size 100 \
		--icon "$(APP_NAME).app" 200 190 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 600 185 \
		$(DMG_FILE) \
		$(BUILD_DIR)/dmg-temp/
	@rm -rf $(BUILD_DIR)/dmg-temp
	@echo "✅ DMG created: $(DMG_FILE)"

# Clean build
clean:
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf $(BUILD_DIR)
	@echo "✅ Clean complete"

# Install to Applications folder
install: build
	@echo "📥 Installing $(APP_NAME) to /Applications..."
	@mkdir -p /Applications/$(APP_NAME).app/Contents/{MacOS,Resources}
	@cp $(RELEASE_BIN) /Applications/$(APP_NAME).app/Contents/MacOS/
	@chmod +x /Applications/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)
	@echo "✅ Installation complete"
	@echo "   Run: /Applications/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
