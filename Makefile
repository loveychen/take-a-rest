# Makefile for TakeARest macOS Swift Project
# 使用 Swift Package Manager (SPM) 完成编译、测试和运行
# 不需要完整的 Xcode 安装，只需要 Command Line Tools

# 项目配置
APP_NAME = TakeARest
BUILD_DIR = ./.build
EXECUTABLE_PATH = ./.build/release/$(APP_NAME)

# 默认目标
.PHONY: all
all: build

# 编译项目（Release 模式）
.PHONY: build
build:
	swift build -c release

# 编译项目（Debug 模式）
.PHONY: build-debug
build-debug:
	swift build -c debug

# 运行所有测试
.PHONY: test
test:
	swift test

# 清理构建产物
.PHONY: clean
clean:
	swift package clean
	rm -rf $(BUILD_DIR)
	rm -rf ./.build

# 运行应用（Release 模式）
.PHONY: run
run:
	@make build
	./$(EXECUTABLE_PATH)

# 运行应用（Debug 模式）
.PHONY: run-debug
run-debug:
	@make build-debug
	./.build/debug/$(APP_NAME)

# 显示项目信息
.PHONY: info
info:
	@echo "项目名称: $(APP_NAME)"
	@echo "可执行文件路径: $(EXECUTABLE_PATH)"
	@echo "构建目录: $(BUILD_DIR)"
	@echo "可用命令:"
	@echo "  make build       - 编译项目 (Release)"
	@echo "  make build-debug - 编译项目 (Debug)"
	@echo "  make test        - 运行所有测试"
	@echo "  make run         - 编译并运行应用 (Release)"
	@echo "  make run-debug   - 编译并运行应用 (Debug)"
	@echo "  make clean       - 清理构建产物"
	@echo "  make info        - 显示项目信息"

# 创建应用程序包
.PHONY: bundle
bundle:
	@make build
	@mkdir -p $(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(APP_NAME).app/Contents/Resources
	@cp -f $(EXECUTABLE_PATH) $(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/
	@# 复制图标文件
	@cp -f Sources/$(APP_NAME)/Resources/TakeARestIcon.icns $(BUILD_DIR)/$(APP_NAME).app/Contents/Resources/
	@# 创建Info.plist文件
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<plist version="1.0">' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '<dict>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleIdentifier</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>com.example.TakeARest</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleName</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>$(APP_NAME)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleExecutable</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>$(APP_NAME)</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleVersion</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>1.0</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleShortVersionString</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>1.0</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>LSMinimumSystemVersion</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>13.0</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleInfoDictionaryVersion</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>6.0</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundlePackageType</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>APPL</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<key>CFBundleIconFile</key>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '\t<string>TakeARestIcon</string>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '</dict>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo '</plist>' >> $(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist
	@echo "应用程序包已创建: $(BUILD_DIR)/$(APP_NAME).app"

# 创建DMG安装包
.PHONY: dmg
dmg:
	@make bundle
	@echo "正在创建干净的DMG安装包..."
	@# 创建临时目录
	@mkdir -p $(BUILD_DIR)/dmg_temp
	@# 复制应用程序到临时目录
	@cp -R $(BUILD_DIR)/$(APP_NAME).app $(BUILD_DIR)/dmg_temp/
	@# 在临时目录中创建Applications文件夹的软链接
	@ln -s /Applications $(BUILD_DIR)/dmg_temp/Applications
	@# 使用create-dmg命令创建DMG
	@create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 800 400 \
		--icon-size 100 \
		--icon "$(APP_NAME).app" 200 190 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 600 185 \
		$(BUILD_DIR)/$(APP_NAME).dmg \
		$(BUILD_DIR)/dmg_temp/
	@# 清理临时目录
	@rm -rf $(BUILD_DIR)/dmg_temp
	@echo "DMG安装包已创建: $(BUILD_DIR)/$(APP_NAME).dmg"

# 更新依赖
.PHONY: update
update:
	swift package update
