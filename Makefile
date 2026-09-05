SHELL := /bin/bash
.DEFAULT_GOAL := help

# Local tooling lives in $HOME/go/bin (golangci-lint); .env supplies ADMIN_PASSWORD etc.
export PATH := $(PATH):$(HOME)/go/bin
-include .env
export

GO_DIR  := backend
WEB_DIR := frontend
DEV_API_BASE ?= http://localhost:8080
DEV_WEB_ORIGIN ?= http://localhost:3000

GEN_FILES := find $(WEB_DIR)/lib \( -name '*.g.dart' -o -name '*.freezed.dart' -o -path '*/l10n/app_localizations*.dart' \) -type f | sort

.PHONY: help dev-api dev-web gen check-gen lint test test-engine build up down logs bots loadtest

help: ## list targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-12s %s\n", $$1, $$2}'

dev-api: ## run the Go API locally
	cd $(GO_DIR) && DATA_DIR=$${DATA_DIR:-./data} DEV_CORS_ORIGIN=$(DEV_WEB_ORIGIN) LOG_FORMAT=text LOG_LEVEL=$${LOG_LEVEL:-debug} go run ./cmd/server

dev-web: ## run the Flutter web app in Chrome against the local API
	cd $(WEB_DIR) && flutter run -d chrome --web-port 3000 --dart-define=API_BASE=$(DEV_API_BASE)

gen: ## regenerate freezed/json_serializable models and l10n
	cd $(WEB_DIR) && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n

check-gen: ## fail when generated Dart files are stale
	@before=$$($(GEN_FILES) | xargs shasum -a 256 2>/dev/null); \
	$(MAKE) --no-print-directory gen >/dev/null; \
	after=$$($(GEN_FILES) | xargs shasum -a 256 2>/dev/null); \
	if [ "$$before" != "$$after" ]; then \
		echo "generated files are stale: run 'make gen' and check in the result"; \
		diff <(echo "$$before") <(echo "$$after") || true; \
		exit 1; \
	fi; \
	echo "generated files are up to date"

lint: ## gofmt, go vet, golangci-lint, dart format, flutter analyze
	@cd $(GO_DIR) && out=$$(gofmt -l .) && if [ -n "$$out" ]; then echo "gofmt: needs formatting:"; echo "$$out"; exit 1; fi
	cd $(GO_DIR) && go vet ./...
	cd $(GO_DIR) && golangci-lint run ./...
	cd $(WEB_DIR) && dart format --set-exit-if-changed lib test
	cd $(WEB_DIR) && flutter analyze --fatal-infos

test: ## go test -race and flutter test
	cd $(GO_DIR) && go test -race ./...
	cd $(WEB_DIR) && flutter test

test-engine: ## engine tests with coverage report (internal/poker)
	mkdir -p $(GO_DIR)/bin
	cd $(GO_DIR) && go test -race -coverprofile=bin/poker.cover ./internal/poker/... && go tool cover -func=bin/poker.cover | tail -1

# Building from source uses the build override; IMAGE_OWNER only names the tags.
COMPOSE_BUILD = IMAGE_OWNER=$${IMAGE_OWNER:-local} docker compose -f docker-compose.yml -f deploy/docker-compose.build.yml

build: ## build both images from source
	$(COMPOSE_BUILD) build

up: ## build from source and start the stack in the background
	$(COMPOSE_BUILD) up -d --build

down: ## stop the stack (keeps the data volume)
	docker compose down

logs: ## follow container logs
	docker compose logs -f --tail=200

BOT_SERVER ?= http://localhost:8080
BOT_COUNT ?= 6
bots: ## run test bots: make bots TABLE=<id> [PASSWORD=<pw>] [BOT_COUNT=6] [BOT_SERVER=http://localhost:8080]
	@test -n "$(TABLE)" || { echo "usage: make bots TABLE=<id> [PASSWORD=<pw>]"; exit 1; }
	cd $(GO_DIR) && go run ./cmd/bot -server $(BOT_SERVER) -table $(TABLE) -password "$(PASSWORD)" -count $(BOT_COUNT)

LOAD_SERVER ?= http://localhost:18080
LOAD_TABLES ?= 20
LOAD_BOTS ?= 9
LOAD_DURATION ?= 60s
loadtest: ## load test against the api published by deploy/docker-compose.loadtest.yml
	cd $(GO_DIR) && go run ./cmd/loadtest -server $(LOAD_SERVER) -tables $(LOAD_TABLES) -bots $(LOAD_BOTS) -duration $(LOAD_DURATION)
