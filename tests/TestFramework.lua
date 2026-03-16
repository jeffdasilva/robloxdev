-- TestFramework.lua
-- Minimal test framework that runs under standard Lua 5.1
-- Provides describe/it/expect pattern similar to TestEZ

local TestFramework = {}

local totalPassed = 0
local totalFailed = 0
local totalSuites = 0
local failedTests = {}

local colors = {
	green = "\27[32m",
	red = "\27[31m",
	yellow = "\27[33m",
	cyan = "\27[36m",
	reset = "\27[0m",
	bold = "\27[1m",
}

local function printColored(color, text)
	io.write(color .. text .. colors.reset)
end

------------------------------------------------------------------------
-- Expect (assertion builder using closures for dot-notation calls)
------------------------------------------------------------------------

local function makeExpect(value)
	local e = {}

	function e.toBe(expected)
		if value ~= expected then
			error(string.format("Expected %s to be %s", tostring(value), tostring(expected)), 2)
		end
	end

	function e.toEqual(expected)
		if value ~= expected then
			error(string.format("Expected %s to equal %s", tostring(value), tostring(expected)), 2)
		end
	end

	function e.toBeCloseTo(expected, tolerance)
		tolerance = tolerance or 0.001
		if math.abs(value - expected) > tolerance then
			error(
				string.format(
					"Expected %s to be close to %s (tolerance %s)",
					tostring(value),
					tostring(expected),
					tostring(tolerance)
				),
				2
			)
		end
	end

	function e.toBeTruthy()
		if not value then
			error(string.format("Expected %s to be truthy", tostring(value)), 2)
		end
	end

	function e.toBeFalsy()
		if value then
			error(string.format("Expected %s to be falsy", tostring(value)), 2)
		end
	end

	function e.toBeNil()
		if value ~= nil then
			error(string.format("Expected %s to be nil", tostring(value)), 2)
		end
	end

	function e.toBeGreaterThan(expected)
		if value <= expected then
			error(string.format("Expected %s to be greater than %s", tostring(value), tostring(expected)), 2)
		end
	end

	function e.toBeLessThan(expected)
		if value >= expected then
			error(string.format("Expected %s to be less than %s", tostring(value), tostring(expected)), 2)
		end
	end

	function e.toBeType(expectedType)
		if type(value) ~= expectedType then
			error(string.format("Expected type %s but got %s", expectedType, type(value)), 2)
		end
	end

	function e.toContain(substring)
		if type(value) ~= "string" then
			error("toContain expects a string value", 2)
		end
		if not string.find(value, substring, 1, true) then
			error(string.format('Expected "%s" to contain "%s"', value, substring), 2)
		end
	end

	return e
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

function TestFramework.expect(value)
	return makeExpect(value)
end

function TestFramework.describe(suiteName, fn)
	totalSuites = totalSuites + 1
	printColored(colors.cyan, "\n● " .. suiteName .. "\n")
	fn()
end

function TestFramework.it(testName, fn)
	local success, err = pcall(fn)
	if success then
		totalPassed = totalPassed + 1
		printColored(colors.green, "  ✓ ")
		print(testName)
	else
		totalFailed = totalFailed + 1
		printColored(colors.red, "  ✗ ")
		print(testName)
		printColored(colors.red, "    → " .. tostring(err) .. "\n")
		table.insert(failedTests, { suite = "", name = testName, error = tostring(err) })
	end
end

function TestFramework.summary()
	print("")
	printColored(
		colors.bold,
		"─────────────────────────────────────────\n"
	)
	printColored(colors.cyan, string.format("  Suites: %d\n", totalSuites))
	printColored(colors.green, string.format("  Passed: %d\n", totalPassed))

	if totalFailed > 0 then
		printColored(colors.red, string.format("  Failed: %d\n", totalFailed))
	else
		printColored(colors.green, string.format("  Failed: %d\n", totalFailed))
	end

	printColored(
		colors.bold,
		"─────────────────────────────────────────\n"
	)

	if totalFailed > 0 then
		printColored(colors.red, "\n  FAILED TESTS:\n")
		for _, ft in ipairs(failedTests) do
			printColored(colors.red, "  • " .. ft.name .. "\n")
			printColored(colors.yellow, "    " .. ft.error .. "\n")
		end
		print("")
	end

	return totalFailed == 0
end

function TestFramework.reset()
	totalPassed = 0
	totalFailed = 0
	totalSuites = 0
	failedTests = {}
end

return TestFramework
