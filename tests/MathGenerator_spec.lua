-- MathGenerator_spec.lua
-- Unit tests for the MathGenerator module

local T = require("tests.TestFramework")
local MathGenerator = require("src.shared.MathGenerator")

local describe = T.describe
local it = T.it
local expect = T.expect

------------------------------------------------------------------------
-- Tests
------------------------------------------------------------------------

describe("MathGenerator.getQuestion", function()
	it("should return a table with required fields", function()
		local q = MathGenerator.getQuestion(2026, 3, 15)
		expect(type(q)).toBe("table")
		expect(q.question).toBeType("string")
		expect(q.answer).toBeType("number")
		expect(q.hint).toBeType("string")
		expect(q.category).toBeType("string")
		expect(q.questionId).toBe("2026-03-15")
	end)

	it("should return the same question for the same date", function()
		local q1 = MathGenerator.getQuestion(2026, 6, 1)
		local q2 = MathGenerator.getQuestion(2026, 6, 1)
		expect(q1.question).toBe(q2.question)
		expect(q1.answer).toBe(q2.answer)
		expect(q1.category).toBe(q2.category)
	end)

	it("should return different questions for different dates", function()
		local q1 = MathGenerator.getQuestion(2026, 1, 1)
		local q2 = MathGenerator.getQuestion(2026, 1, 2)
		-- They might occasionally collide, but let's check a few dates
		local allSame = true
		for day = 1, 10 do
			local qa = MathGenerator.getQuestion(2026, 1, day)
			local qb = MathGenerator.getQuestion(2026, 1, day + 1)
			if qa.question ~= qb.question then
				allSame = false
				break
			end
		end
		expect(allSame).toBeFalsy()
	end)

	it("should produce a valid questionId in YYYY-MM-DD format", function()
		local q = MathGenerator.getQuestion(2025, 12, 25)
		expect(q.questionId).toBe("2025-12-25")
	end)

	it("should generate questions for a full month without errors", function()
		local errorCount = 0
		for day = 1, 31 do
			local ok, _ = pcall(function()
				local q = MathGenerator.getQuestion(2026, 7, day)
				assert(q.question and #q.question > 0)
				assert(type(q.answer) == "number")
			end)
			if not ok then
				errorCount = errorCount + 1
			end
		end
		expect(errorCount).toBe(0)
	end)
end)

describe("MathGenerator.checkAnswer", function()
	it("should return true for the correct answer", function()
		local q = MathGenerator.getQuestion(2026, 3, 15)
		local result = MathGenerator.checkAnswer(2026, 3, 15, q.answer)
		expect(result).toBeTruthy()
	end)

	it("should return false for an incorrect answer", function()
		local q = MathGenerator.getQuestion(2026, 3, 15)
		local wrongAnswer = q.answer + 999
		local result = MathGenerator.checkAnswer(2026, 3, 15, wrongAnswer)
		expect(result).toBeFalsy()
	end)

	it("should accept answers within floating point tolerance", function()
		local q = MathGenerator.getQuestion(2026, 3, 15)
		local result = MathGenerator.checkAnswer(2026, 3, 15, q.answer + 0.0001)
		expect(result).toBeTruthy()
	end)
end)

describe("MathGenerator internal - LCG", function()
	it("should produce deterministic sequences", function()
		local rng1 = MathGenerator._makeLCG(42)
		local rng2 = MathGenerator._makeLCG(42)
		for _ = 1, 10 do
			expect(rng1(1, 100)).toBe(rng2(1, 100))
		end
	end)

	it("should produce different sequences for different seeds", function()
		local rng1 = MathGenerator._makeLCG(100)
		local rng2 = MathGenerator._makeLCG(200)
		local allSame = true
		for _ = 1, 10 do
			if rng1(1, 1000) ~= rng2(1, 1000) then
				allSame = false
				break
			end
		end
		expect(allSame).toBeFalsy()
	end)

	it("should produce values within the specified range", function()
		local rng = MathGenerator._makeLCG(12345)
		for _ = 1, 100 do
			local v = rng(5, 15)
			expect(v >= 5).toBeTruthy()
			expect(v <= 15).toBeTruthy()
		end
	end)
end)

describe("MathGenerator internal - dateSeed", function()
	it("should produce unique seeds for different dates", function()
		local s1 = MathGenerator._dateSeed(2026, 1, 1)
		local s2 = MathGenerator._dateSeed(2026, 1, 2)
		local s3 = MathGenerator._dateSeed(2026, 2, 1)
		expect(s1 ~= s2).toBeTruthy()
		expect(s1 ~= s3).toBeTruthy()
		expect(s2 ~= s3).toBeTruthy()
	end)
end)

describe("MathGenerator - all generators produce valid output", function()
	it("should have at least 10 generators", function()
		expect(#MathGenerator._generators >= 10).toBeTruthy()
	end)

	it("each generator should return valid question structure", function()
		local rng = MathGenerator._makeLCG(99999)
		for i, gen in ipairs(MathGenerator._generators) do
			local q = gen(rng)
			expect(q.question).toBeType("string")
			expect(q.answer).toBeType("number")
			expect(q.hint).toBeType("string")
			expect(q.category).toBeType("string")
		end
	end)
end)

describe("MathGenerator - question variety over 30 days", function()
	it("should produce at least 5 distinct categories over a month", function()
		local categories = {}
		for day = 1, 30 do
			local q = MathGenerator.getQuestion(2026, 6, day)
			categories[q.category] = true
		end
		local count = 0
		for _ in pairs(categories) do
			count = count + 1
		end
		expect(count >= 5).toBeTruthy()
	end)

	it("should produce questions with integer answers for most generators", function()
		-- Most 8th grade questions should have integer answers
		local intCount = 0
		for day = 1, 30 do
			local q = MathGenerator.getQuestion(2026, 8, day)
			if q.answer == math.floor(q.answer) then
				intCount = intCount + 1
			end
		end
		-- At least 90% should be integers
		expect(intCount >= 27).toBeTruthy()
	end)
end)
