# Makefile for marklip-launcher

PRODUCT_NAME = marklip-launcher
BUNDLE_NAME = Marklip Launcher.app
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
BUNDLE_PATH = $(RELEASE_DIR)/$(BUNDLE_NAME)
INSTALL_DIR = $(HOME)/Applications

.PHONY: build clean install uninstall run debug

build:
	./Scripts/bundle-app.sh
	codesign --force --deep --sign - "$(BUNDLE_PATH)"

clean:
	swift package clean
	rm -rf "$(BUNDLE_PATH)"

install: build
	mkdir -p $(INSTALL_DIR)
	rm -rf "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	cp -R "$(BUNDLE_PATH)" "$(INSTALL_DIR)/"

uninstall:
	rm -rf "$(INSTALL_DIR)/$(BUNDLE_NAME)"

run: build
	open "$(BUNDLE_PATH)"

debug:
	swift build
	$(BUILD_DIR)/debug/$(PRODUCT_NAME)
