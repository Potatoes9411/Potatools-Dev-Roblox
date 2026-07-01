local M = {}

local TweenService = game:GetService("TweenService")

M.ThemeDefaults = {
    Rounded = UDim.new(0, 8),
    RoundedBig = UDim.new(0, 14),
}

function M.corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or M.ThemeDefaults.Rounded
    c.Parent = parent
    return c
end

function M.stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(55, 55, 70)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function M.gradient(parent, color1, color2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

function M.tween(instance, time, props)
    local t = TweenService:Create(instance, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

function M.padding(parent, top, bottom, left, right)
    parent.LayoutOrder = parent.LayoutOrder or 0
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.Parent = parent
    return padding
end

return M
