-- Visual direction only. No prices, rewards, IDs or progression live here.
local P = {}
local materials = {
	"Grass",
	"Grass",
	"Sand",
	"Slate",
	"SmoothPlastic",
	"Rock",
	"Metal",
	"Slate",
	"Slate",
	"Marble",
	"Metal",
	"Snow",
	"WoodPlanks",
	"SmoothPlastic",
}
local times = { 16.3, 15.8, 16.7, 14, 15.5, 18.2, 20, 19.5, 21, 15.8, 20, 14.5, 16.8, 17.2 }
local skies = {
	{ 210, 229, 255 },
	{ 196, 223, 210 },
	{ 255, 222, 173 },
	{ 160, 222, 243 },
	{ 250, 217, 239 },
	{ 239, 169, 135 },
	{ 137, 166, 218 },
	{ 178, 154, 234 },
	{ 118, 118, 172 },
	{ 255, 238, 204 },
	{ 157, 215, 226 },
	{ 214, 237, 255 },
	{ 247, 219, 179 },
	{ 233, 208, 255 },
}
function P.world(index)
	index = math.clamp(index, 1, #materials)
	return {
		GroundMaterial = materials[index],
		ClockTime = times[index],
		Sky = skies[index],
		Exposure = index >= 7 and index <= 9 and 0.15 or 0.05,
		Contrast = 0.06,
		Saturation = 0.07,
	}
end
function P.quality(mode, touch)
	local low = mode == "Low" or mode ~= "High" and touch == true
	return {
		Mode = low and "Low" or "High",
		Particles = low and 6 or 24,
		Bloom = not low,
		Shadows = not low,
		Details = not low,
	}
end
P.Materials = materials
return P
