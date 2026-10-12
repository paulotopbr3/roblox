local Art = require(script.Parent.Art)
local Models = {}
local function build(spec, parent, pose, anchored)
	local model = Instance.new("Model")
	model.Name = spec.Name or "UniverseModel"
	model.Parent = parent
	local root
	for _, def in ipairs(spec.Parts) do
		local p = Instance.new(def.Shape == "Wedge" and "WedgePart" or "Part")
		p.Name = def.Name
		p.Size = Vector3.new(table.unpack(def.Size))
		p.Color = Color3.fromRGB(table.unpack(def.Color))
		p.Material = def.Glow and Enum.Material.Neon
			or (def.Material and Enum.Material[def.Material] or Enum.Material.SmoothPlastic)
		p.Reflectance = def.Reflectance or 0
		p.Transparency = def.Transparency or 0
		p.CastShadow = not def.Glow
		p.CanCollide = false
		p.CanQuery = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = anchored ~= false
		p.CFrame = (pose or CFrame.new())
			* CFrame.new(table.unpack(def.Position))
			* CFrame.Angles(math.rad(def.Angles[1]), math.rad(def.Angles[2]), math.rad(def.Angles[3]))
		if def.Shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		elseif def.Shape == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		end
		p.Parent = model
		if not root then
			root = p
			model.PrimaryPart = p
		elseif anchored == false then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	return model
end
function Models.pet(info, tier, parent, pose, anchored)
	local spec = Art.pet(info, tier or 0)
	spec.Name = info.Name
	return build(spec, parent, pose, anchored)
end
function Models.tool(index, parent, pose, anchored)
	local spec = Art.tool(index)
	spec.Name = "PickaxeModel"
	return build(spec, parent, pose, anchored)
end
function Models.world(info, index, parent, pose, scale)
	local spec = Art.world(info, index)
	for _, p in ipairs(spec.Parts) do
		for n = 1, 3 do
			p.Size[n] *= scale or 1
			p.Position[n] *= scale or 1
		end
	end
	return build(spec, parent, pose, true)
end
return Models
