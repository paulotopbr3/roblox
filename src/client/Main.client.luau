local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local Tween = game:GetService("TweenService")
local Run = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local SocialService = game:GetService("SocialService")
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)
local player = Players.LocalPlayer
local shared = game.ReplicatedStorage:WaitForChild("UniverseMiner")
local C = require(shared.Config)
local B = require(shared.Balance)
local P = require(shared.Progression)
local UI = require(script.Parent.UI)
local V = require(script.Parent.Visuals)
local Graphics = require(script.Parent.Graphics)
local colors = UI.Colors
local gui = Instance.new("ScreenGui")
gui.Name = "UniverseMinerUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local remotes = shared:WaitForChild("Remotes", 15)
if not remotes then
	UI.card(gui, "Não foi possível iniciar", "No Studio, abra View → Output e copie a primeira mensagem vermelha.")
	return
end
local action = remotes:WaitForChild("Action")
local update = remotes:WaitForChild("Update")
local function send(key, arg)
	action:FireServer(key, arg)
end
local state, menu = nil, nil
local selectedPet, confirmation = nil, nil
local petPage = 1
local collectionWorld = 1
local storeTab = "Passes"
local storeFilter = "Todos"
local codeValue = ""
local rankData = {}
local rankAvailable = {}
local rankCategory = "Coins"
local toolPage = 1
local showHelp = false
local lastScreenKey = ""
local top = UI.frame(gui, UDim2.new(1, -24, 0, 92), UDim2.fromOffset(12, 10))
UI.text(top, C.Title .. " • " .. C.Release, UDim2.new(1, -110, 0, 20), UDim2.fromOffset(14, 7), 14, colors.Muted)
local wallet = UI.text(top, "Preparando sua aventura…", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 30), 21)
local sub = UI.text(top, "", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 63), 13, colors.Cyan)
local compact = false
local nav = Instance.new("ScrollingFrame")
nav.Size = UDim2.fromOffset(115, 400)
nav.Position = UDim2.fromOffset(12, 112)
nav.BackgroundColor3 = colors.Background
nav.ScrollBarThickness = 3
nav.BorderSizePixel = 0
nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
nav.CanvasSize = UDim2.new()
nav.Parent = gui
nav.ZIndex = 20
UI.round(nav)
local navLayout = UI.list(nav)
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
local panel = UI.frame(gui, UDim2.new(1, -156, 1, -124), UDim2.fromOffset(144, 112))
panel.Visible = false
local heading = UI.text(panel, "", UDim2.new(1, -75, 0, 38), UDim2.fromOffset(16, 7), 23)
local close = UI.button(panel, "×", function()
	menu = nil
	panel.Visible = false
	GuiService.SelectedObject = nil
end)
close.Size = UDim2.fromOffset(40, 36)
close.Position = UDim2.new(1, -50, 0, 8)
local list = Instance.new("ScrollingFrame")
list.Name = "Content"
list.Position = UDim2.fromOffset(8, 54)
list.Size = UDim2.new(1, -16, 1, -62)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local listLayout = UI.list(list)
local objective = UI.frame(gui, UDim2.fromOffset(360, 120), UDim2.new(0, 12, 1, -132))
local objectiveTitle =
	UI.text(objective, "PRÓXIMO OBJETIVO", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 8), 12, colors.Cyan)
local objectiveText = UI.text(objective, "Carregando…", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 32), 17)
local objectiveProgress = UI.bar(objective, 0, colors.Cyan, UDim2.fromOffset(12, 65), UDim2.new(1, -24, 0, 7))
local render, open
local objectiveButton = UI.button(objective, "Ver guia", function()
	open("Guide")
end)
objectiveButton.Size = UDim2.new(1, -24, 0, 29)
objectiveButton.Position = UDim2.fromOffset(12, 81)
local controls = UI.frame(gui, UDim2.fromOffset(310, 120), UDim2.new(1, -322, 1, -132))
local target = nil
local held = false
local heldId = nil
local nextHit = 0
local mine = UI.button(controls, "MINERAR • segure", function()
	if target then
		send("Mine", target:GetAttribute("CrystalId"))
	end
end, colors.Cyan)
mine.TextColor3 = Color3.new(1, 1, 1)
mine.Size = UDim2.new(1, -16, 0, 44)
mine.Position = UDim2.fromOffset(8, 8)
local bag = UI.text(controls, "Mochila 0 / 30", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 57), 12, colors.Muted)
local bagProgress = UI.bar(controls, 0, colors.Gold, UDim2.fromOffset(8, 80), UDim2.new(1, -16, 0, 5))
local sell = UI.button(controls, "Vender • Y", function()
	send("Sell")
end, colors.Green)
sell.Size = UDim2.new(0.58, -10, 0, 27)
sell.Position = UDim2.fromOffset(8, 90)
local auto = UI.button(controls, "Auto", function()
	if state and state.Passes.AutoMine then
		send("AutoMine")
	else
		open("Shop")
	end
end)
auto.Size = UDim2.new(0.42, -12, 0, 27)
auto.Position = UDim2.new(0.58, 2, 0, 90)
local toggle = UI.button(gui, "MENU", function()
	if open then
		open("More")
	end
end)
toggle.Size = UDim2.fromOffset(70, 26)
toggle.Position = UDim2.new(1, -84, 0, 15)
local toast = UI.text(gui, "", UDim2.new(0.7, 0, 0, 76), UDim2.new(0.15, 0, 0.62, 0), 22, colors.Gold)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.TextStrokeTransparency = 0.3
toast.ZIndex = 40
local toastId = 0
local function notify(message)
	toastId += 1
	local id = toastId
	toast.Text = tostring(message)
	task.delay(3, function()
		if toastId == id then
			toast.Text = ""
		end
	end)
end
local music = Instance.new("Sound")
music.SoundId = C.MusicId
music.Volume = 0.15
music.Looped = true
music.Parent = SoundService
if C.MusicId ~= "" then
	music:Play()
end
local names = {
	More = "Mais",
	Rankings = "Top Global",
	Guide = "Guia",
	Tools = "Picaretas",
	Eggs = "Ovos",
	Pets = "Pets",
	Collection = "Coleção",
	Worlds = "Mundos",
	Upgrades = "Gems Lab",
	Rewards = "Presentes",
	Quests = "Missões",
	Rebirth = "Rebirth",
	Shop = "Loja Robux",
	Events = "Eventos",
	Settings = "Ajustes",
	Codes = "Códigos",
	Inventory = "Mochila",
}
open = function(key)
	if not names[key] then
		key = "Guide"
	end
	menu = key
	panel.Visible = true
	confirmation = nil
	if compact then
		nav.Visible = false
	end
	render()
	if key == "Rankings" then
		send("Rankings")
	end
	if UIS.GamepadEnabled then
		GuiService.SelectedObject = list:FindFirstChildWhichIsA("TextButton") or close
	end
end
for _, key in ipairs({ "Pets", "Tools", "Worlds", "Rewards", "Shop", "More" }) do
	local symbol = { Pets = "♥", Tools = "⚒", Worlds = "◎", Rewards = "★", Shop = "◆", More = "⋯" }
	local b = UI.button(nav, symbol[key] .. " " .. names[key], function()
		if menu == key then
			menu = nil
			panel.Visible = false
		else
			open(key)
		end
	end, key == "Shop" and colors.Pink or key == "Rewards" and colors.Green or colors.Accent)
	b.Size = UDim2.new(1 / 6, -10, 0, 46)
	b.TextSize = 12
	b.Name = "Nav" .. key
end
local tabs = Instance.new("Frame")
tabs.Name = "Tabs"
tabs.Size = UDim2.new(1, -24, 0, 36)
tabs.Position = UDim2.fromOffset(12, 48)
tabs.BackgroundTransparency = 1
tabs.Parent = panel
local groups = {
	{ "Pets", "Collection", "Eggs" },
	{ "Tools", "Upgrades", "Rebirth" },
	{ "Worlds", "Rankings" },
	{ "Rewards", "Quests", "Events" },
	{ "Shop" },
	{ "More", "Guide", "Settings" },
}
local function headerTabs()
	UI.clear(tabs)
	local group
	for _, items in ipairs(groups) do
		if table.find(items, menu) then
			group = items
			break
		end
	end
	local visible = group and #group > 1
	tabs.Visible = visible or false
	list.Position = UDim2.fromOffset(8, visible and 92 or 54)
	list.Size = UDim2.new(1, -16, 1, visible and -100 or -62)
	if visible then
		for i, key in ipairs(group) do
			local b = UI.button(tabs, names[key], function()
				open(key)
			end, key == menu and colors.Accent or colors.Card)
			b.TextColor3 = key == menu and Color3.new(1, 1, 1) or colors.Text
			b.Size = UDim2.new(1 / #group, -6, 0, 32)
			b.Position = UDim2.new((i - 1) / #group, 0, 0, 0)
			b.Name = "Tab" .. key
		end
	end
end
local function columns()
	return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 760 and 2 or 4
end
local function portraitTile(parent, id, tier, title, badge, label, callback, color, locked)
	local tile, b, image = UI.tile(parent, title, badge, label, callback, color)
	V.portrait(image, id, tier or 0, locked)
	return tile, b
end
local function viewKey()
	if not state then
		return ""
	end
	local key = menu .. "|" .. state.World .. "|" .. state.Tool
	if menu == "Pets" then
		for _, p in ipairs(state.Pets) do
			key ..= p.Uid .. ":" .. (p.Tier or 0)
		end
		key ..= table.concat(state.Equipped, ",") .. state.Gems
	elseif menu == "Collection" then
		for id in pairs(state.Content.Discoveries) do
			key ..= id .. tostring(state.Content.DiscoveryClaims[id])
		end
	elseif menu == "Tools" or menu == "Worlds" then
		key ..= state.Coins .. "|" .. state.Rebirths
	elseif menu == "Eggs" then
		key ..= state.Coins .. "|" .. state.EggCredits .. "|" .. state.LuckMultiplier
	else
		key ..= state.Coins .. state.Gems .. state.Content.PlaySeconds
	end
	return key
end
local function card(title, desc, label, callback, col)
	return UI.card(list, title, desc, label, callback, col)
end
local function progress(title, current, maximum, reward, callback)
	local c, b = card(
		title,
		B.compact(current) .. " / " .. B.compact(maximum),
		reward,
		callback,
		current >= maximum and colors.Green or colors.Accent
	)
	UI.bar(c, current / maximum, colors.Cyan)
	return b
end
local function petInfo(pet)
	local info = C.Pets[pet.Id]
	local scale = P.variant(pet.Tier)
	local variant = pet.Tier == 2 and "Cosmic" or pet.Tier == 1 and "Golden" or "Normal"
	return info,
		variant
			.. " • "
			.. info.Rarity
			.. " • +"
			.. math.floor(info.Coins * scale * 100)
			.. "% Coins / +"
			.. math.floor(info.Damage * scale * 100)
			.. "% dano"
end
local function purchaseCard(key, kind)
	local pass = kind == "Pass"
	local spec = pass and C.PassDetails[key] or C.Products[key]
	local metadata = pass and state.Store.Passes[key] or state.Store.Products[key]
	metadata = metadata or {}
	local title = pass and C.PassLabels[key] or spec.Label
	local owned = pass and state.Passes[key]
	local configured = pass and C.Passes[key] > 0 or not pass and spec.Id > 0
	local price = metadata.Price and (metadata.Price .. " Robux") or "Ver preço no Roblox"
	local desc = pass and spec.Description
		or spec.Kind == "Eggs" and "Créditos para abrir ovos junto ao pedestal. Cada crédito substitui Coins de uma abertura."
		or spec.Kind == "Pet" and "Entrega direta do pet indicado, uma vez por compra. Não depende de sorte."
		or spec.Kind == "Gems" and "Quantidade fixa de Gems. Não é multiplicada por passes."
		or "Boost de tempo real: o relógio continua enquanto você está offline."
	local _, b = card(
		title,
		desc,
		owned and "✓ Adquirido"
			or not configured and "Oferta não configurada"
			or metadata.ForSale == false and "Indisponível"
			or price .. " • Comprar",
		function()
			send("Purchase", { Type = kind, Key = key })
		end,
		owned and colors.Green or colors.Pink
	)
	b.Name = "Purchase" .. key
	if owned or not configured or metadata.ForSale == false then
		UI.disabled(b, b.Text)
	end
end
render = function()
	if not state or not menu or UIS:GetFocusedTextBox() then
		return
	end
	local scroll = list.CanvasPosition
	local selected = GuiService.SelectedObject
	local selectedName = selected and selected.Name
	UI.clear(list, listLayout)
	heading.Text = names[menu]
	headerTabs()
	lastScreenKey = viewKey()
	local content = state.Content
	if menu == "More" then
		local grid = UI.grid(list, 112, columns())
		for _, key in ipairs({
			"Guide",
			"Eggs",
			"Collection",
			"Upgrades",
			"Quests",
			"Rebirth",
			"Rankings",
			"Events",
			"Codes",
			"Settings",
			"Inventory",
		}) do
			local _, button = UI.shortTile(grid, names[key], "Abrir menu", "Abrir", function()
				open(key)
			end, colors.Accent)
			button.Name = "More" .. key
		end
	elseif menu == "Guide" then
		local goal = C.Tutorial[content.Tutorial]
		if goal then
			local b = progress(
				goal.Title,
				content.TutorialProgress,
				goal.Target,
				"Resgatar " .. goal.Gems .. " Gems",
				function()
					send("Tutorial")
				end
			)
			if content.TutorialProgress < goal.Target then
				UI.disabled(b, "Em progresso")
			end
			UI.button(list, "Ir para " .. names[goal.Menu], function()
				if goal.Menu == "Guide" then
					menu = nil
					panel.Visible = false
					notify("Siga a seta e segure MINERAR.")
				else
					open(goal.Menu)
				end
			end)
		else
			card("Explore seu próximo mundo", "O universo continua após cada rebirth.")
		end
		local grid = UI.grid(list, 126, columns())
		for _, step in ipairs({
			{ "MINERAR", "Segure no cristal", "Eggs" },
			{ "VENDER", "Troque mochila por Coins", "Inventory" },
			{ "MELHORAR", "Picaretas e Gems Lab", "Tools" },
			{ "EXPLORAR", "Desbloqueie mundos", "Worlds" },
		}) do
			UI.shortTile(grid, step[1], step[2], "Ver", function()
				open(step[3])
			end, colors.Cyan)
		end
		UI.button(list, showHelp and "Ocultar dicas" or "Dicas de titãs, combos e pets", function()
			showHelp = not showHelp
			render()
		end)
		if showHelp then
			card("Titãs em equipe", "Cause dano para ganhar sua parte da recompensa. Retorno em 3 min.")
			card("Combo", "Quebre cristais em até 8 segundos: até +50% Coins.")
			card("Pets", "Equipe os melhores e funda três iguais para melhorar seus bônus.")
		end
		UI.button(list, "Convidar um amigo", function()
			local ok, allowed = pcall(function()
				return SocialService:CanSendGameInviteAsync(player)
			end)
			if ok and allowed then
				pcall(function()
					SocialService:PromptGameInvite(player)
				end)
			else
				notify("Convites ficam disponíveis na experiência publicada.")
			end
		end, colors.Cyan)
	elseif menu == "Tools" then
		local nextIndex = math.min(state.Tool + 1, #C.Tools)
		local spec = C.Tools[nextIndex]
		local _, buy, heroImage = UI.hero(
			list,
			spec.Name,
			"Dano " .. B.compact(spec.Damage) .. " • " .. string.format("%.2fs", spec.Interval) .. " por golpe",
			state.Tool == #C.Tools and "Todas desbloqueadas" or "Comprar • " .. B.compact(spec.Cost) .. " Coins",
			function()
				send("Tool")
			end,
			colors.Cyan
		)
		V.portrait(heroImage, nil, 0, false, "Tool", nextIndex)
		if state.Tool == #C.Tools then
			UI.disabled(buy, "Última picareta equipada")
		end
		card("Equipada: " .. C.Tools[state.Tool].Name, "A compra equipa automaticamente sua nova picareta.")
		local maxPage = math.ceil(#C.Tools / 12)
		toolPage = math.clamp(toolPage, 1, maxPage)
		UI.button(list, "Galeria " .. toolPage .. " / " .. maxPage .. " • Próxima", function()
			toolPage = toolPage % maxPage + 1
			render()
		end)
		local grid = UI.grid(list, 198, columns())
		for i = (toolPage - 1) * 12 + 1, math.min(#C.Tools, toolPage * 12) do
			local tileSpec = C.Tools[i]
			local owned = i <= state.Tool
			local _, b, image = UI.tile(
				grid,
				tileSpec.Name,
				"Dano " .. B.compact(tileSpec.Damage),
				i == state.Tool and "Equipada"
					or owned and "Desbloqueada"
					or i == state.Tool + 1 and B.compact(tileSpec.Cost) .. " Coins"
					or "Próxima etapa",
				function()
					if i == state.Tool + 1 then
						send("Tool")
					end
				end,
				owned and colors.Green or colors.Accent
			)
			V.portrait(image, nil, 0, false, "Tool", i)
			b.Name = "Tool" .. i
			if i ~= state.Tool + 1 then
				UI.disabled(b, b.Text)
			end
		end
	elseif menu == "Upgrades" then
		card(
			"Upgrades permanentes com Gems",
			"Mantidos após rebirth. Ganhe Gems em níveis, missões, presentes, coleção e titãs."
		)
		for _, key in ipairs({ "Damage", "Coins", "Backpack", "Slots" }) do
			local u = C.GemUpgrades[key]
			local level = content.Upgrades[key]
			local cost = P.upgradeCost(u, level)
			local _, b = card(
				u.Name .. " • " .. level .. " / " .. u.Max,
				u.Description,
				level >= u.Max and "Máximo" or "Melhorar • " .. B.compact(cost) .. " Gems",
				function()
					send("Upgrade", key)
				end,
				colors.Cyan
			)
			if level >= u.Max then
				UI.disabled(b, "Nível máximo")
			end
		end
	elseif menu == "Eggs" then
		local _, _, image = UI.hero(
			list,
			C.Worlds[state.World].Name .. " • Ovo",
			B.compact(C.Worlds[state.World].EggCost) .. " Coins • " .. state.EggCredits .. " créditos",
			"Abrir 1 ovo",
			function()
				send("Hatch", 1)
			end,
			colors.Gold
		)
		V.portrait(image, "w" .. state.World .. "r5", 0, false)
		if state.Passes.TripleHatch then
			UI.button(list, "Abrir 3 ovos", function()
				send("Hatch", 3)
			end, colors.Accent)
		end
		card("Veja o que pode vir", "Aproxime-se do pedestal. Chances abaixo incluem sua Luck atual.")
		local total = 0
		for rank, weight in ipairs(C.Weights) do
			total += weight * (rank >= 3 and state.LuckMultiplier or 1)
		end
		local grid = UI.grid(list, 188, columns())
		for rank, name in ipairs(C.Rarities) do
			local id = "w" .. state.World .. "r" .. rank
			local pet = C.Pets[id]
			local chance = C.Weights[rank] * (rank >= 3 and state.LuckMultiplier or 1) / total * 100
			local _, b = portraitTile(
				grid,
				id,
				0,
				pet.Name,
				name,
				string.format("%.4f%%", chance),
				function() end,
				colors.Accent
			)
			UI.disabled(b, string.format("%.4f%%", chance))
		end
	elseif menu == "Inventory" then
		card("Sua mochila", state.BagCount .. " cristais • " .. B.compact(state.Bag) .. " Coins", "Vender", function()
			send("Sell")
		end, colors.Green)
		card("Ferramenta equipada", C.Tools[state.Tool].Name, "Ver picaretas", function()
			open("Tools")
		end)
	elseif menu == "Pets" then
		card(
			"Seu esquadrão",
			#state.Pets
				.. " / "
				.. C.MaxPets
				.. " pets • "
				.. #state.Equipped
				.. " / "
				.. B.petSlots(state)
				.. " equipados",
			"Equipar melhores",
			function()
				send("EquipBest")
			end,
			colors.Cyan
		)
		local found
		for _, p in ipairs(state.Pets) do
			if p.Uid == selectedPet then
				found = p
				break
			end
		end
		if found then
			local info, desc = petInfo(found)
			local equipped = table.find(state.Equipped, found.Uid)
			local _, _, image = UI.hero(list, info.Name, desc, equipped and "Desequipar" or "Equipar", function()
				send("Equip", found.Uid)
			end, colors.Cyan)
			V.portrait(image, found.Id, found.Tier or 0, false)
			local fusion = P.fusion(state.Pets, state.Equipped, found.Uid)
			if fusion then
				UI.button(
					list,
					confirmation == "Fuse" and "CONFIRMAR: consumir 3 pets + " .. fusion.Cost .. " Gems"
						or "Fundir 3 iguais → " .. (fusion.Tier == 1 and "Golden 2,5x" or "Cosmic 6,25x"),
					function()
						if confirmation == "Fuse" then
							send("Fuse", found.Uid)
							confirmation = nil
							selectedPet = nil
						else
							confirmation = "Fuse"
							render()
						end
					end,
					colors.Gold
				)
			end
			if not equipped then
				UI.button(
					list,
					confirmation == "Delete" and "CONFIRMAR exclusão permanente" or "Excluir este pet",
					function()
						if confirmation == "Delete" then
							send("DeletePet", found.Uid)
							selectedPet = nil
							confirmation = nil
						else
							confirmation = "Delete"
							render()
						end
					end,
					colors.Danger
				)
			end
		end
		card("Fusão", "Selecione um pet e desequipe três iguais para fundir.")
		local pets = table.clone(state.Pets)
		table.sort(pets, function(a, b)
			return C.Pets[a.Id].Coins * P.variant(a.Tier) > C.Pets[b.Id].Coins * P.variant(b.Tier)
		end)
		local maxPage = math.max(1, math.ceil(#pets / 24))
		petPage = math.clamp(petPage, 1, maxPage)
		UI.button(list, "Página " .. petPage .. " / " .. maxPage .. " • Próxima", function()
			petPage = petPage % maxPage + 1
			selectedPet = nil
			render()
			list.CanvasPosition = Vector2.new()
		end)
		local grid = UI.grid(list, 198, columns())
		for i = (petPage - 1) * 24 + 1, math.min(#pets, petPage * 24) do
			local pet = pets[i]
			local info = C.Pets[pet.Id]
			local equipped = table.find(state.Equipped, pet.Uid)
			local _, b = portraitTile(
				grid,
				pet.Id,
				pet.Tier or 0,
				info.Name,
				(pet.Tier == 2 and "Cosmic" or pet.Tier == 1 and "Golden" or info.Rarity),
				equipped and "✓ Equipado" or "Selecionar",
				function()
					selectedPet = pet.Uid
					confirmation = nil
					render()
					list.CanvasPosition = Vector2.new()
				end,
				equipped and colors.Green or colors.Accent
			)
			b.Name = pet.Uid
		end
	elseif menu == "Collection" then
		local discovered, total = 0, 0
		for id in pairs(C.Pets) do
			total += 1
			if content.Discoveries[id] then
				discovered += 1
			end
		end
		card(
			"Atlas cósmico",
			discovered .. " / " .. total .. " espécies descobertas. Cada primeira descoberta concede Gems."
		)
		UI.button(list, "" .. C.Worlds[collectionWorld].Name .. " • Próximo mundo", function()
			collectionWorld = collectionWorld % #C.Worlds + 1
			render()
		end)
		local ids = {}
		for id, info in pairs(C.Pets) do
			if info.World == collectionWorld then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return C.Pets[a].Rank < C.Pets[b].Rank
		end)
		local grid = UI.grid(list, 198, columns())
		for _, id in ipairs(ids) do
			local info = C.Pets[id]
			local known = content.Discoveries[id]
			local claimed = content.DiscoveryClaims[id]
			local _, b = portraitTile(
				grid,
				id,
				0,
				known and info.Name or "???",
				info.Rarity,
				claimed and "✓ Resgatado" or "+" .. (info.Rank * 5) .. " Gems",
				function()
					send("Discovery", id)
				end,
				colors.Accent,
				not known
			)
			if not known or claimed then
				UI.disabled(b, claimed and "✓ Resgatado" or "Não descoberto")
			end
		end
	elseif menu == "Worlds" then
		card("Sua rota pelo universo", C.Worlds[state.World].Name .. " • visite as ilhas pelo portal ou por aqui.")
		local grid = UI.grid(list, 212, columns())
		for i, w in ipairs(C.Worlds) do
			local unlocked = state.Unlocked[tostring(i)]
			local _, b, image = UI.tile(
				grid,
				w.Name,
				w.RequiredRebirths > 0 and w.RequiredRebirths .. " rebirths" or "Exploração",
				unlocked and (state.World == i and "Você está aqui" or "Viajar") or B.compact(w.Cost) .. " Coins",
				function()
					send("World", i)
				end,
				colors.Accent
			)
			V.worldPortrait(image, i)
			if state.Rebirths < w.RequiredRebirths then
				UI.disabled(b, "Rebirths insuficientes")
			end
		end
	elseif menu == "Rewards" then
		local nextStreak = P.streak(content.Login.LastDay, content.Login.Streak, math.floor(os.time() / 86400))
		local _, dailyButton = card(
			"Presente diário • dia " .. (nextStreak or content.Login.Streak) .. " / 7",
			"25–175 Gems + créditos de ovo. Dia 7: Aurora Guardian. Reset diário às 00:00 UTC.",
			content.CanLogin and "Resgatar presente gratuito" or "✓ Presente de hoje resgatado",
			function()
				send("LoginGift")
			end,
			colors.Green
		)
		if not content.CanLogin then
			UI.disabled(dailyButton, dailyButton.Text)
		end
		for i, gift in ipairs(C.PlayGifts) do
			local claimed = content.PlayClaimed[tostring(i)]
			local b = progress(
				"Exploração • " .. math.floor(gift.Seconds / 60) .. " min",
				content.PlaySeconds,
				gift.Seconds,
				claimed and "✓ Resgatado" or "Resgatar " .. gift.Gems .. " Gems + " .. gift.Credits .. " ovos",
				function()
					send("PlayGift", i)
				end
			)
			if claimed or content.PlaySeconds < gift.Seconds then
				UI.disabled(b, claimed and "✓ Resgatado" or "Continue explorando")
			end
		end
	elseif menu == "Quests" then
		card(
			"Missões e conquistas",
			"Missões diárias resetam às 00:00 UTC. Conquistas são permanentes, uma recompensa por etapa."
		)
		for i, q in ipairs(C.Quests) do
			local claimed = state.Daily.Claimed[tostring(i)]
			local b = progress(
				"Diária • " .. q.Key,
				state.Daily[q.Key],
				q.Target,
				claimed and "✓ Resgatada" or "+" .. q.Gems .. " Gems + " .. q.Reward,
				function()
					send("Quest", i)
				end
			)
			if claimed or state.Daily[q.Key] < q.Target then
				UI.disabled(b, claimed and "✓ Resgatada" or "Em progresso")
			end
		end
		for i, spec in ipairs(C.Achievements) do
			local value = spec.Key == "WorldCount" and P.value(state, spec.Key)
				or spec.Key == "Hatched" and content.Hatched
				or state[spec.Key]
			local claimed = content.Achievements[spec.Id]
			local b = progress(
				spec.Name,
				value,
				spec.Target,
				claimed and "✓ Resgatada" or "Resgatar " .. spec.Gems .. " Gems",
				function()
					send("Achievement", i)
				end
			)
			if claimed or value < spec.Target then
				UI.disabled(b, claimed and "✓ Resgatada" or "Em progresso")
			end
		end
	elseif menu == "Rebirth" then
		card(
			"Renascimento cósmico",
			state.Rebirths
				.. " rebirths • permanente "
				.. B.rebirthMultiplier(state.Rebirths)
				.. "x • custo "
				.. B.compact(state.RebirthCost)
				.. " Coins"
		)
		card(
			"O que você mantém",
			"Pets, Gems, upgrades do Gems Lab, coleção, conquistas, passes e ajustes. Coins, mochila, picareta e mundos voltam ao início."
		)
		progress(
			"Próximo rebirth",
			state.Coins,
			state.RebirthCost,
			confirmation == "Rebirth" and "CONFIRMAR REBIRTH" or "Fazer rebirth",
			function()
				if confirmation == "Rebirth" or state.Passes.InstantRebirth then
					send("Rebirth")
					confirmation = nil
				else
					confirmation = "Rebirth"
					render()
				end
			end
		)
	elseif menu == "Shop" then
		card(
			"Loja oficial • compras opcionais",
			"Passes são permanentes. Produtos podem ser comprados novamente. Preços aqui são referência; confirme o preço final no prompt oficial Roblox."
		)
		UI.button(
			list,
			storeTab == "Passes" and "PASSES permanentes • Ver produtos" or "PRODUTOS • Ver passes",
			function()
				storeTab = storeTab == "Passes" and "Products" or "Passes"
				render()
			end,
			colors.Pink
		)
		if storeTab == "Passes" then
			UI.button(list, "Categoria: " .. storeFilter .. " • Mudar", function()
				local filters = { "Todos", "Progressão", "Pets", "Conforto" }
				storeFilter = filters[(table.find(filters, storeFilter) or 1) % #filters + 1]
				render()
			end)
			for _, key in ipairs(C.PassOrder) do
				if storeFilter == "Todos" or C.PassDetails[key].Category == storeFilter then
					purchaseCard(key, "Pass")
				end
			end
		else
			local keys = {}
			for key in pairs(C.Products) do
				table.insert(keys, key)
			end
			table.sort(keys)
			for _, key in ipairs(keys) do
				purchaseCard(key, "Product")
			end
		end
	elseif menu == "Events" then
		local e = state.Event
		card(
			e.Active and "Evento ativo • " .. e.Kind or "Próximo evento",
			e.Active and "Termina em " .. math.max(0, e.Ends - os.time()) .. "s"
				or "Começa em " .. math.max(0, e.Next - os.time()) .. "s"
		)
		card(
			"Titãs derrotados",
			tostring(content.BossWins) .. " vitórias. Use os menus de mundo para encontrar novos desafios."
		)
		UI.button(list, "Ver Top Global", function()
			open("Rankings")
		end)
	elseif menu == "Rankings" then
		UI.button(list, "" .. rankCategory .. " • Mudar classificação", function()
			local keys = { "Coins", "Rebirths", "Pets", "Gems" }
			rankCategory = keys[(table.find(keys, rankCategory) or 1) % #keys + 1]
			render()
		end)
		UI.button(list, "Atualizar", function()
			send("Rankings")
		end, colors.Cyan)
		card(
			"TOP GLOBAL • " .. rankCategory,
			(rankCategory == "Coins" or rankCategory == "Pets") and "Total histórico • atualização a cada 3 min"
				or "Classificação global • atualização a cada 3 min"
		)
		local rows = rankData[rankCategory] or {}
		if #rows == 0 then
			card(
				"Ainda sem resultados",
				rankAvailable[rankCategory] and "Ainda não há jogadores nesta classificação."
					or "A classificação global precisa de uma experiência publicada com DataStore disponível."
			)
		end
		for position, entry in ipairs(rows) do
			UI.rankRow(list, position, entry.Name, entry.Value, entry.UserId, B.compact)
		end
	elseif menu == "Codes" then
		card(
			"Códigos de presente",
			"Experimente WELCOME, UNIVERSE e COSMIC. Cada código pode ser usado uma vez por conta."
		)
		local input = Instance.new("TextBox")
		input.Name = "CodeInput"
		input.Size = UDim2.new(1, -8, 0, 48)
		input.Text = codeValue
		input.PlaceholderText = "DIGITE O CÓDIGO"
		input.ClearTextOnFocus = false
		input.TextSize = 20
		input.TextColor3 = colors.Text
		input.BackgroundColor3 = colors.Card
		input.Font = Enum.Font.GothamBold
		input.Parent = list
		UI.round(input)
		input:GetPropertyChangedSignal("Text"):Connect(function()
			codeValue = input.Text
		end)
		UI.button(list, "Resgatar", function()
			input:ReleaseFocus()
			send("Code", codeValue)
		end, colors.Green)
	elseif menu == "Settings" then
		UI.button(
			list,
			"Gráficos: " .. (state.Settings.Graphics or "Auto") .. " • " .. Graphics.Effective,
			function()
				local modes = { "Auto", "High", "Low" }
				local index = table.find(modes, state.Settings.Graphics or "Auto") or 1
				send("Graphics", modes[index % #modes + 1])
			end,
			colors.Accent
		)
		for _, key in ipairs({ "Music", "Effects", "ReducedMotion" }) do
			UI.button(list, key .. ": " .. (state.Settings[key] and "ON" or "OFF"), function()
				send("Setting", key)
			end)
		end
		card(
			"Controles",
			"PC: segure clique / MINERAR • celular: toque / segure MINERAR • controle: R2 minera, Y vende, L2 abre ovo, X interage, B fecha menu • E interage com estações"
		)
		card(
			"Dados",
			state.Temporary
					and "Teste Studio: sessão temporária. Não será salva. Publique uma experiência de teste para validar DataStore."
				or "Salvamento automático ativo. Não use os dados de produção em testes destrutivos."
		)
	end
	list.CanvasPosition = scroll
	if selectedName and UIS.GamepadEnabled then
		local chosen = list:FindFirstChild(selectedName, true)
		if chosen and chosen:IsA("GuiButton") then
			GuiService.SelectedObject = chosen
		else
			GuiService.SelectedObject = close
		end
	end
end
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	local small = size.X < 760
	compact = small
	toggle.Visible = true
	toggle.Text = "MAIS"
	nav.AnchorPoint = Vector2.new(0.5, 1)
	nav.Position = UDim2.new(0.5, 0, 1, -12)
	nav.Size = UDim2.fromOffset(math.min(660, size.X - 24), 60)
	nav.AutomaticCanvasSize = Enum.AutomaticSize.None
	nav.Visible = not panel.Visible
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 104)
	panel.Size = UDim2.fromOffset(math.min(860, size.X - 24), math.max(150, size.Y - 178))
	objectiveButton.Visible = not small
	objective.Position = UDim2.new(0, 12, 1, -206)
	objective.Size = UDim2.fromOffset(math.max(150, math.min(320, size.X - 360)), 120)
	controls.Size = UDim2.fromOffset(small and 245 or 310, 120)
	controls.Position = UDim2.new(1, small and -257 or -322, 1, -206)
	if small then
		objective.Size = UDim2.new(1, -24, 0, 76)
		objective.Position = UDim2.fromOffset(12, 108)
		objectiveTitle.TextSize = 10
		objectiveText.TextSize = 13
	end
	wallet.TextSize = small and 15 or 21
	sub.TextSize = small and 11 or 13
	for _, b in ipairs(nav:GetChildren()) do
		if b:IsA("TextButton") then
			b.TextSize = small and 10 or 12
		end
	end
	if panel.Visible and state then
		render()
	end
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
resize()
local highlight = Instance.new("Highlight")
highlight.Name = "MiningTarget"
highlight.FillTransparency = 0.9
highlight.OutlineColor = colors.Cyan
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Parent = workspace
local marker = Instance.new("BillboardGui")
marker.Name = "GuideMarker"
marker.Size = UDim2.fromOffset(150, 32)
marker.StudsOffset = Vector3.new(0, 10, 0)
marker.AlwaysOnTop = true
marker.MaxDistance = 200
marker.Parent = gui
local markerText = UI.text(marker, "↓ SEU OBJETIVO", UDim2.fromScale(1, 1), nil, 15, colors.Gold)
markerText.TextXAlignment = Enum.TextXAlignment.Center
markerText.TextStrokeTransparency = 0.3
local function rayTarget(position)
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if hit and hit.Instance:GetAttribute("Alive") then
		return hit.Instance
	end
	return nil
end
local function beginHold(p)
	if p then
		held = true
		heldId = p:GetAttribute("CrystalId")
		send("Mine", heldId)
		nextHit = os.clock() + 0.13
	end
end
UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginHold(rayTarget(UIS:GetMouseLocation()))
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		held = false
	end
end)
UIS.TouchTapInWorld:Connect(function(position, processed)
	if not processed then
		local p = rayTarget(position)
		if p then
			send("Mine", p:GetAttribute("CrystalId"))
		end
	end
end)
mine.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginHold(target)
	end
end)
CAS:BindAction("UMMine", function(_, phase)
	if phase == Enum.UserInputState.Begin then
		beginHold(target)
	elseif phase == Enum.UserInputState.End then
		held = false
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonR2)
CAS:BindAction("UMSell", function(_, phase)
	if phase == Enum.UserInputState.Begin then
		send("Sell")
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonY)
CAS:BindAction("UMHatch", function(_, phase)
	if phase == Enum.UserInputState.Begin then
		send("Hatch", 1)
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonL2)
CAS:BindAction("UMClose", function(_, phase)
	if phase == Enum.UserInputState.Begin then
		panel.Visible = false
		menu = nil
		GuiService.SelectedObject = nil
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonB)
local nextScan = 0
Run.RenderStepped:Connect(function()
	controls.Visible = not panel.Visible
	nav.Visible = not panel.Visible
	objective.Visible = not panel.Visible
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not state then
		return
	end
	local now = os.clock()
	if held and heldId and now >= nextHit and not panel.Visible then
		nextHit = now + 0.13
		send("Mine", heldId)
	end
	if now < nextScan then
		return
	end
	nextScan = now + 0.2
	local map = workspace:FindFirstChild("UniverseMap")
	local folder = map and map:FindFirstChild(C.Worlds[state.World].Name)
	local nearest, dist = nil, state.Passes.Magnet and 55 or 24
	if folder then
		for _, p in ipairs(folder:GetChildren()) do
			if p:IsA("BasePart") and p:GetAttribute("Alive") then
				local d = (p.Position - root.Position).Magnitude
				if d < dist then
					dist = d
					nearest = p
				end
			end
		end
	end
	target = nearest
	highlight.Adornee = nearest
	mine.Text = nearest
			and ((nearest:GetAttribute("Boss") and "TITÃ " or "MINERAR ") .. B.compact(nearest:GetAttribute("Health")) .. " HP • segure")
		or "Aproxime-se de um cristal"
	local step = state.Content.Tutorial
	local goalTarget = step == 1 and nearest
		or step == 2 and folder and folder:FindFirstChild("Sell")
		or step == 3 and folder and folder:FindFirstChild("PICARETASBase")
		or step == 4 and folder and folder:FindFirstChild("Egg")
		or step == 5 and folder and folder:FindFirstChild("Portal")
		or nil
	marker.Adornee = goalTarget
	marker.Enabled = goalTarget ~= nil
	if heldId and folder then
		local alive = false
		for _, p in ipairs(folder:GetChildren()) do
			if p:IsA("BasePart") and p:GetAttribute("CrystalId") == heldId then
				alive = p:GetAttribute("Alive")
				break
			end
		end
		if not alive then
			held = false
		end
	end
end)
local hatchQueue = {}
local hatching = false
local function hatch(results)
	table.insert(hatchQueue, results)
	if hatching then
		return
	end
	hatching = true
	task.spawn(function()
		while #hatchQueue > 0 do
			local batch = table.remove(hatchQueue, 1)
			local overlay = UI.frame(gui, UDim2.fromScale(0.78, 0.58), UDim2.fromScale(0.11, 0.2), colors.Background)
			overlay.ZIndex = 60
			local headline = UI.text(
				overlay,
				"UMA NOVA COMPANHIA…",
				UDim2.new(1, -24, 0, 50),
				UDim2.fromOffset(12, 6),
				22,
				colors.Gold
			)
			headline.ZIndex = 61
			headline.TextXAlignment = Enum.TextXAlignment.Center
			local viewport = Instance.new("ViewportFrame")
			viewport.Size = UDim2.new(1, -20, 0.65, 0)
			viewport.Position = UDim2.fromOffset(10, 52)
			viewport.BackgroundTransparency = 1
			viewport.Ambient = Color3.new(1, 1, 1)
			viewport.LightColor = Color3.new(1, 1, 1)
			viewport.ZIndex = 61
			viewport.Parent = overlay
			local camera = Instance.new("Camera")
			camera.CFrame = CFrame.new(Vector3.new(0, 1, -8), Vector3.new(0, 0.3, 0))
			camera.Parent = viewport
			viewport.CurrentCamera = camera
			local world = Instance.new("WorldModel")
			world.Parent = viewport
			local models = {}
			local lines = {}
			for i, pet in ipairs(batch) do
				local info = C.Pets[pet.Id]
				local model = V.petModel(info, pet.Tier or 0, world)
				model:PivotTo(CFrame.new((i - (#batch + 1) / 2) * 3, 0, 0))
				table.insert(models, model)
				local _, desc = petInfo(pet)
				table.insert(lines, info.Name .. " • " .. desc)
				if info.Rank >= 5 then
					V.celebrate(35)
				end
			end
			if not state.Settings.ReducedMotion then
				overlay.Rotation = -3
				Tween:Create(overlay, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
			end
			task.wait(state.Passes.FastHatch and 0.25 or 0.6)
			headline.Text = "PET DESCOBERTO!"
			V.sound("Hatch")
			local caption = UI.text(
				overlay,
				table.concat(lines, "\n"),
				UDim2.new(1, -24, 0.2, 0),
				UDim2.new(0, 12, 0.76, 0),
				#batch > 1 and 12 or 17,
				colors.Text
			)
			caption.ZIndex = 61
			caption.TextXAlignment = Enum.TextXAlignment.Center
			task.wait(state.Passes.FastHatch and 0.6 or 1.4)
			overlay:Destroy()
		end
		hatching = false
	end)
end
update.OnClientEvent:Connect(function(kind, payload)
	if kind == "State" then
		if not state and (not payload.Pets or not payload.Equipped) then
			send("Sync")
			return
		end
		if state then
			payload.Pets = payload.Pets or state.Pets
			payload.Equipped = payload.Equipped or state.Equipped
		end
		state = payload
		V.update(state)
		Graphics.apply(state)
		wallet.Text = "♦ "
			.. B.compact(state.Coins)
			.. " Coins    ◆ "
			.. B.compact(state.Gems)
			.. " Gems    ↻ "
			.. state.Rebirths
		sub.Text = (state.Temporary and "STUDIO • sessão temporária | " or "")
			.. C.Worlds[state.World].Name
			.. " • Lv "
			.. state.Level
			.. " • "
			.. string.format("%.1fx Coins", state.CoinMultiplier)
			.. (
				state.Content.Combo > 1
					and " • COMBO " .. state.Content.Combo .. " +" .. math.floor(
						(P.combo(state.Content.Combo) - 1) * 100
					) .. "%"
				or ""
			)
		local goal = C.Tutorial[state.Content.Tutorial]
		local nextTool = C.Tools[state.Tool + 1]
		objectiveTitle.Text = goal and "GUIA • " .. state.Content.Tutorial .. " / " .. #C.Tutorial
			or "SUA PRÓXIMA CONQUISTA"
		objectiveText.Text = goal and goal.Title or nextTool and nextTool.Name or "Rebirth e novos mundos"
		local current = goal and state.Content.TutorialProgress or state.Coins
		local max = goal and goal.Target or nextTool and nextTool.Cost or state.RebirthCost
		objectiveProgress.Size = UDim2.fromScale(math.clamp(current / max, 0, 1), 1)
		objectiveButton.Text = goal and current >= max and "Resgatar recompensa" or "Ver objetivo"
		bag.Text = state.BagCount
			.. " / "
			.. (state.Passes.InfiniteBackpack and "∞" or state.Content.Capacity)
			.. " • "
			.. B.compact(state.Bag)
			.. " Coins para vender"
		bagProgress.Size = UDim2.fromScale(
			state.Passes.InfiniteBackpack and 0.25 or math.clamp(state.BagCount / state.Content.Capacity, 0, 1),
			1
		)
		auto.Text = state.AutoMine and "Auto: ON" or "Auto"
		music.Volume = state.Settings.Music and 0.15 or 0
		if panel.Visible and viewKey() ~= lastScreenKey then
			render()
		end
	elseif kind == "Notice" or kind == "Global" then
		notify(payload)
	elseif kind == "Open" then
		open(payload)
	elseif kind == "Reward" then
		notify(payload.Text)
		V.sound("Reward")
	elseif kind == "MineFX" then
		V.sound("Mine")
		V.burst(payload.Position, payload.Destroyed and 12 or 3, colors.Cyan)
	elseif kind == "Celebration" then
		notify(payload.Text)
		V.sound(payload.Kind)
		V.celebrate(payload.Kind == "Rebirth" and 45 or 20)
	elseif kind == "Hatch" then
		hatch(payload)
	elseif kind == "Rankings" then
		rankData = payload.Rows
		rankAvailable = payload.Available or {}
		if menu == "Rankings" then
			render()
		end
	end
end)
send("Sync")
