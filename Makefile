# Makefile for marklip-launcher

PRODUCT_NAME = marklip-launcher
BUILD_DIR = .build
INSTALL_DIR = /usr/local/bin

.PHONY: build clean install uninstall run debug

build:
	swift build -c release

clean:
	swift package clean

install: build
	mkdir -p $(INSTALL_DIR)
	cp $(BUILD_DIR)/release/$(PRODUCT_NAME) $(INSTALL_DIR)/
	chmod +x $(INSTALL_DIR)/$(PRODUCT_NAME)

uninstall:
	rm -f $(INSTALL_DIR)/$(PRODUCT_NAME)

run: build
	$(BUILD_DIR)/release/$(PRODUCT_NAME)

debug:
	swift build
	$(BUILD_DIR)/debug/$(PRODUCT_NAME)
