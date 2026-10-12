-- Original geometry, shared by equipped tools, portraits and map display stands.
local Art = {}
local toolColors = {
	{ 137, 100, 65 },
	{ 140, 156, 173 },
	{ 188, 205, 220 },
	{ 255, 206, 80 },
	{ 87, 224, 255 },
	{ 79, 228, 158 },
	{ 150, 123, 255 },
	{ 108, 61, 184 },
	{ 255, 240, 172 },
	{ 255, 143, 66 },
	{ 86, 189, 198 },
	{ 227, 175, 91 },
	{ 248, 119, 217 },
	{ 238, 247, 255 },
}
local function shape(name, size, pos, color, kind, angles, glow)
	return {
		Name = name,
		Size = size,
		Position = pos,
		Color = color,
		Shape = kind or "Block",
		Angles = angles or { 0, 0, 0 },
		Glow = glow or false,
	}
end
function Art.tool(index)
	local tier = math.clamp(math.ceil(index / 4), 1, #toolColors)
	local step = (index - 1) % 4
	local col = toolColors[tier]
	local parts = {
		shape("Handle", { 0.3, 3.1, 0.3 }, { 0, 0, 0 }, tier < 4 and { 111, 76, 49 } or { 43, 48, 71 }),
		shape("Grip", { 0.46, 1.1, 0.46 }, { 0, -0.5, 0 }, { 46, 45, 64 }),
		shape("Head", { 1.9 + step * 0.12, 0.45, 0.65 }, { 0, 1.15, 0 }, col),
	}
	for _, side in ipairs({ -1, 1 }) do
		table.insert(
			parts,
			shape(
				"Blade",
				{ 0.7 + step * 0.1, 0.9, 0.65 },
				{ side * 1.2, 0.92, 0 },
				col,
				"Wedge",
				{ 0, side == 1 and 180 or 0, side * 20 },
				tier >= 7
			)
		)
	end
	if tier >= 3 then
		table.insert(parts, shape("Core", { 0.65, 0.65, 0.75 }, { 0, 1.17, -0.03 }, col, "Ball", nil, tier >= 5))
	end
	if tier >= 5 then
		for _, side in ipairs({ -1, 1 }) do
			table.insert(
				parts,
				shape(
					"CrystalFin",
					{ 0.3, 1 + step * 0.15, 0.35 },
					{ side * 0.7, 1.65, 0 },
					col,
					"Wedge",
					{ 0, 0, side * 30 },
					true
				)
			)
		end
	end
	if tier >= 7 then
		table.insert(
			parts,
			shape("CosmicRing", { 0.18, 0.95, 0.95 }, { 0, 0.6, 0 }, col, "Cylinder", { 0, 0, 90 }, true)
		)
	end
	if tier >= 9 then
		for _, side in ipairs({ -1, 1 }) do
			table.insert(
				parts,
				shape(
					"Wing",
					{ 0.95, 0.45, 0.18 },
					{ side * 0.9, 0.7, -0.3 },
					{ 255, 224, 136 },
					"Wedge",
					{ 0, 0, side * 30 }
				)
			)
		end
	end
	if tier >= 11 then
		table.insert(parts, shape("Crown", { 0.3, 1.1, 0.3 }, { 0, 2.1, 0 }, col, "Wedge", nil, true))
	end
	for _, p in ipairs(parts) do
		p.Material = p.Name == "Handle" and (tier < 4 and "Wood" or "Metal") or p.Name == "Grip" and "Fabric" or "Metal"
		p.Reflectance = p.Name == "Head" and 0.07 or 0
		if p.Name == "Blade" then
			p.Glow = false
		end
	end
	for _, side in ipairs({ -1, 1 }) do
		table.insert(
			parts,
			shape(
				"BladeEdge",
				{ 0.5, 0.1, 0.72 },
				{ side * 1.27, 0.63, 0 },
				{ 229, 242, 251 },
				"Wedge",
				{ 0, side == 1 and 180 or 0, side * 20 }
			)
		)
	end
	if tier >= 5 then
		table.insert(parts, shape("EnergyInlay", { 0.12, 1.9, 0.1 }, { 0, 0.45, -0.18 }, col, "Block", nil, true))
	end
	for _, p in ipairs(parts) do
		if p.Name == "BladeEdge" then
			p.Material = "Metal"
			p.Reflectance = 0.06
		end
	end
	return { Tier = tier, Color = col, Parts = parts }
end
function Art.pet(info, tier)
	local col = tier == 1 and { 255, 211, 102 } or tier == 2 and { 179, 137, 255 } or info.Color or { 119, 202, 232 }
	local rank = info.Rank
	local family = rank == 1 and "Sprite"
		or rank == 2 and "Fox"
		or rank == 3 and "Golem"
		or rank == 4 and "Dragon"
		or rank == 5 and "Phoenix"
		or rank == 6 and "Titan"
		or "Oracle"
	local parts = {
		shape(
			"Body",
			{ 1.8, 1.6, 1.6 },
			{ 0, 0, 0 },
			col,
			(rank == 3 or rank == 6) and "Block" or "Ball",
			nil,
			tier > 0
		),
	}
	local dark = { 27, 33, 56 }
	local pale = { 248, 251, 255 }
	for _, side in ipairs({ -1, 1 }) do
		table.insert(parts, shape("Eye", { 0.22, 0.33, 0.15 }, { side * 0.36, 0.12, -0.82 }, dark, "Ball"))
		table.insert(parts, shape("EyeSpark", { 0.08, 0.1, 0.04 }, { side * 0.36 - 0.04, 0.22, -0.91 }, pale, "Ball"))
		if family == "Fox" or family == "Dragon" then
			table.insert(
				parts,
				shape("Ear", { 0.5, 0.9, 0.5 }, { side * 0.55, 0.96, 0 }, col, "Wedge", { 0, side * 45, 0 })
			)
		end
		if family == "Golem" or family == "Titan" then
			table.insert(parts, shape("Arm", { 0.65, 1, 0.75 }, { side * 1.15, -0.05, 0 }, col))
		end
		if family == "Dragon" or family == "Phoenix" then
			table.insert(
				parts,
				shape(
					"Wing",
					{ 1.4, 0.25, 1.2 },
					{ side * 1.45, 0.2, 0.1 },
					family == "Phoenix" and { 255, 182, 71 } or col,
					"Wedge",
					{ 0, 0, side * 22 },
					family == "Phoenix"
				)
			)
		end
		if family == "Sprite" then
			table.insert(parts, shape("Antenna", { 0.2, 0.5, 0.2 }, { side * 0.4, 1, 0 }, col, "Ball", nil, true))
		end
	end
	table.insert(parts, shape("Muzzle", { 0.75, 0.4, 0.15 }, { 0, -0.3, -0.83 }, pale, "Ball"))
	if family == "Fox" then
		table.insert(parts, shape("Tail", { 0.75, 0.7, 1.5 }, { 0, -0.15, 1.2 }, col, "Wedge", { 20, 0, 0 }))
	end
	if family == "Golem" then
		table.insert(
			parts,
			shape("Rune", { 0.45, 0.65, 0.18 }, { 0, 0.1, -0.92 }, { 91, 249, 223 }, "Wedge", nil, true)
		)
	end
	if family == "Dragon" then
		table.insert(parts, shape("Horn", { 0.25, 0.8, 0.25 }, { 0, 1.05, 0.1 }, { 255, 219, 136 }, "Wedge"))
	end
	if family == "Phoenix" then
		table.insert(parts, shape("Crest", { 0.4, 1, 0.8 }, { 0, 0.9, 0 }, { 255, 188, 66 }, "Wedge", nil, true))
	end
	if family == "Titan" then
		table.insert(parts, shape("Helmet", { 2.05, 0.45, 1.85 }, { 0, 0.75, 0 }, { 76, 75, 103 }))
		table.insert(parts, shape("Gem", { 0.5, 0.65, 0.3 }, { 0, 0.55, -0.96 }, col, "Wedge", nil, true))
	end
	if family == "Oracle" then
		table.insert(
			parts,
			shape("Halo", { 0.15, 2.2, 2.2 }, { 0, 1.3, 0 }, { 255, 226, 140 }, "Cylinder", { 0, 0, 90 }, true)
		)
		table.insert(parts, shape("Star", { 0.5, 0.8, 0.4 }, { 0, 0.95, -0.9 }, col, "Wedge", nil, true))
	end
	local motif = (info.World - 1) % 4
	if motif == 1 then
		table.insert(
			parts,
			shape("Leaf", { 0.4, 0.7, 0.2 }, { 0, 0.87, -0.35 }, { 112, 244, 161 }, "Wedge", { 0, 0, 25 })
		)
	elseif motif == 2 then
		table.insert(
			parts,
			shape("OrbitGem", { 0.35, 0.35, 0.35 }, { 0.8, 0.85, -0.6 }, { 255, 220, 132 }, "Ball", nil, true)
		)
	elseif motif == 3 then
		table.insert(parts, shape("Fin", { 0.25, 0.9, 0.55 }, { 0, 0.9, 0.35 }, { 119, 232, 255 }, "Wedge"))
	end
	for _, side in ipairs({ -1, 1 }) do
		table.insert(
			parts,
			shape("Cheek", { 0.25, 0.13, 0.08 }, { side * 0.6, -0.16, -0.69 }, { 247, 157, 177 }, "Ball")
		)
		table.insert(parts, shape("Paw", { 0.43, 0.27, 0.45 }, { side * 0.45, -0.78, -0.32 }, pale, "Ball"))
	end
	for _, p in ipairs(parts) do
		if p.Name == "Eye" then
			p.Material = "Glass"
			p.Reflectance = 0.05
		elseif p.Name == "EyeSpark" then
			p.Glow = true
		end
	end
	if family == "Fox" then
		table.insert(parts, shape("TailTip", { 0.55, 0.45, 0.5 }, { 0, 0, 1.88 }, pale, "Ball"))
	end
	return { Family = family, Color = col, Parts = parts }
end
function Art.world(info, index)
	local col = info.Color
	local light = { 239, 246, 255 }
	local dark = { 48, 61, 85 }
	local parts = { shape("LandmarkBase", { 8, 0.5, 8 }, { 0, 0, 0 }, col) }
	local function add(name, size, pos, color, kind, angles, glow)
		table.insert(parts, shape(name, size, pos, color, kind, angles, glow))
	end
	if index == 1 or index == 2 then
		add("Trunk", { 0.8, 4, 0.8 }, { 0, 2, 0 }, { 122, 85, 54 })
		for _, o in ipairs({ { -1, 4, 0 }, { 1, 4, 0 }, { 0, 5, 0 } }) do
			add("Canopy", { 3.5, 3.5, 3.5 }, o, col, "Ball")
		end
		if index == 1 then
			add("Cabin", { 2.2, 1.7, 2 }, { -2, 1, -1 }, { 244, 223, 158 })
			add("Roof", { 2.8, 1.2, 2.8 }, { -2, 2.1, -1 }, { 239, 136, 112 }, "Wedge")
		else
			add("MushroomStem", { 0.5, 1, 0.5 }, { 2, 0.7, -2 }, light)
			add("MushroomCap", { 1.8, 0.5, 1.8 }, { 2, 1.4, -2 }, { 239, 135, 171 }, "Ball")
		end
	elseif index == 3 then
		for level = 1, 5 do
			local width = 6 - (level - 1)
			add("PyramidStep", { width, 0.9, width }, { 0, level * 0.8, 0 }, { 246, 213, 138 })
		end
		add("Obelisk", { 0.65, 5, 0.65 }, { -3, 2.7, -2 }, { 202, 157, 86 })
		add("SunStone", { 1, 1, 1 }, { 0, 4.5, 0 }, { 255, 226, 86 }, "Ball", nil, true)
	elseif index == 4 then
		add("ShipHull", { 5, 1.1, 2.3 }, { 0, 1, 0 }, { 123, 82, 62 }, "Wedge")
		add("Mast", { 0.25, 5, 0.25 }, { 0, 3, 0 }, { 194, 153, 95 })
		add("Sail", { 2.5, 3, 0.15 }, { 0, 3.5, 0 }, light, "Wedge")
		for _, x in ipairs({ -2.6, 2.6 }) do
			add("Coral", { 0.6, 1.4, 0.6 }, { x, 1, 2 }, col, "Wedge", nil, true)
		end
	elseif index == 5 then
		add("CandyHouse", { 4, 3, 3 }, { 0, 1.9, 0 }, { 248, 187, 216 })
		add("CandyRoof", { 4.7, 2, 3.8 }, { 0, 4, 0 }, { 174, 143, 234 }, "Wedge")
		add("Door", { 1, 1.8, 0.2 }, { 0, 1.1, -1.6 }, { 135, 91, 127 })
		for _, x in ipairs({ -3, 3 }) do
			add("CandyPole", { 0.25, 3.5, 0.25 }, { x, 1.8, 0 }, light)
			add("Lollipop", { 1.5, 1.5, 0.4 }, { x, 3.6, 0 }, { 255, 164, 123 }, "Ball")
		end
	elseif index == 6 then
		for level = 1, 5 do
			local width = 6.5 - level
			add("VolcanoLayer", { 0.9, width, width }, { 0, 0.9 * level, 0 }, { 76, 54, 65 }, "Cylinder", { 0, 0, 90 })
		end
		add("LavaCore", { 1.6, 0.5, 1.6 }, { 0, 4.8, 0 }, { 255, 121, 58 }, "Ball", nil, true)
		add("LavaFlow", { 0.45, 4, 0.3 }, { 0, 2.4, -1.4 }, { 255, 156, 60 }, "Block", { 20, 0, 0 }, true)
	elseif index == 7 then
		add("Rocket", { 4, 1.5, 1.5 }, { 0, 2.5, 0 }, light, "Cylinder", { 0, 0, 90 })
		add("RocketTip", { 1.7, 1.5, 1.7 }, { 0, 5, 0 }, { 227, 115, 144 }, "Wedge")
		for _, x in ipairs({ -1, 1 }) do
			add("RocketFin", { 0.8, 2, 0.3 }, { x, 1.1, 0 }, { 137, 173, 236 }, "Wedge")
		end
		add("Flame", { 0.8, 1.5, 0.8 }, { 0, 0.5, 0 }, { 255, 194, 79 }, "Wedge", nil, true)
	elseif index == 8 or index == 9 then
		add(
			"CosmicCore",
			{ 3, 3, 3 },
			{ 0, 3.5, 0 },
			index == 8 and { 182, 152, 255 } or { 64, 41, 111 },
			"Ball",
			nil,
			true
		)
		for k = 1, 10 do
			local a = k * math.pi / 5
			add(
				"Orbit",
				{ 1.4, 0.2, 0.35 },
				{ math.cos(a) * 2.8, 3.5, math.sin(a) * 2.8 },
				col,
				"Block",
				{ 0, -math.deg(a), 0 },
				true
			)
		end
		if index == 9 then
			for _, x in ipairs({ -3, 3 }) do
				add("VoidObelisk", { 0.6, 5, 0.6 }, { x, 2.8, -1 }, { 48, 35, 72 }, "Wedge")
			end
		end
	elseif index == 10 then
		for _, x in ipairs({ -2, 2 }) do
			for _, z in ipairs({ -1.5, 1.5 }) do
				add("TempleColumn", { 3.5, 0.5, 0.5 }, { x, 2, z }, light, "Cylinder", { 0, 0, 90 })
			end
		end
		add("TempleRoof", { 5.5, 0.7, 4.5 }, { 0, 4.1, 0 }, { 255, 222, 147 })
		add("TempleStar", { 0.5, 2, 0.5 }, { 0, 5, 0 }, { 255, 231, 156 }, "Wedge", nil, true)
	elseif index == 11 then
		for k = 1, 4 do
			local x = (k - 2.5) * 1.6
			local height = 2 + k % 3
			add("Tower", { 1.25, height, 1.4 }, { x, height / 2 + 0.4, 0 }, dark)
			for row = 1, 3 do
				add("Window", { 0.65, 0.15, 0.1 }, { x, row * 0.6 + 0.5, -0.76 }, col, "Block", nil, true)
			end
		end
	elseif index == 12 then
		for _, x in ipairs({ -2, 0, 2 }) do
			add("IcePeak", { 2, 4 + math.abs(x), 2 }, { x, 2.5, 0 }, { 176, 224, 255 }, "Wedge", { 0, x * 15, 0 })
		end
		add("SnowBall", { 2.5, 2.5, 2.5 }, { 0, 1, -2 }, light, "Ball")
	elseif index == 13 then
		add("ClockTower", { 2.5, 5, 2 }, { 0, 2.8, 0 }, { 165, 119, 69 })
		add("ClockFace", { 0.25, 2, 2 }, { 0, 4, -1.1 }, { 255, 225, 154 }, "Cylinder", { 0, 90, 0 })
		add("ClockHand", { 0.1, 0.7, 0.1 }, { 0, 4.25, -1.35 }, dark)
		for _, x in ipairs({ -2.8, 2.8 }) do
			add("Gear", { 0.25, 2, 2 }, { x, 1.6, 0 }, { 232, 185, 94 }, "Cylinder", { 0, 90, 0 })
		end
	else
		for _, x in ipairs({ -2, 2 }) do
			add("DreamTower", { 1.2, 4.5, 1.2 }, { x, 2.5, 0 }, { 233, 205, 251 })
			add("TowerRoof", { 1.5, 1.5, 1.5 }, { x, 5.3, 0 }, { 170, 157, 239 }, "Wedge")
		end
		add("DreamBridge", { 4, 0.6, 1.8 }, { 0, 3.4, 0 }, light)
		add("DreamStar", { 0.6, 2, 0.6 }, { 0, 5, 0 }, { 255, 221, 144 }, "Wedge", nil, true)
	end
	return { Name = info.Name .. " Landmark", Parts = parts }
end
return Art
