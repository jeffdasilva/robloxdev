.PHONY: help check test lint format build serve update clean setup

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

build: ## Build a .rbxlx place file from source
	@echo "🔨 Building Roblox place file..."
	@$(ROJO) build -o MathStreak.rbxlx
	@echo "Built MathStreak.rbxlx"

serve: ## Start Rojo live-sync server (connect from Roblox Studio)
	@echo "🚀 Starting Rojo server..."
	@echo "   Open Roblox Studio and connect with the Rojo plugin."
	@$(ROJO) serve

update: check build ## Run all checks, then build the Roblox place file
	@echo ""
	@echo "✅ All checks passed and MathStreak.rbxlx is up to date."
	@echo "   To publish:"
	@echo "   1. Open MathStreak.rbxlx in Roblox Studio"
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
	@rm -f MathStreak.rbxlx MathStreak.rbxl
	@echo "Done!"
