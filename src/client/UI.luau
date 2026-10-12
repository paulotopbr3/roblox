local UI = {}
UI.Colors = {
	Background = Color3.fromRGB(21, 27, 48),
	Card = Color3.fromRGB(34, 43, 70),
	Muted = Color3.fromRGB(173, 189, 220),
	Text = Color3.fromRGB(245, 249, 255),
	Accent = Color3.fromRGB(96, 107, 255),
	Cyan = Color3.fromRGB(75, 217, 218),
	Gold = Color3.fromRGB(255, 212, 108),
	Pink = Color3.fromRGB(244, 139, 212),
	Green = Color3.fromRGB(74, 197, 153),
	Danger = Color3.fromRGB(201, 80, 108),
}
function UI.round(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 14)
	c.Parent = instance
end
function UI.frame(parent, size, position, color)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = position or UDim2.new()
	f.BackgroundColor3 = color or UI.Colors.Background
	f.BorderSizePixel = 0
	f.Parent = parent
	UI.round(f)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(106, 123, 169)
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = f
	return f
end
function UI.text(parent, value, size, position, fontSize, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = value
	t.TextColor3 = color or UI.Colors.Text
	t.Size = size
	t.Position = position or UDim2.new()
	t.TextSize = fontSize or 16
	t.Font = Enum.Font.GothamBold
	t.TextWrapped = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
	return t
end
function UI.button(parent, value, callback, color)
	local b = Instance.new("TextButton")
	b.Name = value
	b.Text = value
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.TextWrapped = true
	local chosen = color or UI.Colors.Accent
	b.TextColor3 = (chosen.R * 0.2126 + chosen.G * 0.7152 + chosen.B * 0.0722) > 0.6 and UI.Colors.Background
		or UI.Colors.Text
	b.BackgroundColor3 = color or UI.Colors.Accent
	b.BorderSizePixel = 0
	b.Size = UDim2.new(1, -8, 0, 44)
	b.Selectable = true
	b.Parent = parent
	UI.round(b, 10)
	b.Activated:Connect(callback)
	return b
end
function UI.disabled(button, value)
	button.Text = value
	button.Active = false
	button.Selectable = false
	button.AutoButtonColor = false
	button.BackgroundColor3 = UI.Colors.Card
	button.TextColor3 = UI.Colors.Muted
end
function UI.list(parent)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 10)
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end
function UI.card(parent, title, description, action, callback, color)
	local card = UI.frame(parent, UDim2.new(1, -8, 0, action and 140 or 88), nil, UI.Colors.Card)
	UI.text(card, title, UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 18, color)
	UI.text(card, description, UDim2.new(1, -28, 0, 42), UDim2.fromOffset(14, 39), 13, UI.Colors.Muted)
	local b
	if action then
		b = UI.button(card, action, callback, color)
		b.Size = UDim2.new(1, -28, 0, 36)
		b.Position = UDim2.fromOffset(14, 91)
	end
	return card, b
end
function UI.bar(parent, fraction, color, position, size)
	local bar =
		UI.frame(parent, size or UDim2.new(1, -28, 0, 7), position or UDim2.new(0, 14, 1, -12), UI.Colors.Background)
	local fill = UI.frame(bar, UDim2.fromScale(math.clamp(fraction, 0, 1), 1), nil, color or UI.Colors.Cyan)
	return fill
end
function UI.clear(parent, except)
	for _, c in ipairs(parent:GetChildren()) do
		if c ~= except then
			c:Destroy()
		end
	end
end
return UI
