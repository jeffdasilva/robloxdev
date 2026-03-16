-- MathGenerator.lua
-- Generates daily math questions at an 8th-grade level
-- Deterministic: the same date always produces the same question
-- Question types: linear equations, exponents, square roots, percentages,
--   ratios, geometry (area/perimeter), order of operations, simple systems

local MathGenerator = {}

------------------------------------------------------------------------
-- Deterministic pseudo-random number generator (LCG)
-- Seeded from the date string so every player gets the same question
------------------------------------------------------------------------
local function makeLCG(seed)
	local state = seed
	return function(min, max)
		state = (state * 1103515245 + 12345) % 2147483648
		if min and max then
			return min + (state % (max - min + 1))
		end
		return state
	end
end

local function dateSeed(year, month, day)
	return year * 10000 + month * 100 + day
end

------------------------------------------------------------------------
-- Question generators
-- Each returns { question = string, answer = number, hint = string }
------------------------------------------------------------------------

local generators = {}

-- 1) Solve a linear equation: ax + b = c
generators[1] = function(rng)
	local a = rng(2, 12)
	local x = rng(-15, 15)
	local b = rng(-20, 20)
	local c = a * x + b
	return {
		question = string.format("Solve for x:  %dx + %d = %d", a, b, c),
		answer = x,
		hint = "Isolate x by moving constants to the other side.",
		category = "Algebra",
	}
end

-- 2) Evaluate an exponent expression: a^b
generators[2] = function(rng)
	local base = rng(2, 9)
	local exp = rng(2, 4)
	local result = base ^ exp
	return {
		question = string.format("What is %d ^ %d ?", base, exp),
		answer = result,
		hint = string.format("Multiply %d by itself %d times.", base, exp),
		category = "Exponents",
	}
end

-- 3) Square root of a perfect square
generators[3] = function(rng)
	local root = rng(2, 20)
	local square = root * root
	return {
		question = string.format("What is the square root of %d ?", square),
		answer = root,
		hint = "Find a number that multiplied by itself gives you " .. square .. ".",
		category = "Square Roots",
	}
end

-- 4) Percentage: What is p% of n?
generators[4] = function(rng)
	local p = rng(1, 9) * 10 -- 10, 20, ..., 90
	local n = rng(2, 20) * 10 -- 20, 30, ..., 200
	local result = (p / 100) * n
	return {
		question = string.format("What is %d%% of %d ?", p, n),
		answer = result,
		hint = string.format("Convert %d%% to a decimal and multiply by %d.", p, n),
		category = "Percentages",
	}
end

-- 5) Area of a rectangle
generators[5] = function(rng)
	local w = rng(3, 15)
	local h = rng(3, 15)
	local area = w * h
	return {
		question = string.format("A rectangle is %d units wide and %d units tall. What is its area?", w, h),
		answer = area,
		hint = "Area = width × height.",
		category = "Geometry",
	}
end

-- 6) Order of operations: a + b * c
generators[6] = function(rng)
	local a = rng(1, 20)
	local b = rng(2, 10)
	local c = rng(2, 10)
	local result = a + b * c
	return {
		question = string.format("Evaluate:  %d + %d × %d", a, b, c),
		answer = result,
		hint = "Remember PEMDAS — multiply before adding!",
		category = "Order of Operations",
	}
end

-- 7) GCF (Greatest Common Factor)
generators[7] = function(rng)
	local gcf = rng(2, 12)
	local m1 = rng(2, 8)
	local m2 = rng(2, 8)
	-- make sure m1 and m2 are coprime-ish by picking distinct values
	if m1 == m2 then
		m2 = m2 + 1
	end
	local a = gcf * m1
	local b = gcf * m2
	return {
		question = string.format("What is the greatest common factor of %d and %d ?", a, b),
		answer = gcf,
		hint = "List the factors of each number and find the biggest one they share.",
		category = "Number Theory",
	}
end

-- 8) Simple ratio / proportion: if a:b = c:?, find ?
generators[8] = function(rng)
	local a = rng(2, 8)
	local b = rng(2, 8)
	if a == b then
		b = b + 1
	end
	local multiplier = rng(2, 6)
	local c = a * multiplier
	local answer = b * multiplier
	return {
		question = string.format("If %d : %d = %d : ?, what is the missing number?", a, b, c, answer),
		answer = answer,
		hint = string.format("Figure out what %d was multiplied by to get %d, then do the same to %d.", a, c, b),
		category = "Ratios",
	}
end

-- 9) Evaluate expression with parentheses: (a + b) * c - d
generators[9] = function(rng)
	local a = rng(1, 10)
	local b = rng(1, 10)
	local c = rng(2, 6)
	local d = rng(1, 15)
	local result = (a + b) * c - d
	return {
		question = string.format("Evaluate:  (%d + %d) × %d − %d", a, b, c, d),
		answer = result,
		hint = "Do the parentheses first, then multiply, then subtract.",
		category = "Order of Operations",
	}
end

-- 10) Perimeter of a triangle with given sides
generators[10] = function(rng)
	local a = rng(3, 15)
	local b = rng(3, 15)
	local c = rng(math.max(3, math.abs(a - b) + 1), a + b - 1)
	local perimeter = a + b + c
	return {
		question = string.format("A triangle has sides of length %d, %d, and %d. What is its perimeter?", a, b, c),
		answer = perimeter,
		hint = "Perimeter = sum of all sides.",
		category = "Geometry",
	}
end

-- 11) Distributive property: a(b + c) = ?
generators[11] = function(rng)
	local a = rng(2, 9)
	local b = rng(1, 12)
	local c = rng(1, 12)
	local result = a * (b + c)
	return {
		question = string.format("Expand and simplify:  %d(%d + %d)", a, b, c),
		answer = result,
		hint = "Use the distributive property: multiply each term inside the parentheses.",
		category = "Algebra",
	}
end

-- 12) Negative numbers: a - b where result may be negative
generators[12] = function(rng)
	local a = rng(-20, 10)
	local b = rng(-10, 20)
	local result = a - b
	return {
		question = string.format("What is %d − (%d) ?", a, b),
		answer = result,
		hint = "Subtracting a negative is the same as adding!",
		category = "Integers",
	}
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

--- Generate today's question given a date
--- @param year number
--- @param month number (1-12)
--- @param day number (1-31)
--- @return table { question, answer, hint, category, questionId }
function MathGenerator.getQuestion(year, month, day)
	local seed = dateSeed(year, month, day)
	local rng = makeLCG(seed)

	-- pick a generator based on the day
	local idx = (seed % #generators) + 1
	local q = generators[idx](rng)
	q.questionId = string.format("%04d-%02d-%02d", year, month, day)
	return q
end

--- Check if a given answer is correct for the daily question
--- @param year number
--- @param month number
--- @param day number
--- @param playerAnswer number
--- @return boolean
function MathGenerator.checkAnswer(year, month, day, playerAnswer)
	local q = MathGenerator.getQuestion(year, month, day)
	return math.abs(q.answer - playerAnswer) < 0.001
end

--- Exposed for testing
MathGenerator._generators = generators
MathGenerator._makeLCG = makeLCG
MathGenerator._dateSeed = dateSeed

return MathGenerator
