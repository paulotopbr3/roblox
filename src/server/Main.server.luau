local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Data = require(script.Parent.Data)
local Map = require(script.Parent.Map)
local Game = require(script.Parent.Game)
local Commerce = require(script.Parent.Commerce)
local Rankings = require(script.Parent.Rankings)
local Gear = require(script.Parent.Gear)
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
Game.Swing = Gear.swing
Game.Equip = Gear.update
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
	Gear.update(player, s.Data.Tool)
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
		Game.emit(
			player,
			"Rankings",
			{ Rows = Rankings.Cache, Updated = Rankings.Updated, Available = Rankings.Available }
		)
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
				Gear.update(player, s.Data.Tool)
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
		Map.updateRankings(Rankings.Cache, Rankings.Updated, Rankings.Available)
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
