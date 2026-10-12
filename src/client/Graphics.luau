local Lighting = game:GetService("Lighting")
local Input = game:GetService("UserInputService")
local P = require(game.ReplicatedStorage.UniverseMiner.Presentation)
local G = { Key = "", Effective = "High" }
local function effect(class, name)
	local value = Lighting:FindFirstChild(name)
	if not value then
		value = Instance.new(class)
		value.Name = name
		value.Parent = Lighting
	end
	return value
end
function G.apply(state)
	local mode = state.Settings.Graphics or "Auto"
	local quality = P.quality(mode, Input.TouchEnabled)
	local key = state.World .. "|" .. quality.Mode .. "|" .. tostring(state.Settings.Effects ~= false)
	if key == G.Key then
		return
	end
	G.Key = key
	G.Effective = quality.Mode
	local profile = P.world(state.World)
	local sky = Color3.fromRGB(table.unpack(profile.Sky))
	Lighting.Ambient = sky:Lerp(Color3.fromRGB(35, 45, 65), 0.7)
	Lighting.OutdoorAmbient = sky:Lerp(Color3.fromRGB(70, 80, 100), 0.5)
	Lighting.ClockTime = profile.ClockTime
	Lighting.ExposureCompensation = profile.Exposure
	Lighting.GlobalShadows = quality.Shadows
	Lighting.EnvironmentDiffuseScale = 0.75
	Lighting.EnvironmentSpecularScale = quality.Mode == "Low" and 0.4 or 0.9
	pcall(function()
		Lighting.LightingStyle = Enum.LightingStyle.Realistic
		Lighting.PrioritizeLightingQuality = quality.Mode == "High"
	end)
	local atmosphere = effect("Atmosphere", "UniverseAtmosphere")
	atmosphere.Color = Color3.fromRGB(table.unpack(profile.Sky))
	atmosphere.Density = quality.Mode == "Low" and 0.16 or 0.23
	atmosphere.Haze = 0.8
	atmosphere.Glare = 0.08
	local grade = effect("ColorCorrectionEffect", "UniverseGrade")
	grade.Enabled = true
	grade.Contrast = profile.Contrast
	grade.Saturation = profile.Saturation
	grade.Brightness = 0
	grade.TintColor = Color3.fromRGB(255, 250, 243)
	local bloom = effect("BloomEffect", "UniverseBloom")
	bloom.Enabled = quality.Bloom and state.Settings.Effects ~= false
	bloom.Intensity = 0.1
	bloom.Size = 20
	bloom.Threshold = 1.8
	-- Cosmetic LOD: physics, prompts, deposits and hit targets are never hidden.
	local map = workspace:FindFirstChild("UniverseMap")
	if map then
		for _, folder in ipairs(map:GetChildren()) do
			local details = folder:FindFirstChild("GraphicsDetails")
			if details then
				local active = folder:GetAttribute("WorldIndex") == state.World
				for _, object in ipairs(details:GetDescendants()) do
					if object:IsA("BasePart") then
						object.LocalTransparencyModifier = active and quality.Details and 0 or 1
					elseif object:IsA("PointLight") or object:IsA("ParticleEmitter") then
						object.Enabled = active and quality.Details and state.Settings.Effects ~= false
					end
				end
			end
		end
	end
end
function G.particles(request)
	local quality = P.quality(G.Effective, false)
	return math.min(request, quality.Particles)
end
return G
