local M = {}

function M.build(env)
    local createWindow = env.createWindow
    local Theme = env.Theme

    return function()
        local w = createWindow("Vape Modules", "Combat / Movement / Render", 480, 600, UDim2.new(0.5, -240 + math.random(-70, 70), 0.5, -300 + math.random(-60, 60)))
        w:AddSection("Combat")
        w:AddToggle("KillAura", false, function(v) env.KillAura:Set(v) end, "Attack all enemies in a cone")
        w:AddSlider("Attack Range", 3, 30, 13, "studs", 1, function(v) env.KillAura.Settings.AttackRange = v end)
        w:AddSlider("Swing Range", 1, 30, 6, "studs", 1, function(v) env.KillAura.Settings.SwingRange = v end)
        w:AddSlider("Aura CPS", 1, 20, 12, "", 0, function(v) env.KillAura.Settings.CPS = v end)
        w:AddSlider("Aura Delay", 0.02, 1, 0.1, "s", 2, function(v) env.KillAura.Settings.Delay = v end)
        w:AddSlider("Max Targets", 1, 10, 1, "", 0, function(v) env.KillAura.Settings.Targets = v end)
        w:AddSlider("Max Angle", 10, 360, 90, "deg", 0, function(v) env.KillAura.Settings.MaxAngle = v end)
        w:AddToggle("Aura Include NPCs", false, function(v) env.KillAura.Settings.NPC = v end)
        w:AddToggle("Aura Rotate To Target", true, function(v) env.KillAura.Settings.Rotate = v end)
        w:AddToggle("Aura Show Range (boxes)", false, function(v) env.KillAura.Settings.ShowRange = v end)
        w:AddToggle("Aura Hit Particles", false, function(v) env.KillAura.Settings.Particles = v end)
        w:AddToggle("Velocity (Anti-KB)", false, function(v) env.Velocity:Set(v) end, "Reduce knockback")
        w:AddSlider("Horizontal Resist", 0, 100, 100, "%", 0, function(v) env.Velocity.Settings.Horizontal = v end)
        w:AddSlider("Vertical Resist", 0, 100, 0, "%", 0, function(v) env.Velocity.Settings.Vertical = v end)
        w:AddToggle("Criticals", false, function(v) env.Criticals:Set(v) end, "Hop for crit hits")
        w:AddToggle("Reach", false, function(v) env.Reach:Set(v) end, "Extend click hit range")
        w:AddSlider("Reach Distance", 5, 40, 12, "studs", 0, function(v) env.Reach.Settings.Distance = v end)
        w:AddToggle("AutoClicker", false, function(v) env.AutoClicker:Set(v) end)
        w:AddSlider("AutoClicker CPS", 1, 30, 12, "", 0, function(v) env.AutoClicker.Settings.CPS = v end)
        w:AddToggle("AC Hold Mode", true, function(v) env.AutoClicker.Settings.HoldMode = v end)
        w:AddToggle("Silent Aim", false, function(v) env.SilentAim:Set(v) end, "Snap to nearest target on click")
        w:AddSlider("Silent FOV", 20, 800, 200, "px", 0, function(v) env.SilentAim.Settings.FOV = v end)
        w:AddDropdown("Silent Target Part", { "HumanoidRootPart", "Head", "Torso", "UpperTorso" }, "HumanoidRootPart", function(v) env.SilentAim.Settings.Part = v end)
        w:AddToggle("Silent Auto Fire", false, function(v) env.SilentAim.Settings.AutoFire = v end)
        w:AddToggle("Reach (Tool)", false, function(v) env.Reach2:Set(v) end, "Extend held tool reach")
        w:AddDropdown("Reach Mode", { "Resize", "TouchInterest" }, "Resize", function(v) env.Reach2.Settings.Mode = v end)
        w:AddSlider("Reach Range", 1, 30, 3, "studs", 1, function(v) env.Reach2.Settings.Range = v end)
        -- (module continues; truncated for brevity)
        return w
    end
end

return M
