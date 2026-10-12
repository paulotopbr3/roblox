local Http = game:GetService("HttpService")
local Messaging = game:GetService("MessagingService")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local B = require(game.ReplicatedStorage.UniverseMiner.Balance)
local P = require(game.ReplicatedStorage.UniverseMiner.Progression)
local Content = require(script.Parent.Content)
local Economy = require(game.ReplicatedStorage.UniverseMiner.Economy)
local Data = require(script.Parent.Data)
local Map = require(script.Parent.Map)
local Game = { Runtime = {} }
local rng = Random.new()
local outbound
function Game.init(remote)
	outbound = remote
	Content.init(Game)
end
function Game.emit(player, kind, payload)
	outbound:FireClient(player, kind, payload)
end
function Game.notice(player, text)
	Game.emit(player, "Notice", text)
end
function Game.event()
	local now = os.time()
	local cycle = math.floor(now / C.EventPeriod)
	local elapsed = now % C.EventPeriod
	local names = { "Coins", "Luck", "Gems", "Exclusive" }
	return {
		Kind = names[cycle % 4 + 1],
		Active = elapsed < C.EventDuration,
		Ends = cycle * C.EventPeriod + C.EventDuration,
		Next = (cycle + 1) * C.EventPeriod,
	}
end
local function clamp(n)
	return math.min(C.MaxNumber, math.max(0, n))
end
function Game.daily(d)
	local day = math.floor(os.time() / 86400)
	if d.Daily.Day ~= day then
		d.Daily = { Day = day, Crystals = 0, Coins = 0, Eggs = 0, Claimed = {} }
	end
end
function Game.mult(d, kind)
	local value = 1
	for _, uid in ipairs(d.Equipped) do
		for _, pet in ipairs(d.Pets) do
			if pet.Uid == uid then
				value += (C.Pets[pet.Id][kind] or 0) * P.variant(pet.Tier)
				break
			end
		end
	end
	if kind == "Coins" or kind == "Damage" then
		value *= B.rebirthMultiplier(d.Rebirths)
	end
	if kind == "Damage" then
		value *= 1 + (d.Upgrades.Damage or 0) * 0.1
	end
	if kind == "Coins" then
		value *= C.Tools[d.Tool].Coins * (1 + (d.Upgrades.Coins or 0) * 0.08)
	end
	if d.Passes["Double" .. kind] then
		value *= 2
	end
	if (d.Boosts[kind] or 0) > os.time() then
		value *= 2
	end
	local e = Game.event()
	if e.Active and e.Kind == kind then
		value *= 2
	end
	return value
end
function Game.snapshot(player, forceInventory)
	local s = Data.Sessions[player]
	if not s then
		return
	end
	Game.daily(s.Data)
	local d = s.Data
	local view = {}
	for _, key in ipairs({
		"Coins",
		"Gems",
		"Rebirths",
		"Tool",
		"World",
		"Unlocked",
		"VisitedWorlds",
		"Pets",
		"Equipped",
		"Passes",
		"Settings",
		"Boosts",
		"Bag",
		"BagCount",
		"EggCredits",
		"Crystals",
		"TotalCoins",
		"TotalPets",
		"Daily",
	}) do
		view[key] = d[key]
	end
	local ids = {}
	for _, pet in ipairs(d.Pets) do
		table.insert(ids, pet.Uid .. ":" .. (pet.Tier or 0))
	end
	local signature = table.concat(ids, ",") .. "|" .. table.concat(d.Equipped, ",")
	local rt = Game.Runtime[player]
	if rt and rt.InventorySignature == signature and not forceInventory then
		view.Pets = nil
		view.Equipped = nil
	elseif rt then
		rt.InventorySignature = signature
	end
	view.Store = Game.Store and Game.Store() or { Passes = {}, Products = {} }
	view.Content = Content.view(player)
	view.LuckMultiplier = Game.mult(d, "Luck")
	view.Temporary = s.Temporary
	view.Event = Game.event()
	view.CoinMultiplier = Game.mult(d, "Coins")
	view.DamageMultiplier = Game.mult(d, "Damage")
	view.RebirthCost = B.rebirthCost(d.Rebirths)
	view.Level = B.level(d.Crystals)
	view.AutoMine = Game.Runtime[player] and Game.Runtime[player].AutoMine or false
	Game.emit(player, "State", view)
end
function Game.gems(d, amount, boosted)
	d.Gems = clamp(d.Gems + math.floor(amount * (boosted and Game.mult(d, "Gems") or 1)))
end
function Game.coins(d, amount)
	amount = math.floor(amount)
	d.Coins = clamp(d.Coins + amount)
	d.TotalCoins = clamp(d.TotalCoins + amount)
	Game.daily(d)
	d.Daily.Coins = clamp(d.Daily.Coins + amount)
end
function Game.pet(d, id)
	local pet = { Uid = Http:GenerateGUID(false), Id = id }
	table.insert(d.Pets, pet)
	d.TotalPets += 1
	d.Discoveries[id] = true
	if #d.Equipped < B.petSlots(d) then
		table.insert(d.Equipped, pet.Uid)
	end
	return pet
end
function Game.sell(player)
	local d = Data.Sessions[player].Data
	if d.Bag <= 0 then
		return
	end
	local value = d.Bag
	d.Bag = 0
	d.BagCount = 0
	Game.coins(d, value)
	Game.emit(player, "Reward", { Coins = value, Text = "Mochila vendida!" })
end
function Game.mine(player, id)
	if not Data.writable(player) then
		return
	end
	local s = Data.Sessions[player]
	local d = s.Data
	local rt = Game.Runtime[player]
	local c = Map.Crystals[id]
	if not c or c.Health <= 0 or c.World ~= d.World then
		return
	end
	local radius = d.Passes.Magnet and 55 or 24
	if not Map.near(player, c.Part.Position, radius) then
		return
	end
	local now = os.clock()
	local tool = C.Tools[d.Tool]
	if now - rt.LastHit < tool.Interval then
		return
	end
	if not c.Boss and (d.BagCount or 0) >= P.capacity(d, C.BaseBackpack) and not d.Passes.InfiniteBackpack then
		if d.Passes.AutoSell then
			Game.sell(player)
		else
			if now - rt.LastBagNotice > 3 then
				Game.notice(player, "Mochila cheia: use SELL ou o botão Vender.")
				rt.LastBagNotice = now
			end
			return
		end
	end
	rt.LastHit = now
	if Game.Swing then
		Game.Swing(player)
	end
	local damage = tool.Damage * Game.mult(d, "Damage")
	if c.Boss then
		c.Contributors = c.Contributors or {}
		c.Contributors[player] = (c.Contributors[player] or 0) + math.min(c.Health, damage)
	end
	local destroyed = Map.hit(c, damage)
	Game.emit(player, "MineFX", { Position = c.Part.Position, Destroyed = destroyed })
	if destroyed then
		if c.Boss then
			for contributor, total in pairs(c.Contributors or {}) do
				if Data.writable(contributor) and total > 0 then
					local profile = Data.Sessions[contributor].Data
					local share = math.clamp(total / c.MaxHealth, 0, 1)
					local coins = math.floor(C.Worlds[c.World].Reward * 100 * share * Game.mult(profile, "Coins"))
					Game.coins(profile, coins)
					Game.gems(profile, math.max(5, math.floor(100 * share)), true)
					profile.BossWins += 1
					Game.emit(
						contributor,
						"Celebration",
						{ Kind = "Rebirth", Text = "Titã derrotado! +" .. B.compact(coins) .. " Coins + Gems" }
					)
					Game.snapshot(contributor)
				end
			end
			return
		end
		if now > (rt.ComboEnds or 0) then
			rt.Combo = 0
		end
		rt.Combo = math.min(C.ComboMax, (rt.Combo or 0) + 1)
		rt.ComboEnds = now + C.ComboWindow
		local level = B.level(d.Crystals)
		d.Crystals += 1
		Game.daily(d)
		d.Daily.Crystals += 1
		local reward =
			math.floor(C.Worlds[c.World].Reward * (c.Rare and 8 or 1) * Game.mult(d, "Coins") * P.combo(rt.Combo))
		d.Bag = clamp(d.Bag + reward)
		d.BagCount = (d.BagCount or 0) + 1
		Game.emit(player, "Reward", { Coins = reward, Text = "+" .. B.compact(reward) .. " na mochila" })
		if d.Passes.AutoSell then
			Game.sell(player)
		end
		if B.level(d.Crystals) > level then
			Game.gems(d, 5, true)
			Game.emit(
				player,
				"Celebration",
				{ Kind = "Level", Text = "Nível " .. B.level(d.Crystals) .. " • +5 Gems" }
			)
		end
		local event = Game.event()
		if event.Active then
			Game.gems(d, 1, true)
			if event.Kind == "Exclusive" and #d.Pets < C.MaxPets and rng:NextNumber() < 0.002 then
				Game.pet(d, "event")
				Game.emit(player, "Hatch", { { Id = "event" } })
			end
		end
	end
end
local function rarity(d)
	return Economy.rarity(C.Weights, Game.mult(d, "Luck"), rng:NextNumber())
end
function Game.hatch(player, count)
	local d = Data.Sessions[player].Data
	local rt = Game.Runtime[player]
	if count ~= 1 and count ~= 3 then
		return
	end
	if count == 3 and not d.Passes.TripleHatch then
		return Game.notice(player, "Triple Hatch necessário.")
	end
	local now = os.clock()
	local interval = d.Passes.FastHatch and 1 or 3
	if now - rt.LastHatch < interval then
		return
	end
	if not Map.near(player, Map.Eggs[d.World].Position, 20) then
		return Game.notice(player, "Aproxime-se do ovo do seu mundo.")
	end
	local plan, reason = Economy.hatchPlan(C.Worlds[d.World].EggCost, d.Coins, d.EggCredits, count, #d.Pets, C.MaxPets)
	if not plan then
		return Game.notice(
			player,
			reason == "Capacity" and "Inventário cheio: libere espaço em Pets." or "Coins insuficientes."
		)
	end
	rt.LastHatch = now
	d.Coins -= plan.Cost
	d.EggCredits -= plan.Credits
	local results = {}
	for _ = 1, count do
		local rank = rarity(d)
		local id = "w" .. d.World .. "r" .. rank
		local p = Game.pet(d, id)
		table.insert(results, p)
		if rank >= 6 then
			local msg = player.DisplayName .. " encontrou " .. C.Pets[id].Name .. " (" .. C.Pets[id].Rarity .. ")!"
			outbound:FireAllClients("Global", msg)
			task.spawn(function()
				pcall(function()
					Messaging:PublishAsync("UM_Rare_v1", { Job = game.JobId, Text = msg })
				end)
			end)
		end
	end
	Game.daily(d)
	d.Daily.Eggs += count
	d.Hatched += count
	Game.emit(player, "Hatch", results)
	return nil
end
function Game.rebirth(player)
	local d = Data.Sessions[player].Data
	local cost = B.rebirthCost(d.Rebirths)
	if d.Coins < cost then
		return Game.notice(player, "Você precisa de " .. B.compact(cost) .. " Coins.")
	end
	d.Coins = 0
	d.Bag = 0
	d.BagCount = 0
	d.Tool = 1
	d.Unlocked = { ["1"] = true }
	d.World = 1
	d.Rebirths += 1
	Game.gems(d, 50 + math.min(d.Rebirths, 10000) * 10, true)
	Map.teleport(player, 1)
	if Game.Equip then
		Game.Equip(player, 1)
	end
	Game.emit(
		player,
		"Celebration",
		{ Kind = "Rebirth", Text = "REBIRTH! Multiplicador permanente " .. B.rebirthMultiplier(d.Rebirths) .. "x" }
	)
	return nil
end
function Game.action(player, action, arg)
	if not Data.writable(player) then
		return
	end
	local d = Data.Sessions[player].Data
	local rt = Game.Runtime[player]
	if action == "Mine" then
		if type(arg) == "number" and arg == arg then
			Game.mine(player, arg)
		end
		return
	end
	if action == "Sync" then
		Game.snapshot(player, true)
		return
	end
	if action == "Sell" then
		Game.sell(player)
	elseif action == "Tool" then
		local nextTool = C.Tools[d.Tool + 1]
		if nextTool and d.Coins >= nextTool.Cost then
			d.Coins -= nextTool.Cost
			d.Tool += 1
			if Game.Equip then
				Game.Equip(player, d.Tool)
			end
			Game.emit(player, "Celebration", { Kind = "Level", Text = nextTool.Name })
		else
			Game.notice(player, "Coins insuficientes ou ferramenta máxima.")
		end
	elseif action == "World" then
		if type(arg) ~= "number" or arg % 1 ~= 0 or not C.Worlds[arg] then
			return
		end
		local w = C.Worlds[arg]
		if not d.Unlocked[tostring(arg)] then
			if d.Rebirths < w.RequiredRebirths then
				return Game.notice(player, "Requer " .. w.RequiredRebirths .. " rebirths.")
			end
			if not d.Passes.TeleportAllWorlds then
				if arg > 1 and not d.Unlocked[tostring(arg - 1)] then
					return Game.notice(player, "Desbloqueie o mundo anterior.")
				end
				if d.Coins < w.Cost then
					return Game.notice(player, "Coins insuficientes.")
				end
				d.Coins -= w.Cost
			end
			d.Unlocked[tostring(arg)] = true
		end
		d.World = arg
		d.VisitedWorlds[tostring(arg)] = true
		Map.teleport(player, arg)
	elseif action == "Hatch" then
		Game.hatch(player, arg)
	elseif action == "Rebirth" then
		Game.rebirth(player)
	elseif action == "AutoMine" then
		if d.Passes.AutoMine then
			rt.AutoMine = not rt.AutoMine
		else
			Game.notice(player, "Auto Mine necessário.")
		end
	elseif action == "Equip" or action == "DeletePet" then
		if type(arg) ~= "string" or #arg > 40 then
			return
		end
		for index, pet in ipairs(d.Pets) do
			if pet.Uid == arg then
				local equipped = table.find(d.Equipped, arg)
				if action == "DeletePet" then
					if equipped then
						return Game.notice(player, "Desequipe antes de excluir.")
					end
					table.remove(d.Pets, index)
				elseif equipped then
					table.remove(d.Equipped, equipped)
				elseif #d.Equipped < B.petSlots(d) then
					table.insert(d.Equipped, arg)
				else
					Game.notice(player, "Slots de pets cheios.")
				end
				break
			end
		end
	elseif action == "EquipBest" then
		local pets = table.clone(d.Pets)
		table.sort(pets, function(a, b)
			return (C.Pets[a.Id].Coins + C.Pets[a.Id].Damage) * P.variant(a.Tier)
				> (C.Pets[b.Id].Coins + C.Pets[b.Id].Damage) * P.variant(b.Tier)
		end)
		d.Equipped = {}
		for i = 1, math.min(#pets, B.petSlots(d)) do
			table.insert(d.Equipped, pets[i].Uid)
		end
	elseif action == "Quest" then
		if type(arg) ~= "number" or not C.Quests[arg] then
			return
		end
		Game.daily(d)
		local q = C.Quests[arg]
		if d.Daily.Claimed[tostring(arg)] or (d.Daily[q.Key] or 0) < q.Target then
			return
		end
		if q.Reward == "daily" and #d.Pets >= C.MaxPets then
			return Game.notice(player, "Libere espaço em Pets.")
		end
		d.Daily.Claimed[tostring(arg)] = true
		Game.gems(d, q.Gems, true)
		if q.Reward == "daily" then
			Game.pet(d, "daily")
		else
			d.Boosts[q.Reward] = math.max(os.time(), d.Boosts[q.Reward] or 0) + 900
		end
		Game.notice(player, "Missão concluída! Gems e recompensa entregues.")
	elseif action == "Code" then
		if type(arg) ~= "string" or #arg > 40 then
			return
		end
		arg = string.upper(arg)
		local code = C.Codes[arg]
		if code and not d.Codes[arg] then
			d.Codes[arg] = true
			Game.gems(d, code.Gems, false)
			Game.notice(player, "Código resgatado!")
		else
			Game.notice(player, "Código inválido ou já resgatado.")
		end
	elseif Content.action(player, action, arg) then
	elseif action == "Graphics" then
		if arg == "Auto" or arg == "Low" or arg == "High" then
			d.Settings.Graphics = arg
		end
	elseif action == "Setting" then
		if arg == "Music" or arg == "Effects" or arg == "ReducedMotion" then
			d.Settings[arg] = not d.Settings[arg]
		end
	end
	Game.snapshot(player)
	return nil
end
function Game.join(player)
	Game.Runtime[player] = {
		LastHit = -10,
		LastHatch = -10,
		LastBagNotice = -10,
		AutoMine = false,
		LastAFK = os.clock(),
		Tokens = 35,
		TokenAt = os.clock(),
	}
	local s = Data.Sessions[player]
	s.Data.BagCount = s.Data.BagCount or 0
	Content.join(player)
end
function Game.rate(player)
	local rt = Game.Runtime[player]
	if not rt then
		return false
	end
	local now = os.clock()
	rt.Tokens = math.min(35, rt.Tokens + (now - rt.TokenAt) * 20)
	rt.TokenAt = now
	if rt.Tokens < 1 then
		return false
	end
	rt.Tokens -= 1
	return true
end
function Game.tick()
	Map.step()
	for player, rt in pairs(Game.Runtime) do
		if Data.writable(player) then
			local d = Data.Sessions[player].Data
			if os.clock() > (rt.ComboEnds or 0) then
				rt.Combo = 0
			end
			if rt.AutoMine and d.Passes.AutoMine then
				local nearest, dist = nil, math.huge
				for id, c in pairs(Map.Crystals) do
					if
						c.World == d.World
						and c.Health > 0
						and Map.near(player, c.Part.Position, d.Passes.Magnet and 55 or 24)
					then
						local root = player.Character.HumanoidRootPart
						local distance = (root.Position - c.Part.Position).Magnitude
						if distance < dist then
							nearest = id
							dist = distance
						end
					end
				end
				if nearest then
					Game.mine(player, nearest)
				end
			end
			if d.Passes.AutoSell and d.Bag > 0 then
				Game.sell(player)
			end
			if Map.near(player, Map.Sell[d.World].Position, 12) then
				Game.sell(player)
			end
			if os.clock() - rt.LastAFK >= 30 then
				rt.LastAFK = os.clock()
				for _, zone in ipairs(Map.AFK) do
					if Map.near(player, zone.Part.Position, 12) and (not zone.VIP or d.Passes.VIP) then
						local mult = (zone.VIP and 3 or 1) * (d.Passes.PremiumAFK and 2 or 1)
						local coins = math.floor(20 * mult * Game.mult(d, "Coins"))
						Game.coins(d, coins)
						Game.gems(d, mult, true)
						Game.emit(player, "Reward", { Coins = coins, Text = "AFK • +" .. coins .. " Coins" })
						break
					end
				end
			end
		end
	end
end
function Game.subscribe()
	task.spawn(function()
		local ok, err = pcall(function()
			Messaging:SubscribeAsync("UM_Rare_v1", function(message)
				local payload = message.Data
				if type(payload) == "table" and payload.Job ~= game.JobId and type(payload.Text) == "string" then
					outbound:FireAllClients("Global", payload.Text)
				end
			end)
		end)
		if not ok then
			warn("Anúncios entre servidores indisponíveis:", err)
		end
	end)
end
return Game
