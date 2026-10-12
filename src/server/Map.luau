local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Map = { Crystals = {}, Spawns = {}, Eggs = {}, AFK = {}, Sell = {} }
local rng = Random.new()
local function part(name, size, pos, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function label(p, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(230, 55)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 100
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = gui
	return t
end
function Map.build()
	local root = Instance.new("Folder")
	root.Name = "UniverseMap"
	root.Parent = workspace
	for i, w in ipairs(C.Worlds) do
		local folder = Instance.new("Folder")
		folder.Name = w.Name
		folder.Parent = root
		local base = Vector3.new((i - 1) * 280, 0, 0)
		local col = Color3.fromRGB(table.unpack(w.Color))
		part("Island", Vector3.new(160, 8, 160), base + Vector3.new(0, -4, 0), col, folder)
		for _, edge in ipairs({ { 0, 0, 80, 160, 20, 2 }, { 0, 0, -80, 160, 20, 2 }, { 80, 0, 0, 2, 20, 160 }, {
			-80,
			0,
			0,
			2,
			20,
			160,
		} }) do
			part(
				"Boundary",
				Vector3.new(edge[4], edge[5], edge[6]),
				base + Vector3.new(edge[1], 7, edge[3]),
				col:Lerp(Color3.new(0, 0, 0), 0.3),
				folder
			)
		end
		Map.Spawns[i] = base + Vector3.new(0, 5, 55)
		local sign = part("WorldSign", Vector3.new(18, 3, 2), base + Vector3.new(0, 5, 69), col, folder)
		label(sign, w.Name)
		local egg =
			part("Egg", Vector3.new(5, 7, 5), base + Vector3.new(-45, 4, 48), Color3.fromRGB(255, 213, 82), folder)
		egg.Shape = Enum.PartType.Ball
		egg.Material = Enum.Material.Neon
		Map.Eggs[i] = egg
		label(egg, "EGG • " .. w.EggCost .. " Coins")
		local sell = part(
			"Sell",
			Vector3.new(16, 0.5, 16),
			base + Vector3.new(35, 0.4, 52),
			Color3.fromRGB(255, 207, 60),
			folder
		)
		Map.Sell[i] = sell
		label(sell, "SELL • vender mochila")
		for slot = 1, 20 do
			local x = ((slot - 1) % 5 - 2) * 22
			local z = math.floor((slot - 1) / 5) * 22 - 48
			local crystal = part("Crystal", Vector3.new(5, 9, 5), base + Vector3.new(x, 5, z), col, folder)
			crystal.Material = Enum.Material.Neon
			crystal.CanCollide = false
			local id = i * 100 + slot
			crystal:SetAttribute("CrystalId", id)
			local text = label(crystal, "")
			Map.Crystals[id] = { Part = crystal, Label = text, World = i, RespawnAt = 0 }
			Map.reset(Map.Crystals[id])
		end
		for k = 1, 8 do
			local p = part(
				"Decoration",
				Vector3.new(4, 12 + k % 3 * 4, 4),
				base + Vector3.new(k % 2 == 0 and -70 or 70, 7, k * 15 - 65),
				col:Lerp(Color3.new(1, 1, 1), 0.2),
				folder
			)
			if i == 2 then
				p.Material = Enum.Material.Grass
			elseif i >= 7 then
				p.Material = Enum.Material.Neon
			end
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "UniverseSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Map.Spawns[1] - Vector3.new(0, 4, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root
	for _, vip in ipairs({ false, true }) do
		local p = part(
			vip and "VIPAFK" or "AFK",
			Vector3.new(18, 1, 18),
			Vector3.new(vip and 55 or -55, 0.5, 68),
			vip and Color3.fromRGB(255, 201, 40) or Color3.fromRGB(76, 211, 244),
			root
		)
		label(p, vip and "VIP AFK • 3x" or "AFK Rewards")
		table.insert(Map.AFK, { Part = p, VIP = vip })
	end
end
function Map.reset(c)
	local rare = rng:NextNumber() < 0.07
	local w = C.Worlds[c.World]
	c.Rare = rare
	c.MaxHealth = w.Health * (rare and 4 or 1)
	c.Health = c.MaxHealth
	c.RespawnAt = 0
	c.Part.Transparency = 0
	c.Part:SetAttribute("Health", c.Health)
	c.Part:SetAttribute("MaxHealth", c.MaxHealth)
	c.Part.Color = rare and Color3.fromRGB(255, 222, 65) or Color3.fromRGB(table.unpack(w.Color))
	c.Label.Text = (rare and "★ RARE " or "") .. c.Health .. " HP"
	c.Part:SetAttribute("Alive", true)
end
function Map.hit(c, damage)
	c.Health = math.max(0, c.Health - damage)
	c.Part:SetAttribute("Health", c.Health)
	c.Label.Text = c.Health .. " HP"
	if c.Health == 0 then
		c.Part.Transparency = 1
		c.Label.Text = ""
		c.Part:SetAttribute("Alive", false)
		c.RespawnAt = os.clock() + 5
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
