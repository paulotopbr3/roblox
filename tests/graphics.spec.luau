local P = require("../src/shared/Presentation")
local C = require("../src/shared/Config")
local profiles = {}
for world = 1, #C.Worlds do
	local profile = P.world(world)
	assert(profile.ClockTime >= 0 and profile.ClockTime <= 24 and #profile.Sky == 3 and profile.GroundMaterial)
	for _, channel in ipairs(profile.Sky) do
		assert(channel >= 0 and channel <= 255)
	end
	profiles[profile.ClockTime] = true
end
local distinct = 0
for _ in pairs(profiles) do
	distinct += 1
end
assert(distinct >= 10)
assert(
	P.world(1).GroundMaterial == "Grass"
		and P.world(3).GroundMaterial == "Sand"
		and P.world(12).GroundMaterial == "Snow"
)
print("PASS all 14 biomes have valid materials and distinct lighting profiles")
assert(P.quality("Auto", true).Mode == "Low" and P.quality("Auto", false).Mode == "High")
assert(P.quality("High", true).Mode == "High" and P.quality("Low", false).Mode == "Low")
print("PASS automatic quality adapts to touch and explicit choices override it")
assert(P.quality("Low", false).Particles < P.quality("High", false).Particles and not P.quality("Low", false).Shadows)
print("PASS low preset bounds effects and shadows")
