local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Rankings = { Cache = {}, Updated = 0, Busy = false }
local stores = {}
for _, key in ipairs({ "Coins", "Rebirths", "Pets", "Gems" }) do
	stores[key] = DSS:GetOrderedDataStore(C.DataStore .. "_Rank_" .. key)
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
			stores[key]:SetAsync(tostring(player.UserId), encode(value))
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
	for key, store in pairs(stores) do
		local ok, result = pcall(function()
			return store:GetSortedAsync(false, 20):GetCurrentPage()
		end)
		if ok then
			local rows = {}
			for _, entry in ipairs(result) do
				local userId = tonumber(entry.key)
				local name = "User " .. entry.key
				if userId then
					local found, username = pcall(function()
						return Players:GetNameFromUserIdAsync(userId)
					end)
					if found then
						name = username
					end
				end
				table.insert(rows, { Name = name, Value = decode(entry.value), UserId = userId })
			end
			Rankings.Cache[key] = rows
		else
			warn("Leitura de ranking indisponível:", key)
		end
	end
	Rankings.Updated = os.time()
	Rankings.Busy = false
end
return Rankings
