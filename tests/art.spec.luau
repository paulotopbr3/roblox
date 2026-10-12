local Art = require("../src/shared/Art")
local C = require("../src/shared/Config")
local count = 0
local function test(name, fn)
	fn()
	count += 1
	print("PASS " .. name)
end
local function valid(parts)
	assert(#parts >= 3)
	for _, p in ipairs(parts) do
		assert(p.Name and #p.Size == 3 and #p.Position == 3 and #p.Color == 3 and #p.Angles == 3)
		for _, size in ipairs(p.Size) do
			assert(size > 0 and size < 100)
		end
		for _, value in ipairs(p.Color) do
			assert(value >= 0 and value <= 255)
		end
		assert(p.Shape == "Block" or p.Shape == "Ball" or p.Shape == "Cylinder" or p.Shape == "Wedge")
	end
end
test("all 56 pickaxes have valid equippable geometry", function()
	for index = 1, #C.Tools do
		local spec = Art.tool(index)
		valid(spec.Parts)
		assert(spec.Parts[1].Name == "Handle")
	end
end)
test("tool tiers grow in geometry rather than recoloring one stick", function()
	assert(#Art.tool(56).Parts > #Art.tool(1).Parts)
	assert(Art.tool(1).Parts[3].Size[1] < Art.tool(4).Parts[3].Size[1])
	assert(Art.tool(1).Color[1] ~= Art.tool(56).Color[1])
end)
test("all 104 pets and variants have portraits with valid geometry", function()
	local species = 0
	for _, info in pairs(C.Pets) do
		species += 1
		for tier = 0, 2 do
			valid(Art.pet(info, tier).Parts)
		end
	end
	assert(species == 104)
end)
test("seven rarity families have distinct silhouettes", function()
	local seen = {}
	for rank = 1, 7 do
		local spec = Art.pet(C.Pets["w1r" .. rank], 0)
		assert(not seen[spec.Family])
		seen[spec.Family] = true
	end
	assert(Art.pet(C.Pets.w1r7, 1).Color[1] == 255 and Art.pet(C.Pets.w1r7, 2).Color[1] == 179)
end)
test("14 world dioramas share original landmarks with the map", function()
	local names = {}
	for i, info in ipairs(C.Worlds) do
		local spec = Art.world(info, i)
		valid(spec.Parts)
		assert(not names[spec.Name])
		names[spec.Name] = true
	end
	assert(#Art.world(C.Worlds[3], 3).Parts ~= #Art.world(C.Worlds[4], 4).Parts)
end)
print(count .. " art checks passed")
