local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Models = require(game.ReplicatedStorage.UniverseMiner.Models)
local B = require(game.ReplicatedStorage.UniverseMiner.Balance)
local Presentation = require(game.ReplicatedStorage.UniverseMiner.Presentation)
local Map = { Crystals = {}, Spawns = {}, Eggs = {}, AFK = {}, Sell = {}, RankBoards = {} }
local rng = Random.new()
local function part(name, size, pos, color, parent, class)
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Material = name == "Trunk" and Enum.Material.Wood
		or name == "Crown" and Enum.Material.Grass
		or name:find("Path") and Enum.Material.Concrete
		or Enum.Material.SmoothPlastic
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function label(p, value, offset)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(200, 48)
	gui.StudsOffset = offset or Vector3.new(0, 4, 0)
	gui.MaxDistance = 75
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = value
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.4
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextWrapped = true
	t.Parent = gui
	return t
end
local function prompt(p, title, key, arg)
	local trigger = Instance.new("ProximityPrompt")
	trigger.ActionText = title
	trigger.ObjectText = "Universe Miner"
	trigger.KeyboardKeyCode = Enum.KeyCode.E
	trigger.GamepadKeyCode = Enum.KeyCode.ButtonX
	trigger.MaxActivationDistance = 12
	trigger.RequiresLineOfSight = false
	trigger.HoldDuration = 0.15
	trigger.Parent = p
	trigger.Triggered:Connect(function(player)
		if Map.near(player, p.Position, 15) and Map.Interact then
			Map.Interact(player, key, arg)
		end
	end)
end
local function cylinder(name, size, pos, color, parent)
	local p = part(name, size, pos, color, parent)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	return p
end
local function orb(name, size, pos, color, parent)
	local p = part(name, size, pos, color, parent)
	p.Shape = Enum.PartType.Ball
	return p
end
local function booth(parent, base, color, title, menu)
	local floor = part(title .. "Base", Vector3.new(20, 1, 16), base, Color3.fromRGB(228, 225, 216), parent)
	floor.Material = Enum.Material.Concrete
	local counter =
		part("Counter", Vector3.new(17, 3, 3), base + Vector3.new(0, 2, -3), Color3.fromRGB(97, 74, 66), parent)
	counter.Material = Enum.Material.WoodPlanks
	part("CounterTop", Vector3.new(18, 0.35, 4), base + Vector3.new(0, 3.7, -3), Color3.fromRGB(236, 231, 222), parent).Material =
		Enum.Material.Marble
	for _, x in ipairs({ -8, 8 }) do
		part("Pillar", Vector3.new(0.7, 10, 0.7), base + Vector3.new(x, 5, -4), Color3.fromRGB(47, 62, 80), parent).Material =
			Enum.Material.Metal
	end
	local roof = part("Canopy", Vector3.new(22, 1, 11), base + Vector3.new(0, 10, -3), color, parent)
	part(
		"CanopyTrim",
		Vector3.new(22.5, 0.4, 11.5),
		base + Vector3.new(0, 9.5, -3),
		Color3.fromRGB(244, 223, 178),
		parent
	).Material =
		Enum.Material.Metal
	for n = 1, 5 do
		part(
			"AwningStripe",
			Vector3.new(2, 0.15, 11),
			base + Vector3.new((n - 3) * 4, 10.6, -3),
			color:Lerp(Color3.new(1, 1, 1), 0.65),
			parent
		)
	end
	local lamp = Instance.new("PointLight")
	lamp.Color = Color3.fromRGB(255, 225, 180)
	lamp.Range = 18
	lamp.Brightness = 0.65
	lamp.Parent = roof
	label(roof, title, Vector3.new(0, 2, 0))
	prompt(floor, "Abrir " .. title, "Menu", menu)
end
local function crystal(folder, pos, col, id, world, boss)
	local height = boss and 14 or 7
	local core = part(
		boss and "Titan" or "Crystal",
		Vector3.new(boss and 9 or 3, height, boss and 7 or 3),
		pos,
		col,
		folder,
		boss and "Part" or "WedgePart"
	)
	core.CanCollide = false
	core.CanQuery = true
	core.Material = boss and Enum.Material.Metal or Enum.Material.Glass
	core.Reflectance = boss and 0.04 or 0.08
	core:SetAttribute("CrystalId", id)
	core.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(id % 180), boss and 0 or math.rad(-8))
	local pieces = {}
	local function add(name, size, offset, color, class, glow, query)
		local p = part(name, size, pos + offset, color, folder, class)
		p.CanCollide = false
		p.CanQuery = query or false
		p.Material = glow and Enum.Material.Neon or boss and Enum.Material.Metal or Enum.Material.Glass
		p.Reflectance = glow and 0 or 0.04
		if query then
			p:SetAttribute("CrystalId", id)
		end
		table.insert(pieces, p)
		return p
	end
	if boss then
		add(
			"TitanHead",
			Vector3.new(7, 6, 6),
			Vector3.new(0, 9, 0),
			col:Lerp(Color3.new(0.1, 0.15, 0.2), 0.6),
			nil,
			false,
			true
		)
		for _, side in ipairs({ -1, 1 }) do
			add(
				"TitanArm",
				Vector3.new(4, 10, 4),
				Vector3.new(side * 7, 0, 0),
				col:Lerp(Color3.new(0, 0, 0), 0.35),
				nil,
				false,
				true
			)
			add("TitanShoulder", Vector3.new(5, 4, 5), Vector3.new(side * 6, 5, 0), col, "WedgePart")
			add(
				"TitanEye",
				Vector3.new(1.4, 0.7, 0.2),
				Vector3.new(side * 1.5, 9.5, -3.1),
				Color3.fromRGB(255, 225, 129),
				nil,
				true
			)
			add(
				"TitanBoot",
				Vector3.new(4, 4, 5),
				Vector3.new(side * 2.6, -6, 0),
				Color3.fromRGB(56, 70, 86),
				nil,
				false,
				true
			)
		end
		add("TitanCrest", Vector3.new(2, 5, 2), Vector3.new(0, 13, 0), col, "WedgePart", true)
		add(
			"TitanHeart",
			Vector3.new(3, 4, 0.4),
			Vector3.new(0, 2, -3.65),
			Color3.fromRGB(186, 248, 255),
			"WedgePart",
			true
		)
	else
		for side = -1, 1, 2 do
			local p = add(
				"CrystalFacet",
				Vector3.new(1.8, height * 0.72, 1.8),
				Vector3.new(side * 2, -height * 0.1, 0),
				col,
				"WedgePart",
				false,
				true
			)
			p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, side * 0.55, side * 0.24)
		end
		add("CrystalEnergy", Vector3.new(0.5, height * 0.7, 0.5), Vector3.new(0, 0, 0), col, nil, true)
		add("CrystalCap", Vector3.new(1.6, 1.4, 1.6), Vector3.new(0, 3.6, 0), col, "WedgePart")
	end
	local pedestal = cylinder(
		"Deposit",
		Vector3.new(boss and 0.8 or 0.5, boss and 25 or 8, boss and 25 or 8),
		pos - Vector3.new(0, boss and 8.4 or 3.7, 0),
		Color3.fromRGB(75, 88, 105),
		folder
	)
	pedestal.Material = Enum.Material.Slate
	local t = label(core, "", Vector3.new(0, boss and 17 or 6, 0))
	t.Parent.MaxDistance = boss and 85 or 36
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -40, 0, 5)
	bar.Position = UDim2.fromOffset(20, 40)
	bar.BackgroundColor3 = Color3.fromRGB(40, 49, 65)
	bar.BorderSizePixel = 0
	bar.Parent = t.Parent
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = col
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local c = {
		Part = core,
		Label = t,
		Bar = fill,
		World = world,
		RespawnAt = 0,
		Pieces = pieces,
		Boss = boss,
		Contributors = {},
	}
	Map.Crystals[id] = c
	Map.reset(c)
	if boss then
		local light = Instance.new("PointLight")
		light.Color = col
		light.Range = 20
		light.Brightness = 0.6
		light.Parent = core
		prompt(core, "Ver desafio cooperativo", "Menu", "Guide")
	end
end
local function decorate(folder, base, i, col)
	for k = 1, 12 do
		local x = k % 2 == 0 and -78 or 78
		local z = (math.floor((k - 1) / 2) * 25) - 60
		local pos = base + Vector3.new(x, 0, z)
		if i == 1 or i == 2 then
			part("Trunk", Vector3.new(2, 8, 2), pos + Vector3.new(0, 4, 0), Color3.fromRGB(111, 79, 52), folder)
			orb(
				"Crown",
				Vector3.new(11, 11, 11),
				pos + Vector3.new(0, 11, 0),
				i == 1 and Color3.fromRGB(92, 202, 138) or Color3.fromRGB(47, 143, 101),
				folder
			)
		elseif i == 3 then
			local dune =
				orb("Dune", Vector3.new(12, 7, 12), pos + Vector3.new(0, 1, 0), Color3.fromRGB(244, 219, 149), folder)
			dune.Material = Enum.Material.Sand
			part("Cactus", Vector3.new(2, 8, 2), pos + Vector3.new(0, 6, 0), Color3.fromRGB(61, 148, 108), folder)
		elseif i == 5 then
			part("CandyStem", Vector3.new(1, 11, 1), pos + Vector3.new(0, 5, 0), Color3.new(1, 1, 1), folder)
			local candy = orb(
				"Lollipop",
				Vector3.new(8, 8, 3),
				pos + Vector3.new(0, 12, 0),
				Color3.fromHSV(k / 12, 0.45, 1),
				folder
			)
			candy.Material = Enum.Material.SmoothPlastic
		elseif i == 6 then
			local rock = part(
				"VolcanicRock",
				Vector3.new(9, 10, 9),
				pos + Vector3.new(0, 4, 0),
				Color3.fromRGB(48, 38, 50),
				folder,
				"WedgePart"
			)
			rock.Material = Enum.Material.Slate
			local lava = part(
				"LavaVein",
				Vector3.new(0.8, 9, 1),
				pos + Vector3.new(0, 4, 4.5),
				Color3.fromRGB(255, 117, 50),
				folder
			)
			lava.Material = Enum.Material.Neon
			lava.CanCollide = false
		elseif i == 4 or i == 12 then
			local coral = part(
				i == 12 and "IceSpire" or "Coral",
				Vector3.new(4, 10 + k % 3 * 3, 4),
				pos + Vector3.new(0, 5, 0),
				col:Lerp(Color3.new(1, 1, 1), 0.4),
				folder,
				"WedgePart"
			)
			coral.Material = i == 12 and Enum.Material.Ice or Enum.Material.Neon
		elseif i == 13 then
			cylinder(
				"GearColumn",
				Vector3.new(12, 7, 7),
				pos + Vector3.new(0, 6, 0),
				Color3.fromRGB(133, 91, 55),
				folder
			)
			local gear = part(
				"ClockworkGear",
				Vector3.new(9, 1.5, 9),
				pos + Vector3.new(0, 12, 0),
				Color3.fromRGB(232, 187, 97),
				folder
			)
			gear.Material = Enum.Material.Metal
		else
			local spire = part(
				"AstralSpire",
				Vector3.new(3, 14 + k % 3 * 3, 3),
				pos + Vector3.new(0, 7, 0),
				col:Lerp(Color3.new(1, 1, 1), 0.2),
				folder,
				"WedgePart"
			)
			spire.Material = Enum.Material.Neon
			orb("OrbitStone", Vector3.new(5, 5, 5), pos + Vector3.new(0, 18, 0), col, folder)
		end
	end
end
local function rankingBoard(root, key, x, color)
	local board =
		part("Global" .. key, Vector3.new(28, 24, 1), Vector3.new(x, 14, 90), Color3.fromRGB(31, 42, 67), root)
	for _, side in ipairs({ -1, 1 }) do
		part("BoardSupport", Vector3.new(1, 14, 1), board.Position + Vector3.new(side * 12, -12, 0), color, root)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "GlobalTable"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(700, 600)
	gui.Parent = board
	local function entry(value, y, size, col)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -32, 0, size or 38)
		t.Position = UDim2.fromOffset(16, y)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBold
		t.TextSize = size == 50 and 28 or 20
		t.TextColor3 = col or Color3.fromRGB(240, 247, 255)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = value
		t.Parent = gui
		return t
	end
	entry("TOP GLOBAL • " .. string.upper(key), 12, 50, color)
	entry("#     JOGADOR                            TOTAL", 70, 32, Color3.fromRGB(173, 196, 224))
	local rows = {}
	for rank = 1, 10 do
		rows[rank] = entry(rank .. ".  —", 105 + (rank - 1) * 42, 38, rank <= 3 and color or nil)
	end
	local status = entry("Aguardando DataStore • publique para ativar", 554, 32, Color3.fromRGB(173, 196, 224))
	Map.RankBoards[key] = { Rows = rows, Status = status }
	prompt(board, "Abrir classificação global", "Menu", "Rankings")
end
function Map.updateRankings(cache, updated, available)
	for key, board in pairs(Map.RankBoards) do
		local rows = cache[key] or {}
		for rank, t in ipairs(board.Rows) do
			local entry = rows[rank]
			t.Text = entry and rank .. ".  " .. entry.Name .. "    " .. B.compact(entry.Value) or rank .. ".  —"
		end
		board.Status.Text = available[key] and "GLOBAL • atualização a cada 3 min"
			or (
				#rows > 0 and "GLOBAL • exibindo último resultado salvo"
				or "Global indisponível • aguarde DataStore"
			)
	end
end
local function enrich(folder, base, i, col)
	local landmark = Models.world(C.Worlds[i], i, folder, CFrame.new(base + Vector3.new(-65, 0.5, -65)), 4)
	landmark.Name = "SignatureLandmark"
	-- Shop exhibits use the exact same geometry as equipped pickaxes.
	for n = 1, 3 do
		local index = math.clamp((i - 1) * 4 + n, 1, #C.Tools)
		local pos = base + Vector3.new(-60 + (n - 1) * 5, 4, 60)
		cylinder("ToolDisplayStand", Vector3.new(2.4, 3, 3), pos - Vector3.new(0, 2.8, 0), col, folder)
		Models.tool(index, folder, CFrame.new(pos) * CFrame.Angles(0, math.rad(-20), math.rad(-10)), true)
	end
	for n, rank in ipairs({ 2, 4, 5 }) do
		local pos = base + Vector3.new(-68, 3.2, 35 + n * 7)
		cylinder("PetDisplayStand", Vector3.new(1.6, 4, 4), pos - Vector3.new(0, 2.4, 0), col, folder)
		local id = "w" .. i .. "r" .. rank
		Models.pet(C.Pets[id], 0, folder, CFrame.new(pos), true)
	end
	-- Garden islands, puddles and small paths keep the mine area readable.
	for n = 1, 6 do
		local x = n % 2 == 0 and 57 or -57
		local z = -25 + (math.floor((n - 1) / 2)) * 19
		if i == 4 then
			local water = orb(
				"Lagoon",
				Vector3.new(12, 0.3, 9),
				base + Vector3.new(x, 0.3, z),
				Color3.fromRGB(83, 187, 234),
				folder
			)
			water.Material = Enum.Material.Glass
			water.Transparency = 0.3
			water.CanCollide = false
		elseif i == 3 then
			local dune = orb(
				"SandBank",
				Vector3.new(10, 4, 8),
				base + Vector3.new(x, -0.8, z),
				Color3.fromRGB(246, 225, 167),
				folder
			)
			dune.Material = Enum.Material.Sand
		elseif i == 6 then
			local lava = orb(
				"LavaPool",
				Vector3.new(9, 0.3, 7),
				base + Vector3.new(x, 0.3, z),
				Color3.fromRGB(255, 146, 63),
				folder
			)
			lava.Material = Enum.Material.Neon
			lava.CanCollide = false
		else
			local patch = cylinder(
				"GardenPatch",
				Vector3.new(0.2, 9, 9),
				base + Vector3.new(x, 0.3, z),
				col:Lerp(Color3.new(1, 1, 1), 0.2),
				folder
			)
			for petal = 1, 3 do
				orb(
					"Flower",
					Vector3.new(0.8, 0.8, 0.8),
					patch.Position + Vector3.new(petal - 2, 0.6, 0),
					Color3.fromRGB(255, 222, 143),
					folder
				)
			end
		end
	end
	for k = 1, 8 do
		local p = part("PathPaver", Vector3.new(10, 0.1, 1), base + Vector3.new(0, 0.3, -70 + k * 17), col, folder)
		p.CanCollide = false
	end
end
function Map.build()
	Map.Crystals = {}
	Map.Spawns = {}
	Map.Eggs = {}
	Map.AFK = {}
	Map.Sell = {}
	Map.RankBoards = {}
	local old = workspace:FindFirstChild("UniverseMap")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "UniverseMap"
	root.Parent = workspace
	for i, w in ipairs(C.Worlds) do
		local folder = Instance.new("Folder")
		folder.Name = w.Name
		folder:SetAttribute("WorldIndex", i)
		folder.Parent = root
		local base = Vector3.new((i - 1) * 300, 0, 0)
		local col = Color3.fromRGB(table.unpack(w.Color))
		local ground = (i >= 7 and i <= 11) and Color3.fromRGB(28, 32, 55) or col:Lerp(Color3.new(1, 1, 1), 0.45)
		local profile = Presentation.world(i)
		local rim = cylinder(
			"IslandRim",
			Vector3.new(8, 264, 264),
			base + Vector3.new(0, -7, 0),
			ground:Lerp(Color3.new(0, 0, 0), 0.35),
			folder
		)
		rim.Material = Enum.Material.Rock
		local floor =
			cylinder("FloatingIsland", Vector3.new(5, 256, 256), base + Vector3.new(0, -2.5, 0), ground, folder)
		floor.Material = Enum.Material[profile.GroundMaterial]
		for k = 1, 16 do
			local angle = k * math.pi / 8
			local p = part(
				"CliffFacet",
				Vector3.new(24, 20 + (k % 3) * 5, 28),
				base + Vector3.new(math.cos(angle) * 114, -16, math.sin(angle) * 114),
				ground:Lerp(Color3.new(0, 0, 0), 0.48),
				folder,
				"WedgePart"
			)
			p.Material = Enum.Material.Rock
			p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, -angle, 0)
			local wall = part(
				"SafetyBarrier",
				Vector3.new(52, 28, 1),
				base + Vector3.new(math.cos(angle) * 123, 13, math.sin(angle) * 123),
				col,
				folder
			)
			wall.Transparency = 1
			wall.CFrame = CFrame.new(wall.Position) * CFrame.Angles(0, -angle + math.pi / 2, 0)
			local rail = part(
				"CliffRail",
				Vector3.new(36, 1, 1),
				base + Vector3.new(math.cos(angle) * 120, 0.7, math.sin(angle) * 120),
				Color3.fromRGB(102, 116, 130),
				folder
			)
			rail.Material = Enum.Material.Metal
			rail.CFrame = CFrame.new(rail.Position) * CFrame.Angles(0, -angle + math.pi / 2, 0)
		end
		part(
			"MainPath",
			Vector3.new(12, 0.2, 155),
			base + Vector3.new(0, 0.12, 0),
			Color3.fromRGB(236, 235, 251),
			folder
		)
		part(
			"HubPath",
			Vector3.new(155, 0.2, 12),
			base + Vector3.new(0, 0.15, 55),
			Color3.fromRGB(236, 235, 251),
			folder
		)
		local spawnPos = base + Vector3.new(0, 5, 39)
		Map.Spawns[i] = spawnPos
		local welcome = cylinder("ArrivalPad", Vector3.new(0.4, 15, 15), base + Vector3.new(0, 0.4, 39), col, folder)
		welcome.Material = Enum.Material.Neon
		booth(folder, base + Vector3.new(-55, 0.8, 64), Color3.fromRGB(126, 96, 232), "PICARETAS", "Tools")
		booth(folder, base + Vector3.new(55, 0.8, 64), Color3.fromRGB(71, 189, 182), "GEMS LAB", "Upgrades")
		cylinder("EggPedestal", Vector3.new(2, 12, 12), base + Vector3.new(-35, 1.2, 38), col, folder)
		local eggOrb =
			orb("Egg", Vector3.new(5, 7, 5), base + Vector3.new(-35, 6, 38), Color3.fromRGB(255, 217, 103), folder)
		eggOrb.Material = Enum.Material.Neon
		Map.Eggs[i] = eggOrb
		label(eggOrb, "OVO • " .. w.EggCost .. " Coins")
		prompt(eggOrb, "Abrir menu de ovos", "Menu", "Eggs")
		local sell = cylinder(
			"Sell",
			Vector3.new(0.5, 17, 17),
			base + Vector3.new(35, 0.5, 38),
			Color3.fromRGB(255, 209, 92),
			folder
		)
		Map.Sell[i] = sell
		sell.Material = Enum.Material.Neon
		label(sell, "VENDER MOCHILA")
		prompt(sell, "Vender gratuitamente", "Sell")
		local board =
			part("WorldSign", Vector3.new(23, 7, 1), base + Vector3.new(0, 12, 80), Color3.fromRGB(39, 40, 69), folder)
		label(board, w.Name, Vector3.new(0, 0, 0))
		prompt(board, "Guia e desafios", "Menu", "Guide")
		for slot = 1, 20 do
			local x = ((slot - 1) % 5 - 2) * 23
			local z = math.floor((slot - 1) / 5) * 22 - 42
			if x == 0 then
				x = 9
			end
			crystal(folder, base + Vector3.new(x, 4, z), col, i * 100 + slot, i, false)
		end
		crystal(folder, base + Vector3.new(65, 9, -48), col, i * 100 + 99, i, true)
		local arena = cylinder("TitanArena", Vector3.new(0.2, 29, 29), base + Vector3.new(65, 0.4, -48), col, folder)
		arena.Material = Enum.Material.Neon
		label(arena, "TITÃ • jogue em equipe", Vector3.new(0, 22, 0))
		if C.Worlds[i + 1] then
			local portal = part("Portal", Vector3.new(15, 22, 2), base + Vector3.new(0, 11, -80), col, folder)
			portal.Transparency = 0.65
			portal.Material = Enum.Material.Neon
			portal.CanCollide = false
			for _, x in ipairs({ -9, 9 }) do
				local pillar = part("PortalPillar", Vector3.new(3, 24, 3), base + Vector3.new(x, 12, -80), col, folder)
				pillar.Material = Enum.Material.Neon
			end
			part("PortalArch", Vector3.new(21, 3, 3), base + Vector3.new(0, 25, -80), col, folder)
			label(portal, "PRÓXIMO: " .. C.Worlds[i + 1].Name, Vector3.new(0, 15, 0))
			prompt(portal, "Ver mundos e desbloquear", "Menu", "Worlds")
		end
		local details = Instance.new("Folder")
		details.Name = "GraphicsDetails"
		details.Parent = folder
		decorate(details, base, i, col)
		for k = 1, 6 do
			local angle = k * math.pi / 3
			local point = base + Vector3.new(math.cos(angle) * 111, -3, math.sin(angle) * 111)
			local peak = part(
				"BackdropPeak",
				Vector3.new(28, 20 + (k % 3) * 9, 25),
				point,
				col:Lerp(Color3.new(0.15, 0.2, 0.25), 0.5),
				details,
				"WedgePart"
			)
			peak.CanCollide = false
			peak.Material = i == 3 and Enum.Material.Sand or i == 12 and Enum.Material.Snow or Enum.Material.Rock
			peak.CFrame = CFrame.new(point) * CFrame.Angles(0, -angle, 0)
			local cap = part(
				"PeakCap",
				Vector3.new(18, 5, 17),
				point + Vector3.new(0, 10 + (k % 3) * 4, 0),
				col:Lerp(Color3.new(1, 1, 1), 0.4),
				details,
				"WedgePart"
			)
			cap.CanCollide = false
			cap.Material = i == 12 and Enum.Material.Snow or Enum.Material.Slate
		end
		enrich(folder, base, i, col)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "UniverseSpawn"
	spawn.Size = Vector3.new(8, 0.5, 8)
	spawn.Position = Map.Spawns[1] - Vector3.new(0, 4.5, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.Parent = root
	for _, vip in ipairs({ false, true }) do
		local p = cylinder(
			vip and "VIPAFK" or "AFK",
			Vector3.new(0.5, 19, 19),
			Vector3.new(vip and 75 or -75, 0.5, 83),
			vip and Color3.fromRGB(255, 202, 92) or Color3.fromRGB(117, 200, 245),
			root
		)
		label(p, vip and "LOUNGE VIP AFK • 3x" or "AFK • presentes a cada 30s")
		table.insert(Map.AFK, { Part = p, VIP = vip })
		prompt(p, vip and "Benefícios VIP" or "Presentes gratuitos", "Menu", vip and "Shop" or "Rewards")
	end
	for n, key in ipairs({ "Coins", "Rebirths", "Pets", "Gems" }) do
		rankingBoard(root, key, -49.5 + (n - 1) * 33, Color3.fromRGB(255, 213, 114))
	end
	local light = game:GetService("Lighting")
	light.ClockTime = 16.3
	light.EnvironmentDiffuseScale = 0.75
	light.EnvironmentSpecularScale = 0.9
	light.ExposureCompensation = 0.05
	pcall(function()
		light.LightingStyle = Enum.LightingStyle.Realistic
		light.PrioritizeLightingQuality = true
	end)
	light.Brightness = 2
	light.Ambient = Color3.fromRGB(119, 116, 162)
	light.OutdoorAmbient = Color3.fromRGB(159, 167, 196)
	local atmosphere = light:FindFirstChild("UniverseAtmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "UniverseAtmosphere"
	atmosphere.Density = 0.22
	atmosphere.Color = Color3.fromRGB(205, 221, 255)
	atmosphere.Decay = Color3.fromRGB(115, 91, 160)
	atmosphere.Parent = light
	local bloom = light:FindFirstChild("UniverseBloom") or Instance.new("BloomEffect")
	bloom.Name = "UniverseBloom"
	bloom.Intensity = 0.1
	bloom.Size = 18
	bloom.Threshold = 1.8
	bloom.Parent = light
end
function Map.reset(c)
	local rare = not c.Boss and rng:NextNumber() < 0.07
	local w = C.Worlds[c.World]
	c.Rare = rare
	c.MaxHealth = w.Health * (c.Boss and 100 or rare and 4 or 1)
	c.Health = c.MaxHealth
	c.RespawnAt = 0
	c.Contributors = {}
	c.Part.Transparency = c.Boss and 0 or 0.08
	c.Part:SetAttribute("Health", c.Health)
	c.Part:SetAttribute("MaxHealth", c.MaxHealth)
	c.Part:SetAttribute("Boss", c.Boss)
	local col = rare and Color3.fromRGB(255, 223, 91) or Color3.fromRGB(table.unpack(w.Color))
	c.Part.Color = col
	for _, p in ipairs(c.Pieces) do
		p.Transparency = c.Boss and 0 or p.Material == Enum.Material.Glass and 0.1 or 0
		if not c.Boss then
			p.Color = col
		end
		if p:GetAttribute("CrystalId") then
			p:SetAttribute("Health", c.Health)
			p:SetAttribute("MaxHealth", c.MaxHealth)
			p:SetAttribute("Alive", true)
			p:SetAttribute("Boss", c.Boss)
		end
	end
	c.Label.Text = (c.Boss and "TITÃ " or rare and "★ RARO " or "") .. math.ceil(c.Health) .. " HP"
	c.Part:SetAttribute("Alive", true)
	c.Bar.Size = UDim2.fromScale(1, 1)
	c.Bar.BackgroundColor3 = col
end
function Map.hit(c, damage)
	c.Health = math.max(0, c.Health - damage)
	c.Part:SetAttribute("Health", c.Health)
	for _, p in ipairs(c.Pieces) do
		if p:GetAttribute("CrystalId") then
			p:SetAttribute("Health", c.Health)
		end
	end
	c.Bar.Size = UDim2.fromScale(c.Health / c.MaxHealth, 1)
	c.Label.Text = (c.Boss and "TITÃ " or "") .. math.ceil(c.Health) .. " HP"
	if c.Health == 0 then
		c.Part.Transparency = 1
		for _, p in ipairs(c.Pieces) do
			p.Transparency = 1
			if p:GetAttribute("CrystalId") then
				p:SetAttribute("Alive", false)
			end
		end
		c.Label.Text = c.Boss and "Retorna em 3 minutos" or ""
		c.Part:SetAttribute("Alive", false)
		c.RespawnAt = os.clock() + (c.Boss and C.BossRespawn or 5)
		return true
	end
	return false
end
function Map.step()
	for _, c in pairs(Map.Crystals) do
		if c.RespawnAt > 0 and os.clock() >= c.RespawnAt then
			Map.reset(c)
		end
	end
end
function Map.teleport(player, world)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(Map.Spawns[world])
	end
end
function Map.near(player, position, distance)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return root and h and h.Health > 0 and (root.Position - position).Magnitude <= distance
end
return Map
