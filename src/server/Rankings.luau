local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Rankings = { Cache = {}, Updated = 0, Busy = false, Available = {} }
local stores = {}
local names = {}
local keys = { "Coins", "Rebirths", "Pets", "Gems" }
local function getStore(key)
	if not stores[key] then
		stores[key] = DSS:GetOrderedDataStore(C.DataStore .. "_Rank_" .. key)
	end
	return stores[key]
end
-- OrderedDataStore accepts signed integers, not arbitrary large doubles.
local function encode(value)
	return math.floor(math.log10(1 + value) * 1000000)
end
local function decode(value)
	return 10 ^ (value / 1000000) - 1
end
function Rankings.write(player, d)
	local values = { Coins = d.TotalCoins, Rebirths = d.Rebirths, Pets = d.TotalPets, Gems = d.Gems }
	for key, value in pairs(values) do
		local ok, err = pcall(function()
			if key == "Gems" then
				getStore(key):SetAsync(tostring(player.UserId), encode(value))
			else
				getStore(key):UpdateAsync(tostring(player.UserId), function(old)
					return math.max(old or 0, encode(value))
				end)
			end
		end)
		if not ok then
			warn("Ranking " .. key .. ":", err)
		end
	end
end
function Rankings.refresh()
	if Rankings.Busy then
		return
	end
	Rankings.Busy = true
	for _, key in ipairs(keys) do
		local ok, result = pcall(function()
			return getStore(key):GetSortedAsync(false, 20):GetCurrentPage()
		end)
		if ok then
			Rankings.Available[key] = true
			local rows = {}
			for _, entry in ipairs(result) do
				local userId = tonumber(entry.key)
				local name = names[entry.key] or "User " .. entry.key
				if userId and not names[entry.key] then
					local found, username = pcall(function()
						return Players:GetNameFromUserIdAsync(userId)
					end)
					if found then
						name = username
						names[entry.key] = username
					end
				end
				table.insert(rows, { Name = name, Value = decode(entry.value), UserId = userId })
			end
			Rankings.Cache[key] = rows
		else
			Rankings.Available[key] = false
			warn("Leitura de ranking indisponível:", key)
		end
	end
	Rankings.Updated = os.time()
	Rankings.Busy = false
end
return Rankings
