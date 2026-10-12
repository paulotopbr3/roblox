local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Models = require(game.ReplicatedStorage.UniverseMiner.Models)
local Gear = {}
function Gear.update(player, index)
	local char = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not backpack or not humanoid or humanoid.Health <= 0 then
		return
	end
	for _, container in ipairs({ char, backpack }) do
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("UniversePickaxe") then
				if item:GetAttribute("ToolIndex") == index then
					if item.Parent == backpack then
						humanoid:EquipTool(item)
					end
					return
				end
				item:Destroy()
			end
		end
	end
	local tool = Instance.new("Tool")
	tool.Name = C.Tools[index].Name
	tool.ToolTip = "Dano " .. C.Tools[index].Damage .. " • minerar cristais"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.4, 0) * CFrame.Angles(0, 0, math.rad(-12))
	tool:SetAttribute("UniversePickaxe", true)
	tool:SetAttribute("ToolIndex", index)
	local model = Models.tool(index, tool, CFrame.new(), false)
	for _, child in ipairs(model:GetChildren()) do
		child.Parent = tool
	end
	model:Destroy()
	tool.Parent = backpack
	humanoid:EquipTool(tool)
end
function Gear.swing(player)
	local char = player.Character
	if not char then
		return
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("UniversePickaxe") then
		local signal = Instance.new("StringValue")
		signal.Name = "toolanim"
		signal.Value = "Slash"
		signal.Parent = tool
		game:GetService("Debris"):AddItem(signal, 0.25)
	end
end
return Gear
