-- run.lua
-- Test runner: discovers and runs all *_spec.lua files
-- Usage: lua tests/run.lua

------------------------------------------------------------------------
-- Roblox API stubs so modules that reference Roblox globals can load
-- (only needed for modules that don't actually call them at load time)
------------------------------------------------------------------------

-- Minimal stubs
if not game then
	-- These stubs are intentionally minimal – the MathGenerator module
	-- doesn't use Roblox APIs so they won't be invoked during tests.
	_G.game = setmetatable({}, {
		__index = function()
			return function()
				return {}
			end
		end,
	})
	_G.Color3 = {
		fromRGB = function(r, g, b)
			return { R = r / 255, G = g / 255, B = b / 255 }
		end,
	}
	_G.Enum = setmetatable({}, {
		__index = function()
			return setmetatable({}, {
				__index = function()
					return "STUB"
				end,
			})
		end,
	})
	_G.Instance = {
		new = function()
			return setmetatable({}, {
				__newindex = function() end,
				__index = function()
					return function() end
				end,
			})
		end,
	}
	_G.UDim = {
		new = function(s, o)
			return { Scale = s, Offset = o }
		end,
	}
	_G.UDim2 = {
		new = function(xs, xo, ys, yo)
			return { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo } }
		end,
	}
	_G.Vector2 = {
		new = function(x, y)
			return { X = x, Y = y }
		end,
	}
end

------------------------------------------------------------------------
-- Set up the Lua path so require("src.shared.X") works
------------------------------------------------------------------------

local projectRoot = "."
package.path = projectRoot .. "/?.lua;" .. projectRoot .. "/?/init.lua;" .. package.path

------------------------------------------------------------------------
-- Run tests
------------------------------------------------------------------------

local T = require("tests.TestFramework")

print("")
print(
	"╔═══════════════════════════════════════╗"
)
print("║       BRAIN BLITZ — TEST SUITE        ║")
print(
	"╚═══════════════════════════════════════╝"
)

-- Load all spec files
require("tests.MathGenerator_spec")

-- Print summary and exit
local allPassed = T.summary()

if allPassed then
	print("All tests passed! ✓\n")
	os.exit(0)
else
	print("Some tests failed! ✗\n")
	os.exit(1)
end
