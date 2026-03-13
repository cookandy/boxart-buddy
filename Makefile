# Name of your project
PROJECT_NAME := boxartbuddy
VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo 1.1.1)
DIST_NAME := $(PROJECT_NAME)-$(VERSION)
CONTENT_DIR := BoxartBuddy
DIST_DIR := dist
ZIP_FILE := $(DIST_DIR)/$(DIST_NAME).muxapp
DISTIGNORE := .distignore
DEVICE_IP := 192.168.1.181

.PHONY: dist clean deploy

dist:
	@echo "Creating distribution..."
	@rm -rf $(DIST_DIR)
	@mkdir -p $(DIST_DIR)
	@rsync -a . $(DIST_DIR)/$(CONTENT_DIR) \
		--exclude-from=$(DISTIGNORE) \
		--exclude=$(DIST_DIR) \
		--delete-excluded
	@mkdir -p $(DIST_DIR)/$(CONTENT_DIR)/glyph
	@cp ./boxart-buddy/assets/image/glyph.png $(DIST_DIR)/$(CONTENT_DIR)/glyph/boxartbuddy.png
	@mkdir -p $(DIST_DIR)/$(CONTENT_DIR)/grid/640x480 \
		$(DIST_DIR)/$(CONTENT_DIR)/grid/720x480 \
		$(DIST_DIR)/$(CONTENT_DIR)/grid/720x576 \
		$(DIST_DIR)/$(CONTENT_DIR)/grid/720x720 \
		$(DIST_DIR)/$(CONTENT_DIR)/grid/1024x768 \
		$(DIST_DIR)/$(CONTENT_DIR)/grid/1280x720
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_120.png $(DIST_DIR)/$(CONTENT_DIR)/grid/boxartbuddy.png
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_120.png $(DIST_DIR)/$(CONTENT_DIR)/grid/640x480/boxartbuddy.png
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_120.png $(DIST_DIR)/$(CONTENT_DIR)/grid/720x480/boxartbuddy.png
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_140.png $(DIST_DIR)/$(CONTENT_DIR)/grid/720x576/boxartbuddy.png
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_140.png $(DIST_DIR)/$(CONTENT_DIR)/grid/720x720/boxartbuddy.png
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_204.png $(DIST_DIR)/$(CONTENT_DIR)/grid/1024x768/boxartbuddy.png
	@cp ./boxart-buddy/assets/image/grid/boxartbuddy_204.png $(DIST_DIR)/$(CONTENT_DIR)/grid/1280x720/boxartbuddy.png
	@cd $(DIST_DIR) && zip -r $(DIST_NAME).muxapp .
	@rm -rf $(DIST_DIR)/$(CONTENT_DIR)
	@echo "Created $(ZIP_FILE)"

clean:
	rm -rf $(DIST_DIR)

deploy:
	@sshpass -p 'root' scp $(ZIP_FILE) root@$(DEVICE_IP):/mnt/mmc/ARCHIVE
	@echo "Deployed to $(DEVICE_IP):/mnt/mmc/ARCHIVE"

all: clean dist