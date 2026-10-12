local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local Tween = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local shared = game.ReplicatedStorage:WaitForChild("UniverseMiner")
local C = require(shared.Config)
local B = require(shared.Balance)
local remotes = shared:WaitForChild("Remotes", 15)
if not remotes then
	local diagnostic = Instance.new("ScreenGui")
	diagnostic.Name = "UniverseStartupError"
	diagnostic.ResetOnSpawn = false
	diagnostic.Parent = player:WaitForChild("PlayerGui")
	local message = Instance.new("TextLabel")
	message.Size = UDim2.fromScale(0.8, 0.25)
	message.Position = UDim2.fromScale(0.1, 0.35)
	message.BackgroundColor3 = Color3.fromRGB(40, 25, 40)
	message.TextColor3 = Color3.new(1, 1, 1)
	message.Font = Enum.Font.GothamBold
	message.TextSize = 22
	message.TextWrapped = true
	message.Text =
		"Universe Miner não iniciou. No Studio, abra View → Output e confira a primeira mensagem vermelha."
	message.Parent = diagnostic
	warn("UniverseMiner: server failed to create Remotes within 15 seconds")
	return
end
local action = remotes:WaitForChild("Action")
local update = remotes:WaitForChild("Update")
local state = nil
local menu = nil
local selectedPet = nil
local confirmDelete = nil
local confirmRebirth = false
local bg = Color3.fromRGB(21, 23, 45)
local accent = Color3.fromRGB(96, 82, 244)
local gold = Color3.fromRGB(255, 205, 65)
local gui = Instance.new("ScreenGui")
gui.Name = "UniverseMinerUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = p
end
local function frame(parent, size, pos, color)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color or bg
	f.BorderSizePixel = 0
	f.Parent = parent
	corner(f)
	return f
end
local function text(parent, value, size, pos, fontSize)
	local t = Instance.new("TextLabel")
	t.Size = size
	t.Position = pos or UDim2.new()
	t.BackgroundTransparency = 1
	t.Text = value
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextSize = fontSize or 17
	t.Font = Enum.Font.GothamBold
	t.TextWrapped = true
	t.Parent = parent
	return t
end
local function button(parent, title, fn, color)
	local b = Instance.new("TextButton")
	b.Name = title
	b.Text = title
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextWrapped = true
	b.Size = UDim2.new(1, -12, 0, 48)
	b.BackgroundColor3 = color or accent
	b.BorderSizePixel = 0
	b.Selectable = true
	b.Parent = parent
	corner(b)
	b.Activated:Connect(fn)
	return b
end
local function send(key, arg)
	action:FireServer(key, arg)
end
local top = frame(gui, UDim2.new(1, -24, 0, 94), UDim2.fromOffset(12, 8))
local title = text(top, C.Title, UDim2.new(1, 0, 0, 25), UDim2.fromOffset(0, 3), 19)
local stats = text(top, "Carregando dados…", UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 29), 16)
local goal = text(top, "", UDim2.new(1, -12, 0, 28), UDim2.fromOffset(6, 60), 14)
goal.TextColor3 = gold
local nav = Instance.new("ScrollingFrame")
nav.Size = UDim2.fromOffset(116, 460)
nav.Position = UDim2.fromOffset(12, 112)
nav.BackgroundColor3 = bg
nav.BorderSizePixel = 0
nav.ScrollBarThickness = 3
nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
nav.CanvasSize = UDim2.new()
nav.Parent = gui
corner(nav)
local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 4)
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Parent = nav
local panel = frame(gui, UDim2.new(0.68, 0, 0.68, 0), UDim2.new(0.28, 0, 0.19, 0))
panel.Visible = false
local header = text(panel, "", UDim2.new(1, -70, 0, 45), UDim2.fromOffset(12, 4), 22)
header.TextXAlignment = Enum.TextXAlignment.Left
local close = button(panel, "×", function()
	panel.Visible = false
	menu = nil
	GuiService.SelectedObject = nil
end)
close.Size = UDim2.fromOffset(44, 38)
close.Position = UDim2.new(1, -52, 0, 6)
local list = Instance.new("ScrollingFrame")
list.Name = "Content"
list.Position = UDim2.fromOffset(10, 55)
list.Size = UDim2.new(1, -20, 1, -65)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = list
local controls = frame(gui, UDim2.fromOffset(310, 100), UDim2.new(1, -322, 1, -112))
local mine
mine = button(controls, "MINERAR • R2 / clique", function()
	send("Mine", mine:GetAttribute("Target"))
end, gold)
mine.TextColor3 = bg
mine.Position = UDim2.fromOffset(6, 6)
local sell = button(controls, "Vender mochila • Y", function()
	send("Sell")
end, Color3.fromRGB(40, 156, 95))
sell.Size = UDim2.new(0.5, -8, 0, 36)
sell.Position = UDim2.fromOffset(6, 60)
local auto = button(controls, "Auto Mine", function()
	send("AutoMine")
end)
auto.Size = UDim2.new(0.5, -8, 0, 36)
auto.Position = UDim2.new(0.5, 2, 0, 60)
local toast = text(gui, "", UDim2.new(0.7, 0, 0, 66), UDim2.new(0.15, 0, 0.75, 0), 22)
toast.ZIndex = 20
toast.TextStrokeTransparency = 0.3
local toastSerial = 0
local function notify(value)
	toastSerial += 1
	local serial = toastSerial
	toast.Text = tostring(value)
	task.delay(3, function()
		if toastSerial == serial then
			toast.Text = ""
		end
	end)
end
local function sound(kind)
	if state and state.Settings.Effects == false then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = C.SoundIds[kind] ~= "" and C.SoundIds[kind] or "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.2
	s.PlaybackSpeed = kind == "Mine" and 1.6 or kind == "Rebirth" and 0.7 or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 5)
end
local function burst(position, count)
	if state and state.Settings.Effects == false then
		return
	end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.Position = position
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = gold
	p.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 12
	light.Brightness = 2
	light.Parent = p
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.2, 0.4)
	emitter.Speed = NumberRange.new(4, 9)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = p
	emitter:Emit(count)
	Tween:Create(p, TweenInfo.new(0.3), { Size = Vector3.new(4, 4, 4), Transparency = 1 }):Play()
	Debris:AddItem(p, 0.4)
end
local function characterBurst(count)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(root.Position, count)
	end
end
local music = Instance.new("Sound")
music.Name = "UniverseMusic"
music.Looped = true
music.Volume = 0.15
music.Parent = SoundService
if C.MusicId and C.MusicId ~= "" then
	music.SoundId = C.MusicId
	music:Play()
end
local function row(value)
	local t = text(list, value, UDim2.new(1, -12, 0, 62), nil, 15)
	t.TextXAlignment = Enum.TextXAlignment.Left
	return t
end
local render
local rankData = {}
local function open(name)
	menu = name
	panel.Visible = true
	confirmDelete = nil
	confirmRebirth = false
	render()
	if name == "Events" then
		send("Rankings")
	end
	if UIS.GamepadEnabled then
		GuiService.SelectedObject = list:FindFirstChildWhichIsA("TextButton") or close
	end
end
for _, name in ipairs({ "Shop", "Pets", "Inventory", "Worlds", "Rebirth", "Quests", "Codes", "Events", "Settings" }) do
	local b = button(nav, name, function()
		if menu == name then
			menu = nil
			panel.Visible = false
		else
			open(name)
		end
	end)
	b.Size = UDim2.new(1, -10, 0, 46)
end
local codeValue = ""
render = function()
	if not state or not menu then
		return
	end
	if UIS:GetFocusedTextBox() then
		return
	end
	local scroll = list.CanvasPosition
	local chosen = GuiService.SelectedObject
	local chosenName = chosen and chosen.Name
	for _, child in ipairs(list:GetChildren()) do
		if child ~= layout then
			child:Destroy()
		end
	end
	header.Text = menu
	if menu == "Shop" then
		local nextTool = C.Tools[state.Tool + 1]
		row(
			"Atual: "
				.. C.Tools[state.Tool].Name
				.. " • Dano "
				.. B.compact(C.Tools[state.Tool].Damage * state.DamageMultiplier)
		)
		if nextTool then
			button(list, "Comprar " .. nextTool.Name .. " • " .. B.compact(nextTool.Cost) .. " Coins", function()
				send("Tool")
			end)
		else
			row("Todas as 36 picaretas desbloqueadas!")
		end
		row(
			"Compras em Robux: preço exibido na confirmação oficial do Roblox. Boosts usam tempo real, inclusive offline."
		)
		local keys = {}
		for key in pairs(C.Passes) do
			table.insert(keys, key)
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			if C.Passes[key] > 0 then
				button(list, (state.Passes[key] and "✓ " or "") .. C.PassLabels[key], function()
					send("Purchase", { Type = "Pass", Key = key })
				end)
			end
		end
		local productKeys = {}
		for key in pairs(C.Products) do
			table.insert(productKeys, key)
		end
		table.sort(productKeys)
		for _, key in ipairs(productKeys) do
			local p = C.Products[key]
			if p.Id > 0 then
				button(list, p.Label, function()
					send("Purchase", { Type = "Product", Key = key })
				end, Color3.fromRGB(34, 145, 157))
			end
		end
	elseif menu == "Pets" then
		row(
			#state.Pets
				.. " / "
				.. C.MaxPets
				.. " pets • "
				.. #state.Equipped
				.. " / "
				.. B.petSlots(state)
				.. " equipados"
		)
		button(list, "Equipar melhores", function()
			send("EquipBest")
		end)
		if selectedPet then
			button(
				list,
				confirmDelete == selectedPet and "CONFIRMAR exclusão permanente"
					or "Excluir pet selecionado (desequipado)",
				function()
					if confirmDelete == selectedPet then
						send("DeletePet", selectedPet)
						confirmDelete = nil
						selectedPet = nil
					else
						confirmDelete = selectedPet
						render()
					end
				end,
				Color3.fromRGB(171, 57, 81)
			)
		end
		for _, pet in ipairs(state.Pets) do
			local info = C.Pets[pet.Id]
			local equipped = table.find(state.Equipped, pet.Uid)
			local b = button(
				list,
				(equipped and "✓ " or "")
					.. info.Name
					.. " • "
					.. info.Rarity
					.. " | +"
					.. math.floor(info.Coins * 100)
					.. "% Coins",
				function()
					selectedPet = pet.Uid
					send("Equip", pet.Uid)
				end
			)
			b.Name = pet.Uid
		end
	elseif menu == "Inventory" then
		row(
			"Mochila: "
				.. (state.BagCount or 0)
				.. " / "
				.. (state.Passes.InfiniteBackpack and "∞" or C.BaseBackpack)
				.. " cristais\nValor: "
				.. B.compact(state.Bag)
				.. " Coins • créditos de ovo: "
				.. state.EggCredits
		)
		button(list, "Vender agora", function()
			send("Sell")
		end)
		row("Picaretas desbloqueadas: " .. state.Tool .. " / " .. #C.Tools .. " • a melhor está equipada")
		for key, ends in pairs(state.Boosts) do
			row(key .. " Boost • " .. math.max(0, ends - os.time()) .. "s restantes")
		end
		row(
			"Ovo do mundo atual: "
				.. B.compact(C.Worlds[state.World].EggCost)
				.. " Coins por abertura. Aproxime-se do ovo amarelo."
		)
		button(list, "Abrir 1 ovo", function()
			send("Hatch", 1)
		end, gold)
		if state.Passes.TripleHatch then
			button(list, "Abrir 3 ovos", function()
				send("Hatch", 3)
			end)
		end
		local luck = (state.Passes.DoubleLuck and 2 or 1)
			* ((state.Boosts.Luck or 0) > os.time() and 2 or 1)
			* (state.Event.Active and state.Event.Kind == "Luck" and 2 or 1)
		local total = 0
		for i, w in ipairs(C.Weights) do
			total += w * (i >= 3 and luck or 1)
		end
		for i, name in ipairs(C.Rarities) do
			row(name .. " • " .. string.format("%.4f%%", C.Weights[i] * (i >= 3 and luck or 1) / total * 100))
		end
	elseif menu == "Worlds" then
		for i, w in ipairs(C.Worlds) do
			button(
				list,
				(state.World == i and "▶ " or "")
					.. w.Name
					.. " • "
					.. (state.Unlocked[tostring(i)] and "Viajar" or B.compact(w.Cost) .. " Coins")
					.. (w.RequiredRebirths > 0 and " • " .. w.RequiredRebirths .. " rebirths" or ""),
				function()
					send("World", i)
				end,
				Color3.fromRGB(table.unpack(w.Color))
			)
		end
	elseif menu == "Rebirth" then
		row(
			"Rebirths: "
				.. state.Rebirths
				.. " • permanente: "
				.. B.rebirthMultiplier(state.Rebirths)
				.. "x\nCusto: "
				.. B.compact(state.RebirthCost)
				.. " Coins"
		)
		row(
			"Reinicia Coins, mochila, ferramentas e mundos. Mantém Gems, pets, passes, missões e multiplicador permanente. Rebirths 2 e 4 abrem requisitos de Void e Heaven."
		)
		button(list, confirmRebirth and "CONFIRMAR REBIRTH" or "Fazer rebirth", function()
			if confirmRebirth or state.Passes.InstantRebirth then
				send("Rebirth")
				confirmRebirth = false
			else
				confirmRebirth = true
				render()
			end
		end, gold)
	elseif menu == "Quests" then
		row("Missões diárias • reset às 00:00 UTC • recompensas resgatadas manualmente")
		for i, q in ipairs(C.Quests) do
			button(
				list,
				q.Key
					.. ": "
					.. B.compact(state.Daily[q.Key] or 0)
					.. " / "
					.. B.compact(q.Target)
					.. " • "
					.. q.Gems
					.. " Gems + "
					.. q.Reward
					.. (state.Daily.Claimed[tostring(i)] and " ✓" or " • Resgatar"),
				function()
					send("Quest", i)
				end
			)
		end
	elseif menu == "Codes" then
		row("Digite um código. Cada código pode ser usado uma vez por conta.")
		local input = Instance.new("TextBox")
		input.Name = "CodeInput"
		input.Size = UDim2.new(1, -12, 0, 48)
		input.BackgroundColor3 = Color3.fromRGB(48, 51, 82)
		input.TextColor3 = Color3.new(1, 1, 1)
		input.TextSize = 20
		input.Font = Enum.Font.GothamBold
		input.PlaceholderText = "Código"
		input.Text = codeValue
		input.ClearTextOnFocus = false
		input.Parent = list
		corner(input)
		input:GetPropertyChangedSignal("Text"):Connect(function()
			codeValue = input.Text
		end)
		button(list, "Resgatar", function()
			input:ReleaseFocus()
			send("Code", codeValue)
		end)
	elseif menu == "Events" then
		local e = state.Event
		row(
			e.Active
					and (e.Kind == "Exclusive" and "Evento: chance de Event Nebula minerando" or "Evento: 2x " .. e.Kind)
				or "Sem evento ativo"
		)
		row("Próximo evento em " .. math.max(0, e.Next - os.time()) .. "s • duração 15 min a cada 2 h")
		row(
			"Durante eventos: cristais concedem Gems. Rankings globais atualizados periodicamente; Coins e Pets representam totais históricos."
		)
		button(list, "Atualizar rankings", function()
			send("Rankings")
		end)
		for _, key in ipairs({ "Coins", "Rebirths", "Pets", "Gems" }) do
			row("Global " .. key)
			if not rankData[key] then
				row("Indisponível ou aguardando DataStore.")
			else
				for i, entry in ipairs(rankData[key]) do
					row(i .. ". " .. entry.Name .. " • " .. B.compact(entry.Value))
				end
			end
		end
	elseif menu == "Settings" then
		for _, key in ipairs({ "Music", "Effects" }) do
			button(list, key .. ": " .. (state.Settings[key] and "ON" or "OFF"), function()
				send("Setting", key)
			end)
		end
		row(
			"PC: clique num cristal • Controle: R2 minera o cristal próximo, Y vende, X abre ovo, B fecha menu • Toque: toque no cristal ou use MINERAR."
		)
		row(
			state.Temporary and "STUDIO: dados temporários. Nada será salvo nesta sessão."
				or "Salvamento automático ativo; aguarde ao sair."
		)
	end
	list.CanvasPosition = scroll
	if chosenName and UIS.GamepadEnabled then
		local target = list:FindFirstChild(chosenName)
		if target and target:IsA("GuiButton") then
			GuiService.SelectedObject = target
		end
	end
end
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	local small = size.X < 760 or size.Y < 600
	nav.Size = UDim2.fromOffset(small and 88 or 116, math.min(small and 333 or 460, size.Y - 128))
	for _, b in ipairs(nav:GetChildren()) do
		if b:IsA("TextButton") then
			b.Size = UDim2.new(1, -8, 0, small and 33 or 46)
			b.TextSize = small and 12 or 16
		end
	end
	panel.Position = UDim2.fromOffset(small and 105 or 140, 112)
	panel.Size = UDim2.new(1, small and -117 or -160, 1, -124)
	controls.Size = UDim2.fromOffset(small and 245 or 310, 100)
	controls.Position = UDim2.new(1, small and -257 or -322, 1, -112)
	stats.TextSize = small and 12 or 16
	title.TextSize = small and 15 or 19
	goal.TextSize = small and 11 or 14
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
resize()
local function targetAt(position)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if hit and hit.Instance:GetAttribute("CrystalId") then
		send("Mine", hit.Instance:GetAttribute("CrystalId"))
	end
end
UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		targetAt(UIS:GetMouseLocation())
	end
end)
UIS.TouchTapInWorld:Connect(function(position, processed)
	if not processed then
		targetAt(position)
	end
end)
CAS:BindAction("UMMine", function(_, phase)
	if phase == Enum.UserInputState.Begin then
		send("Mine", mine:GetAttribute("Target"))
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
end, false, Enum.KeyCode.ButtonX)
CAS:BindAction("UMClose", function(_, phase)
	if phase == Enum.UserInputState.Begin then
		panel.Visible = false
		menu = nil
		GuiService.SelectedObject = nil
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonB)
local petVisuals = {}
local petSignature = ""
local function rebuildPets()
	local signature = table.concat(state.Equipped, ",")
	if signature == petSignature then
		return
	end
	petSignature = signature
	for _, p in ipairs(petVisuals) do
		p:Destroy()
	end
	petVisuals = {}
	for _, uid in ipairs(state.Equipped) do
		for _, pet in ipairs(state.Pets) do
			if pet.Uid == uid then
				local info = C.Pets[pet.Id]
				local p = Instance.new("Part")
				p.Name = info.Name
				p.Size = Vector3.new(1.8, 1.8, 1.8)
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
				p.Material = Enum.Material.Neon
				p.Color = Color3.fromHSV(info.Rank / 8, 0.65, 1)
				p.Parent = workspace
				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.fromOffset(120, 24)
				billboard.StudsOffset = Vector3.new(0, 1.8, 0)
				billboard.MaxDistance = 60
				billboard.Parent = p
				text(billboard, info.Name, UDim2.fromScale(1, 1), nil, 11)
				table.insert(petVisuals, p)
				break
			end
		end
	end
end
local nextScan = 0
RunService.RenderStepped:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	controls.Visible = not panel.Visible
	local now = os.clock()
	for i, p in ipairs(petVisuals) do
		local angle = i * math.pi * 2 / math.max(1, #petVisuals) + now * 0.5
		local pos = root.Position + Vector3.new(math.cos(angle) * 4, math.sin(now * 3 + i) * 0.4, math.sin(angle) * 4)
		p.CFrame = CFrame.new(pos, root.Position)
	end
	if now < nextScan then
		return
	end
	nextScan = now + 0.25
	local map = workspace:FindFirstChild("UniverseMap")
	if not map or not state then
		return
	end
	local folder = map:FindFirstChild(C.Worlds[state.World].Name)
	local nearest = nil
	local dist = state.Passes.Magnet and 55 or 24
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
	mine:SetAttribute("Target", nearest and nearest:GetAttribute("CrystalId") or nil)
	mine.Text = nearest and ("MINERAR • " .. B.compact(nearest:GetAttribute("Health")) .. " HP")
		or "Aproxime-se de um cristal"
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
			local pets = table.remove(hatchQueue, 1)
			local overlay = frame(gui, UDim2.fromScale(0.65, 0.4), UDim2.fromScale(0.2, 0.28), accent)
			overlay.ZIndex = 30
			local t = text(overlay, "✦ ABRINDO OVO ✦", UDim2.fromScale(1, 1), nil, 28)
			t.ZIndex = 31
			for _ = 1, 3 do
				overlay.Rotation = -5
				Tween:Create(overlay, TweenInfo.new(0.18), { Rotation = 5 }):Play()
				task.wait(0.18)
			end
			overlay.Rotation = 0
			local lines = {}
			for _, p in ipairs(pets) do
				local info = C.Pets[p.Id]
				table.insert(lines, info.Name .. " • " .. info.Rarity)
				if info.Rank >= 5 then
					overlay.BackgroundColor3 = gold
					characterBurst(30)
				end
			end
			t.Text = table.concat(lines, "\n")
			sound("Hatch")
			task.wait(1.4)
			overlay:Destroy()
		end
		hatching = false
	end)
end
update.OnClientEvent:Connect(function(kind, payload)
	if kind == "State" then
		if state then
			payload.Pets = payload.Pets or state.Pets
			payload.Equipped = payload.Equipped or state.Equipped
		end
		state = payload
		stats.Text = "Coins "
			.. B.compact(state.Coins)
			.. "   •   Gems "
			.. B.compact(state.Gems)
			.. "   •   Rebirths "
			.. state.Rebirths
			.. "   •   Lv "
			.. state.Level
		local nextTool = C.Tools[state.Tool + 1]
		goal.Text = (state.Temporary and "⚠ STUDIO TEMPORÁRIO • " or "")
			.. C.Worlds[state.World].Name
			.. " • "
			.. string.format("%.1fx Coins", state.CoinMultiplier)
			.. " • "
			.. (
				nextTool and "Meta: " .. nextTool.Name .. " • " .. B.compact(nextTool.Cost)
				or "Meta: próximo rebirth"
			)
		auto.Text = state.AutoMine and "Auto: ON" or "Auto Mine"
		music.Volume = state.Settings.Music and 0.15 or 0
		rebuildPets()
		if panel.Visible then
			render()
		end
	elseif kind == "Notice" or kind == "Global" then
		notify(payload)
	elseif kind == "Reward" then
		notify(payload.Text or "+Coins")
		sound("Reward")
	elseif kind == "Celebration" then
		notify(payload.Text)
		sound(payload.Kind)
		characterBurst(payload.Kind == "Rebirth" and 50 or 24)
		if state and state.Settings.Effects == false then
			return
		end
		local flash = frame(gui, UDim2.fromScale(1, 1), UDim2.new(), gold)
		flash.BackgroundTransparency = 0.7
		flash.ZIndex = 25
		Tween:Create(flash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
		Debris:AddItem(flash, 0.8)
	elseif kind == "Hatch" then
		hatch(payload)
	elseif kind == "Rankings" then
		rankData = payload.Rows
		if menu == "Events" then
			render()
		end
	elseif kind == "MineFX" then
		sound("Mine")
		if state and state.Settings.Effects == false then
			return
		end
		burst(payload.Position, payload.Destroyed and 14 or 4)
	end
end)
send("Sync")
