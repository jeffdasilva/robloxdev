# ⚡ Math Streak

A daily math challenge game for Roblox. Every day, players get a new 8th-grade-level math question to solve. They have **5 attempts** per day, and the game tracks their **longest streak** of consecutive correct days on a global **leaderboard**.

Built entirely in Lua with [Rojo](https://rojo.space/) for source-code-first development.

---

## Features

- **Daily Question** — A new math question every day (same for all players), covering algebra, exponents, square roots, percentages, geometry, order of operations, GCF, ratios, and more.
- **5 Attempts** — Players get 5 tries each day. Solving it continues the streak; running out of attempts breaks it.
- **Streak Tracking** — Current streak and best streak are saved per player using Roblox DataStores.
- **Global Leaderboard** — Shows top players ranked by their best streak, with gold/silver/bronze medals.
- **Hints** — Each question comes with a hint that players can reveal if they're stuck.
- **Modern UI** — Dark-themed, vibrant colors, smooth animations, fun emojis — designed for kids.
- **Deterministic** — Questions are generated from the date using a seeded PRNG, so every player gets the same question on the same day.

---

## Project Structure

```
robloxdev/
├── Makefile                      # Build, test, lint, format commands
├── README.md                     # This file
├── default.project.json          # Rojo project configuration
├── aftman.toml                   # Tool version management (Rojo, StyLua, Selene)
├── stylua.toml                   # StyLua formatter configuration
├── selene.toml                   # Selene linter configuration
├── .gitignore
│
├── src/
│   ├── shared/                   # → ReplicatedStorage/MathStreak
│   │   ├── Config.lua            # Game-wide constants (colors, fonts, remotes, limits)
│   │   ├── MathGenerator.lua     # Pure math question generation (no Roblox APIs)
│   │   └── Remotes.lua           # RemoteEvent/Function setup and access
│   │
│   ├── server/                   # → ServerScriptService/MathStreak
│   │   ├── init.server.lua       # Server entry point
│   │   ├── DailyMathService.lua  # Core game logic (attempts, streaks, remote handlers)
│   │   └── PlayerDataStore.lua   # DataStore wrapper for player persistence
│   │
│   ├── client/                   # → StarterPlayer/StarterPlayerScripts/MathStreak
│   │   ├── init.client.lua       # Client entry point
│   │   ├── QuestionUI.lua        # Main question panel UI (input, submit, feedback)
│   │   ├── LeaderboardUI.lua     # Leaderboard panel UI (toggle, scrolling list)
│   │   └── UIComponents.lua      # Reusable UI helpers (corners, strokes, panels, buttons)
│   │
│   └── gui/                      # → StarterGui/MathStreakGui
│       └── init.meta.json        # ScreenGui properties
│
└── tests/
    ├── run.lua                   # Test runner (entry point for `make test`)
    ├── TestFramework.lua         # Minimal describe/it/expect test framework
    └── MathGenerator_spec.lua    # 16 unit tests for the math generator
```

### How the Code Fits Together

#### Shared Layer (`src/shared/`)

- **`Config.lua`** — Central configuration: max attempts (5), DataStore keys, UI colors (dark purple/violet theme), font choices, and remote event/function names. Both server and client import this.
- **`MathGenerator.lua`** — The heart of the game. Uses a deterministic linear congruential generator (LCG) seeded from the date (`year * 10000 + month * 100 + day`) so every player gets the same question. Contains 12 question generators covering: linear equations, exponents, square roots, percentages, rectangle area, order of operations (PEMDAS), greatest common factor, ratios, parenthesized expressions, triangle perimeter, distributive property, and negative number arithmetic. This module is **pure math** with no Roblox dependencies, making it fully testable outside Roblox.
- **`Remotes.lua`** — Creates RemoteFunction/RemoteEvent instances in ReplicatedStorage on the server side, and provides a `get(name)` accessor used by both server and client.

#### Server Layer (`src/server/`)

- **`DailyMathService.lua`** — The server-side service that:
  - Loads player data on join, caches it in memory, and saves on leave and periodically (every 2 min).
  - Resets daily state (attempts, solved flag) when the date changes.
  - Checks streak continuity — if the player didn't complete yesterday's question, the streak resets.
  - Handles `GetDailyQuestion`, `SubmitAnswer`, `GetPlayerData`, and `GetLeaderboard` remote invocations.
  - Updates the OrderedDataStore leaderboard whenever a player achieves a new best streak.
- **`PlayerDataStore.lua`** — Wraps Roblox DataStoreService. Stores per-player: `currentStreak`, `bestStreak`, `lastCompletedDate`, `attemptsUsed`, `todayQuestionId`, `todaySolved`. Also manages the OrderedDataStore for the global leaderboard.

#### Client Layer (`src/client/`)

- **`QuestionUI.lua`** — Builds the full-screen dark UI with:
  - A title banner ("⚡ MATH STREAK ⚡")
  - A streak counter (top right, with fire emoji)
  - A question card with category badge, question text, answer input, submit button, feedback text, attempt dots, and a hint toggle
  - Animations: cards slide in, correct answers pulse, wrong answers shake the input
  - Auto-locks when solved or out of attempts
- **`LeaderboardUI.lua`** — A toggleable side panel showing the top streaks with 🥇🥈🥉 medals, player names, and streak counts. The current player's row is highlighted. Data is fetched from the server on toggle.
- **`UIComponents.lua`** — Reusable factory functions for creating rounded panels, buttons, corner radii, strokes, gradients, shadows, and padding.

#### Tests (`tests/`)

- **`TestFramework.lua`** — A self-contained `describe`/`it`/`expect` framework that runs on standard Lua 5.1. Uses closure-based `expect()` for dot-notation calls (e.g., `expect(x).toBe(y)`). Provides colored terminal output.
- **`MathGenerator_spec.lua`** — 16 tests covering:
  - Question structure validation (required fields, types)
  - Determinism (same date → same question)
  - Variety (different dates → different questions)
  - Answer checking (correct, incorrect, floating-point tolerance)
  - LCG determinism and range bounds
  - Date seed uniqueness
  - All 12 generators produce valid output
  - Category variety over 30 days
  - Integer answer prevalence

---

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [aftman](https://github.com/LPGhatguy/aftman) | Tool version manager | `cargo install aftman` |
| [Rojo](https://rojo.space/) 7.4+ | Sync Lua code → Roblox | `aftman install` (auto) |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | Lua formatter | `aftman install` (auto) |
| [Selene](https://kampfkarren.github.io/selene/) | Lua linter | `aftman install` (auto) |
| [Lua 5.1](https://www.lua.org/) | Run unit tests locally | `sudo apt-get install lua5.1` |
| [Roblox Studio](https://www.roblox.com/create) | Open/publish the game | Roblox website |
| Rojo Studio Plugin | Connect Studio to Rojo | Install from Roblox plugin marketplace |

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/jeffdasilva/robloxdev.git
cd robloxdev

# 2. Install tools
make setup

# 3. Run all checks (lint + format + tests)
make check

# 4. Build the Roblox place file
make build
```

---

## Makefile Commands

| Command | What it does |
|---------|--------------|
| `make help` | Show all available commands |
| `make check` | Run linter + format check + unit tests |
| `make test` | Run unit tests only |
| `make lint` | Run Selene linter on `src/` |
| `make format` | Auto-format all Lua files with StyLua |
| `make format-check` | Check formatting without modifying files |
| `make build` | Build `MathStreak.rbxlx` with Rojo |
| `make serve` | Start Rojo live-sync server |
| `make update` | Run all checks + build the place file |
| `make setup` | Install/verify all required tools |
| `make clean` | Remove build artifacts |

---

## Development Workflow

### Live development with Rojo

The recommended workflow uses Rojo's live-sync feature:

1. **Start the Rojo server:**
   ```bash
   make serve
   ```

2. **Open Roblox Studio** and create a new place (or open an existing one).

3. **Connect via the Rojo plugin:**
   - Install the Rojo plugin from the Roblox plugin marketplace (search "Rojo").
   - Click the Rojo plugin button in Studio.
   - Click "Connect" to sync your local code into Studio.

4. **Edit code in your editor** — changes appear in Studio in real-time.

5. **Press Play in Studio** to test the game.

### Testing locally

The `MathGenerator` module is written without Roblox dependencies, so it can be tested with standard Lua 5.1:

```bash
make test
```

This runs 16 tests covering question generation, answer checking, determinism, and variety.

### Before committing

```bash
make check
```

This runs the linter (Selene), checks formatting (StyLua), and runs all unit tests.

---

## Publishing to Roblox

### Option A: Build + Open in Studio

```bash
make build
```

This creates `MathStreak.rbxlx`. Open it in Roblox Studio and use **File → Publish to Roblox**.

### Option B: Live-sync + Publish from Studio

```bash
make serve
```

Connect from Studio with the Rojo plugin, then **File → Publish to Roblox**.

### Important: Enable DataStores

After publishing, you need to enable API services for DataStores to work:

1. Go to your game's page on the Roblox website.
2. Click **Configure** → **Security**.
3. Enable **"Allow HTTP Requests"** and **"Enable Studio Access to API Services"**.

---

## How the Daily Question Works

1. The date (UTC) is converted to a seed: `year × 10000 + month × 100 + day`.
2. The seed drives a deterministic LCG (linear congruential generator).
3. A question type is selected from 12 generators (based on `seed % 12`).
4. The chosen generator uses the LCG to produce randomized parameters.
5. Since the seed is date-based, **all players get the same question on the same day**.

### Question Categories

| # | Category | Example |
|---|----------|---------|
| 1 | Algebra | Solve for x: 5x + 3 = 28 |
| 2 | Exponents | What is 4^3? |
| 3 | Square Roots | What is √144? |
| 4 | Percentages | What is 30% of 150? |
| 5 | Geometry (Area) | Rectangle 7×12, what's the area? |
| 6 | Order of Operations | 8 + 3 × 5 |
| 7 | Number Theory (GCF) | GCF of 24 and 36? |
| 8 | Ratios | If 3:4 = 9:?, find ? |
| 9 | Order of Operations | (6 + 4) × 3 − 7 |
| 10 | Geometry (Perimeter) | Triangle with sides 5, 8, 10 |
| 11 | Algebra (Distributive) | 4(3 + 7) |
| 12 | Integers | 5 − (−3) |

---

## License

MIT
