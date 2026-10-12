local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Map = { Crystals = {}, Spawns = {}, Eggs = {}, AFK = {}, Sell = {} }
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
	p.Material = Enum.Material.SmoothPlastic
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
	local floor = part(title .. "Base", Vector3.new(18, 1, 14), base, color, parent)
	part("Counter", Vector3.new(15, 3, 3), base + Vector3.new(0, 2, -3), color:Lerp(Color3.new(1, 1, 1), 0.4), parent)
	for _, x in ipairs({ -7, 7 }) do
		part("Pillar", Vector3.new(0.8, 10, 0.8), base + Vector3.new(x, 5, -4), Color3.fromRGB(40, 46, 67), parent)
	end
	local roof = part("Canopy", Vector3.new(19, 1.5, 9), base + Vector3.new(0, 10, -3), color, parent)
	label(roof, title, Vector3.new(0, 2, 0))
	prompt(floor, "Abrir " .. title, "Menu", menu)
end
local function crystal(folder, pos, col, id, world, boss)
	local height = boss and 17 or 7
	local core = part(
		boss and "Titan" or "Crystal",
		Vector3.new(boss and 10 or 3, height, boss and 10 or 3),
		pos,
		col,
		folder,
		boss and "Part" or "WedgePart"
	)
	core.CanCollide = false
	core.CanQuery = true
	core.Material = Enum.Material.Neon
	core:SetAttribute("CrystalId", id)
	core.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(id % 180), math.rad(boss and 0 or -12))
	local pieces = {}
	if boss then
		core.Shape = Enum.PartType.Ball
	end
	for side = -1, 1, 2 do
		local p = part(
			"Shard",
			Vector3.new(boss and 5 or 1.8, height * 0.7, boss and 5 or 1.8),
			pos + Vector3.new(side * (boss and 6 or 2.2), -height * 0.15, 0),
			col,
			folder,
			"WedgePart"
		)
		p.Material = Enum.Material.Neon
		p.CanCollide = false
		p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, side * 0.5, side * 0.3)
		table.insert(pieces, p)
	end
	cylinder(
		"Deposit",
		Vector3.new(1, boss and 19 or 9, boss and 19 or 9),
		pos - Vector3.new(0, height / 2, 0),
		Color3.fromRGB(36, 42, 66),
		folder
	)
	local c = {
		Part = core,
		Label = label(core, "", Vector3.new(0, height * 0.65, 0)),
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
		light.Range = 24
		light.Brightness = 1
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
function Map.build()
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
		folder.Parent = root
		local base = Vector3.new((i - 1) * 300, 0, 0)
		local col = Color3.fromRGB(table.unpack(w.Color))
		local ground = (i >= 7 and i <= 11) and Color3.fromRGB(28, 32, 55) or col:Lerp(Color3.new(1, 1, 1), 0.45)
		part("FloatingIsland", Vector3.new(190, 8, 190), base + Vector3.new(0, -4, 0), ground, folder)
		local bottom = part(
			"IslandCore",
			Vector3.new(150, 20, 150),
			base + Vector3.new(0, -18, 0),
			ground:Lerp(Color3.new(0, 0, 0), 0.2),
			folder,
			"WedgePart"
		)
		bottom.Material = Enum.Material.Slate
		for _, edge in ipairs({ { 0, 93, 186, 2 }, { 0, -93, 186, 2 }, { 93, 0, 2, 186 }, { -93, 0, 2, 186 } }) do
			local rail = part(
				"LightRail",
				Vector3.new(edge[3], 0.8, edge[4]),
				base + Vector3.new(edge[1], 1, edge[2]),
				col,
				folder
			)
			rail.Material = Enum.Material.Neon
			local wall = part(
				"SafetyBarrier",
				Vector3.new(edge[3], 30, edge[4]),
				base + Vector3.new(edge[1], 14, edge[2]),
				col,
				folder
			)
			wall.Transparency = 1
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
		decorate(folder, base, i, col)
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
	local light = game:GetService("Lighting")
	light.ClockTime = 15
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
	bloom.Intensity = 0.25
	bloom.Size = 18
	bloom.Threshold = 1.5
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
	c.Part.Transparency = 0
	c.Part:SetAttribute("Health", c.Health)
	c.Part:SetAttribute("MaxHealth", c.MaxHealth)
	c.Part:SetAttribute("Boss", c.Boss)
	local col = rare and Color3.fromRGB(255, 223, 91) or Color3.fromRGB(table.unpack(w.Color))
	c.Part.Color = col
	for _, p in ipairs(c.Pieces) do
		p.Transparency = 0
		p.Color = col
	end
	c.Label.Text = (c.Boss and "TITÃ " or rare and "★ RARO " or "") .. math.ceil(c.Health) .. " HP"
	c.Part:SetAttribute("Alive", true)
end
function Map.hit(c, damage)
	c.Health = math.max(0, c.Health - damage)
	c.Part:SetAttribute("Health", c.Health)
	c.Label.Text = (c.Boss and "TITÃ " or "") .. math.ceil(c.Health) .. " HP"
	if c.Health == 0 then
		c.Part.Transparency = 1
		for _, p in ipairs(c.Pieces) do
			p.Transparency = 1
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
