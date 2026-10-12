local P = {}
function P.upgradeCost(upgrade, level)
	return math.floor(upgrade.Base * upgrade.Growth ^ level)
end
function P.capacity(data, base)
	return base + (data.Upgrades.Backpack or 0) * 15
end
function P.variant(tier)
	return 2.5 ^ math.clamp(tier or 0, 0, 2)
end
function P.combo(count)
	return 1 + math.min(20, math.max(0, count)) * 0.025
end
function P.streak(lastDay, streak, day)
	if lastDay == day then
		return nil
	end
	return lastDay == day - 1 and streak % 7 + 1 or 1
end
function P.fusion(pets, equipped, uid)
	local selected
	for _, p in ipairs(pets) do
		if p.Uid == uid then
			selected = p
			break
		end
	end
	if not selected or (selected.Tier or 0) >= 2 then
		return nil
	end
	local found = {}
	for _, p in ipairs(pets) do
		if p.Id == selected.Id and (p.Tier or 0) == (selected.Tier or 0) and not table.find(equipped, p.Uid) then
			table.insert(found, p.Uid)
		end
		if #found == 3 then
			return {
				Ids = found,
				PetId = selected.Id,
				Tier = (selected.Tier or 0) + 1,
				Cost = 50 * 5 ^ (selected.Tier or 0),
			}
		end
	end
	return nil
end
function P.value(data, key)
	if key == "WorldCount" then
		local n = 0
		for _, yes in pairs(data.VisitedWorlds or data.Unlocked) do
			if yes then
				n += 1
			end
		end
		return n
	end
	return data[key] or 0
end
return P
