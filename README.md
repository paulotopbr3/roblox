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
]]></string>
          </Properties>
        </Item>
      </Item>
    </Item>
  </Item>
</roblox>
