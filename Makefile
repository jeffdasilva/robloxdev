.PHONY: help check test lint format build serve update clean setup stamp-version

# Default target
help: ## Show this help message
	@echo ""
	@echo "  ⚡ MATH STREAK — Development Commands"
	@echo "  ─────────────────────────────────────────"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─────────────────────────────────────────
# Tool paths
# ─────────────────────────────────────────

STYLUA  := StyLua
SELENE  := selene
ROJO    := rojo
LUA     := lua

# Version info (auto-generated at build time)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "0.1.0")
BUILD_TIME := $(shell date -u '+%Y-%m-%d %H:%M UTC')
CONFIG_FILE := src/shared/Config.lua

# ─────────────────────────────────────────
# Quality & Testing
# ─────────────────────────────────────────

check: lint format-check test ## Run all checks (lint + format check + tests)

test: ## Run unit tests
	@echo "🧪 Running unit tests..."
	@$(LUA) tests/run.lua

lint: ## Run selene linter on source code
	@echo "🔍 Running selene linter..."
	@$(SELENE) src/

format: ## Auto-format all Lua files with StyLua
	@echo "✨ Formatting with StyLua..."
	@$(STYLUA) src/ tests/
	@echo "Done!"

format-check: ## Check formatting without modifying files
	@echo "📐 Checking formatting..."
	@$(STYLUA) --check src/ tests/

# ─────────────────────────────────────────
# Rojo / Roblox
# ─────────────────────────────────────────

build: stamp-version ## Build a .rbxlx place file from source
	@echo "🔨 Building Roblox place file..."
	@$(ROJO) build -o BrainBlitz.rbxlx
	@echo "Built BrainBlitz.rbxlx  ($(VERSION) @ $(BUILD_TIME))"

serve: stamp-version ## Start Rojo live-sync server (connect from Roblox Studio)
	@echo "🚀 Starting Rojo server ($(VERSION) @ $(BUILD_TIME))..."
	@echo "   Open Roblox Studio and connect with the Rojo plugin."
	@$(ROJO) serve

stamp-version: ## Stamp version and build time into Config.lua
	@sed -i 's/Config.VERSION = "[^"]*"/Config.VERSION = "$(VERSION)"/' $(CONFIG_FILE)
	@sed -i 's/Config.BUILD_TIME = "[^"]*"/Config.BUILD_TIME = "$(BUILD_TIME)"/' $(CONFIG_FILE)
	@echo "📌 Version: $(VERSION) | Build: $(BUILD_TIME)"

update: check build ## Run all checks, then build the Roblox place file
	@echo ""
	@echo "✅ All checks passed and BrainBlitz.rbxlx is up to date."
	@echo "   To publish:"
	@echo "   1. Open BrainBlitz.rbxlx in Roblox Studio"
	@echo "   2. File → Publish to Roblox"
	@echo ""
	@echo "   Or use 'make serve' for live-sync development."

# ─────────────────────────────────────────
# Setup
# ─────────────────────────────────────────

setup: ## Install all required tools via aftman
	@echo "📦 Installing tools..."
	@aftman install
	@echo ""
	@echo "Verifying installations..."
	@$(ROJO) --version
	@$(STYLUA) --version
	@$(SELENE) --version
	@$(LUA) -v 2>&1 || echo "⚠️  Lua 5.1 not found. Install with: sudo apt-get install lua5.1"
	@echo ""
	@echo "✅ Setup complete!"

# ─────────────────────────────────────────
# Clean
# ─────────────────────────────────────────

clean: ## Remove build artifacts
	@echo "🧹 Cleaning..."
	@rm -f BrainBlitz.rbxlx BrainBlitz.rbxl
	@echo "Done!"
