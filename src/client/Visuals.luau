local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Run = game:GetService("RunService")
local Sound = game:GetService("SoundService")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Graphics = require(script.Parent.Graphics)
local Models = require(game.ReplicatedStorage.UniverseMiner.Models)
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
	emitter:Emit(Graphics.particles(count))
	Tween:Create(light, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(p, 1)
end
function V.celebrate(count)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		V.burst(root.Position, count, gold)
	end
end
function V.petModel(info, tier, parent)
	local model = Models.pet(info, tier or 0, parent, CFrame.new(), false)
	model.PrimaryPart.Anchored = true
	return model
end
function V.portrait(parent, id, tier, locked, kind, index)
	local imageId = kind == "Tool" and C.ToolImages[index] or C.PetImages[id]
	if imageId and imageId ~= "" and not locked then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = imageId
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = parent
		return image
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Portrait"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(220, 230, 255)
	viewport.LightColor = Color3.fromRGB(255, 244, 220)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local model = kind == "Tool"
			and Models.tool(index, world, CFrame.new() * CFrame.Angles(0, math.rad(-25), math.rad(-18)), true)
		or Models.pet(C.Pets[id], tier or 0, world, CFrame.new() * CFrame.Angles(0, math.rad(-18), 0), true)
	if locked then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") then
				p.Color = Color3.fromRGB(117, 128, 151)
				p.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.CFrame = CFrame.new(
		Vector3.new(0, kind == "Tool" and 0.9 or 0.5, kind == "Tool" and -8 or -6),
		Vector3.new(0, kind == "Tool" and 0.7 or 0.2, 0)
	)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
end
function V.worldPortrait(parent, index)
	local imageId = C.WorldImages[index]
	if imageId and imageId ~= "" then
		local image = Instance.new("ImageLabel")
		image.Size = UDim2.fromScale(1, 1)
		image.BackgroundTransparency = 1
		image.Image = imageId
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = parent
		return image
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "WorldPreview"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(220, 231, 250)
	viewport.LightColor = Color3.fromRGB(255, 245, 224)
	viewport.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	Models.world(C.Worlds[index], index, world, CFrame.new(), 1)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 37
	camera.CFrame = CFrame.new(Vector3.new(10, 7, -12), Vector3.new(0, 2.4, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
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
		p.PrimaryPart.CFrame =
			p.PrimaryPart.CFrame:Lerp(CFrame.new(pos, pos + root.CFrame.LookVector), math.min(1, dt * 12))
	end
end)
return V
