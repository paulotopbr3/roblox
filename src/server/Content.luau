local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local P = require(game.ReplicatedStorage.UniverseMiner.Progression)
local B = require(game.ReplicatedStorage.UniverseMiner.Balance)
local Data = require(script.Parent.Data)
local Content = {}
local Game
function Content.init(api)
	Game = api
end
function Content.join(player)
	local d = Data.Sessions[player].Data
	if not d.WelcomeGranted then
		d.WelcomeGranted = true
		Game.pet(d, "starter")
	end
	local rt = Game.Runtime[player]
	rt.JoinedAt = os.clock()
	rt.Gifts = {}
end
function Content.view(player)
	local d = Data.Sessions[player].Data
	local rt = Game.Runtime[player]
	local tutorial = C.Tutorial[d.Tutorial]
	return {
		Tutorial = d.Tutorial,
		TutorialProgress = tutorial and P.value(d, tutorial.Key) or 0,
		Upgrades = d.Upgrades,
		Login = d.Login,
		CanLogin = d.Login.LastDay ~= math.floor(os.time() / 86400),
		Achievements = d.Achievements,
		Discoveries = d.Discoveries,
		DiscoveryClaims = d.DiscoveryClaims,
		Hatched = d.Hatched,
		BossWins = d.BossWins,
		PlaySeconds = math.floor(os.clock() - rt.JoinedAt),
		PlayClaimed = rt.Gifts,
		Capacity = P.capacity(d, C.BaseBackpack),
		Combo = rt.Combo or 0,
		ComboEnds = rt.ComboEnds or 0,
	}
end
local function celebration(player, message)
	Game.emit(player, "Celebration", { Kind = "Level", Text = message })
end
function Content.action(player, key, arg)
	local d = Data.Sessions[player].Data
	local rt = Game.Runtime[player]
	if key == "Tutorial" then
		local goal = C.Tutorial[d.Tutorial]
		if not goal or P.value(d, goal.Key) < goal.Target then
			return true
		end
		d.Tutorial += 1
		Game.gems(d, goal.Gems, false)
		celebration(player, "Objetivo concluído! +" .. goal.Gems .. " Gems")
	elseif key == "LoginGift" then
		local day = math.floor(os.time() / 86400)
		local streak = P.streak(d.Login.LastDay, d.Login.Streak, day)
		if not streak then
			return true
		end
		if streak == 7 and #d.Pets >= C.MaxPets then
			Game.notice(player, "Libere espaço para seu Aurora Guardian.")
			return true
		end
		d.Login = { LastDay = day, Streak = streak }
		local gems = 25 * streak
		Game.gems(d, gems, false)
		d.EggCredits += streak >= 3 and 2 or 1
		if streak == 7 then
			Game.pet(d, "streak")
		end
		celebration(player, "Presente do dia " .. streak .. " • +" .. gems .. " Gems e créditos de ovo")
	elseif key == "PlayGift" then
		if type(arg) ~= "number" or not C.PlayGifts[arg] then
			return true
		end
		local gift = C.PlayGifts[arg]
		if rt.Gifts[tostring(arg)] or os.clock() - rt.JoinedAt < gift.Seconds then
			return true
		end
		rt.Gifts[tostring(arg)] = true
		Game.gems(d, gift.Gems, false)
		d.EggCredits += gift.Credits
		celebration(player, "Presente de exploração • +" .. gift.Gems .. " Gems")
	elseif key == "Upgrade" then
		if type(arg) ~= "string" or not C.GemUpgrades[arg] then
			return true
		end
		local spec = C.GemUpgrades[arg]
		local level = d.Upgrades[arg]
		if level >= spec.Max then
			Game.notice(player, "Upgrade no nível máximo.")
			return true
		end
		local price = P.upgradeCost(spec, level)
		if d.Gems < price then
			Game.notice(player, "Precisa de " .. B.compact(price) .. " Gems.")
			return true
		end
		d.Gems -= price
		d.Upgrades[arg] += 1
		celebration(player, spec.Name .. " • nível " .. d.Upgrades[arg])
	elseif key == "Achievement" then
		if type(arg) ~= "number" or not C.Achievements[arg] then
			return true
		end
		local spec = C.Achievements[arg]
		if d.Achievements[spec.Id] or P.value(d, spec.Key) < spec.Target then
			return true
		end
		d.Achievements[spec.Id] = true
		Game.gems(d, spec.Gems, false)
		celebration(player, spec.Name .. " • +" .. spec.Gems .. " Gems")
	elseif key == "Discovery" then
		if type(arg) ~= "string" or not C.Pets[arg] or not d.Discoveries[arg] or d.DiscoveryClaims[arg] then
			return true
		end
		d.DiscoveryClaims[arg] = true
		local gems = C.Pets[arg].Rank * 5
		Game.gems(d, gems, false)
		Game.notice(player, "Descoberta registrada • +" .. gems .. " Gems")
	elseif key == "Fuse" then
		if type(arg) ~= "string" or #arg > 40 then
			return true
		end
		local plan = P.fusion(d.Pets, d.Equipped, arg)
		if not plan then
			Game.notice(player, "Fusão precisa de 3 pets iguais e desequipados, da mesma variante.")
			return true
		end
		if d.Gems < plan.Cost then
			Game.notice(player, "Fusão custa " .. plan.Cost .. " Gems.")
			return true
		end
		d.Gems -= plan.Cost
		for i = #d.Pets, 1, -1 do
			if table.find(plan.Ids, d.Pets[i].Uid) then
				table.remove(d.Pets, i)
			end
		end
		local pet = Game.pet(d, plan.PetId)
		pet.Tier = plan.Tier
		Game.emit(player, "Hatch", { pet })
	else
		return false
	end
	return true
end
return Content
