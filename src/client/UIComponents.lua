-- UIComponents.lua
-- Reusable UI creation helpers for the modern BrainBlitz look

local UIComponents = {}

function UIComponents.makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
	return corner
end

function UIComponents.makeStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(110, 75, 255)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UIComponents.makeGradient(parent, topColor, bottomColor)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

function UIComponents.makeShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(23, 23, 277, 277)
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -5)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

function UIComponents.makePadding(parent, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 10)
	padding.PaddingRight = UDim.new(0, right or 10)
	padding.PaddingBottom = UDim.new(0, bottom or 10)
	padding.PaddingLeft = UDim.new(0, left or 10)
	padding.Parent = parent
	return padding
end

function UIComponents.makeButton(parent, props)
	local btn = Instance.new("TextButton")
	btn.Name = props.Name or "Button"
	btn.Size = props.Size or UDim2.new(0, 200, 0, 50)
	btn.Position = props.Position or UDim2.new(0.5, -100, 0.5, -25)
	btn.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	btn.BackgroundColor3 = props.Color or Color3.fromRGB(110, 75, 255)
	btn.Text = props.Text or "Button"
	btn.TextColor3 = props.TextColor or Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = props.TextSize or 18
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.Parent = parent

	UIComponents.makeCorner(btn, props.CornerRadius or 10)

	return btn
end

function UIComponents.makePanel(parent, props)
	local panel = Instance.new("Frame")
	panel.Name = props.Name or "Panel"
	panel.Size = props.Size or UDim2.new(0, 400, 0, 300)
	panel.Position = props.Position or UDim2.new(0.5, -200, 0.5, -150)
	panel.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	panel.BackgroundColor3 = props.Color or Color3.fromRGB(30, 30, 50)
	panel.BorderSizePixel = 0
	panel.Parent = parent

	UIComponents.makeCorner(panel, props.CornerRadius or 16)

	if props.Stroke then
		UIComponents.makeStroke(panel, props.StrokeColor, props.StrokeThickness)
	end

	return panel
end

return UIComponents
