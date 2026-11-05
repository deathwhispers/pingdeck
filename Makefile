APP_NAME := PingDeck
BUILD_DIR := .build/release
DIST_DIR := dist
APP_BUNDLE := $(DIST_DIR)/$(APP_NAME).app

.PHONY: all build debug run test check app dmg clean

all: build

build:
	swift build -c release

debug:
	swift build

run:
	swift run $(APP_NAME)

test:
	swift test

check: build test

app: build
	bash ./scripts/bundle.sh

dmg: app
	bash ./scripts/dmg.sh

clean:
	rm -rf .build $(DIST_DIR)
