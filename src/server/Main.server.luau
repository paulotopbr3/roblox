local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Data = require(script.Parent.Data)
local Map = require(script.Parent.Map)
local Game = require(script.Parent.Game)
local Commerce = require(script.Parent.Commerce)
local Rankings = require(script.Parent.Rankings)
local shared = game.ReplicatedStorage.UniverseMiner
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = shared
local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes
local updates = Instance.new("RemoteEvent")
updates.Name = "Update"
updates.Parent = remotes
Game.Store = function()
	return Commerce.Catalog
end
Game.init(updates)
Map.Interact = function(player, key, arg)
	if not Data.writable(player) or not Game.rate(player) then
		return
	end
	if key == "Menu" then
		Game.emit(player, "Open", arg)
	else
		Game.action(player, key, arg)
	end
end
Map.build()
Commerce.init()
Game.subscribe()
local closing = false
local function character(player, char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	for _ = 1, 100 do
		if Data.Sessions[player] then
			break
		end
		task.wait(0.1)
	end
	local s = Data.Sessions[player]
	if not s then
		return
	end
	Map.teleport(player, s.Data.World)
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if hand and not char:FindFirstChild("PickaxeHandle") then
		local handle = Instance.new("Part")
		handle.Name = "PickaxeHandle"
		handle.Size = Vector3.new(0.3, 3, 0.3)
		handle.Color = Color3.fromRGB(115, 78, 48)
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = char
		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = handle
		weld.C0 = CFrame.new(0, -0.6, -0.5) * CFrame.Angles(math.rad(40), 0, 0)
		weld.Parent = handle
		local head = Instance.new("Part")
		head.Name = "PickaxeHead"
		head.Size = Vector3.new(2.5, 0.45, 0.55)
		head.Color = Color3.fromRGB(137, 202, 230)
		head.Material = Enum.Material.Metal
		head.CanCollide = false
		head.Massless = true
		head.Parent = char
		local joint = Instance.new("Weld")
		joint.Part0 = handle
		joint.Part1 = head
		joint.C0 = CFrame.new(0, 1.3, 0)
		joint.Parent = head
	end
end
local function join(player)
	player.CharacterAdded:Connect(function(char)
		task.spawn(character, player, char)
	end)
	local s, err = Data.load(player)
	if not s then
		player:Kick(err)
		return
	end
	if not player.Parent or closing then
		Data.release(player)
		return
	end
	Game.join(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	for _, key in ipairs({ "Coins", "Gems", "Rebirths" }) do
		local v = Instance.new("NumberValue")
		v.Name = key
		v.Parent = stats
	end
	if player.Character then
		task.spawn(character, player, player.Character)
	end
	Game.snapshot(player)
	task.spawn(Commerce.refresh, player)
end
Players.PlayerAdded:Connect(join)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(join, player)
end
Players.PlayerRemoving:Connect(function(player)
	Game.Runtime[player] = nil
	local s = Data.Sessions[player]
	if s and not s.Temporary then
		task.spawn(Rankings.write, player, s.Data)
	end
	Data.release(player)
end)
action.OnServerEvent:Connect(function(player, key, arg)
	if type(key) ~= "string" or #key > 20 or not Game.rate(player) or not Data.writable(player) then
		return
	end
	if key == "Purchase" then
		Commerce.prompt(player, arg)
	elseif key == "Rankings" then
		Game.emit(player, "Rankings", { Rows = Rankings.Cache, Updated = Rankings.Updated })
	else
		Game.action(player, key, arg)
	end
end)
task.spawn(function()
	while not closing do
		Game.tick()
		task.wait(0.15)
	end
end)
task.spawn(function()
	while not closing do
		task.wait(2)
		for player, s in pairs(Data.Sessions) do
			if not s.Closing then
				local head = player.Character and player.Character:FindFirstChild("PickaxeHead")
				if head then
					head.Color = Color3.fromHSV((s.Data.Tool / #C.Tools) * 0.8, 0.7, 1)
					head.Material = s.Data.Tool > 12 and Enum.Material.Neon or Enum.Material.Metal
				end
				Game.snapshot(player)
				local stats = player:FindFirstChild("leaderstats")
				if stats then
					for _, key in ipairs({ "Coins", "Gems", "Rebirths" }) do
						stats[key].Value = s.Data[key]
					end
				end
			end
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(C.AutosaveSeconds)
		for player, s in pairs(Data.Sessions) do
			if not s.Closing then
				task.spawn(function()
					if Data.save(player, false) and not s.Temporary then
						Rankings.write(player, s.Data)
					end
				end)
			end
		end
	end
end)
task.spawn(function()
	while not closing do
		Rankings.refresh()
		task.wait(180)
	end
end)
game:BindToClose(function()
	closing = true
	local count = 0
	for player, s in pairs(Data.Sessions) do
		if not s.Closing then
			count += 1
			task.spawn(function()
				Data.release(player)
				count -= 1
			end)
		end
	end
	local deadline = os.clock() + 25
	while count > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
