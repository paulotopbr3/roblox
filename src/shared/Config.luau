local C = {}
C.Title = "Universe Miner Simulator"
C.Release = "Cosmic Horizons"
C.BossRespawn = 180
C.ComboWindow = 8
C.ComboMax = 20
C.DataStore = "UniverseMiner_v1"
C.StudioTemporaryData = true
C.MaxNumber = 1e150
C.MaxPets = 400
C.BasePetSlots = 3
C.BaseBackpack = 30
C.AutosaveSeconds = 60
C.EventPeriod = 7200
C.EventDuration = 900
C.MusicId = "" -- áudio autorizado opcional
C.SoundIds = { Mine = "", Reward = "", Hatch = "", Rebirth = "", Level = "" } -- IDs de áudio autorizado
C.Worlds = {}
local names = {
	"Starter",
	"Forest",
	"Desert",
	"Ocean",
	"Candy",
	"Volcano",
	"Space",
	"Galaxy",
	"Void",
	"Heaven",
	"Cyber",
	"Frost",
	"Clockwork",
	"Dream",
}
local colors = {
	{ 94, 195, 115 },
	{ 40, 139, 73 },
	{ 234, 195, 93 },
	{ 55, 176, 218 },
	{ 238, 125, 193 },
	{ 220, 80, 41 },
	{ 73, 92, 150 },
	{ 127, 74, 213 },
	{ 53, 32, 83 },
	{ 232, 215, 157 },
	{ 30, 215, 196 },
	{ 132, 213, 255 },
	{ 201, 144, 73 },
	{ 218, 151, 248 },
}
for i, name in ipairs(names) do
	C.Worlds[i] = {
		Name = name .. " World",
		Cost = i == 1 and 0 or math.floor(1500 * 5 ^ (i - 2)),
		Health = math.floor(10 * 3 ^ (i - 1)),
		Reward = math.floor(15 * 4 ^ (i - 1)),
		EggCost = math.floor(100 * 4 ^ (i - 1)),
		Color = colors[i],
		RequiredRebirths = i >= 9 and (i - 8) * 2 or 0,
	}
end
C.Tools = {}
local tiers = {
	"Wood",
	"Stone",
	"Iron",
	"Gold",
	"Diamond",
	"Emerald",
	"Galaxy",
	"Void",
	"God",
	"Solar",
	"Titan",
	"Chronos",
	"Nova",
	"Infinity",
}
for i = 1, 56 do
	C.Tools[i] = {
		Name = tiers[math.ceil(i / 4)] .. " Pickaxe " .. ((i - 1) % 4 + 1),
		Cost = i == 1 and 0 or math.floor(70 * 1.9 ^ (i - 2)),
		Damage = math.floor(3 * 1.48 ^ (i - 1)),
		Interval = math.max(0.12, 0.55 - 0.012 * (i - 1)),
		Coins = 1 + (i - 1) * 0.08,
	}
end
C.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" }
C.Weights = { 6000, 2500, 1000, 400, 85, 14, 1 }
C.Pets = {}
local species = { "Sprite", "Fox", "Golem", "Dragon", "Phoenix", "Titan", "Oracle" }
for world = 1, #C.Worlds do
	for rarity, label in ipairs(C.Rarities) do
		local id = "w" .. world .. "r" .. rarity
		C.Pets[id] = {
			Name = names[world] .. " " .. species[rarity],
			Rarity = label,
			Rank = rarity,
			World = world,
			Coins = 0.10 * world * rarity,
			Damage = 0.12 * world * rarity,
			Gems = 0.03 * rarity,
		}
	end
end
C.Pets.daily = { Name = "Daily Comet", Rarity = "Epic", Rank = 4, World = 1, Coins = 0.8, Damage = 0.8, Gems = 0.2 }
C.Pets.event = { Name = "Event Nebula", Rarity = "Mythical", Rank = 6, World = 7, Coins = 3, Damage = 3, Gems = 0.4 }
C.Pets.weekly =
	{ Name = "Weekly Supernova", Rarity = "Mythical", Rank = 6, World = 8, Coins = 4, Damage = 4, Gems = 0.5 }
C.Pets.vip = { Name = "Royal Star", Rarity = "Legendary", Rank = 5, World = 6, Coins = 2, Damage = 2, Gems = 0.3 }
C.Pets.starter =
	{ Name = "Orbit Buddy", Rarity = "Uncommon", Rank = 2, World = 1, Coins = 0.12, Damage = 0.15, Gems = 0.04 }
C.Pets.streak =
	{ Name = "Aurora Guardian", Rarity = "Mythical", Rank = 6, World = 12, Coins = 3.5, Damage = 4, Gems = 0.4 }
-- IDs zero desativam compras. Use IDs únicos da mesma experiência.
C.Passes = {}
for _, name in ipairs({
	"DoubleCoins",
	"DoubleLuck",
	"DoubleGems",
	"AutoMine",
	"AutoSell",
	"InfiniteBackpack",
	"VIP",
	"FastHatch",
	"TripleHatch",
	"TeleportAllWorlds",
	"ExtraPetSlots",
	"Magnet",
	"ExclusivePets",
	"InstantRebirth",
	"PremiumAFK",
}) do
	C.Passes[name] = 0
end
C.PassLabels = {
	DoubleCoins = "2x Coins",
	DoubleLuck = "2x Luck",
	DoubleGems = "2x Gems",
	AutoMine = "Auto Mine",
	AutoSell = "Auto Sell",
	InfiniteBackpack = "Infinite Backpack",
	VIP = "VIP",
	FastHatch = "Fast Hatch",
	TripleHatch = "Triple Hatch",
	TeleportAllWorlds = "Teleport All Worlds",
	ExtraPetSlots = "+3 Pet Slots",
	Magnet = "Magnet",
	ExclusivePets = "Exclusive Pet",
	InstantRebirth = "Rebirth sem confirmação",
	PremiumAFK = "Premium AFK Rewards",
}
C.PassOrder = {
	"DoubleCoins",
	"AutoMine",
	"AutoSell",
	"VIP",
	"ExtraPetSlots",
	"TripleHatch",
	"DoubleLuck",
	"DoubleGems",
	"FastHatch",
	"Magnet",
	"InfiniteBackpack",
	"TeleportAllWorlds",
	"ExclusivePets",
	"InstantRebirth",
	"PremiumAFK",
}
C.PassDetails = {
	DoubleCoins = { Category = "Progressão", Description = "Dobra Coins ganhas minerando e em AFK. Permanente." },
	DoubleLuck = {
		Category = "Pets",
		Description = "Dobra os pesos de Rare ou superior. As chances atualizadas aparecem nos ovos.",
	},
	DoubleGems = {
		Category = "Progressão",
		Description = "Dobra Gems ganhas no jogo. Gems compradas têm quantidade fixa.",
	},
	AutoMine = { Category = "Conforto", Description = "Minera cristais próximos automaticamente; pode ser desligado." },
	AutoSell = {
		Category = "Conforto",
		Description = "Vende sua mochila automaticamente. Vender manualmente é gratuito.",
	},
	InfiniteBackpack = { Category = "Conforto", Description = "Remove o limite de cristais da mochila." },
	VIP = { Category = "Conforto", Description = "Libera o lounge VIP AFK com recompensas 3x." },
	FastHatch = { Category = "Pets", Description = "Reduz a espera entre ovos de 3 segundos para 1 segundo." },
	TripleHatch = { Category = "Pets", Description = "Abre 3 ovos por ação, pagando o custo de cada ovo." },
	TeleportAllWorlds = {
		Category = "Progressão",
		Description = "Dispensa custo e sequência dos mundos. Requisitos de rebirth permanecem.",
	},
	ExtraPetSlots = { Category = "Pets", Description = "Mais 3 pets equipados, além dos slots conquistados com Gems." },
	Magnet = { Category = "Conforto", Description = "Aumenta o alcance de mineração de 24 para 55 studs." },
	ExclusivePets = {
		Category = "Pets",
		Description = "Entrega Royal Star uma vez. O pet pode ser excluído permanentemente.",
	},
	InstantRebirth = {
		Category = "Conforto",
		Description = "Pula a confirmação do rebirth. Custo e resets continuam iguais.",
	},
	PremiumAFK = { Category = "Conforto", Description = "Dobra recompensas nas áreas AFK, inclusive no lounge VIP." },
}
C.GemUpgrades = {
	Damage = { Name = "Força cósmica", Description = "+10% dano por nível", Max = 20, Base = 30, Growth = 1.45 },
	Coins = { Name = "Fortuna estelar", Description = "+8% Coins por nível", Max = 20, Base = 40, Growth = 1.45 },
	Backpack = {
		Name = "Mochila expandida",
		Description = "+15 espaços por nível",
		Max = 10,
		Base = 25,
		Growth = 1.5,
	},
	Slots = { Name = "Companhia orbital", Description = "+1 slot de pet por nível", Max = 3, Base = 300, Growth = 3 },
}
C.Tutorial = {
	{ Title = "Quebre 5 cristais", Key = "Crystals", Target = 5, Menu = "Guide", Gems = 15 },
	{ Title = "Venda sua primeira mochila", Key = "TotalCoins", Target = 75, Menu = "Inventory", Gems = 25 },
	{ Title = "Compre uma picareta melhor", Key = "Tool", Target = 2, Menu = "Tools", Gems = 40 },
	{ Title = "Abra seu primeiro ovo", Key = "Hatched", Target = 1, Menu = "Inventory", Gems = 60 },
	{ Title = "Explore Forest World", Key = "WorldCount", Target = 2, Menu = "Worlds", Gems = 100 },
}
C.Achievements = {}
for _, group in ipairs({
	{ Key = "Crystals", Name = "Explorador da mina", Targets = { 50, 250, 1000, 5000 } },
	{ Key = "Hatched", Name = "Colecionador", Targets = { 10, 50, 200, 1000 } },
	{ Key = "Rebirths", Name = "Nova vida", Targets = { 1, 5, 25, 100 } },
	{ Key = "WorldCount", Name = "Viajante", Targets = { 3, 6, 10, 14 } },
}) do
	for tier, target in ipairs(group.Targets) do
		table.insert(C.Achievements, {
			Id = group.Key .. tier,
			Name = group.Name .. " " .. tier,
			Key = group.Key,
			Target = target,
			Gems = 50 * tier * tier,
		})
	end
end
C.PlayGifts = {
	{ Seconds = 120, Gems = 15, Credits = 0 },
	{ Seconds = 300, Gems = 30, Credits = 1 },
	{ Seconds = 600, Gems = 60, Credits = 2 },
	{ Seconds = 1200, Gems = 120, Credits = 3 },
}
C.Products = {
	Gems50 = { Id = 0, Kind = "Gems", Amount = 50, Label = "50 Gems" },
	Gems500 = { Id = 0, Kind = "Gems", Amount = 500, Label = "500 Gems" },
	Gems5000 = { Id = 0, Kind = "Gems", Amount = 5000, Label = "5000 Gems" },
	Luck15 = { Id = 0, Kind = "Luck", Amount = 900, Label = "Luck • 15 min" },
	Luck30 = { Id = 0, Kind = "Luck", Amount = 1800, Label = "Luck • 30 min" },
	Coins15 = { Id = 0, Kind = "Coins", Amount = 900, Label = "Coins • 15 min" },
	Coins30 = { Id = 0, Kind = "Coins", Amount = 1800, Label = "Coins • 30 min" },
	Eggs10 = { Id = 0, Kind = "Eggs", Amount = 10, Label = "10 créditos de ovo" },
	Eggs100 = { Id = 0, Kind = "Eggs", Amount = 100, Label = "100 créditos de ovo" },
	WeeklyPet = { Id = 0, Kind = "Pet", Pet = "weekly", Amount = 1, Label = "Weekly Supernova" },
}
C.Quests = {
	{ Key = "Crystals", Target = 100, Gems = 75, Reward = "Coins" },
	{ Key = "Coins", Target = 10000, Gems = 100, Reward = "Luck" },
	{ Key = "Eggs", Target = 15, Gems = 150, Reward = "daily" },
}
C.Codes = { WELCOME = { Gems = 100 }, UNIVERSE = { Gems = 250 } }
C.Codes.COSMIC = { Gems = 300 }
return C
