local DSS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Data = { Sessions = {} }
local store = DSS:GetDataStore(C.DataStore)
local token = game.JobId .. ":" .. Http:GenerateGUID(false)
local LEASE = 240
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = copy(v)
	end
	return out
end
local function fresh()
	return {
		Version = 1,
		Coins = 0,
		Gems = 0,
		Rebirths = 0,
		Tool = 1,
		World = 1,
		Unlocked = { ["1"] = true },
		Pets = {},
		Equipped = {},
		Passes = {},
		Settings = { Music = true, Effects = true },
		Boosts = { Coins = 0, Luck = 0 },
		Bag = 0,
		BagCount = 0,
		ExclusiveGranted = false,
		EggCredits = 0,
		Crystals = 0,
		TotalCoins = 0,
		TotalPets = 0,
		Codes = {},
		Receipts = {},
		Daily = { Day = math.floor(os.time() / 86400), Crystals = 0, Coins = 0, Eggs = 0, Claimed = {} },
	}
end
local function normalize(raw)
	local d = fresh()
	if type(raw) ~= "table" then
		return d
	end
	if raw.Version and raw.Version ~= 1 then
		error("Versão de dados não suportada")
	end
	for k, v in pairs(d) do
		if type(raw[k]) == type(v) then
			d[k] = raw[k]
		end
	end
	for _, key in ipairs({ "Coins", "Gems", "Rebirths", "Bag", "BagCount", "EggCredits", "Crystals", "TotalCoins", "TotalPets" }) do
		local n = d[key]
		d[key] = (n == n and n >= 0 and n < math.huge) and math.min(C.MaxNumber, n) or 0
	end
	d.Tool = math.clamp(math.floor(tonumber(d.Tool) or 1), 1, #C.Tools)
	d.World = math.clamp(math.floor(tonumber(d.World) or 1), 1, #C.Worlds)
	d.Unlocked["1"] = true
	local pets = {}
	for _, pet in ipairs(d.Pets) do
		if type(pet) == "table" and type(pet.Uid) == "string" and C.Pets[pet.Id] then
			table.insert(pets, pet)
		end
	end
	d.Pets = pets
	d.Passes = {} -- Ownership is verified with Marketplace on each login.
	return d
end
function Data.load(player)
	local loaded, blocked
	local ok, err = pcall(function()
		store:UpdateAsync("u:" .. player.UserId, function(old)
			blocked = false
			if old and old.Lock and old.Lock.Token ~= token and (old.Lock.Expires or 0) > os.time() then
				blocked = true
				return nil
			end
			loaded = normalize(old and old.Data)
			return { Data = loaded, Lock = { Token = token, Expires = os.time() + LEASE } }
		end)
	end)
	if blocked then
		return nil, "Seus dados estão em outra sessão. Aguarde um minuto e tente novamente."
	end
	if not ok then
		warn("UniverseMiner load:", err)
		if RunService:IsStudio() and C.StudioTemporaryData then
			local s = { Data = fresh(), Temporary = true, Busy = false, LastSave = os.time() }
			Data.Sessions[player] = s
			return s
		end
		return nil, "Não foi possível carregar seus dados com segurança. Tente novamente."
	end
	local s = { Data = loaded, Temporary = false, Busy = false, LastSave = os.time() }
	Data.Sessions[player] = s
	return s
end
function Data.save(player, release)
	local s = Data.Sessions[player]
	if not s then
		return false
	end
	while s.Busy do
		task.wait(0.1)
	end
	if s.Temporary then
		return true
	end
	s.Busy = true
	local snapshot = copy(s.Data)
	local lost = false
	local ok, err = pcall(function()
		store:UpdateAsync("u:" .. player.UserId, function(old)
			if not old or not old.Lock or old.Lock.Token ~= token then
				lost = true
				return nil
			end
			return { Data = snapshot, Lock = not release and { Token = token, Expires = os.time() + LEASE } or nil }
		end)
	end)
	s.Busy = false
	if lost then
		s.ReadOnly = true
		player:Kick("A sessão de dados expirou. Entre novamente para proteger seu progresso.")
	end
	if not ok then
		warn("UniverseMiner save:", err)
	end
	if ok and not lost then
		s.LastSave = os.time()
		return true
	end
	return false
end
function Data.release(player)
	local s = Data.Sessions[player]
	if not s then
		return
	end
	s.Closing = true
	for attempt = 1, 3 do
		if Data.save(player, true) then
			break
		end
		task.wait(attempt)
	end
	Data.Sessions[player] = nil
end
function Data.writable(player)
	local s = Data.Sessions[player]
	return s and not s.ReadOnly and not s.Closing and (s.Temporary or os.time() - s.LastSave < LEASE - 40)
end
return Data
