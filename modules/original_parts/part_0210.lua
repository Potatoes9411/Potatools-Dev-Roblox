b.Parent = verRow
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = b
        b.MouseButton1Click:Connect(function()
            Z3USState.version = vn
            for n2, b2 in pairs(vbtns) do
                local sel = (n2 == vn)
                tween(b2, 0.12, { BackgroundColor3 = sel and Theme.Accent or Color3.fromRGB(13,14,17) })
                b2.TextColor3 = sel and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,170,190)
            end
        end)
        vbtns[vn] = b
    end

    -- LOAD button (big, Z3US-style)
    local loadBtn = Instance.new("TextButton")
    loadBtn.Position = UDim2.new(0, 14, 1, -56)
    loadBtn.Size = UDim2.new(1, -28, 0, 44)
    loadBtn.BackgroundColor3 = Theme.Accent
    loadBtn.Text = "Load"
    loadBtn.Font = Theme.FontBold; loadBtn.TextSize = 18
    loadBtn.TextColor3 = Color3.fromRGB(255,255,255)
    loadBtn.BorderSizePixel = 0; loadBtn.ZIndex = 12; loadBtn.Parent = content
    local lbcc = Instance.new("UICorner"); lbcc.CornerRadius = UDim.new(0, 14); lbcc.Parent = loadBtn
    gradient(loadBtn, Theme.AccentBright, Theme.AccentDark, 0)
    local lus = Instance.new("UIScale"); lus.Scale = 1; lus.Parent = loadBtn
    loadBtn.MouseEnter:Connect(function() tween(lus, 0.1, {Scale=1.03}) end)
    loadBtn.MouseLeave:Connect(function() tween(lus, 0.1, {Scale=1}) end)
    loadBtn.MouseButton1Click:Connect(function()
        tween(lus, 0.08, {Scale=0.97}); task.wait(0.08); tween(lus, 0.1, {Scale=1})
        z3usLoad()
    end)

    -- footer credit
    local credit = Instance.new("TextLabel")
    credit.BackgroundTransparency = 1
    credit.Position = UDim2.new(0, 0, 1, -18)
    credit.Size = UDim2.new(1, 0, 0, 14)
    credit.Font = Theme.Font; credit.TextSize = 10; credit.TextColor3 = Color3.fromRGB(70,80,110)
    credit.Text = "Z3US-style loader  â€¢  Studio test suite"
    credit.ZIndex = 12; credit.Parent = content

    -- minimize / close
    local minimized = false
    local fullSize = root.Size
    ctrl("â€“", Theme.Yellow, -38, function()
        minimized = not minimized
        if minimized then
            fullSize = root.Size
            tween(root, 0.22, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 60) })
            content.Visible = false
        else
            tween(root, 0.22, { Size = fullSize })
            content.Visible = true
        end
    end)
    ctrl("âœ•", Theme.Red, -74, function()
        tween(root, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.2)
        self:Destroy()
    end)

    makeDraggable(root, header)
    root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bringToFront(root)
        end
    end)

    -- entrance animation
    local us = Instance.new("UIScale"); us.Scale = 0.92; us.Parent = root
    root.BackgroundTransparency = 0.15
    root.Position = root.Position + UDim2.new(0, 0, 0, 20)
    tween(root, 0.35, { BackgroundTransparency = 0 })
    tween(us, 0.35, { Scale = 1 })
    tween(root, 0.35, { Position = root.Position - UDim2.new(0, 0, 0, 20) })
    bringToFront(root)

    self.Root = root
    function self:Destroy()
        self._dead = true
        tween(root, 0.18, { BackgroundTransparency = 1 })
        local usd = root:FindFirstChildOfClass("UIScale")
        if usd then tween(usd, 0.18, { Scale = 0.9 }) end
        task.wait(0.18)
        root:Destroy()
        Z3USHubState.open = nil
    end

    notify("Z3US Loader", "Select a game and press Load.", 4, Theme.Accent)
    return self
end

--==============================================================================
--// GAME REGISTRY  (order shown in the hub list)
--==============================================================================
GameList = {
    { name = "Universal",            cat = "GLOBAL",   icon = "ðŸŒ", desc = "Works in every game",   color = Theme.Accent,        builder = Universal },
    { name = "Auto-Detect Game",     cat = "GLOBAL",   icon = "ðŸ”", desc = "Detect game by PlaceId & load", color = Theme.AccentBright, builder = function() local e = autoLoadDetected(); if not e then return Universal() end return OpenWindows[e.name] or Universal() end },
    { name = "Script Manager",       cat = "GLOBAL",   icon = "ðŸ“¥", desc = "Load external scripts (DaraHub-style)", color = Theme.AccentBright, builder = ScriptManager },
    { name = "Teleport Pro",         cat = "GLOBAL",   icon = "ðŸ“", desc = "Saved spots, paths, part TP", color = Theme.AccentBright, builder = TeleportProWindow },
    { name = "Place Teleporter",     cat = "GLOBAL",   icon = "ðŸš€", desc = "TP to any game by PlaceId (animated grid)", color = Theme.AccentBright, builder = buildPlaceHub },
    { name = "Server Browser",       cat = "GLOBAL",   icon = "ðŸ›°ï¸", desc = "Browse & join servers", color = Theme.AccentBright, builder = ServerBrowser },
    { name = "Z3US Loader",          cat = "GLOBAL",   icon = "âš¡", desc = "Z3US game loader (key/autoload)", color = Theme.AccentBright, builder = buildZ3USLoader },
    { name = "Camera Suite",         cat = "GLOBAL",   icon = "ðŸ“·", desc = "FOV, lighting, freecam, visuals", color = Theme.AccentBright, builder = CameraSuite },
    { name = "Movement Suite",       cat = "GLOBAL",   icon = "ðŸƒ", desc = "All movement features",  color = Theme.AccentBright, builder = MovementSuite },
    { name = "Combat Suite",         cat = "GLOBAL",   icon = "âš”ï¸", desc = "All combat features",    color = Theme.AccentBright, builder = CombatSuite },
    { name = "Visual Suite",         cat = "GLOBAL",   icon = "ðŸ‘ï¸", desc = "All ESP & visuals",      color = Theme.AccentBright, builder = VisualSuite },
    { name = "World Suite",          cat = "GLOBAL",   icon = "ðŸŒ", desc = "World & utility tools",  color = Theme.AccentBright, builder = WorldSuite },
    { name = "Arsenal",              cat = "FPS",      icon = "ðŸ”«", desc = "Gunplay suite",          color = Color3.fromRGB(255,90,90),   builder = Arsenal },
    { name = "Rivals",               cat = "FPS",      icon = "ðŸŽ¯", desc = "Competitive FPS",        color = Color3.fromRGB(70,150,255),  builder = Rivals },
    { name = "Hypershot",            cat = "FPS",      icon = "âš¡", desc = "Ball shooter",           color = Color3.fromRGB(255,170,60),  builder = Hypershot },
    { name = "Counterblox",          cat = "FPS",      icon = "ðŸ§¨", desc = "CS-style FPS",           color = Color3.fromRGB(255,200,60),  builder = Counterblox },
    { name = "Gunfight Arena",       cat = "FPS",      icon = "ðŸ”«", desc = "Arena FPS",              color = Color3.fromRGB(255,110,90),  builder = GunfightArena },
    { name = "Planks",               cat = "FPS",      icon = "ðŸªµ", desc = "Planks FPS",             color = Color3.fromRGB(120,200,120), builder = Planks },
    { name = "Strucid",              cat = "FPS",      icon = "ðŸ›¡ï¸", desc = "Build FPS",              color = Color3.fromRGB(120,180,255), builder = Strucid },
    { name = "Apocalypse Rising",    cat = "SURVIVAL", icon = "ðŸ§Ÿ", desc = "Survival loot FPS",      color = Color3.fromRGB(120,140,90),  builder = ApocalypseRising },
    { name = "Vehicle Legends",      cat = "SIMULATOR",icon = "ðŸŽï¸", desc = "Drive & collect",        color = Color3.fromRGB(255,90,90),   builder = VehicleLegends },
    { name = "Roblox High School 2", cat = "RP",       icon = "ðŸŽ“", desc = "Campus utilities",       color = Color3.fromRGB(255,120,180), builder = RobloxHigh2 },
    { name = "Auto Strategy",        cat = "STRATEGY", icon = "â™Ÿï¸", desc = "Auto place units",       color = Theme.Accent,                builder = AutoStrategy },
    { name = "Zombie Survival",      cat = "ACTION",   icon = "ðŸ§Ÿ", desc = "Wave fighter",           color = Color3.fromRGB(120,200,80),  builder = ZombieSurvival },
    { name = "Knife Simulator",      cat = "SIMULATOR",icon = "ðŸ”ª", desc = "Auto throw",             color = Theme.Yellow,                builder = KnifeSim },
    { name = "Tap Simulator",        cat = "CLICKER",  icon = "ðŸ‘†", desc = "Auto tap",               color = Theme.Yellow,                builder = TapSim },
    { name = "Sus Game",             cat = "ACTION",   icon = "ðŸ‘¨â€ðŸš€", desc = "Among-style roles",      color = Theme.Red,                   builder = SusGame },
    { name = "Lift Game",            cat = "SIMULATOR",icon = "ðŸ‹ï¸", desc = "Auto lift",              color = Theme.Yellow,                builder = LiftGame },
    { name = "Grow a Tree",          cat = "SIMULATOR",icon = "ðŸŒ³", desc = "Auto grow & harvest",    color = Color3.fromRGB(120,200,120), builder = GrowTree },
    { name = "Gravity Shift",        cat = "ACTION",   icon = "ðŸŒ€", desc = "Gravity control",        color = Color3.fromRGB(150,150,200), builder = GravityShift },
    { name = "Raft Survival",        cat = "SURVIVAL", icon = "â›µ", desc = "Ocean survival",         color = Color3.fromRGB(86,156,240),  builder = RaftSurvival },
    { name = "Pet Gacha",            cat = "RNG",      icon = "ðŸŽ°", desc = "Auto roll pets",          color = Color3.fromRGB(255,150,180), builder = GachaGame },
    { name = "Trading Cards",        cat = "COLLECT",  icon = "ðŸƒ", desc = "Open & trade cards",     color = Color3.fromRGB(180,180,200), builder = TradingCards },
    { name = "Arcade / Minigames",   cat = "PARTY",    icon = "ðŸ•¹ï¸", desc = "Auto-play minigames",    color = Theme.Accent,                builder = ArcadeHub },
    { name = "Battle Royale",        cat = "FPS",      icon = "ðŸŽ–ï¸", desc = "Loot & survive",         color = Color3.fromRGB(180,140,80),  builder = BattleRoyale },
    { name = "Build / Creative",     cat = "SANDBOX",  icon = "ðŸ§±", desc = "Build helper",           color = Color3.fromRGB(120,200,120), builder = BuildGame },
    { name = "Space Survival",       cat = "SURVIVAL", icon = "ðŸš€", desc = "Sci-fi farm",            color = Color3.fromRGB(120,180,255), builder = SpaceSurvival },
    { name = "Hide & Seek Extreme",  cat = "ACTION",   icon = "ðŸ™ˆ", desc = "Hide & survive",         color = Theme.Accent,                builder = HideSeekExtreme },
    { name = "Factory Tycoon",       cat = "TYCOON",   icon = "ðŸ­", desc = "Auto production",        color = Color3.fromRGB(120,180,200), builder = FactoryTycoon },
    { name = "Block Sandbox",        cat = "SANDBOX",  icon = "â¬›", desc = "Mine & build",           color = Color3.fromRGB(120,200,120), builder = BlockSandbox },
    { name = "Racing / Kart",        cat = "RACING",   icon = "ðŸ", desc = "Drive & boost",          color = Color3.fromRGB(255,120,80),  builder = KartGame },
    { name = "Social / Hangout",     cat = "SOCIAL",   icon = "ðŸ’¬", desc = "Auto chat & emote",      color = Theme.Accent,                builder = SocialGame },
    { name = "Endless Obby",         cat = "OBBY",     icon = "ðŸªœ", desc = "Auto-climb towers",      color = Color3.fromRGB(122,200,120), builder = EndlessObby },
    { name = "Wave Defense",         cat = "STRATEGY", icon = "ðŸŒŠ", desc = "Defend waves",           color = Color3.fromRGB(120,200,80),  builder = WaveDefense },
    { name = "Shooter Arena",        cat = "FPS",      icon = "ðŸŽ¯", desc = "Arena shooter",          color = Color3.fromRGB(255,120,80),  builder = ShooterArena },
    { name = "Minigames Collection", cat = "PARTY",    icon = "ðŸŽ²", desc = "Party minigames",        color = Theme.Accent,                builder = MinigamesCollection },
    { name = "Idle Factory",         cat = "CLICKER",  icon = "ðŸ—ï¸", desc = "Idle clicker",           color = Theme.Yellow,                builder = IdleFactory },
    { name = "Sword Combat",         cat = "ACTION",   icon = "ðŸ—¡ï¸", desc = "Melee combat",           color = Color3.fromRGB(220,60,60),   builder = SwordCombat },
    { name = "Collect Everything",   cat = "UTILITY",  icon = "ðŸ§²", desc = "Magnet all items",       color = Color3.fromRGB(120,220,120), builder = CollectEverything },
    { name = "Jailbreak",            cat = "OPEN WORLD", icon = "ðŸš“", desc = "Cops & robbers",       color = Color3.fromRGB(120,200,120), builder = Jailbreak },
    { name = "Combat Arena",         cat = "FIGHTING", icon = "âš”ï¸", desc = "Melee / reach",         color = Color3.fromRGB(255,90,90),   builder = CombatArena },
    { name = "Steal a Brainrot",     cat = "COLLECT",  icon = "ðŸ§ ", desc = "Steal & collect",        color = Color3.fromRGB(180,120,255), builder = StealABrainrot },
    { name = "Murder Mystery 2",     cat = "MYSTERY",  icon = "ðŸ”ª", desc = "Roles & survival",       color = Color3.fromRGB(235,77,92),   builder = MurderMystery2 },
    { name = "Blade Ball",           cat = "ACTION",   icon = "âš¾", desc = "Auto parry",             color = Color3.fromRGB(245,196,76),  builder = BladeBall },
    { name = "Tower of Hell",        cat = "OBBY",     icon = "ðŸ—¼", desc = "Climb the tower",        color = Color3.fromRGB(122,200,120), builder = TowerOfHell },
    { name = "Da Hood",              cat = "ACTION",   icon = "ðŸŒ†", desc = "Lock-on & silent aim",   color = Color3.fromRGB(255,120,80),  builder = DaHood },
    { name = "Natural Disasters",    cat = "SURVIVAL", icon = "ðŸŒªï¸", desc = "Survive disasters",      color = Color3.fromRGB(86,156,240),  builder = NaturalDisasters },
    { name = "One Tap",              cat = "FPS",      icon = "ðŸ’¥", desc = "One-shot FPS",           color = Color3.fromRGB(180,80,255),  builder = OneTap },
    { name = "Bee Swarm Simulator",  cat = "SIMULATOR",icon = "ðŸ", desc = "Auto farm fields",       color = Color3.fromRGB(245,196,76),  builder = BeeSwarmSimulator },
    { name = "Flee the Facility",    cat = "SURVIVAL", icon = "ðŸƒ", desc = "Escape the beast",       color = Color3.fromRGB(86,156,240),  builder = FleeTheFacility },
    { name = "Grow a Garden",        cat = "SIMULATOR",icon = "ðŸŒ±", desc = "Auto farm garden",       color = Color3.fromRGB(76,209,142),  builder = GrowAGarden },
    { name = "Grow a Garden PRO",    cat = "SIMULATOR",icon = "ðŸ«", desc = "Full GAG suite",         color = Color3.fromRGB(76,209,142),  builder = GrowAGardenPro },
    { name = "Grow a Garden 2",      cat = "SIMULATOR",icon = "ðŸ¥•", desc = "GAG2 auto farm",         color = Color3.fromRGB(120,200,120), builder = GrowAGarden2 },
    { name = "Steal a Brainrot PRO", cat = "ACTION",   icon = "ðŸ§ ", desc = "Full SAB suite",         color = Color3.fromRGB(180,120,255), builder = StealABrainrotPro },
    { name = "Split or Steal Brainrot",cat = "ACTION", icon = "ðŸ˜ˆ", desc = "PvB steal/split",        color = Color3.fromRGB(180,80,120),  builder = SplitOrStealBrainrot },
    { name = "Swing Obby Brainrots", cat = "OBBY",     icon = "ðŸ¤¸", desc = "Swing obby brainrots",   color = Color3.fromRGB(180,120,255), builder = SwingObbyBrainrots },
    { name = "Parkour for Brainrots",cat = "OBBY",     icon = "ðŸƒ", desc = "Parkour brainrots",      color = Color3.fromRGB(180,120,255), builder = ParkourForBrainrots },
    { name = "Pet Catchers",         cat = "SIMULATOR",icon = "ðŸ¾", desc = "Auto catch pets",        color = Color3.fromRGB(180,120,255), builder = PetCatchers },
    { name = "Pets Go",              cat = "RNG",      icon = "ðŸŽ²", desc = "Roll & collect",         color = Color3.fromRGB(180,120,255), builder = PetsGo },
    { name = "Tap Simulator PRO",    cat = "CLICKER",  icon = "ðŸ‘†", desc = "Auto tap suite",         color = Theme.Accent,                builder = TapSimulatorPro },
    { name = "Card RNG",             cat = "RNG",      icon = "ðŸƒ", desc = "Roll & battle",          color = Color3.fromRGB(180,180,200), builder = CardRNG },
    { name = "Brainrot Giant",       cat = "ACTION",   icon = "ðŸ¦£", desc = "Grow & fight",           color = Color3.fromRGB(180,120,255), builder = BrainrotGiant },
    { name = "Brainrot Loaders",     cat = "GLOBAL",   icon = "ðŸ“¥", desc = "External SAB/GAG scripts", color = Theme.AccentBright,       builder = BrainrotExternalLoader },
    { name = "Brainrot Master",      cat = "GLOBAL",   icon = "ðŸ§ ", desc = "Universal brainrot farm", color = Theme.AccentBright,       builder = BrainrotMaster },
    { name = "Brainrot Simulator",   cat = "SIMULATOR",icon = "ðŸŒ€", desc = "Auto-spawn brainrots",   color = Color3.fromRGB(180,120,255), builder = BrainrotSimulator },
    { name = "Merge Brainrot",       cat = "SIMULATOR",icon = "ðŸ”—", desc = "Auto merge units",       color = Color3.fromRGB(180,120,255), builder = MergeBrainrot },
    { name = "Find the Brainrots",   cat = "FIND",     icon = "ðŸ§ ", desc = "Find brainrots",         color = Color3.fromRGB(180,120,255), builder = FindTheBrainrots },
    { name = "Brainrot Tycoon",      cat = "TYCOON",   icon = "ðŸ­", desc = "Brainrot tycoon",        color = Color3.fromRGB(180,120,255), builder = BrainrotTycoon },
    { name = "Brainrot Defend",      cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Defense game",           color = Color3.fromRGB(180,120,255), builder = BrainrotDefend },
    { name = "Brainrot Clicker",     cat = "CLICKER",  icon = "ðŸ‘†", desc = "Auto click brainrots",   color = Theme.Accent,                builder = BrainrotClicker },
    { name = "Brainrot Battlegrounds",cat="ACTION",    icon = "âš”ï¸", desc = "Combat & steal",         color = Color3.fromRGB(180,120,255), builder = BrainrotBattlegrounds },
    { name = "Brainrot Pet Sim",     cat = "SIMULATOR",icon = "ðŸ¾", desc = "Hatch & collect",        color = Color3.fromRGB(180,120,255), builder = BrainrotPetSim },
    { name = "Brainrot Racing",      cat = "RACING",   icon = "ðŸŽï¸", desc = "Race & collect",         color = Color3.fromRGB(180,120,255), builder = BrainrotRacing },
    { name = "Grow a Tree PRO",      cat = "SIMULATOR",icon = "ðŸŒ³", desc = "Full tree suite",        color = Color3.fromRGB(120,200,120), builder = GrowATreePro },
    { name = "SAB MASTER",           cat = "ACTION",   icon = "ðŸ’€", desc = "Ultimate SAB suite",     color = Color3.fromRGB(180,120,255), builder = StealABrainrotMaster },
    { name = "Universal Pet RNG",    cat = "RNG",      icon = "ðŸŽ²", desc = "Roll & farm pets",       color = Color3.fromRGB(180,120,255), builder = UniversalPetRNG },
    { name = "Universal Collector",  cat = "GLOBAL",   icon = "ðŸ§²", desc = "Collect anything",       color = Theme.AccentBright,          builder = UniversalCollector },
    { name = "Universal Buyer",      cat = "GLOBAL",   icon = "ðŸ›’", desc = "Auto-buy remotes",       color = Theme.AccentBright,          builder = UniversalBuyer },
    { name = "Universal Seller",     cat = "GLOBAL",   icon = "ðŸ’°", desc = "Auto-sell remotes",      color = Theme.AccentBright,          builder = UniversalSeller },
    { name = "Universal Hatcher",    cat = "GLOBAL",   icon = "ðŸ¥š", desc = "Auto-hatch eggs",        color = Theme.AccentBright,          builder = UniversalHatcher },
    { name = "Universal Rebirther",  cat = "GLOBAL",   icon = "â™¾ï¸", desc = "Auto-rebirth",           color = Theme.AccentBright,          builder = UniversalRebirther },
    { name = "Auto Clicker PRO",     cat = "GLOBAL",   icon = "ðŸ–±ï¸", desc = "Advanced auto-click",    color = Theme.AccentBright,          builder = AutoClickerPro },
    { name = "Universal NPC Farmer", cat = "GLOBAL",   icon = "ðŸ¤–", desc = "Auto-farm NPCs",         color = Theme.AccentBright,          builder = UniversalNPCFarmer },
    { name = "Universal Auto-Play",  cat = "GLOBAL",   icon = "â–¶ï¸", desc = "Quests & progress",      color = Theme.AccentBright,          builder = UniversalAutoPlay },
    { name = "Brainrot Arena",       cat = "ACTION",   icon = "ðŸŸï¸", desc = "Arena combat & steal",   color = Color3.fromRGB(180,120,255), builder = BrainrotArena },
    { name = "Brainrot Wallet",      cat = "SIMULATOR",icon = "ðŸ’°", desc = "Money farm",             color = Color3.fromRGB(255,200,40),  builder = BrainrotWallet },
    { name = "Brainrot Survival",    cat = "SURVIVAL", icon = "ðŸ§Ÿ", desc = "Wave survival",          color = Color3.fromRGB(180,120,255), builder = BrainrotSurvival },
    { name = "Brainrot Factory",     cat = "TYCOON",   icon = "ðŸ­", desc = "Production suite",       color = Color3.fromRGB(180,120,255), builder = BrainrotFactory },
    { name = "Brainrot Obby",        cat = "OBBY",     icon = "ðŸ§©", desc = "Obby + collect",         color = Color3.fromRGB(180,120,255), builder = BrainrotObby },
    { name = "Pet Sim 99 PRO",       cat = "SIMULATOR",icon = "ðŸŒŸ", desc = "Full PS99 suite",        color = Color3.fromRGB(120,200,255), builder = PetSim99Pro },
    { name = "Pet Sim X PRO",        cat = "SIMULATOR",icon = "âœ¨", desc = "Full PSX suite",         color = Color3.fromRGB(255,200,40),  builder = PetSimXPro },
    { name = "Bloxstrike",           cat = "FPS",      icon = "ðŸŽ®", desc = "Tactical FPS",           color = Color3.fromRGB(255,120,50),  builder = Bloxstrike },
    { name = "Break Your Bones",     cat = "PHYSICS",  icon = "ðŸ¦´", desc = "Bone farming",           color = Color3.fromRGB(220,220,220), builder = BreakYourBones },
    { name = "Slime RNG",            cat = "RNG",      icon = "ðŸŸ¢", desc = "Auto roll",              color = Color3.fromRGB(120,220,120), builder = SlimeRNG },
    { name = "Redliners",            cat = "FPS",      icon = "ðŸ”´", desc = "Fast-paced FPS",         color = Color3.fromRGB(255,60,90),   builder = Redliners },
    { name = "Settings",             cat = "GLOBAL",   icon = "âš™ï¸", desc = "Theme, FOV, gravity, anti-afk", color = Theme.Accent,         builder = Settings },
    { name = "Vape Modules",         cat = "GLOBAL",   icon = "ðŸ§©", desc = "KillAura, Velocity, Tracers, XRay", color = Theme.AccentBright, builder = VapeModules },
    { name = "Legit HUD",            cat = "GLOBAL",   icon = "ðŸ“Š", desc = "FPS, Ping, Keystrokes, Cape", color = Theme.AccentBright,   builder = LegitHUD },
    { name = "Doors",                cat = "HORROR",   icon = "ðŸšª", desc = "Entity ESP & skip",      color = Color3.fromRGB(255,90,60),   builder = Doors },
    { name = "Blox Fruits",          cat = "ADVENTURE",icon = "ðŸŽ", desc = "Auto farm NPCs",         color = Color3.fromRGB(255,160,60),  builder = BloxFruits },
    { name = "Pet Sim 99",           cat = "SIMULATOR",icon = "ðŸ¾", desc = "Coins & eggs",           color = Color3.fromRGB(120,200,255), builder = PetSim99 },
    { name = "Evade",                cat = "SURVIVAL", icon = "ðŸ‘¤", desc = "Nextbot avoid",          color = Color3.fromRGB(255,60,60),   builder = Evade },
    { name = "Brookhaven",           cat = "RP",       icon = "ðŸ ", desc = "RP utilities",           color = Color3.fromRGB(255,90,180),  builder = Brookhaven },
    { name = "Adopt Me",             cat = "RP",       icon = "ðŸ¦´", desc = "Auto pet care",          color = Color3.fromRGB(255,120,180), builder = AdoptMe },
    { name = "Tower Defense Sim",    cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto upgrade / waves",   color = Color3.fromRGB(120,180,255), builder = TowerDefenseSim },
    { name = "Dead Rails",           cat = "SURVIVAL", icon = "ðŸš‚", desc = "Loot & travel",          color = Color3.fromRGB(180,140,80),  builder = DeadRails },
    { name = "99 Nights",            cat = "ACTION",   icon = "ðŸŒ™", desc = "Night survival farm",    color = Color3.fromRGB(80,50,120),   builder = NinetyNineNights },
    { name = "Escape",               cat = "SURVIVAL", icon = "ðŸšª", desc = "Escape the killer",      color = Color3.fromRGB(86,156,240),  builder = EscapeGame },
    { name = "Bronx",                cat = "FPS",      icon = "ðŸŒ‡", desc = "Gang street FPS",        color = Color3.fromRGB(200,120,80),  builder = Bronx },
    { name = "Steep Steps",          cat = "OBBY",     icon = "â›°ï¸", desc = "Climb helper",           color = Color3.fromRGB(120,200,120), builder = SteepSteps },
    { name = "Build A Boat",         cat = "SANDBOX",  icon = "â›µ", desc = "Sail & collect",         color = Color3.fromRGB(120,180,255), builder = BuildABoat },
    { name = "Pilot Training",       cat = "FLIGHT",   icon = "âœˆï¸", desc = "Teleport airports",      color = Color3.fromRGB(86,156,240),  builder = PilotTraining },
    { name = "Anime Adventures",     cat = "ADVENTURE",icon = "ðŸŒ€", desc = "Auto farm enemies",      color = Color3.fromRGB(180,120,255), builder = AnimeAdventures },
    { name = "Ninja Legends",        cat = "SIMULATOR",icon = "ðŸ¥·", desc = "Auto swing & sell",      color = Color3.fromRGB(245,196,76),  builder = NinjaLegends },
    { name = "Mining Simulator",     cat = "SIMULATOR",icon = "â›ï¸", desc = "Auto mine & sell",       color = Color3.fromRGB(180,140,80),  builder = MiningSimulator },
    { name = "Slap Battles",         cat = "ACTION",   icon = "ðŸ‘‹", desc = "Auto slap / aura",       color = Color3.fromRGB(245,196,76),  builder = SlapBattles },
    { name = "Survive the Killer",   cat = "SURVIVAL", icon = "ðŸ©¸", desc = "Killer avoid / ESP",     color = Color3.fromRGB(255,60,60),   builder = SurviveTheKiller },
    { name = "Royale High",          cat = "RP",       icon = "ðŸ‘‘", desc = "Campus utilities",       color = Color3.fromRGB(255,120,180), builder = RoyaleHigh },
    { name = "Big Paintball",        cat = "FPS",      icon = "ðŸŽ¨", desc = "Paintball FPS",          color = Color3.fromRGB(120,200,255), builder = BigPaintball },
    { name = "Phantom Forces",       cat = "FPS",      icon = "ðŸŽ–ï¸", desc = "Tactical FPS",           color = Color3.fromRGB(110,110,130), builder = PhantomForces },
    { name = "Frontlines",           cat = "FPS",      icon = "ðŸª–", desc = "Large-scale FPS",        color = Color3.fromRGB(200,120,60),  builder = Frontlines },
    { name = "Players",              cat = "GLOBAL",   icon = "ðŸ‘¥", desc = "Player list & actions",  color = Theme.Accent,                builder = PlayersPanel },
    { name = "Friends & Targets",    cat = "GLOBAL",   icon = "ðŸ¤", desc = "Recolor ESP / priorities", color = Theme.AccentBright,        builder = FriendsTargets },
    { name = "Piggy",                cat = "HORROR",   icon = "ðŸ·", desc = "Escape & role ESP",      color = Color3.fromRGB(255,90,60),   builder = Piggy },
    { name = "Pizza Place",          cat = "JOB",      icon = "ðŸ•", desc = "Auto work & deliver",    color = Color3.fromRGB(255,160,60),  builder = PizzaPlace },
    { name = "Theme Park Tycoon 2",  cat = "TYCOON",   icon = "ðŸŽ¢", desc = "Builder utilities",      color = Color3.fromRGB(120,200,255), builder = ThemeParkTycoon2 },
    { name = "Weight Lifting Sim",   cat = "SIMULATOR",icon = "ðŸ‹ï¸", desc = "Auto lift & rebirth",    color = Color3.fromRGB(245,196,76),  builder = WeightLiftingSimulator },
    { name = "Magnet Simulator",     cat = "SIMULATOR",icon = "ðŸ§²", desc = "Auto collect & sell",    color = Color3.fromRGB(120,180,255), builder = MagnetSimulator },
    { name = "Super Bomb Survival",  cat = "SURVIVAL", icon = "ðŸ’£", desc = "Bomb avoid & ESP",       color = Color3.fromRGB(255,60,60),   builder = SuperBombSurvival },
    { name = "Lumber Tycoon 2",      cat = "TYCOON",   icon = "ðŸªµ", desc = "Auto chop & sell",       color = Color3.fromRGB(120,200,120), builder = LumberTycoon2 },
    { name = "Random Rumble",        cat = "ACTION",   icon = "ðŸ¥Š", desc = "Combat + aura",          color = Color3.fromRGB(180,120,255), builder = RandomRumble },
    { name = "Ragdoll Universe",     cat = "FUN",      icon = "ðŸ¤¸", desc = "Fling & reset",          color = Color3.fromRGB(180,120,255), builder = RagdollUniverse },
    { name = "Robloxian High",       cat = "RP",       icon = "ðŸ«", desc = "Campus utilities",       color = Color3.fromRGB(255,120,180), builder = RobloxianHighschool },
    { name = "Color Block",          cat = "SURVIVAL", icon = "ðŸŸ©", desc = "Safe block finder",      color = Color3.fromRGB(76,209,142),  builder = ColorBlock },
    { name = "Gym Simulator",        cat = "SIMULATOR",icon = "ðŸ’ª", desc = "Auto workout",           color = Color3.fromRGB(245,196,76),  builder = GymSimulator },
    { name = "Westbound",            cat = "FPS",      icon = "ðŸ¤ ", desc = "Western shooter",        color = Color3.fromRGB(200,150,80),  builder = Westbound },
    { name = "King Legacy",          cat = "ADVENTURE",icon = "ðŸ‘‘", desc = "Auto farm enemies",      color = Color3.fromRGB(255,160,60),  builder = KingLegacy },
    { name = "Clicker Simulator",    cat = "CLICKER",  icon = "ðŸ–±ï¸", desc = "Auto click & rebirth",   color = Color3.fromRGB(245,196,76),  builder = ClickerSimulator },
    { name = "Bubble Gum Sim",       cat = "SIMULATOR",icon = "ðŸ«§", desc = "Auto blow & sell",       color = Color3.fromRGB(255,120,200), builder = BubbleGumSimulator },
    { name = "Boxing Simulator",     cat = "SIMULATOR",icon = "ðŸ¥Š", desc = "Auto punch",             color = Color3.fromRGB(245,196,76),  builder = BoxingSimulator },
    { name = "Race Clicker",         cat = "CLICKER",  icon = "ðŸ", desc = "Auto click & race",      color = Color3.fromRGB(120,180,255), builder = RaceClicker },
    { name = "Epic Minigames",       cat = "PARTY",    icon = "ðŸŽ²", desc = "Survival hints",         color = Theme.Accent,                builder = EpicMinigames },
    { name = "Pet Simulator X",      cat = "SIMULATOR",icon = "ðŸ£", desc = "Coins & eggs",           color = Color3.fromRGB(255,200,40),  builder = PetSimX },
    { name = "Project Slayers",      cat = "ADVENTURE",icon = "âš”ï¸", desc = "Auto farm & spin",       color = Color3.fromRGB(180,120,255), builder = ProjectSlayers },
    { name = "Shindo Life",          cat = "ADVENTURE",icon = "ðŸŒ€", desc = "Spin & grind",           color = Color3.fromRGB(255,120,80),  builder = ShindoLife },
    { name = "YBA",                  cat = "ADVENTURE",icon = "ðŸ‘", desc = "Auto farm stands",       color = Color3.fromRGB(255,160,60),  builder = YBA },
    { name = "Anime Vanguards",      cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto farm units",        color = Color3.fromRGB(180,120,255), builder = AnimeVanguards },
    { name = "Juke's Towers",        cat = "OBBY",     icon = "ðŸ§—", desc = "Climb helper",           color = Color3.fromRGB(122,200,120), builder = JukesTowers },
    { name = "Pls Donate",           cat = "SOCIAL",   icon = "ðŸ’¬", desc = "Auto chat / AFK",        color = Color3.fromRGB(76,209,142),  builder = PlsDonate },
    { name = "Dragon Adventures",    cat = "ADVENTURE",icon = "ðŸ‰", desc = "Auto feed & incubate",   color = Color3.fromRGB(120,200,120), builder = DragonAdventures },
    { name = "Creatures of Sonaria", cat = "SURVIVAL", icon = "ðŸ¦Ž", desc = "Auto eat & grow",        color = Color3.fromRGB(120,200,120), builder = CreaturesOfSonaria },
    { name = "MeepCity",             cat = "RP",       icon = "ðŸ˜º", desc = "RP utilities",           color = Color3.fromRGB(255,120,180), builder = MeepCity },
    { name = "Ro-Ghoul",             cat = "ADVENTURE",icon = "ðŸ©¸", desc = "Auto farm & aura",       color = Color3.fromRGB(180,60,60),   builder = RoGhoul },
    { name = "Demonfall",            cat = "ADVENTURE",icon = "ðŸ‘¹", desc = "Auto farm NPCs",         color = Color3.fromRGB(180,80,120),  builder = Demonfall },
    { name = "DBZ Final Stand",      cat = "ADVENTURE",icon = "ðŸ”¥", desc = "Train & fight",          color = Color3.fromRGB(255,160,40),  builder = DBZFinalStand },
    { name = "Break In",             cat = "STORY",    icon = "ðŸšï¸", desc = "Story survival",         color = Color3.fromRGB(180,120,120), builder = BreakIn },
    { name = "ER: Liberty County",   cat = "RP",       icon = "ðŸš”", desc = "Roleplay utilities",     color = Color3.fromRGB(70,150,255),  builder = ERLC },
    { name = "SCP Roleplay",         cat = "FPS",      icon = "ðŸ”¬", desc = "SCP & keycard ESP",      color = Color3.fromRGB(180,60,60),   builder = SCPRoleplay },
    { name = "Camping",              cat = "STORY",    icon = "ðŸ•ï¸", desc = "Story survival",         color = Color3.fromRGB(120,180,100), builder = Camping },
    { name = "Fish Game",            cat = "SURVIVAL", icon = "ðŸ¦‘", desc = "Red light helper",       color = Color3.fromRGB(76,209,142),  builder = FishGame },
    { name = "Hide and Seek",        cat = "ACTION",   icon = "ðŸ™ˆ", desc = "Tag helper",             color = Theme.Accent,                builder = HideAndSeek },
    { name = "World Zero",           cat = "RPG",      icon = "ðŸŒŒ", desc = "RPG farm",               color = Color3.fromRGB(120,180,255), builder = WorldZero },
    { name = "Isle",                 cat = "STORY",    icon = "ðŸï¸", desc = "Mystery survival",       color = Color3.fromRGB(120,160,140), builder = Isle },
    { name = "Rumble Quest",         cat = "ACTION",   icon = "ðŸŒŸ", desc = "Combat & aura",          color = Color3.fromRGB(150,120,255), builder = RumbleQuest },
    { name = "RoCitizens",           cat = "RP",       icon = "ðŸ˜ï¸", desc = "RP utilities",           color = Color3.fromRGB(120,180,255), builder = RoCitizens },
    { name = "The Survival Game",    cat = "SURVIVAL", icon = "ðŸª“", desc = "Open survival",          color = Color3.fromRGB(120,180,100), builder = SurvivalGame },
    { name = "Bedwars",              cat = "ACTION",   icon = "ðŸ›ï¸", desc = "Combat + bed defense",   color = Color3.fromRGB(120,180,255), builder = Bedwars },
    { name = "Doomspire",            cat = "ACTION",   icon = "ðŸ—ï¸", desc = "Brickbattle combat",     color = Color3.fromRGB(255,160,60),  builder = Doomspire },
    { name = "Combat Warriors",      cat = "ACTION",   icon = "ðŸ—¡ï¸", desc = "Melee + aura",           color = Color3.fromRGB(220,60,60),   builder = CombatWarriors },
    { name = "Ability Wars",         cat = "ACTION",   icon = "âœ¨", desc = "Auto ability",           color = Color3.fromRGB(180,120,255), builder = AbilityWars },
    { name = "Mic Up",               cat = "SOCIAL",   icon = "ðŸŽ™ï¸", desc = "Social utilities",       color = Theme.Accent,                builder = MicUp },
    { name = "Island Royale",        cat = "FPS",      icon = "ðŸï¸", desc = "Battle royale FPS",      color = Color3.fromRGB(120,200,120), builder = IslandRoyale },
    { name = "Plates of Fate",       cat = "SURVIVAL", icon = "ðŸ½ï¸", desc = "Plate survival",         color = Color3.fromRGB(76,209,142),  builder = PlatesOfFate },
    { name = "Find the Markers",     cat = "HUNT",     icon = "ðŸ–ï¸", desc = "Marker hunt",            color = Color3.fromRGB(255,200,40),  builder = FindTheMarkers },
    { name = "Obby Helper",          cat = "OBBY",     icon = "ðŸš§", desc = "Any tower/obby",         color = Color3.fromRGB(122,200,120), builder = ObbyGeneric },
    { name = "Wacky Wizards",        cat = "SIMULATOR",icon = "ðŸ§ª", desc = "Potion brew",            color = Color3.fromRGB(180,120,255), builder = WackyWizards },
    { name = "Troll Suite",          cat = "FUN",      icon = "ðŸ¤¡", desc = "Cosmetics & fun",        color = Color3.fromRGB(255,120,80),  builder = TrollSuite },
    { name = "Simulator Helper",     cat = "CLICKER",  icon = "âš™ï¸", desc = "Any clicker/sim",        color = Color3.fromRGB(245,196,76),  builder = GenericSim },
    { name = "Zombie Attack",        cat = "ACTION",   icon = "ðŸ§Ÿ", desc = "Wave fighter",           color = Color3.fromRGB(120,200,80),  builder = ZombieAttack },
    { name = "Tornado Alley",        cat = "SURVIVAL", icon = "ðŸŒªï¸", desc = "Disaster survival",      color = Color3.fromRGB(150,150,160), builder = TornadoAlley },
    { name = "Boat Treasure",        cat = "SANDBOX",  icon = "ðŸï¸", desc = "Sail & collect",         color = Color3.fromRGB(120,180,255), builder = BoatTreasure },
    { name = "Speed Run",            cat = "OBBY",     icon = "ðŸ’¨", desc = "Dash & win",             color = Color3.fromRGB(120,200,255), builder = SpeedRun },
    { name = "Word Game",            cat = "PARTY",    icon = "âŒ¨ï¸", desc = "Auto typer",             color = Theme.Accent,                builder = WordGame },
    { name = "Snowball",             cat = "ACTION",   icon = "â„ï¸", desc = "Throw combat",           color = Color3.fromRGB(150,200,255), builder = SnowballGame },
    { name = "Paint Game",           cat = "FUN",      icon = "ðŸŽ¨", desc = "Auto paint",             color = Color3.fromRGB(255,120,200), builder = PaintGame },
    { name = "Survive Disaster",     cat = "SURVIVAL", icon = "ðŸŒ‹", desc = "Disaster survival",      color = Theme.Blue,                  builder = SurviveDisaster },
    { name = "Dig Game",             cat = "SIMULATOR",icon = "â›ï¸", desc = "Auto dig & sell",        color = Color3.fromRGB(180,140,80),  builder = DigGame },
    { name = "Anime RPG",            cat = "RPG",      icon = "âš”ï¸", desc = "Farm & roll",            color = Color3.fromRGB(180,120,255), builder = AnimeRPG },
    { name = "Fantasy RPG",          cat = "RPG",      icon = "ðŸ§™", desc = "Quest & farm",           color = Color3.fromRGB(150,120,255), builder = FantasyRPG },
    { name = "Vehicle Simulator",    cat = "SIMULATOR",icon = "ðŸš—", desc = "Drive & collect",        color = Color3.fromRGB(120,180,255), builder = VehicleSimulator },
    { name = "Tycoon Helper",        cat = "TYCOON",   icon = "ðŸ­", desc = "Any tycoon",             color = Color3.fromRGB(120,220,120), builder = TycoonGeneric },
    { name = "Fishing Game",         cat = "SIMULATOR",icon = "ðŸŽ£", desc = "Auto fish",              color = Color3.fromRGB(86,156,240),  builder = FishingGame },
    { name = "Portal / Science",     cat = "PUZZLE",   icon = "ðŸŒ€", desc = "Puzzle helper",          color = Color3.fromRGB(120,180,200), builder = PortalGame },
    { name = "Rocket / Launch",      cat = "SANDBOX",  icon = "ðŸš€", desc = "Build & launch",         color = Color3.fromRGB(220,220,220), builder = RocketGame },
    { name = "Paintball",            cat = "FPS",      icon = "ðŸŽ¨", desc = "Paintball FPS",          color = Color3.fromRGB(120,200,255), builder = PaintballGeneric },
    { name = "Difficult Parkour",    cat = "OBBY",     icon = "ðŸƒ", desc = "Hard obby",             color = Color3.fromRGB(122,200,120), builder = ParkourObby },
    { name = "Cooking Game",         cat = "JOB",      icon = "ðŸ³", desc = "Auto cook",             color = Color3.fromRGB(255,160,80),  builder = CookingGame },
    { name = "Delivery / Job",       cat = "JOB",      icon = "ðŸ“¦", desc = "Auto deliver",          color = Color3.fromRGB(120,180,255), builder = DeliveryGame },
    { name = "Survival Sandbox",     cat = "SURVIVAL", icon = "ðŸªµ", desc = "Craft & gather",        color = Color3.fromRGB(120,180,100), builder = CraftingSandbox },
    { name = "Racing Game",          cat = "RACING",   icon = "ðŸ", desc = "Drive & collect",       color = Color3.fromRGB(255,120,80),  builder = RacingGame },
    { name = "Horror Game",          cat = "HORROR",   icon = "ðŸ‘»", desc = "Survive monsters",       color = Color3.fromRGB(180,60,80),   builder = HorrorGame },
    { name = "Trading / Economy",    cat = "ECONOMY",  icon = "ðŸ’±", desc = "Auto trade",             color = Color3.fromRGB(120,220,120), builder = TradingGame },
    { name = "Sport / Skate",        cat = "SPORT",    icon = "ðŸ›¹", desc = "Tricks & speed",         color = Color3.fromRGB(120,200,255), builder = SportGame },
    { name = "Help & About",         cat = "GLOBAL",   icon = "â“", desc = "Usage guide & keybinds", color = Theme.Accent,                builder = HelpAbout },
    { name = "Sols RNG",             cat = "RNG",      icon = "ðŸŽ²", desc = "Auto roll auras",        color = Color3.fromRGB(180,140,255), builder = SolsRNG },
    { name = "Type Soul",            cat = "RPG",      icon = "ðŸ—¡ï¸", desc = "Farm & raid",            color = Color3.fromRGB(180,120,255), builder = TypeSoul },
    { name = "Anime Defenders",      cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto place units",       color = Color3.fromRGB(150,120,255), builder = AnimeDefenders },
    { name = "Dungeon Quest",        cat = "RPG",      icon = "ðŸ°", desc = "Dungeon farm",           color = Color3.fromRGB(150,100,200), builder = DungeonQuest },
    { name = "Treasure Quest",       cat = "RPG",      icon = "ðŸ’Ž", desc = "Dungeon & chests",       color = Color3.fromRGB(255,180,60),  builder = TreasureQuest },
    { name = "A Universal Time",     cat = "RPG",      icon = "ðŸŒŸ", desc = "Stand farm",             color = Color3.fromRGB(180,140,255), builder = UniversalTime },
    { name = "Grand Piece Online",   cat = "RPG",      icon = "âš“", desc = "Pirate farm",            color = Color3.fromRGB(120,180,255), builder = GPO },
    { name = "Haze Piece",           cat = "RPG",      icon = "ðŸŒ´", desc = "Fruit farm",             color = Color3.fromRGB(120,180,255), builder = HazePiece },
    { name = "A One Piece Game",     cat = "RPG",      icon = "ðŸ´â€â˜ ï¸", desc = "Pirate farm",            color = Color3.fromRGB(255,160,60),  builder = AOnePieceGame },
    { name = "Deepwoken",            cat = "RPG",      icon = "ðŸŒŠ", desc = "Survival RPG",           color = Color3.fromRGB(100,130,180), builder = Deepwoken },
    { name = "Pressure",             cat = "HORROR",   icon = "ðŸ”‹", desc = "Horror survival",        color = Color3.fromRGB(120,160,200), builder = Pressure },
    { name = "The Wild West",        cat = "FPS",      icon = "ðŸ¤ ", desc = "Cowboy shooter",         color = Color3.fromRGB(200,150,80),  builder = TheWildWest },
    { name = "Loomian Legacy",       cat = "RPG",      icon = "ðŸ¦Ž", desc = "Auto battle",            color = Color3.fromRGB(120,180,255), builder = LoomianLegacy },
    { name = "Blood & Iron",         cat = "FPS",      icon = "âš”ï¸", desc = "Historic shooter",       color = Color3.fromRGB(160,60,60),   builder = BloodAndIron },
    { name = "Welcome to Bloxburg",  cat = "RP",       icon = "ðŸ¡", desc = "Build & jobs",           color = Color3.fromRGB(120,200,120), builder = Bloxburg },
    { name = "Total Roblox Drama",   cat = "SURVIVAL", icon = "ðŸŽ¬", desc = "Survival hints",         color = Theme.Accent,                builder = TotalRobloxDrama },
    { name = "Ragdoll Engine",       cat = "FUN",      icon = "ðŸŽª", desc = "Fling & reset",          color = Color3.fromRGB(180,120,255), builder = RagdollEngine },
    { name = "Weapon Forge",         cat = "SIMULATOR",icon = "ðŸ”¨", desc = "Craft weapons",          color = Color3.fromRGB(180,180,200), builder = WeaponForge },
    { name = "Nico's Nextbots",      cat = "SURVIVAL", icon = "ðŸ˜±", desc = "Nextbot avoid",          color = Color3.fromRGB(255,80,80),   builder = NicosNextbots },
    { name = "Fantastic Frontier",   cat = "RPG",      icon = "ðŸ—ºï¸", desc = "RPG farm",               color = Color3.fromRGB(150,200,150), builder = FantasticFrontier },
    { name = "Vesteria",             cat = "RPG",      icon = "ðŸŒ²", desc = "MMORPG farm",            color = Color3.fromRGB(120,160,200), builder = Vesteria },
    { name = "Anime Fighting Sim",   cat = "RPG",      icon = "ðŸ‘Š", desc = "Train & farm",           color = Color3.fromRGB(180,120,255), builder = AnimeFightingSim },
    { name = "Decaying Winter",      cat = "RPG",      icon = "â„ï¸", desc = "Survival RPG",           color = Color3.fromRGB(160,140,120), builder = DecayingWinter },
    { name = "Sonic Speed Sim",      cat = "SIMULATOR",icon = "ðŸ’™", desc = "Speed & rings",          color = Color3.fromRGB(120,180,255), builder = SonicSpeedSim },
    { name = "Muscle Legends",       cat = "SIMULATOR",icon = "ðŸ’ª", desc = "Auto lift",              color = Color3.fromRGB(245,196,76),  builder = MuscleLegends },
    { name = "Murder Game X",        cat = "MYSTERY",  icon = "ðŸ”ª", desc = "Role ESP & survive",     color = Theme.Red,                   builder = MurderGameX },
    { name = "Dungeon / Raid",       cat = "RPG",      icon = "âš”ï¸", desc = "Raid farm",              color = Color3.fromRGB(150,120,200), builder = RaidGame },
    { name = "Idle / Incremental",   cat = "CLICKER",  icon = "ðŸ“ˆ", desc = "Any idle game",          color = Theme.Yellow,                builder = IdleGame },
    { name = "Pet Collection",       cat = "SIMULATOR",icon = "ðŸ¶", desc = "Hatch & equip",          color = Color3.fromRGB(255,150,180), builder = PetGame },
    { name = "Survival Island",      cat = "SURVIVAL", icon = "ðŸï¸", desc = "Gather & craft",         color = Color3.fromRGB(120,180,100), builder = SurvivalIsland },
    { name = "Defense Game",         cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto place towers",      color = Color3.fromRGB(120,180,255), builder = DefenseGame },
}

--==============================================================================
--// REGISTER ALL "FIND THE" GAMES  (75+ hunt games via the generic builder)
--==============================================================================
for _, ft in ipairs(FindTheGames) do
    -- skip the first (Markers) since it already has a dedicated registry entry
    if ft.name ~= "Find the Markers" then
        local cfg = ft
        table.insert(GameList, {
            name = ft.name,
            cat = "FIND THE",
            icon = ft.icon,
            desc = "Hunt & auto-collect " .. ft.singular:lower() .. "s",
            color = ft.color,
            builder = function() return buildFindTheGame(cfg) end,
        })
    end
end

--==============================================================================
--// MAIN HUB UI
--==============================================================================
local Hub = {}
do
    local frame = Instance.new("Frame")
    frame.Name = "MainHub"
    frame.Size = UDim2.new(0, 560, 0, 420)
    frame.Position = UDim2.new(0.5, -280, 0.5, -210)
    frame.BackgroundColor3 = Theme.Background
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = ScreenGui
    corner(frame, Theme.RoundedBig)
    stroke(frame, Theme.Stroke, 1, 0.15)

    -- accent top bar
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 11
    accent.Parent = frame
    gradient(accent, Theme.AccentBright, Theme.AccentDark, 0)
    local ac = Instance.new("UICorner"); ac.CornerRadius = Theme.RoundedBig; ac.Parent = accent

    -- header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 56)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = frame
    corner(header, Theme.RoundedBig)
    local hf = Instance.new("Frame"); hf.Size = UDim2.new(1,0,0,28); hf.BackgroundColor3 = Theme.Sidebar; hf.BorderSizePixel=0; hf.ZIndex=11; hf.Position = UDim2.new(0,0,0,28); hf.Parent = header

    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 34, 0, 34)
    logo.Position = UDim2.new(0, 14, 0.5, -17)
    logo.BackgroundColor3 = Theme.Accent
    logo.BorderSizePixel = 0
    logo.ZIndex = 12
    logo.Parent = header
    corner(logo, UDim.new(0, 8))
    gradient(logo, Theme.AccentBright, Theme.AccentDark, 45)
    local logoTxt = Instance.new("TextLabel")
    logoTxt.BackgroundTransparency = 1
    logoTxt.Size = UDim2.new(1,0,1,0)
    logoTxt.Font = Theme.FontBold
    logoTxt.TextSize = 18
    logoTxt.TextColor3 = Color3.fromRGB(255,255,255)
    logoTxt.Text = "P"
    logoTxt.ZIndex = 13
    logoTxt.Parent = logo

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 58, 0, 8)
    title.Size = UDim2.new(1, -160, 0, 22)
    title.Font = Theme.FontBold
    title.TextSize = 17
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Potatools"
    title.ZIndex = 12
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.new(0, 58, 0, 31)
    subtitle.Size = UDim2.new(1, -160, 0, 14)
    subtitle.Font = Theme.Font
    subtitle.TextSize = 11
    subtitle.TextColor3 = Theme.TextDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Potatools Suite  â€¢  " .. #GameList .. " games  â€¢  " .. os.date("%H:%M")
    subtitle.ZIndex = 12
    subtitle.Parent = header

    -- header buttons
    local function ctrl(text, color, x, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, x, 0.5, -14)
        b.BackgroundColor3 = Theme.Element
        b.Text = text
        b.Font = Theme.FontBold
        b.TextSize = 14
        b.TextColor3 = color
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = header
        corner(b, UDim.new(0, 7))
        b.MouseButton1Click:Connect(fn)
        return b
    end
    ctrl("â€“", Theme.Yellow, -34, function()
        Hub.Minimized = not Hub.Minimized
        if Hub.Minimized then
            Hub._fullSize = frame.Size
            tween(frame, 0.2, { Size = UDim2.new(0, frame.AbsoluteSize.X, 0, 56) })
            content.Visible = false
            searchBar.Visible = false
        else
            tween(frame, 0.2, { Size = Hub._fullSize })
            content.Visible = true
            searchBar.Visible = true
        end
    end)
    ctrl("âœ•", Theme.Red, -68, function()
        frame.Visible = false
        Hub.ToggleIcon.Visible = true
    end)

    -- search bar
    local searchBar = Instance.new("Frame")
    searchBar.Size = UDim2.new(1, -28, 0, 34)
    searchBar.Position = UDim2.new(0, 14, 0, 64)
    searchBar.BackgroundColor3 = Theme.Element
    searchBar.BorderSizePixel = 0
    searchBar.ZIndex = 11
    searchBar.Parent = frame
    corner(searchBar, Theme.Rounded)
    stroke(searchBar, Theme.Stroke, 1, 0.3)
    local searchIcon = Instance.new("TextLabel")
    searchIcon.BackgroundTransparency = 1
    searchIcon.Position = UDim2.new(0, 8, 0, 0)
    searchIcon.Size = UDim2.new(0, 20, 1, 0)
    searchIcon.Font = Theme.Font
    searchIcon.TextSize = 14
    searchIcon.TextColor3 = Theme.TextDim
    searchIcon.Text = "ðŸ”"
    searchIcon.ZIndex = 12
    searchIcon.Parent = searchBar
    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Position = UDim2.new(0, 34, 0, 0)
    searchBox.Size = UDim2.new(1, -42, 1, 0)
    searchBox.Font = Theme.Font
    searchBox.TextSize = 13
    searchBox.TextColor3 = Theme.Text
    searchBox.PlaceholderText = "Search games..."
    searchBox.PlaceholderColor3 = Theme.TextDim
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ZIndex = 12
    searchBox.Parent = searchBar

    -- content scroll
    local content = Instance.new("ScrollingFrame")
    content.Name = "GameList"
    content.Position = UDim2.new(0, 14, 0, 104)
    content.Size = UDim2.new(1, -28, 1, -118)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.ScrollBarImageColor3 = Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.ZIndex = 11
    content.Parent = frame
    padding(content, 2, 8, 2, 2)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local function refreshList(query)
        query = string.lower(tostring(query or ""))
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("GuiButton") then
                local match = query == "" or string.lower(child.Name):find(query) or string.lower(child:GetAttribute("desc") or ""):find(query)
                child.Visible = match
            end
        end
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshList(searchBox.Text)
    end)

    -- build game cards
    local order = 0
    for _, g in ipairs(GameList) do
        order = order + 1
        local card = Instance.new("TextButton")
        card.Name = g.name
        card.Size = UDim2.new(1, 0, 0, 52)
        card.BackgroundColor3 = Theme.Element
        card.AutoButtonColor = false
        card.Text = ""
        card.BorderSizePixel = 0
        card.ZIndex = 11
        card.LayoutOrder = order
        card:SetAttribute("desc", g.desc)
        card.Parent = content
        corner(card, Theme.Rounded)

        local iconBox = Instance.new("Frame")
        iconBox.Size = UDim2.new(0, 38, 0, 38)
        iconBox.Position = UDim2.new(0, 8, 0.5, -19)
        iconBox.BackgroundColor3 = g.color
        iconBox.BorderSizePixel = 0
        iconBox.ZIndex = 12
        iconBox.Parent = card
        corner(iconBox, UDim.new(0, 8))
        local icTxt = Instance.new("TextLabel")
        icTxt.BackgroundTransparency = 1
        icTxt.Size = UDim2.new(1,0,1,0)
        icTxt.Font = Theme.Font
        icTxt.TextSize = 18
        icTxt.Text = g.icon
        icTxt.ZIndex = 13
        icTxt.Parent = iconBox

        local nLbl = Instance.new("TextLabel")
        nLbl.BackgroundTransparency = 1
        nLbl.Position = UDim2.new(0, 56, 0, 8)
        nLbl.Size = UDim2.new(1, -120, 0, 18)
        nLbl.Font = Theme.FontBold
        nLbl.TextSize = 14
        nLbl.TextColor3 = Theme.Text
        nLbl.TextXAlignment = Enum.TextXAlignment.Left
        nLbl.Text = g.name
        nLbl.ZIndex = 12
        nLbl.Parent = card

        local dLbl = Instance.new("TextLabel")
        dLbl.BackgroundTransparency = 1
        dLbl.Position = UDim2.new(0, 56, 0, 27)
        dLbl.Size = UDim2.new(1, -120, 0, 14)
        dLbl.Font = Theme.Font
        dLbl.TextSize = 11
        dLbl.TextColor3 = Theme.TextDim
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = g.desc
        dLbl.ZIndex = 12
        dLbl.Parent = card

        local catLbl = Instance.new("TextLabel")
        catLbl.BackgroundTransparency = 1
        catLbl.Position = UDim2.new(1, -78, 0.5, -9)
        catLbl.Size = UDim2.new(0, 70, 0, 18)
        catLbl.Font = Theme.FontBold
        catLbl.TextSize = 9
        catLbl.TextColor3 = g.color
        catLbl.TextXAlignment = Enum.TextXAlignment.Right
        catLbl.Text = g.cat
        catLbl.ZIndex = 12
        catLbl.Parent = card

        local openArrow = Instance.new("TextLabel")
        openArrow.BackgroundTransparency = 1
        openArrow.Position = UDim2.new(1, -22, 0.5, -10)
        openArrow.Size = UDim2.new(0, 18, 0, 20)
        openArrow.Font = Theme.FontBold
        openArrow.TextSize = 16
        openArrow.TextColor3 = Theme.TextDim
        openArrow.Text = "â€º"
        openArrow.ZIndex = 12
        openArrow.Parent = card

        local hover
        card.MouseEnter:Connect(function()
            hover = tween(card, 0.12, { BackgroundColor3 = Theme.ElementHover })
        end)
        card.MouseLeave:Connect(function()
            tween(card, 0.12, { BackgroundColor3 = Theme.Element })
        end)
        card.MouseButton1Click:Connect(function()
            tween(card, 0.08, { BackgroundColor3 = g.color })
            task.wait(0.08)
            tween(card, 0.12, { BackgroundColor3 = Theme.Element })
            -- open / focus the game window
            if OpenWindows[g.name] and not OpenWindows[g.name]._destroyed then
                OpenWindows[g.name].Root.Visible = true
                bringToFront(OpenWindows[g.name].Root)
            else
                local ok, win = pcall(g.builder)
                if ok and win then
                    OpenWindows[g.name] = win
                    win._gameKey = g.name
                else
                    notify("Error", "Failed to open " .. g.name .. ": " .. tostring(win), 5, Theme.Red)
                end
            end
        end)
    end

    -- floating reopen icon
    local toggleIcon = Instance.new("TextButton")
    toggleIcon.Size = UDim2.new(0, 50, 0, 50)
    toggleIcon.Position = UDim2.new(0, 20, 0, 20)
    toggleIcon.BackgroundColor3 = Theme.Accent
    toggleIcon.Text = "HUB"
    toggleIcon.Font = Theme.FontBold
    toggleIcon.TextSize = 12
    toggleIcon.TextColor3 = Color3.fromRGB(255,255,255)
    toggleIcon.BorderSizePixel = 0
    toggleIcon.Visible = false
    toggleIcon.ZIndex = 50
    toggleIcon.Parent = ScreenGui
    corner(toggleIcon, UDim.new(0, 12))
    gradient(toggleIcon, Theme.AccentBright, Theme.AccentDark, 45)
    stroke(toggleIcon, Color3.new(1,1,1), 1, 0.6)
    makeDraggable(toggleIcon, toggleIcon)
    toggleIcon.MouseButton1Click:Connect(function()
        frame.Visible = true
        toggleIcon.Visible = false
    end)

    makeDraggable(frame, header)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then bringToFront(frame) end
    end)

    Hub.Frame = frame
    Hub.Content = content
    Hub.ToggleIcon = toggleIcon
    Hub.Minimized = false
end

--==============================================================================
--// GLOBAL KEYBINDS  (toggle hub, panic disable all)
--==============================================================================
local HUB_KEY = Enum.KeyCode.RightControl
function disableAllFeatures()
    ESP.Enable(false)
    Aimbot.Config.Enabled = false
    Triggerbot.Config.Enabled = false
    Hitbox.Config.Enabled = false; Hitbox.Refresh()
    Movement.WalkSpeed.Enabled = false
    Movement.JumpPower.Enabled = false
    Movement.InfJump = false
    Movement.Noclip = false
    Movement.Fly.Enabled = false
    ClickTP.Enabled = false
    Aimbot.Config.ShowFOV = false
    for _, m in pairs(Modules) do if m.Enabled then pcall(function() m:Set(false) end) end end
    FPSBoost:Set(false)
    CoordsHUD:Set(false); ServerHUD:Set(false)
    DamageNumbers:Set(false); HitIndicator:Set(false); AutoDodge:Set(false)
    CameraFOV.Enabled = false
    Gravity.Enabled = false
    setCrosshair(false)
    notify("Panic", "All shared features disabled.", 3, Theme.Red)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == HUB_KEY then
        Hub.Frame.Visible = not Hub.Frame.Visible
        Hub.ToggleIcon.Visible = not Hub.Frame.Visible
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        disableAllFeatures()
    elseif input.KeyCode == Enum.KeyCode.Delete then
        disableAllFeatures()
    end
end)

--==============================================================================
--// CLOCK + RESPAWN ESP RE-HOOK
--==============================================================================
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            if ESP.Config.Enabled then
                espFullScan()
            end
        end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    -- ensure ESP re-applies to others remains; nothing extra needed (handled by conns)
    if Movement.Fly.Enabled then
        task.wait(0.4)
        flyStop()
    end
end)

--==============================================================================
--// DONE  (boot sequence: loading screen + auto-detect hint)
--==============================================================================
-- Detect the current game for the loading screen label.
local _bootGameName = "Universal"
do
    local _entry = autoDetectGame()
    if _entry then _bootGameName = _entry.name end
end
-- Show a fancy DaraHub-style loading screen, then notify.
task.spawn(function()
    LoadingScreen:Show("Loading " .. _bootGameName, 2.2)
    task.wait(2.2)
end)

-- Log environment info to the script manager's log (DaraHub-style diagnostics).
scriptLog("Hub initialised â€” Executor: " .. getExecutorInfo(), Color3.fromRGB(120,200,255))
scriptLog("HttpGet: " .. tostring(supportsHttp()) .. " | loadstring: " .. tostring(hasLoadstring), Color3.fromRGB(150,220,150))
scriptLog("PlaceId " .. game.PlaceId .. " -> " .. _bootGameName, Color3.fromRGB(180,190,210))

-- Attempt DaraHub-style queue_on_teleport auto-reload (silent; no-op in Studio).
setupQueueTeleport('loadstring(game:HttpGet("YOUR_HUB_URL"))()')

BindIndicator:Build()
notify("Potatools", "Loaded successfully. Press RightCtrl to hide/show.", 5, Theme.Accent)
if _bootGameName ~= "Universal" then
    task.delay(2.4, function()
        notify("Auto-Detect", "You're in " .. _bootGameName .. " â€” open it from the hub or use 'Auto-Detect Game'.", 6, Theme.Green)
    end)
end
print("[Potatools] Loaded â€” " .. #GameList .. " games registered. RightCtrl toggles the hub, RightShift/Delete = panic disable.")
print("[Potatools] Detected game: " .. _bootGameName .. " (PlaceId " .. game.PlaceId .. ")")
print("[Potatools] " .. (function()
    local n = 0
    for _ in pairs(Modules) do n = n + 1 end
    return n
end)() .. " Vape-style modules registered.")

return ScreenGui
tj1!13eJ"_dt0!J^hm!2opj#&+(A!Q5!C!!!-+!!!"Jp]:H)*uF\RT*P,m!!!#.?l/S>pHJ?R#QOl!('SB]#*2"QBOHT[(MJj1S-B/t!:L#(!6>2E#AF1b!P\YL!8%=R'F"O;"9ni+p]:m)!2!@0p]CHrp]:Eq!1,V\p]BVWp]:^$!;?L+!6>2M#&+(a!M9U2!8%>+!<rN("9ni+p]:m)!9Zcep]CHrp]:Eq!;D3K(\e'P5550b!!&>j%03m=pB,+0^]F01B`Q3TRKE`o!/C_l!9aH.<H%q_=a0r8!uH4F"dBc,!!!-+!!!"Jp]:Hq*#JAO^B403!!!#f3Z%Pm^DQ_I#QOkf"_dt@&&/?`!0@5J#&+()!RCj^!2'A`!X8W)k65Q"p]8D=B`NYbGZBP#!8Ikb!!'J4B`QK\T*K'1fE';#B`R&lg]n#`!1*q)!9aHU#&+),!TsW#!;HT8"_dse!ga+*!/L]k#AF1"!c/&@!5APK!+=+TB`Mh5#&+'Vj:_^t!1*n(!-lNfB`NYak65Q"L]O[aB`O4q`"rUX!4N/H!3cLu!GMPD!VZ\1!5JV="onY<!GMP$!m^s_!2'D^").b6!ot+$!!)HiB`OM%cN@k]TE;k/B`P(5GZCsK!-hYV!<Cmg"onW+"onW',L?Lb!<=@s!h]S/<+u?j!n[Pd!!(@I&HDgX!`?-eciV7<!CY99ciV8i%0-Ck;?b,CciV8i!!!#^Af&MiV]*VX#QOjc"_dtp!J^hm!9aHu#AF2-!LF")!;HT8"_dse!p9`$!/L][#@.=k!o!_[!!!-+!!)cq!!!"[L&i+c!p9^eIeWsEO+mZOp]C0jp]:Eq!1+$/p]Bnbp]:^$!8mrl!&sr\!-i0i!.Y(MBQ*rjB)m0qB)mG_E+]0,!H;ZOO9#UuO9#=]EWC?7!A:>W!,uQNL]MI-!0@3]BRg*`N#Wf;J,tTC"onXq#&+),!I.Uh!-hXs!<DQj(OuP,"e,]#!!)0cB`Nqj^B\HQO91aQB`OM%dK0UQ!!EK+!;HU)!!'bc(\e'X)#+.4!!&o:(\e'`C\Rr:!!%77:]P`C=9.dl(KeEQcN@k]@+kbg!!!-+!!)cq%0-CK@2J\?rrMlr!!!#62Ac,i`t\:M#QOkF"X3qs!p9`$!/L]$<KI4]GZgC7!:L"+QiVsG_up8E!-hX[!:L"+BU8q<#AF0Wk65Q"GfKu%!.Y+=").ak!Nu`B!0@5r!GMP$!RCj^!2'@b#AF1:!Oi8I!3cLu!GMPD!VZ\1!5JW%#AF1Z!M9R1!71b""9ni+"9ni+!.O\E!1,JXp];i<!WW3#^OlP'p]Bn#p]:^$!5APK!8n!`#AF2-!Ug,)!;HT8"_dse!ho]"!!!!$!,.]f"__#!J,oge@*`$\BOLQ_"__;).0XBmU^./)!!EK+!;HU)!!%du(\e(3!Vc]r!!(VD(\e'@;tpD"!!%cXBE6ZcNs04thuT/LB`R>tirfPd!-hY.!<DQj(Q\Zi#+#R/!13eJ"_dt0!NZP2!!)`oB`Q3TY6SbAciNS;B`QcdMuj1`!1sL1!6>2M#&+(a!I.UH!-hXS!:L"+@*\qi!GMOIY6SbAE:3mC!-lNfB`NYak65Q"L]NYD"onY4#&+(A!M9U2!4W((").bN!VZV/!6>25#&+(a!LF%*!8%=5"_dtp!J1X_!!&&`B`Oe,QNq4)Vu`LpB`P@<pAnt.\,l=+B`PpLT*K'1a8raSB`QK\U&kN!!/C_l!8%=5"_dtp!I.UX!-hXc!:L"+E5)Xa$O-S2"9ni+!$fhlO9#>+fE,`QH>*B;!n[Pd!!)a^B`R&m!,0^\!71dEO%.ItO(^r.!mh"i!Y#,0Va1L-!mh"i!WW3#mnstC!k2mb!XJc+cN@k]huURn+opg-^B\HQn,\j[B`Ro/Ws8h/!!EK+!;HU)!!)16(\e(3!Vc]r!!'c9(\e'@=SMq'!!)Hi1B=odGZDN[!-hL7!)P;)#QRsZ\Hi1C0!P]_gB@c]!1sL1!4W((").bN!VZV/!6>2!#mLA0"9ni+p]:m)!2!^:p]CHrp]:Eq!3\F"p]C1Dp]:^$!5AR+!<AJfcN@k]TE4K`B`P(4Y6SbAYQ<ee"onYd"_dsm!M9R1!0@5J#AF1*!Q#$F!!%cXB`OM$Ns04tTE1YiB`P(4[g$OHYQ=J!B`PXDpB,+0^]D:X"onW+"onYu!Y#,0k7\[,!ri;r!WW3#T->*H!j=*K!XJc+T*FK[!3cKj#AF1J!VZ\1!5JX0!GMPT!MTr+!!!-+!!)cq%0-CsA/G"BrrMlr!!!#F4;[boVdK3##QOj["g%e*kQ.:[B`RW'QNq4)p]8D=B`NYbM[Tdi!65HNBOLiW"__;I-j=9la$^)E@-<(A"__;q0a25uV^)FZ@.FO,!!(=IB`R&lQNh.(kQ/F'B`RW'JdVb_!4N/H!71b%"_dth!KRCu!8mmp$O-S2"9ni+p]:m)!;AGhp]CHrp]:Eq!/H1-(\e(+Eqf\A!!%cX$NR++[g$OHYQ:@$B`PXDpB,+0^]B&o"onW+"onYu!Y#,0LKYMh!ri;r!WW3#QYRE4!k1Ag!XJc+pApHY!4W((").bN!M9U2!6>2M#&+(a!RhA[!!%7H8-!m;:]Tqd(JsQ&Y6SbA=S`C0!!!-+!!)cq%0-C;Fr0oTrrMlr!!!"c;A]*0s$6>\#QOl!"'biA!VZV/!6>25#&+(a!LF%*!8%=X%0ce4^B\HQGio6E!.Y*j"_dsm!LF%*!0@5R#&+()!J^hm!2'@R"_dt8!Q5$D!!(%CB`NYaQNh.(L]P6qB`O4qo*,C!!:L"+^]F03pAnt.a8raSB`QK\T*K'1fE%$:B`R&lRfrur!:L"+\,l=)pB,+0^]C&4B`Q3TK*2AY!!EK+!!"7j!b_QYfE+SD,N&W"fE)Wb!71cZ!!(@I&'tBU>L3FKT/"[o^Hb36!mguKI`MQjLEcuD!mh"i!WW3#s",&.!k0`%!XJc+pB,+0a8pNc:]Tqd"\;I7=\o+e!uFe;#O_b/!6>5f").aC^B&$KBYOdd!-"8/B`NCu"_dse!P8UA!!&VrB`P@<[g$OH\,l=)B`PpLo)T$q!:L#(!/L][#AF1"!l"bM!13i6").b.!kJI<!!%7HTE,&]!uIU2Ns1:BB`P(4b6S:P!3ZWA!3cNL<O`&0GZhf_!362+!!)HiB`OM$cN@k]TE2e.B`P(4M[fpk!!EK+!;HU)!!'c:(\e'p"o&-!!!&'D(\e(#1ACnV!!)X2VuZku"9ni+p]:m)!:P(Ip]@&hp]:Eq!7)#hp]CI;p]:^$!!$1&!"9hIGl/Ha!!$,6!.Y*#!C6\crrd$9G]7e5L]Q!C"onW+"onW'IeWsEmm.cb!oF+T!WW3#Nt<-&!q-cs!XJc+N!oghcjnP1"onXi#&+'VY6SbAGQ:cXX9Sk4!!)cq!!!"[>o38;Y6Xh(!!!#>B,C=Es#ToV#QOj\%;,[&!Nu`B!13eR#&+(1!?_r0!<<*i?i[A8B`Mh!!<rN(+B`(PJ,q<:!%;I[L]ND7"onXBB)n"oE+]0<!H;ZOTE0]H"onXR!G;CWE+]0$!H;ZOL]KjI!!!-+!!!"Jp]:HA5Ss1spAt$j!!!#F5Ss1spAt$j!!!#V8f.7(^D6MF#QOiY'n?>[!It2nE,ZY,!+;#l"onW+"onYu!WW3#s*,@T!g`u`!WW3#Vg]HW!k1ht!XJc+YR1sB!,uQNTE,<0TE,%C!@n-ME+]0$!<`T,!,tYg!H<!IpB6QYQiUH2pB6!I-m/M/F`;<k!<rN("9ni+p]:m)!1tMQp]?3U!.O\E!1tMQp]@&mp]:Eq!4Og%p]C2F!Vc^%!!)?em/[4^!ji^I!!!-+!!)cq%0-C+4r<tqk6:V^!!!#n$lA[?kAg7u#QOj`%C-!7!!EK+!;HU)!!&?=(\e&u#5A6"!!'K'(\e'`?ha[.!!')4`rQ1E!RqJ]!!!-+!!)cq!!!"s$lA[?pAt$j%0-C+$lA[?VZHjIp]:Gn$lA[?pAt$jJH5`NV[OC:!a#-u!!!#6=r6r8f4"FU#QOkG%I*tM%A4'O"9ni+fEjWi$/cBu"onW'IeWsEhd%&n!a#-u!!!$!/f49aQPT>t#QOi):TOic#m:G4!;HU)!!(nR(\e'p"o&-!!!(>2(\e&m%/9l0!!')94obQc"onYu!WW3#pLP09!fmN[!WW3#cOq&h!j>Su!XJc+Qj@=)BP9[3!0e-"!,/\@"onW')#s[*").as!Ug,)!13ci"onW+"onYu!Y#,0f/slE!ri;r!WW3#f0'rF!hXr:!XJc+hZ_a8!2'@r#AF1:!<?/f!L*im"onYu!WW3#s!/EU!qu]qIeWsEs!/EU!qu`j!WW3#QZs>A!l%.u!XJc+O9]*B!RM4e(^9s?bQf*f&G,u-!!!-+!!)cq%0-CK?5NA<a"$ic!!!#n<YtN4YCH<K#QOi)>Q=a(A,ln%/StJ!&3u!c&=4tc!#QP<Y88#tD#b\$5d+Z?k>#^k./,N3!&+N[!!!-+!!)cq%0-C[K`N"b!ga/e!WW3#T*Z>/!hW]l!XJc+35>Op!$FfT!$Ddpk:RS`!!!QB!!!QIO"V&s!X8W)^Lh0[&B"_V!!!-+!!)cq!!!"[.Mqj]f)tdL!!!#n.2Va\[nZW!#QOi9B)lV7$jH\3BQ]+3BQ.'eYQ:s/6?o^802f"TYQ8MD!!!-+!!)cq!!!#V0,OBbQNm3d!!!$!'GpNGpNuZ:#QOkO$YKID!GH*G\,if7&HDg8!HinnBS-<i!!)'o)utKiliI@k!!EK+!!"7j!jD\*,M3&_k6#Duhu\ZcB`R>u!,1!d!8%>`fE0*;!$gD'5j&5`!9aL)BP@J9!WZol!WW46ciO3o!`A,ociTPM7*l"^!W[\j!W\R2"ipbl!ltEC!!)12(WZ[X<QG4I!!%NMG(9TAJ,s9_G]4%0J-!go"onW+"onYu!eC@P!/DI/p]C0jp]:Eq!:Mi_p]B%up]:^$!/LY7kQQbCE*mRG!Jgb\L]NS<MZO(_!!EK+!;HU)!!'c*(\e'H"TX#H!W]u,(\e(+"8Dot!!(Ua(\e(#'_h_8!!%NMiW0%8$%N%CE,]buE/4P$!<rN("9ni+p]:m)!3\a+p]BU^p]:Eq!09&Tp]A2Pp]:^$!7M/u!!!-+!!)cq%0-C;<>YE3T7m=@!WW3#a+FC/p]BVbp]:^$!,/\>e-M-:UCd\1!:1-t!13fb$O-S2!)J1L&Gu_:!!!!:!!&quB)o.:!.D'P!4WD=kS:$#"9ni+p]?!I!!*%G(\e(+!Vc]r!!%d'(\e(+0),JR!!&>i6]_=fY6RI7E*trG!I14=;L!GF!<rN(!#Yb:?pN$?BOF*/#B6RA;K-T-!<rN(!*50^dh2cf!!!"Jp]:HI0,OBb^B403!!!#>(DliJY;l:Y#QOi)!rro$").as!T+&p!13ej#AF12!Fl<6!5AP%G^+HDGcq>P!s!iPHNjHM"9ni+p]?!I!!(&U(\e&e#P\?#!!&o6(\e&e$MXZ.!!(pX'p&NR!<?f[!<CII(!lu3!<`T,!!EK+!!%KC!W^Pf(\e'8!r)g+!!(>d(\e'8"o&-!!!&W[(\e'p'_h_8!!&qu1XH/q#g`Tb!2oqQ%gE"6"9ni+p]?!I!!(nh(\e'8!r)fs!!(nh(\e'0#P\?#!!'JR(\e&u=SMq'!!&)j'sJ%$!LNm&huSW7ciJ9F!LNoG!Hj2!TE.l%!71`pB)pQb#\O.q!QY:S!9aF`B\3=cbQ.nJ!!EK+!;HU)!!*%8(\e&u"S`%L!<<-"C_ujJY6+J#!!!$!C_ujJQNHp`!!!#NI2DY[cVaH=#QOkO"QTUY!Jgd'!CG-6TE-]DciMJociIbZTE0rP"onW+"onYu!Y#,0f,PV%!r!u8!WW3#mnahq!hU2%!XJc+Y6Pum!LNm@;U>Hk!RLj[!13f1!<rN("9ni+p]:m)!9Y[Fp]?cbp]:Eq!1-.kp]?L)p]:^$!13f0!T4!7!MBH.kQ-J?huQ1.!T3u3;W%T6!S[_]!!"*X!"] ],Y8%V8%VYn[&.nmBJcl8X!)R+N(W[3l"onYu!Y#,0LO]CAp]A26p]:Eq!8h9&p]AKQp]:^$!.Y)C!-iH=E.@tY(E<F*!<`T,!;HU)!!)1s(\e'p"o&-!!!*%S!>kM4k99U%#QOl%';#:*!!EK+!!%KC!W]\h(\e&5p]:m)!4Op(p]Bmep]:Eq!:MNVp]?47p]:^$!!"4l$2=`."onYu!Y#,0^L.lQ!p9a^!WW3#LJer`!p=t+!XJc+_]'Zt!!EK+!!%KC!W^7d(\e(+!Vc]r!!)aU(\e'`F8,eB!!$[rb8KdZ],LqS!;m'+!!"ZML]J'C!Hhe#!>'3'&-N1;!!EK+!;HVH!<<+l6l5V"^B403!!!"S5o9:ta!pcb#QOk.#?&>?&.j!rL]N,B"onW+"onYu!Y#,0VeR%C!l"p6!WW3#k;X:Q!nVYk!XJc+E*rZr!V7$1!!!-+!!!"Jp]:GNGSg,Vf)tdL!!!"[>8R&9^M<NF#QOk>#AF1j!XM?t\,ic<B`PpL!*6<)q\KA>!!)cq%0-CK+;aeST*"ch!!!#F)Ai/MYD*)Q!XJc+!3lP)!:L#(!13fU").b.!VZ_2!2oq!!<rN(E+]0$!QtrW!!!-+!!)cqJH5`NQSB<O!m_,H!Y#,0QSB<O!ga&b!WW3#kBRm=!q1R4!XJc+^]EBpL^db%!CFR&\,e6\\,j)?\,g4BO9(FD't=:#!O)S>a8q(t\,g`.!O)T@"onW+"onYu!WW3#a%[BF!nRPL!Y#,0a%[BF!ga&b!WW3#k9Ll=!j>Jr!XJc+YR[c9\,hBd\,eq+!K[>K#?&><YQ:p47)/i=!UBaj!!!-+!!!"Jp]:G^*>eJPhZNWT!!!#&+W'nTpHnWV#QOkG!Hj2!cjQ<R"onXa!GMOY5\C(I!FTO?L]NS<#QOi)2Lki*"p>,1!!"7j!dF\ifE+SD,N&W"fE)Wb!8%>`fE-gik:^NLhu`?ZB`R>uciQ`\!71dEh^QnRVd2^;!mguKI`MQjk9U;Q!mh"i!WW3#YB(N$!ln!U!XJc+0P:B!?tTIYGR+<%"DB(]!!!*$BE/,7E8ps'!!!-+!!)cq%0-CS72P_#^BOB6!!!#F72P_#=82gs!!)a!(\e'(0_b\T!!%NT]`A+XE'&#h!K.:)!.Y(Q"onYu!Y#,0pN@AJ!p9a^!WW3#[gj5L!mbl]!XJc+Cl&/m!!EK+!!%KC!W^Oi(\e'@#5A6"!!&>k(\e(38b`>m!!(VcD#h?U?tTIYBFt4EUE!iYk6<C?!!%Na?_@Ps+,Cn(TH(`PE+"1sE4ZJ^!!!!#\,huu"knn9li@:j!9=.b!!(dT"onW''EA-W!<rN("9ni++:S;N[g!WkhZ=o#!!)0c(EebB+:%rI#UKHNV].5g#RFK;a!b0s!!!-+!!"-m!<<,O!uE)`#9X!H!*9sZQNSE:!!!!-QidW7*Gkcf&4Y9!&-*mS(b,^i!!"2C(^MDf!#c%A!8n*+TGH/b"9ni+!.H$jLBJD9Y6Q0M!!'J5(Eeb@+:%rI!"o;local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
/F^B"onWC"onW;"onXZ'LS6)p]:R&!!!-+!!"DV!!)`q(F[$%-ia5Ik62YMNs-p;!!!9U!!!!-&-*8C&H>o>h#RKu&1%;V!#,D5!!6_?"k&>1>Qt0.<!E=&9EkIs6j<Vk"9ni++:S;NNs-=Bk5c\*!!'b=(EeJ:+:%rI&39dk!#,D5#V5rULBq_s&--,=&.h*f"qUnA!!!-+!!",N!!%cZ(EfUV!.H$jLBeV<^B#GW!!(mY(Ef=O+:%rIhc9ml#k%t7!"]\HY;D=A(bY%V!$VUI!6>Ng\.[-r!!!5GMueS4"onXN"onXF"onX>"onYm'2%0pp`BVC!!"DV!!)`o(F[$%!.H<rpAl'YQNei<!!)0c(FZ`s-jTeQ#h/kTa9!1j!!(U`"V;LN'EA+=/-#[*#]0PQ!+>j=&3u9\&@[DqD#bD&"onW'!e^T*!=SFV!<<3%#QQ%K&-,ME!Y>bE!!'5(+K,Fa$eK'/!"]-=!"bY%"onW+"onX"JH5`NhZFZkY6Rl(!!'b8(JqjO:]LIqT*?*.=&9/&!6>Zc3"S&l&2:Hl"onY)!?;(noDo-r!($ki!!!l:!.4tN!!EK+!)NXq!2fl7:sT4DIS^$B!Z+\J#>bC#!1s</:hNT1!!)crB)q]6&.fs,!&brV!"9\M!+>jEVZ^i:+F=:m!!m3;(]\t$!!"I:!?eED"onW+"onW'IS^#7(JqjI:]LIq%i8("#>b[+!*^EC\-.Eb"onW+"onW'IS^$R,8X1s"],1!!7r_;:sT2>#QOiY=#g3c`rg/Y8-!<_!2BQ7!2'_"!<rN(!!8Dd0aZHj!NZ;+!!&eq"onXn!<rN(J-,ko"8Ds$"onWg%0-D&!>e#)"[IV>!!)`q(I4;k5QCca^BYQ?T*IUe!!"-H+P/jq2AdP:%'Tm@+BK]c+:r/c0E_R[!!$[T!8f_P!%8[s!&.@V!!!-+!!!"J5QJ7u(I4;k5QCca[fdL4LBg'M!!!Q]!!!!-(]Xh8pFDU;+pJ#I+D1[6-m\in!#,D5Es;UE!!!2AMudGn!!$7.!!#t&!!#[s!!!-+!!",N!!&Vr(EgHt+92BA^BYPtLBSe+!!!QqNs60)$uumb!#,D5#V5rULBq_s&--,=&0_;Y!6>9E\-&*4!!!shNWGXO"onXf!X8W)Muj1`!!!l:!/q6h!!!-+!!(@HJH5`NpB)5Y!KRE2!<<*"k62[K!KRE2!=/Z*VZ^i::cL^q4BP]e=SDt1&GQA.!"_sL!&dXf$lf7\Zj-d8!!"I\"Ag!@!!!-+!!(@H%0-C;#8b_fcTBJS!!!#N!uK;b?dJfZ!!!!:!!!RC!%8+c!&,7j!@Rs:)f5R/0NTt&"V;5!!!!QY+94;JPR%Br!!!"JciF-M"rGVeY6WDT!!!"S";fDcrs$gN#QOkn").b&#7q.@!2fs:!%<0u!!!:C]E_R"#R18/"9ni+ciF+H!4MtFciM/jciF+H!8e"tciLTXciFCP!:Nm(!'majB)kIf&HDg/F_q+L3+i4f8.bh%!)G(0X9/Y,!0;MA!,r&F!!(@H%0-C#";fDchZD.*!!!"s!>j)`LEb(G#QOjc">Bh#3+i5A!>#fe!!%$>=Hik,!*JOf"onX*B)i2sB)iM8!<rN("9ni+ciF+H!7(caciKaD!.N8q!7(caciN#+ciF+H!653YciLU)ciFCP!1*_'!/L[&#\O/4$A\]p!!!!poE9sNKE28W!!EK+!71`U!!&W`(XN3?!mgrJ!!)a-(XN2L"jd8U!!&p>quHe2?tTIYBFt4E[h<NXE!-@F!+8'Q#C)S7D#f(e?tTIq!It1_!!)<c"onXV"pP&-"9ni+ciFRU!7t*bciN;5ciF+H!8dhociKJ;ciFCP!1X-1!!&p>D#dBlB)l%1&HDe6"onW+"onYM!=]#/ha/.+!T*t*!<<*"a%mMu!J_<7!=/Z*[h;C8=?&R,#@NltD#e6/B)llR"onX:&HDft!GqgU3+i59E"N'M!)NFnE:O)8!!&Z(IrNaPE+].V?tTHNRK3Tm!!mM3!H8/G!!(@H%0-C#@2I8krrLII%0-CK4r;QHLB>g'!!!"s!uK;bk?$"2#QOi-"onW',H(X9!<=@K!E]=H\,ekX"0_e+^]C?TB`Q3T!3Q@4!<B>)&HDg0!>,;3Vu]cIAZ,X=GXSJ2Vu`Ol%0-Cs3X)/WVu`Ol!!!#&BG[<BrsYP$#QOj^!HS5@!%EL%.&m:P!!!-+!!!"JciF-EIi$H4pArVA%0-C+Ii$H4LBl0,!!!"kC_tG!T3BSB#QOjc"Dn.#!FTO?QiRa0O9#=]EWC'I!T=%ZYQP(5!!(@H%0-Ck(DkF!k6935!!!"[6l42NO$1hj#QOjW"%N=k"9ni+ciFRU!8fmTciJn,!.N8q!8fmTciJn*ciF+H!3^eeciL%PciFCP!6YQA!<B>+"9ni+ciFRU!;Au"ciN;5ciF+H!5DPNciNScciFCP!87R!!!&(-B`NqiZN:=2!!!!)n;ICd!<rN(]E&3:!!EK+!&tDf!1sH33<'"=!!!#F!uEq`#<2th!0:k'!$D8T&-*8,Nt`-:5gMn2&4#,J&-N1;!!EK+!&tDf!7(ld3*/'>!!)`q(HA;t3!]Ka&4#t5&.hnSpB;*>&-)]V#Ts+*#_W5V"Dn,E`rg/Y&.hnSVaM.%!!!-+!!!"J2un^:(HCR]2uipYcNY1FQNK2Q!!!j;+Km`-'57HF$ijr`!!EK+!"9hI+;>"[!!"H`#S[IC!)*Rs!72f/J/,"#"9ni+3"5iff..XsT)ptP!!*$((HA#j3!]Ka!)W^r!#,D5"9ni+3.V)1!65*V36q[d!!!#.!uEr#0/s4;!/H">TEkK"UB(Q!!!!%J"O2l+*!QBC'F"O;$jH\3TEQ(?&!.J."onW?!!!#n!>cTf!>l7G!;?L1(ag.#!!'b=(DrbL(^L*A[lJ:*#cJ0q!<DS-#U]TP"9ni+"9ni+(]XO9T)ofGmfOC9!!&Vm(Ds%T(]XO9^B,2gcNb9m!!)d%>lXjK"onW'!A+MuMua%c!!"Eu!<<+\"W&T%!@SBW!07:".#.gO!!!#&#8\eT#:KiX!!k+U!!!E=!"_0#!S7DA8ne8J"9ni+!,)oD&6BFp!gbr^!$D8T&-*8C&>+4RB)j%c,ldoF'EA,`"psc-fGFYo!!!!"Gm;3G!<`T,!!%Hr!1*p,.),d2!!!#&#8\fO"XjWV!!k+U!/Chs!:U0m@/piM5`Z*\!"9\E(e2Q!!>kqD!!!:I&/YB]!!!')!!&Ag9CND+!WW82!<g<!!?;:D!#,V;!"9&3!!EK+!!EK+!#P\9!;?L1(p=/]%0-D&!>cU)"rI=?!5AaT(nV$M#QOi1/-#\>!V?Bm!!!]5!3dDZ^_<(F!!.?Lb)??@"onW;"onW3"onYU![mIC=9Jg.!%89V!;?R3.$k)c%0-C;"rAZu-ia5I^BYQ'T*HbM!!!;!!<<+T#]0PQ!3ZD'&.h*f"qUbC(]YCB`r[(\"onW?>Ssq[#^$[q!#,D5+pJ#I!!,4inVdJg"onW;"onW3"onW["onW//-#[R#AF/L!"9\E(fqQH4qJ8B+94;:g]7N^!!#P!!!'b8(J(G)8,rViNs-=j=%ESs!%;[8))*a20G#oK0Wt]a"onW+"onW'IRjGd(J):A8.>P!-Po=g"\8Un!1*g)8;@F@#QOiY$NQP(49bcck6>c'0JGcT#;?Er!&uAlNs@oMBJ9Dp)uqZ2"onW'.74p\"onY-*=h!7J/8=m!!#P!!!)Hh(J*Eb8,rVimfXFtrs)(#!!!!:!!%cV%KI=_5fZ_="9ni+"9ni+!.IH=cN4nRQNft\!!&Vp(J)"98-f1qY6SbAi!U*/!%7h\(]YCc!"] ]S!#P]a(]XO<"UQ1RgPc0?!<rN(X8rM*!2KW"!!&Mi"onY=%Lpbqi#;e'!!"DV!!'b8(F]:a-ia5I<u3:2""4-L!9XM%.(9C/#QOk^2f/O#!"9D=^]?'E!<A05/-$e0&HDe6"onW79b8-A$lBN],ldoF'EA+9"onWO%0-C+!Z*8W#:KQP!073u.*huD!!!#F#8\et#:KiX!8f_P!!iS0!>#5J/r9T/O+@=G!$Knr&HDeB9b8-A$lB6U,ldop"onW'!D*L?Mub1.!!!uC!!!];!!!E3!!((Q%+#1Q!sAf.!%89V!1sK4-mpDC!!)0c(FY=J-jTeQ#Qt.RJH6$AYBL6X5j);V"9ni+"9ni+."MC!!7q;h.),d2!!!"#(FYUQ-jTeQ#[-X$!7tk#!#PuA&-)t`!!!!5!!!!",n'R.!Rq2U!!(4F"onYA!sS`*$jH\3a9?_M#I"dC"onX"JH5`N[g!XFk64Z^!!)0c(Jp.r:^@%$=&LFP=&Q72&-+RI.&6kJ!!!iO(glocal InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
)#6Y52!2oo-!!(&H(T7At"fMG%!!)a((T7A$;Q'U%!!'&,2ZNgX!]`CJd#8!A"onX6"onW+"onWO!!!"S"W&T5""4-L!7(``.$k/e#QOiA&HDgp!_gWO(`6KpQ\>GO9b8-E"onW'I1QA]"onW'IOG3*";`K4""4-L!;?R3.&R:u#QOi1/-#YM$kNCEB)nk4&.nmB!"9\M#\O,[&dA=9\,pr;)3>5H"onW'!"&"N!R(QK!!'q<"onY9!<rN(k6>c'-n%>>-jXGc0Hb!.3!9Ec!!EK+!'gMa!;?R35edOh!!!"k"rBQ!!C-nj!2'H@!!')%"onW+"onWg%0-CS#8]X,5QCca^B,3:f)n8D!!!j;)#"1Fnc9R-!"]\a!&bDD!<<3%#c@fB!"f/3D#bDo"onW+"onWg%0-B`";a=Y!C-Vb!4N1L5`Z"4#QOiIjoHmV!LJ4K!&ssl-ie''!%8`i!!&)rJ,u#TL]mnc!!#7a!!(m](I4;k5QCcaY6Ge.mfG`[!!(p`=")AqVZgc72umV?!"9hI.(]Ka!!!!J@h8VX!!!:;!"]-Y&-)\272;PX!PAjG!!'A8"onY)%0ce45X=cA8B__h8FHY>#mLA0!#Yb:X8rM*!!"J?'F5BW!!!!JbRcb8&I&48!#Yb:!#,D5[qBCT+M8<k!!)0dD#cOT5j($b0P:AN"9ni+"9ni+TE,#m!+-P8!M9Rh!<<*"QNS+t!NuQt!=/Z*5VC^l!&u8)!;$a*!!!-+!!&Ym%0-B`";d^3hZBGO!!!#F"rEp5QNNl]#QOi)!rt$Q"HEK_3;3Yp!'gYk!!!QF5X5kl3$82Z3)Tk`!!&Ym%0-Au(SCf,!MBGn!!'2,(SCft!h]Q"!!&o"D#c7<OobSe3"QWT+94;RN!haZ+Lc"%$jH\3VZ^i:0IT3$GrQ?H0H^?R0E_A)S-(I`%L)n5"9ni+TE,#m!;@`TTE2e4TE,#m!4O0hTE1[5TE,;u!2fs:!&3mD5ehS(&.gN<!&cOL%mWDK"\>F"+%Yi&U]CZ"!3^Q[!([*'2ujd\[l6Q;=$XeS"9ni+"9ni+TE,#m!7)JuTE3(:TE,#m!653YTE44GTE,;u!/Lbj!)Pp,!!!!/!!i]3!!#=i!!)0dD#cOT5`\o)0P:ANUB(Q!!;?_8!([Y984Z!2mfcNaF\"Ip"onYI%0ce4&6CRc-&4p'!'gNt0ED"[)uqYq"onXr!=]#/s'QY9!TsWZ!<<*"LB89b!T*sO!=/Z*r!02%!!#8Lmfc7g"!:)&"5F4f!!#8Lmfc7H#9QM*!sAf.!2'?%!!(>,(SCfl"eYkr!!(V-(SCf<J"QfJ!!)?or;cluLIu7\BMWIFE'S%9G]45p!-ADF!!EK+!2'>m!!(o1!>hC0k67LZ%0-CcK`N!_!P\f2!<<*"T*#n&!T-)6!=/Z*k6>c':f'D9:m_LX!<?4DD#dsO5edM2RfN]n!!EK+!2'>m!!&'*(SCf$#+tts!!&o!(SCf$=J,[#!!&quB)m0!&7>K7.f]QI"onYt#AjH3&/@`,5X=cA:f):*30XaS!!!-+!!&Ym!!!"kC_r`FhZKMP%0-C#C_r`F^B1&/!!!#^72MTthgkg$!=/Z*"9ni+!$d:#O9#>+O9'=P+_^qD!T43A!<<+]!E5=HO9#b0!0@6%H>*A@!<>n(O9*C6B`O4qNsTM#QiR2#L]IL3!E&local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
%!W>9!<rN("9ni+O9#dj!3ZMAO9([OO9#=]!7qDkO9)NhO9#Ue!!!FX!>#8+!<@WN!"=Ya!!EK+!!j-l!<<*iGQ;u2-ud*-"onW'<`$F3"9ni+O9#dj!4N+JO9+MJO9#=]!-]6@!RCq2!=/Z*mfR8(:u;Fj!*HE0B`MOF$ig9PFXV2/$uc1H@/t6H%!W<d"onW'@/tP0!ZV2b]E8?<!!EK+!0@54!<<,'"W*7$T*LGY!!!#NAf$O0Y8r]*#QOi)%#=oa#S:AD!-/'9!";s8!"<68/-Z(SKEMJZ!!!F(#QP98!!$F-=Gm1a!!!-+!!&)]%0-C#8f*Qihe\AT!!!#F";d.#O*Zlg#QOi)@/s[8$toVH&82%DEWB3DAggIU$r@30$s3K4"onW+"onXb!=]#/QWk8f!ET8MO9#@5;AYDqLBWb?%0-C[;AYDqQWoOP!!!#^A/C=.T,<Xj#QOi)@/sC0$t'&@fE#@[!9+"Z\-i9F=9nm8?iU18!+5d8BE/;LBE/$Q!*E?G-rA(g"onYI!sAU#g]@Z[!!EK+!0@3j!!)aW(Q\Zi#ESrd!!(nC(Q\ZaD3+c(!!!![GRsj`!-jA&"onW+"onXb!J(7O!1t_WO9,(XO9#dj!1t_WO9(sYO9#=]!8fsVO9)6]O9#Ue!!#+%%hJ_L!-i`'GUNPfncO+l"onX]"9\]Y!#Yb:Y6SbA0E;M@!!$F-33NR$!'gNb0U`"B!rsb<").`hhZ[]o3!9Ec!3ZWA!'gNb0P^Y+!!#@j!!'2-B`JD=$kNC=@/piA"onY,#AF/T!*0@D!#Yb:RK3Tm!!!l:!!!E5#QP8E&--,=&-N1;!!!EE!!j,Q!!"&?#QP9P!!$F-E;K\@!!!!-E"E"X!-",()usq>"onW'!sK8O$M98XoE#3s!:0ak!!)']"onYY!X8W)\-G1\)W283"onW'IRjI2#8]qG#=ngp!9XM%8<3pF#QOiQ686aq!":Om#\O,sQNq4)5kG*^!!"D_.0!r\$nr50B)jnr"onW+"onWo!!!"+(J):A8,rViQNS*qY6%6#!!%NWB)jnmB`LBuBJ9E?(,.Bk"onW+"onW'IRjIj"rBgs#=ngp!,!*=LBL-R!!$YG!6>0@BJ9E?(,52d-pfU9!":OmU&bGu!$GnS0W+qc!&ssl-iei""onW+"onWo%0-CS!Z+D"#=sCH!!'J/(J(_78,rVimfF:rmg2Mj!!!!-YQb(-SH09-Y6SbA(mbG@!$EBq#UfZ]-kMjK"onW'BJ9E7680efI4,'q!!Kom!?;:D!#,V;!"9&3!!EK+!!$1&!"aJW!"]J;!/Lp`YQMZ[!!!/;Muan&!!!];!!!E3!!'eD5hHgm%.=:4!!iRQ#QOu3!!!iF!!'J4(Du<=(]XO9`s!7rT*H2=!!"48!<<*"!!U2t!@.jL!#u1C!#,V;!4WkYfEUOQ"9ni+"9ni++:S;N[g!WkV[FUI!!)0c(EebB+:%rI!*T@&&3'Xi&./C;!!"aiPl[Z_"onXn!sS`*PQM*i!,s*3!H?ga"onY)"p=pf!VAV]!!)`rB`P(4^B\HQYQ5#$!4W'5#AF1R!<?0)!LsW")#s[*").b&!Ug,)!2'?R"onXR!G;CWE&2H`!UN8q!.Y(g"onXR!G;CWE'&#h!BV8$J,sUsJ,sU^"onZ$#mLA0f4o.&BOGHQE+fg`!;m.7B]fSa$3gJ1E+]0$!Mg20!!!iJ!!!RR&/ZL+!#QP<Y?i&>"onWG5i4(7(_H`J(fBHe(_@8Z!.4tN!/CYn!#QP<kCWdPLBDAn+A2n=!5Bdn!$E*j!!!RR&/YrqO":jL"rmUS9EkIs!*T@&!+Z'8QS!%S&.h*^,S5;,!!"*X!#QP<Y8%nX-><H&lN%1i!6P<H!!'5('t=:#!Or.s\,hZlQNpF(!O)U.#=Q?.^]D4O'u0iX*!QBC\,g`.!O)UG!Hj2!O9+u8"onW+"onXR"+^IQ!2k2\J-4+&J--5\!2k2\J-2El!.KG#!2k2\J-37`J-,cO!8denJ-3OgJ--&W!4W%pi!d++02f:\\,j)?B)n"oO9$*+!Jgc\!>WZVL]NtG"onW+"onXR!t>51mi3-o"6Ti<!rr<$(DhT(T)jHE#QOkK!qH?l!!EK+!.Y.\!!)1m(OuV&"+UIR!!(=V(OuVf8:UdJ!!"[r!JgafL]MX+J,p4#0+b;l;MY>b&9\V@!Mfi&!!"-S!3cK;B)oFBYQ5=9!!EK+!3cKHJ,s=sFbg'3E*-eX!O)SkGd%3%;Qp2+!O)T;!,*hd!!!-+!!%NO%0-B`&f6'#T)jHE!!!"[E>O--QT0Kt#QOjDCk)P*U&bGu!!EK+!.Y.O!!(n?(OuUK"TX"%!s%4B(OuThJ-,cO!4Q>PJ-1RRJ--&W!;H\0!/Lf/!C6\c"9ni+J--5\!1t_WJ-5fPJ-,cO!:N]"J-2\OJ--&W!<32k!<@@`F^U"+_up8E!+H-4!!EK+!.Y.O!!)bD!>g7g[g%?b!!!"k=;QJiYAo'p#QOk/"A4=MO9(OJ"onW':V7k_S-B/t!!EK+!.Y.\!!&'M(OuVf!It7P!!)1N(OuUkH[l2(!!'2-^&\4Y!*3c<+B`(PJ,q<:!%;I[L]Ico!0@5b#AF1*!LF")!2'?8&;U>e!(UDsY6SbABU8p;!-"D."onW+"onW'IXhM#Nu/[`"1JJb!t>51Nu/[`".'4B!rr<$T3<%]"0Z6c!sel,b68peVuag@"onY<*bbTcMZO(_!,+.*!H@o<"onX*B)lUY5l^n(18FtrX8rM*!!EK+!!"7j!h]So&nq?u!mgu\!!!!DfE+<VB`R&mcOjjkkQ1`tfE)'"!d;olfE0D$;9)qg!p:IiciVPqa8ueN!4P5ta9']ia8u>A!66l3a9(gZa8uVI!'"TkE*ufKG]45p!-ebL!4r79!!(IK"onXj'+"@EJ/WqF+HRGM$ih`o"FpLU"onXR!t>51QWb2U"6Ti<!rr<$k=HJ?"4()"!sel,`%qAn!!!l:!2op2!3cJ(IBW_P0P:B!?tTIYGR+9LBI*WY!!<47!!<4?Nr`qpGX,mAJ,s%j!/LZ;!=/Z*!&f?.ZN115!!%NO%0-Cs#T&!nQNhsB!!!#nA/BauO$%pp#QOkK1V*SeYQ;'2"onW+"onXR!t>51hdmUS"31Op!rr<$hgH;k".t2HJ--&W!!#DLJ-#KI"onWFD#b+Y5d+K*O)/M1(_@8Z!;%37!!%Nk)OM#5$NpY6!.Y.\!!(>\(OuV&"b6[T!!(>\(OuThJ-,cO!/G\5J-2\hJ--&W