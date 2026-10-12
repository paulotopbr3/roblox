local UI = {}
UI.Colors = {
	Background = Color3.fromRGB(249, 251, 255),
	Card = Color3.fromRGB(231, 239, 252),
	Muted = Color3.fromRGB(87, 107, 138),
	Text = Color3.fromRGB(36, 52, 79),
	Accent = Color3.fromRGB(35, 104, 214),
	Cyan = Color3.fromRGB(20, 132, 144),
	Gold = Color3.fromRGB(255, 195, 73),
	Pink = Color3.fromRGB(194, 67, 146),
	Green = Color3.fromRGB(22, 133, 92),
	Danger = Color3.fromRGB(204, 71, 101),
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
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(
		color or UI.Colors.Background,
		(color or UI.Colors.Background):Lerp(Color3.fromRGB(222, 234, 251), 0.12)
	)
	gradient.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(106, 123, 169)
	stroke.Transparency = 0.68
	stroke.Thickness = 1.5
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
	b.TextColor3 = (chosen.R * 0.2126 + chosen.G * 0.7152 + chosen.B * 0.0722) > 0.6 and UI.Colors.Text
		or Color3.new(1, 1, 1)
	b.BackgroundColor3 = color or UI.Colors.Accent
	b.BorderSizePixel = 0
	b.Size = UDim2.new(1, -8, 0, 44)
	b.Selectable = true
	b.Parent = parent
	UI.round(b, 10)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(chosen, chosen:Lerp(Color3.new(0, 0, 0), 0.08))
	gradient.Parent = b
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
	local card = UI.frame(parent, UDim2.new(1, -8, 0, action and 126 or 78), nil, UI.Colors.Card)
	UI.text(card, title, UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 18, color)
	UI.text(card, description, UDim2.new(1, -28, 0, 42), UDim2.fromOffset(14, 39), 13, UI.Colors.Muted)
	local b
	if action then
		b = UI.button(card, action, callback, color)
		b.Size = UDim2.new(1, -28, 0, 36)
		b.Position = UDim2.fromOffset(14, 79)
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
function UI.grid(parent, height, columns)
	local holder = Instance.new("Frame")
	holder.Name = "VisualGrid"
	holder.Size = UDim2.new(1, -8, 0, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.CellSize = UDim2.new(1 / columns, -8, 0, height)
	layout.FillDirectionMaxCells = columns
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder
	local function resize()
		holder.Size = UDim2.new(1, -8, 0, layout.AbsoluteContentSize.Y)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
	return holder
end
function UI.tile(parent, title, badge, action, callback, color)
	local tile = UI.frame(parent, UDim2.fromOffset(160, 190), nil, UI.Colors.Card)
	local image = Instance.new("Frame")
	image.Name = "Artwork"
	image.Size = UDim2.new(1, -12, 0.55, 0)
	image.Position = UDim2.fromOffset(6, 5)
	image.BackgroundTransparency = 1
	image.Parent = tile
	local name = UI.text(tile, title, UDim2.new(1, -12, 0, 30), UDim2.new(0, 6, 0.55, 0), 13)
	name.TextXAlignment = Enum.TextXAlignment.Center
	local tag = UI.text(tile, badge, UDim2.new(1, -12, 0, 22), UDim2.new(0, 6, 1, -61), 11, color or UI.Colors.Muted)
	tag.TextXAlignment = Enum.TextXAlignment.Center
	local b = UI.button(tile, action, callback, color)
	b.Size = UDim2.new(1, -12, 0, 28)
	b.Position = UDim2.new(0, 6, 1, -34)
	b.TextSize = 12
	return tile, b, image
end
function UI.hero(parent, title, description, action, callback, color)
	local f = UI.frame(parent, UDim2.new(1, -8, 0, 192), nil, UI.Colors.Card)
	local image = Instance.new("Frame")
	image.Name = "Artwork"
	image.Size = UDim2.new(0.4, -12, 1, -20)
	image.Position = UDim2.fromOffset(6, 10)
	image.BackgroundTransparency = 1
	image.Parent = f
	UI.text(f, title, UDim2.new(0.6, -12, 0, 45), UDim2.new(0.4, 0, 0, 12), 19, color)
	UI.text(f, description, UDim2.new(0.6, -16, 0, 61), UDim2.new(0.4, 0, 0, 61), 13, UI.Colors.Muted)
	local b = UI.button(f, action, callback, color)
	b.Size = UDim2.new(0.6, -16, 0, 40)
	b.Position = UDim2.new(0.4, 0, 1, -54)
	return f, b, image
end
function UI.shortTile(parent, title, subtitle, action, callback, color)
	local f = UI.frame(parent, UDim2.fromOffset(150, 112), nil, UI.Colors.Card)
	UI.text(f, title, UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 8), 15, color)
	UI.text(f, subtitle, UDim2.new(1, -16, 0, 30), UDim2.fromOffset(8, 34), 11, UI.Colors.Muted)
	local b = UI.button(f, action, callback, color)
	b.Size = UDim2.new(1, -16, 0, 28)
	b.Position = UDim2.new(0, 8, 1, -36)
	b.TextSize = 12
	return f, b
end
function UI.rankRow(parent, position, name, value, userId, format)
	local f = UI.frame(parent, UDim2.new(1, -8, 0, 58), nil, UI.Colors.Card)
	UI.text(
		f,
		tostring(position),
		UDim2.fromOffset(28, 40),
		UDim2.fromOffset(8, 9),
		18,
		position <= 3 and UI.Colors.Accent or UI.Colors.Muted
	)
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromOffset(40, 40)
	image.Position = UDim2.fromOffset(40, 9)
	image.BackgroundColor3 = UI.Colors.Background
	image.BorderSizePixel = 0
	image.Image = userId and userId > 0 and "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150" or ""
	image.Parent = f
	UI.round(image, 20)
	local n = UI.text(f, name, UDim2.new(0.6, -90, 0, 40), UDim2.fromOffset(88, 9), 14)
	n.TextWrapped = false
	n.TextTruncate = Enum.TextTruncate.AtEnd
	local number = UI.text(f, format(value), UDim2.new(0.4, -16, 0, 40), UDim2.new(0.6, 0, 0, 9), 14, UI.Colors.Accent)
	number.TextXAlignment = Enum.TextXAlignment.Right
	return f
end
return UI
