local C = require("../src/shared/Config")
local B = require("../src/shared/Balance")
local E = require("../src/shared/Economy")
local count = 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		error(name .. ": " .. tostring(err))
	end
	count += 1
	print("PASS " .. name)
end
test("catalog supports full progression", function()
	assert(#C.Worlds == 14 and #C.Tools == 56 and #C.Rarities == 7)
	local pets = 0
	for _ in pairs(C.Pets) do
		pets += 1
	end
	assert(pets == 104)
	for i = 2, #C.Tools do
		assert(
			C.Tools[i].Cost > C.Tools[i - 1].Cost
				and C.Tools[i].Damage > C.Tools[i - 1].Damage
				and C.Tools[i].Interval <= C.Tools[i - 1].Interval
		)
	end
	for i = 2, #C.Worlds do
		assert(C.Worlds[i].Cost > C.Worlds[i - 1].Cost and C.Worlds[i].Reward > C.Worlds[i - 1].Reward)
	end
end)
test("rebirth grows, remains finite and rewards indefinitely", function()
	assert(B.rebirthCost(0) == 25000 and B.rebirthMultiplier(0) == 1)
	for i = 1, 600 do
		assert(B.rebirthCost(i) > B.rebirthCost(i - 1) and B.rebirthCost(i) < math.huge)
	end
	assert(B.rebirthCost(1000000) <= C.MaxNumber and B.rebirthMultiplier(1000000) > B.rebirthMultiplier(1000))
end)
test("rarity exact boundaries and rare tails", function()
	assert(E.rarity(C.Weights, 1, 0) == 1)
	assert(E.rarity(C.Weights, 1, 0.599999) == 1)
	assert(E.rarity(C.Weights, 1, 0.6) == 2)
	assert(E.rarity(C.Weights, 1, 0.99995) == 7)
	assert(E.rarity(C.Weights, 1, 0.9988) == 6)
end)
test("boosted luck increases rare results with fixed rolls", function()
	local normal, boosted = 0, 0
	for i = 0, 9999 do
		local roll = (i + 0.5) / 10000
		if E.rarity(C.Weights, 1, roll) >= 3 then
			normal += 1
		end
		if E.rarity(C.Weights, 8, roll) >= 3 then
			boosted += 1
		end
	end
	assert(normal == 1500 and boosted > normal)
end)
test("hatch charge consumes credits first and is atomic", function()
	local p = E.hatchPlan(100, 100, 2, 3, 397, 400)
	assert(p.Cost == 100 and p.Credits == 2)
	local rejected, reason = E.hatchPlan(100, 99, 2, 3, 397, 400)
	assert(rejected == nil and reason == "Coins")
	rejected, reason = E.hatchPlan(100, 1000, 100, 3, 398, 400)
	assert(rejected == nil and reason == "Capacity")
	assert(E.hatchPlan(100, 0, 3, 3, 0, 400).Cost == 0)
	assert(E.hatchPlan(100, 1000, 0, 100, 0, 400) == nil)
end)
local function profile()
	return { Gems = 0, Boosts = {}, EggCredits = 0, Receipts = {}, Pets = {} }
end
local function petFactory(d, id)
	table.insert(d.Pets, id)
end
test("receipt retry does not duplicate premium currency", function()
	local d = profile()
	local valid, granted = E.receipt(d, "r1", C.Products.Gems500, 100, petFactory, C.MaxNumber)
	assert(valid and granted and d.Gems == 500)
	valid, granted = E.receipt(d, "r1", C.Products.Gems500, 200, petFactory, C.MaxNumber)
	assert(valid and not granted and d.Gems == 500)
	E.receipt(d, "r2", C.Products.Gems500, 200, petFactory, C.MaxNumber)
	assert(d.Gems == 1000)
end)
test("receipt retries preserve boosters, credits and pets", function()
	for _, key in ipairs({ "Luck15", "Coins30", "Eggs100", "WeeklyPet" }) do
		local d = profile()
		local p = C.Products[key]
		E.receipt(d, "same", p, 100, petFactory, C.MaxNumber)
		E.receipt(d, "same", p, 200, petFactory, C.MaxNumber)
		if p.Kind == "Pet" then
			assert(#d.Pets == 1)
		elseif p.Kind == "Eggs" then
			assert(d.EggCredits == 100)
		else
			assert(d.Boosts[p.Kind] == 100 + p.Amount)
		end
	end
end)
test("boost extends active duration, expired boost restarts now", function()
	local d = profile()
	E.receipt(d, "a", C.Products.Luck15, 100, petFactory, C.MaxNumber)
	E.receipt(d, "b", C.Products.Luck30, 200, petFactory, C.MaxNumber)
	assert(d.Boosts.Luck == 2800)
	E.receipt(d, "c", C.Products.Luck15, 4000, petFactory, C.MaxNumber)
	assert(d.Boosts.Luck == 4900)
end)
test("unknown receipt never marked delivered", function()
	local d = profile()
	assert(not E.receipt(d, "x", { Kind = "unknown" }, 100, petFactory, C.MaxNumber))
	assert(d.Receipts.x == nil)
end)
test("premium gem amount ignores earn multipliers and caps safely", function()
	local d = profile()
	d.Gems = C.MaxNumber
	E.receipt(d, "x", C.Products.Gems5000, 100, petFactory, C.MaxNumber)
	assert(d.Gems == C.MaxNumber)
end)
test("pet slots and level progression", function()
	assert(B.petSlots({ Passes = {} }) == 3 and B.petSlots({ Passes = { ExtraPetSlots = true } }) == 6)
	assert(B.level(0) == 1 and B.level(8) == 2 and B.level(32) == 3)
end)
test("products and passes configured safely", function()
	local passes, products = 0, 0
	local ids = {}
	for _, id in pairs(C.Passes) do
		passes += 1
		if id > 0 then
			assert(not ids[id])
			ids[id] = true
		end
	end
	ids = {}
	for _, p in pairs(C.Products) do
		products += 1
		assert(p.Amount > 0)
		if p.Id > 0 then
			assert(not ids[p.Id])
			ids[p.Id] = true
		end
	end
	assert(passes == 15 and products == 10)
end)
print(count .. " tests passed")
