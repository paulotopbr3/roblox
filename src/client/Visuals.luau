local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Run = game:GetService("RunService")
local Sound = game:GetService("SoundService")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local player = Players.LocalPlayer
local V = { State = nil, Pets = {}, Signature = "" }
local gold = Color3.fromRGB(255, 212, 108)
function V.sound(kind)
	if V.State and V.State.Settings.Effects == false then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = C.SoundIds[kind] or ""
	if s.SoundId == "" then
		s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	end
	s.Volume = 0.12
	s.PlaybackSpeed = kind == "Mine" and 1.5 or kind == "Rebirth" and 0.75 or 1
	s.Parent = Sound
	s:Play()
	Debris:AddItem(s, 4)
end
function V.burst(position, count, col)
	if V.State and V.State.Settings.Effects == false then
		return
	end
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.Position = position
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = col or gold
	light.Range = 12
	light.Brightness = 2
	light.Parent = p
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Color = ColorSequence.new(col or gold)
	emitter.Lifetime = NumberRange.new(0.25, 0.6)
	emitter.Speed = NumberRange.new(4, 10)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = p
	emitter:Emit(count)
	Tween:Create(light, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(p, 1)
end
function V.celebrate(count)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		V.burst(root.Position, count, gold)
	end
end
local function piece(parent, name, size, offset, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Shape = shape or Enum.PartType.Block
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.CFrame = parent.CFrame * CFrame.new(offset)
	p.Parent = parent
	local weld = Instance.new("Weld")
	weld.Part0 = parent
	weld.Part1 = p
	weld.C0 = CFrame.new(offset)
	weld.Parent = p
	return p
end
function V.petModel(info, tier, parent)
	local p = Instance.new("Part")
	p.Name = info.Name
	p.Size = Vector3.new(1.8, 1.7, 1.7)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Color = tier == 1 and gold
		or tier == 2 and Color3.fromRGB(167, 137, 255)
		or Color3.fromHSV(info.World / 16, 0.5, 1)
	p.Material = tier > 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.Parent = parent
	piece(
		p,
		"Eye",
		Vector3.new(0.25, 0.35, 0.15),
		Vector3.new(-0.4, 0.2, -0.88),
		Color3.fromRGB(20, 25, 48),
		Enum.PartType.Ball
	)
	piece(
		p,
		"Eye",
		Vector3.new(0.25, 0.35, 0.15),
		Vector3.new(0.4, 0.2, -0.88),
		Color3.fromRGB(20, 25, 48),
		Enum.PartType.Ball
	)
	for _, side in ipairs({ -1, 1 }) do
		piece(p, "Ear", Vector3.new(0.5, 0.7, 0.5), Vector3.new(side * 0.55, 1, 0), p.Color)
	end
	if info.Rank >= 4 then
		for _, side in ipairs({ -1, 1 }) do
			piece(p, "Wing", Vector3.new(1.3, 0.25, 1.1), Vector3.new(side * 1.4, 0.2, 0), gold)
		end
	end
	if info.Rank >= 5 then
		piece(p, "Crown", Vector3.new(1, 0.3, 0.7), Vector3.new(0, 1.25, 0), gold)
	end
	return p
end
function V.update(state)
	V.State = state
	local ids = {}
	for _, uid in ipairs(state.Equipped) do
		for _, pet in ipairs(state.Pets) do
			if uid == pet.Uid then
				table.insert(ids, uid .. ":" .. (pet.Tier or 0))
				break
			end
		end
	end
	local signature = table.concat(ids, ",")
	if signature == V.Signature then
		return
	end
	V.Signature = signature
	for _, p in ipairs(V.Pets) do
		p:Destroy()
	end
	V.Pets = {}
	for _, uid in ipairs(state.Equipped) do
		for _, pet in ipairs(state.Pets) do
			if pet.Uid == uid then
				table.insert(V.Pets, V.petModel(C.Pets[pet.Id], pet.Tier or 0, workspace))
				break
			end
		end
	end
end
Run.RenderStepped:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local reduced = V.State and V.State.Settings.ReducedMotion
	for i, p in ipairs(V.Pets) do
		local angle = i * math.pi * 2 / math.max(1, #V.Pets)
		local pos = root.Position
			+ Vector3.new(
				math.cos(angle) * 4.5,
				1 + (reduced and 0 or math.sin(os.clock() * 3 + i) * 0.3),
				math.sin(angle) * 4.5
			)
		p.CFrame = p.CFrame:Lerp(CFrame.new(pos, pos + root.CFrame.LookVector), math.min(1, dt * 12))
	end
end)
return V
