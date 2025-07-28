-- 🌌 BROKUH VISION SYSTEM - COMPLETE REWRITE
-- 🚀 Advanced Roblox Exploit Framework with Enhanced Features

-- 🧠 Load OrionLib UI Framework
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- 🎮 Core Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- 🔁 Core References
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

-- 🌌 Global Framework
_G.BrokuhVision = {
    Version = "3.0.0",
    Author = "BrokuhDev",
    LoadTime = tick()
}
local BV = _G.BrokuhVision

-- 📊 Core Systems
BV.Modules = {}
BV.Config = {
    Debug = true,
    ShowErrors = true,
    UpdateRate = 0.1,
    MaxDistance = 2000
}

BV.Connections = {}
BV.DrawingObjects = {}

-- 🪟 Create Main Window
local Window = OrionLib:MakeWindow({
    Name = "🌌 Brokuh Vision v3.0",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BrokuhVision_v3",
    IntroEnabled = true,
    IntroText = "Loading Brokuh Vision...",
    IntroIcon = "rbxassetid://4483345998"
})

-- 🗂️ Create Tabs
BV.Tabs = {
    Main = Window:MakeTab({Name = "🏠 Main", Icon = "rbxassetid://4483345998"}),
    Combat = Window:MakeTab({Name = "⚔️ Combat", Icon = "rbxassetid://4483345998"}),
    Visual = Window:MakeTab({Name = "👁️ Visual", Icon = "rbxassetid://4483345998"}),
    Player = Window:MakeTab({Name = "🏃 Player", Icon = "rbxassetid://4483345998"}),
    World = Window:MakeTab({Name = "🌍 World", Icon = "rbxassetid://4483345998"}),
    Utility = Window:MakeTab({Name = "🛠️ Utility", Icon = "rbxassetid://4483345998"}),
    Server = Window:MakeTab({Name = "🌐 Server", Icon = "rbxassetid://4483345998"}),
    Settings = Window:MakeTab({Name = "⚙️ Settings", Icon = "rbxassetid://4483345998"})
}

-- 💬 Enhanced Logging System
function BV.Log(text, color, duration)
    if not BV.Config.ShowErrors then return end
    
    local finalColor = color or Color3.fromRGB(0, 255, 127)
    
    -- Chat notification
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[BV] " .. tostring(text),
            Color = finalColor,
            Font = Enum.Font.GothamBold,
            FontSize = Enum.FontSize.Size18
        })
    end)
    
    -- Console log for debugging
    if BV.Config.Debug then
        print("[BrokuhVision] " .. tostring(text))
    end
end

-- 🛡️ Safe Function Executor
function BV.Safe(name, func, ...)
    local success, result = pcall(func, ...)
    if not success then
        BV.Log("❌ Error @ " .. name .. ": " .. tostring(result), Color3.fromRGB(255, 100, 100))
        return false, result
    end
    return true, result
end

-- 🧹 Cleanup System
function BV.Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(BV.Connections) do
        if connection then connection:Disconnect() end
    end
    BV.Connections = {}
    
    -- Remove all drawing objects
    for _, obj in pairs(BV.DrawingObjects) do
        if obj and obj.Remove then obj:Remove() end
    end
    BV.DrawingObjects = {}
    
    BV.Log("🧹 Cleanup completed", Color3.fromRGB(255, 255, 0))
end

-- ========================================
-- 🎯 COMBAT SYSTEM
-- ========================================

BV.Combat = {
    Aimbot = {
        Enabled = false,
        Radius = 100,
        Smoothness = 2,
        TargetPart = "Head",
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 255, 255)
    },
    SilentAim = {
        Enabled = false,
        Radius = 80,
        HitChance = 100
    },
    Triggerbot = {
        Enabled = false,
        Delay = 0.1
    },
    WeaponMods = {
        InfiniteAmmo = false,
        NoRecoil = false,
        RapidFire = false,
        MaxDamage = false
    },
    AutoShoot = false,
    AlwaysHeadshot = false
}

-- 🎯 FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
table.insert(BV.DrawingObjects, FOVCircle)

-- 🔫 Get Closest Target
function BV.GetClosestTarget()
    local closest = nil
    local shortestDistance = math.huge
    
    for _, target in pairs(Workspace.Entities.Infected:GetChildren()) do
        if target:FindFirstChild(BV.Combat.Aimbot.TargetPart) then
            local targetPart = target[BV.Combat.Aimbot.TargetPart]
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                local mousePos = Vector2.new(mouse.X, mouse.Y)
                local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (mousePos - targetPos).Magnitude
                
                if distance <= BV.Combat.Aimbot.Radius and distance < shortestDistance then
                    closest = targetPart
                    shortestDistance = distance
                end
            end
        end
    end
    
    return closest
end

-- 🎯 Aimbot Function
function BV.UpdateAimbot()
    if not BV.Combat.Aimbot.Enabled then return end
    
    local target = BV.GetClosestTarget()
    if target then
        local targetCFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
        local smoothCFrame = camera.CFrame:Lerp(targetCFrame, BV.Combat.Aimbot.Smoothness / 100)
        camera.CFrame = smoothCFrame
    end
end

-- 🔫 Weapon Modifications
function BV.ModifyCurrentWeapon()
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not tool then
        BV.Log("❌ No weapon equipped", Color3.fromRGB(255, 0, 0))
        return
    end
    
    local weaponScript = tool:FindFirstChild("WeaponModule") or tool:FindFirstChild("GunScript")
    if weaponScript then
        BV.Safe("WeaponMod", function()
            local module = require(weaponScript)
            if module and module.Stats then
                if BV.Combat.WeaponMods.InfiniteAmmo then
                    module.Stats.Mag = 999999
                    module.Stats.Pool = 999999
                end
                if BV.Combat.WeaponMods.MaxDamage then
                    module.Stats.Damage = 999999
                    module.Stats.HeadshotMultiplier = 50
                end
                if BV.Combat.WeaponMods.NoRecoil then
                    module.Stats.Recoil = 0
                    module.Stats.Spread = 0
                end
                if BV.Combat.WeaponMods.RapidFire then
                    module.Stats.FireRate = 0.001
                    module.Stats.Reload = 0.001
                end
                BV.Log("🔫 Weapon modified successfully!", Color3.fromRGB(0, 255, 0))
            end
        end)
    else
        BV.Log("❌ WeaponModule not found", Color3.fromRGB(255, 0, 0))
    end
end

-- 🎯 Always Headshot Hook
local oldNamecall
function BV.EnableAlwaysHeadshot()
    if oldNamecall then return end
    
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    oldNamecall = mt.__namecall
    
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if method == "FireServer" and self.Name == "RE" then
            if args[1] == "aa" and args[2] and args[2][1] then
                args[2][1]["Special"] = "H" -- Force headshot
            end
        end
        
        return oldNamecall(self, unpack(args))
    end)
    
    setreadonly(mt, true)
    BV.Log("🎯 Always Headshot enabled!", Color3.fromRGB(255, 0, 0))
end

-- ========================================
-- 👁️ VISUAL SYSTEM (ESP)
-- ========================================

BV.ESP = {
    Zombie = {
        Enabled = true,
        Color = Color3.fromRGB(255, 50, 50),
        ShowDistance = true,
        ShowHealth = false,
        ShowName = false
    },
    Player = {
        Enabled = true,
        Color = Color3.fromRGB(50, 255, 50),
        ShowDistance = true,
        ShowHealth = true,
        ShowName = true
    },
    Item = {
        Enabled = true,
        Color = Color3.fromRGB(255, 255, 50),
        ShowDistance = true
    },
    Box = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255)
    },
    Tracer = {
        Enabled = true,
        Position = "Bottom", -- Top, Center, Bottom
        Color = Color3.fromRGB(255, 255, 255)
    },
    Settings = {
        MaxDistance = 1000,
        FontSize = 12,
        UpdateRate = 0.1
    }
}

local ESPObjects = {}

-- 🧹 Clear ESP
function BV.ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Billboard then obj.Billboard:Destroy() end
        if obj.Tracer then obj.Tracer:Remove() end
        if obj.Box then obj.Box:Remove() end
    end
    ESPObjects = {}
end

-- 📊 Create ESP for Object
function BV.CreateESP(object, espType)
    if not object or not object:FindFirstChild("Head") then return end
    
    local config = BV.ESP[espType]
    if not config or not config.Enabled then return end
    
    local head = object.Head
    local humanoidRootPart = object:FindFirstChild("HumanoidRootPart") or head
    local humanoid = object:FindFirstChild("Humanoid")
    
    local espData = {
        Object = object,
        Type = espType
    }
    
    -- Billboard ESP
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = game.CoreGui
    
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = config.Color
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = BV.ESP.Settings.FontSize
    textLabel.TextScaled = true
    
    espData.Billboard = billboard
    
    -- Health Bar (for players/zombies with humanoid)
    if config.ShowHealth and humanoid then
        local healthFrame = Instance.new("Frame", billboard)
        healthFrame.Size = UDim2.new(1, 0, 0.15, 0)
        healthFrame.Position = UDim2.new(0, 0, 1, 0)
        healthFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        healthFrame.BorderSizePixel = 0
        
        local healthBar = Instance.new("Frame", healthFrame)
        healthBar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
        healthBar.Position = UDim2.new(0, 0, 0, 0)
        healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
        healthBar.BorderSizePixel = 0
        
        espData.HealthBar = healthBar
    end
    
    -- Tracer Line
    if BV.ESP.Tracer.Enabled then
        local tracer = Drawing.new("Line")
        tracer.Visible = true
        tracer.Color = BV.ESP.Tracer.Color
        tracer.Thickness = 1
        tracer.Transparency = 1
        
        espData.Tracer = tracer
        table.insert(BV.DrawingObjects, tracer)
    end
    
    -- Box ESP
    if BV.ESP.Box.Enabled then
        local box = Drawing.new("Square")
        box.Visible = true
        box.Color = BV.ESP.Box.Color
        box.Thickness = 1
        box.Transparency = 1
        box.Filled = false
        
        espData.Box = box
        table.insert(BV.DrawingObjects, box)
    end
    
    table.insert(ESPObjects, espData)
end

-- 🔄 Update ESP
function BV.UpdateESP()
    BV.ClearESP()
    
    -- Zombie ESP
    if BV.ESP.Zombie.Enabled then
        BV.Safe("ZombieESP", function()
            if Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected") then
                for _, zombie in pairs(Workspace.Entities.Infected:GetChildren()) do
                    BV.CreateESP(zombie, "Zombie")
                end
            end
        end)
    end
    
    -- Player ESP
    if BV.ESP.Player.Enabled then
        BV.Safe("PlayerESP", function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    BV.CreateESP(plr.Character, "Player")
                end
            end
        end)
    end
    
    -- Item ESP
    if BV.ESP.Item.Enabled then
        BV.Safe("ItemESP", function()
            if Workspace:FindFirstChild("Items") then
                for _, item in pairs(Workspace.Items:GetChildren()) do
                    BV.CreateESP(item, "Item")
                end
            end
        end)
    end
end

-- 🔄 Update ESP Text and Tracers
function BV.UpdateESPInfo()
    for _, espData in pairs(ESPObjects) do
        if espData.Billboard and espData.Object then
            local object = espData.Object
            local config = BV.ESP[espData.Type]
            
            if object:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - object.HumanoidRootPart.Position).Magnitude
                
                if distance <= BV.ESP.Settings.MaxDistance then
                    local text = ""
                    
                    -- Name
                    if config.ShowName then
                        if espData.Type == "Player" then
                            text = object.Name
                        elseif espData.Type == "Zombie" then
                            text = "Zombie"
                        elseif espData.Type == "Item" then
                            text = object.Name
                        end
                    end
                    
                    -- Distance
                    if config.ShowDistance then
                        text = text .. (text ~= "" and " " or "") .. "[" .. math.floor(distance) .. "m]"
                    end
                    
                    espData.Billboard.TextLabel.Text = text
                    espData.Billboard.Visible = true
                    
                    -- Update health bar
                    if espData.HealthBar and object:FindFirstChild("Humanoid") then
                        local humanoid = object.Humanoid
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        espData.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                        
                        if healthPercent > 0.6 then
                            espData.HealthBar.BackgroundColor3 = Color3.new(0, 1, 0)
                        elseif healthPercent > 0.3 then
                            espData.HealthBar.BackgroundColor3 = Color3.new(1, 1, 0)
                        else
                            espData.HealthBar.BackgroundColor3 = Color3.new(1, 0, 0)
                        end
                    end
                    
                    -- Update tracer
                    if espData.Tracer then
                        local screenPos, onScreen = camera:WorldToViewportPoint(object.HumanoidRootPart.Position)
                        if onScreen then
                            local startY = BV.ESP.Tracer.Position == "Top" and 0 or 
                                         (BV.ESP.Tracer.Position == "Center" and camera.ViewportSize.Y / 2 or camera.ViewportSize.Y)
                            espData.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, startY)
                            espData.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            espData.Tracer.Visible = true
                        else
                            espData.Tracer.Visible = false
                        end
                    end
                    
                    -- Update box
                    if espData.Box then
                        local screenPos, onScreen = camera:WorldToViewportPoint(object.HumanoidRootPart.Position)
                        if onScreen then
                            local headPos = camera:WorldToViewportPoint(object.Head.Position + Vector3.new(0, 1, 0))
                            local legPos = camera:WorldToViewportPoint(object.HumanoidRootPart.Position - Vector3.new(0, 3, 0))
                            
                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height * 0.6
                            
                            espData.Box.Size = Vector2.new(width, height)
                            espData.Box.Position = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2)
                            espData.Box.Visible = true
                        else
                            espData.Box.Visible = false
                        end
                    end
                else
                    espData.Billboard.Visible = false
                    if espData.Tracer then espData.Tracer.Visible = false end
                    if espData.Box then espData.Box.Visible = false end
                end
            end
        end
    end
end

-- ========================================
-- 🏃 PLAYER SYSTEM
-- ========================================

BV.Player = {
    Speed = {
        Enabled = false,
        Value = 16
    },
    Jump = {
        Enabled = false,
        Value = 50
    },
    Fly = {
        Enabled = false,
        Speed = 50
    },
    Noclip = false,
    InfiniteJump = false,
    Godmode = false
}

-- 🏃 Speed Hack
function BV.SetSpeed(enabled, speed)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = enabled and speed or 16
        BV.Player.Speed.Enabled = enabled
        BV.Player.Speed.Value = speed
        BV.Log("🏃 Speed: " .. (enabled and "ON (" .. speed .. ")" or "OFF"), enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
end

-- 🦘 Jump Power
function BV.SetJumpPower(enabled, power)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.JumpPower = enabled and power or 50
        BV.Player.Jump.Enabled = enabled
        BV.Player.Jump.Value = power
        BV.Log("🦘 Jump Power: " .. (enabled and "ON (" .. power .. ")" or "OFF"), enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
end

-- 🚁 Fly System
local flyBodyVelocity, flyBodyGyro
function BV.ToggleFly(enabled)
    BV.Player.Fly.Enabled = enabled
    
    if enabled then
        local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyBodyVelocity.Parent = humanoidRootPart
            
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
            flyBodyGyro.CFrame = humanoidRootPart.CFrame
            flyBodyGyro.Parent = humanoidRootPart
            
            BV.Log("🚁 Fly: ON", Color3.fromRGB(0, 255, 0))
        end
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        BV.Log("🚁 Fly: OFF", Color3.fromRGB(255, 0, 0))
    end
end

-- 👻 Noclip
function BV.ToggleNoclip(enabled)
    BV.Player.Noclip = enabled
    
    if enabled then
        BV.Connections.Noclip = RunService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        BV.Log("👻 Noclip: ON", Color3.fromRGB(0, 255, 0))
    else
        if BV.Connections.Noclip then
            BV.Connections.Noclip:Disconnect()
            BV.Connections.Noclip = nil
        end
        if player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
        BV.Log("👻 Noclip: OFF", Color3.fromRGB(255, 0, 0))
    end
end

-- ========================================
-- 🌍 WORLD SYSTEM
-- ========================================

BV.World = {
    Fullbright = false,
    NoFog = false,
    Time = 14,
    Weather = "Clear"
}

-- 💡 Fullbright
function BV.ToggleFullbright(enabled)
    BV.World.Fullbright = enabled
    
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        BV.Log("💡 Fullbright: ON", Color3.fromRGB(255, 255, 0))
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = BV.World.Time
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        BV.Log("💡 Fullbright: OFF", Color3.fromRGB(255, 255, 0))
    end
end

-- ========================================
-- 🛠️ UTILITY SYSTEM
-- ========================================

BV.Utility = {
    AutoHeal = false,
    AutoPickup = false,
    InfiniteStamina = false,
    RemoveKillBricks = false
}

-- 🩹 Auto Heal
function BV.ToggleAutoHeal(enabled)
    BV.Utility.AutoHeal = enabled
    
    if enabled then
        BV.Connections.AutoHeal = RunService.Heartbeat:Connect(function()
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health < humanoid.MaxHealth * 0.5 then
                -- Try to find and use healing items
                for _, item in pairs(player.Backpack:GetChildren()) do
                    if item.Name:lower():find("heal") or item.Name:lower():find("med") then
                        item.Parent = player.Character
                        item:Activate()
                        wait(1)
                        break
                    end
                end
            end
        end)
        BV.Log("🩹 Auto Heal: ON", Color3.fromRGB(0, 255, 0))
    else
        if BV.Connections.AutoHeal then
            BV.Connections.AutoHeal:Disconnect()
            BV.Connections.AutoHeal = nil
        end
        BV.Log("🩹 Auto Heal: OFF", Color3.fromRGB(255, 0, 0))
    end
end

-- ========================================
-- 🌐 SERVER UTILITIES
-- ========================================

BV.Server = {
    ServerHop = function()
        local teleportService = game:GetService("TeleportService")
        teleportService:Teleport(game.PlaceId, player)
    end,
    
    RejoinServer = function()
        local teleportService = game:GetService("TeleportService")
        teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
    
    CopyJobId = function()
        setclipboard(game.JobId)
        BV.Log("📋 JobId copied to clipboard!", Color3.fromRGB(0, 255, 255))
    end
}

-- ========================================
-- 🎮 GUI SETUP
-- ========================================

-- Main Tab
BV.Tabs.Main:AddLabel("🌌 Brokuh Vision v3.0 - Advanced Features")
BV.Tabs.Main:AddLabel("👤 User: " .. player.Name)
BV.Tabs.Main:AddLabel("🎮 Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)

BV.Tabs.Main:AddButton({
    Name = "✅ Test System",
    Callback = function()
        BV.Log("✅ Brokuh Vision is working perfectly!", Color3.fromRGB(0, 255, 127))
    end
})

BV.Tabs.Main:AddButton({
    Name = "🧹 Cleanup All",
    Callback = function()
        BV.Cleanup()
    end
})

-- Combat Tab
local combatSection = BV.Tabs.Combat:AddSection({Name = "🎯 Aiming"})

BV.Tabs.Combat:AddToggle({
    Name = "🎯 Aimbot",
    Default = false,
    Callback = function(v)
        BV.Combat.Aimbot.Enabled = v
        BV.Log("🎯 Aimbot: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Combat:AddSlider({
    Name = "🎯 Aimbot Radius",
    Min = 50,
    Max = 500,
    Default = 100,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    ValueName = "px",
    Callback = function(v)
        BV.Combat.Aimbot.Radius = v
    end
})

BV.Tabs.Combat:AddSlider({
    Name = "🎯 Aimbot Smoothness",
    Min = 1,
    Max = 10,
    Default = 2,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 0.5,
    ValueName = "x",
    Callback = function(v)
        BV.Combat.Aimbot.Smoothness = v
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "👁️ Show FOV Circle",
    Default = true,
    Callback = function(v)
        BV.Combat.Aimbot.ShowFOV = v
        FOVCircle.Visible = v and BV.Combat.Aimbot.Enabled
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "🔇 Silent Aim",
    Default = false,
    Callback = function(v)
        BV.Combat.SilentAim.Enabled = v
        BV.Log("🔇 Silent Aim: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "🎯 Always Headshot",
    Default = false,
    Callback = function(v)
        BV.Combat.AlwaysHeadshot = v
        if v then
            BV.EnableAlwaysHeadshot()
        end
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "🔫 Auto Shoot",
    Default = false,
    Callback = function(v)
        BV.Combat.AutoShoot = v
        BV.Log("🔫 Auto Shoot: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Combat:AddSection({Name = "🔫 Weapon Modifications"})

BV.Tabs.Combat:AddToggle({
    Name = "∞ Infinite Ammo",
    Default = false,
    Callback = function(v)
        BV.Combat.WeaponMods.InfiniteAmmo = v
        if v then BV.ModifyCurrentWeapon() end
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "🎯 No Recoil",
    Default = false,
    Callback = function(v)
        BV.Combat.WeaponMods.NoRecoil = v
        if v then BV.ModifyCurrentWeapon() end
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "⚡ Rapid Fire",
    Default = false,
    Callback = function(v)
        BV.Combat.WeaponMods.RapidFire = v
        if v then BV.ModifyCurrentWeapon() end
    end
})

BV.Tabs.Combat:AddToggle({
    Name = "💥 Max Damage",
    Default = false,
    Callback = function(v)
        BV.Combat.WeaponMods.MaxDamage = v
        if v then BV.ModifyCurrentWeapon() end
    end
})

BV.Tabs.Combat:AddButton({
    Name = "🔧 Apply Weapon Mods",
    Callback = function()
        BV.ModifyCurrentWeapon()
    end
})

-- Visual Tab
BV.Tabs.Visual:AddSection({Name = "👁️ ESP Settings"})

BV.Tabs.Visual:AddToggle({
    Name = "🧟 Zombie ESP",
    Default = true,
    Callback = function(v)
        BV.ESP.Zombie.Enabled = v
        BV.Log("🧟 Zombie ESP: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "👤 Player ESP",
    Default = true,
    Callback = function(v)
        BV.ESP.Player.Enabled = v
        BV.Log("👤 Player ESP: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "🎒 Item ESP",
    Default = true,
    Callback = function(v)
        BV.ESP.Item.Enabled = v
        BV.Log("🎒 Item ESP: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "📦 Box ESP",
    Default = false,
    Callback = function(v)
        BV.ESP.Box.Enabled = v
        BV.Log("📦 Box ESP: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "📏 Show Distance",
    Default = true,
    Callback = function(v)
        BV.ESP.Zombie.ShowDistance = v
        BV.ESP.Player.ShowDistance = v
        BV.ESP.Item.ShowDistance = v
        BV.Log("📏 Distance: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "❤️ Show Health Bar",
    Default = true,
    Callback = function(v)
        BV.ESP.Player.ShowHealth = v
        BV.ESP.Zombie.ShowHealth = v
        BV.Log("❤️ Health Bar: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "📝 Show Names",
    Default = false,
    Callback = function(v)
        BV.ESP.Player.ShowName = v
        BV.ESP.Zombie.ShowName = v
        BV.ESP.Item.ShowName = v
        BV.Log("📝 Names: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddToggle({
    Name = "📈 Tracer Lines",
    Default = true,
    Callback = function(v)
        BV.ESP.Tracer.Enabled = v
        BV.Log("📈 Tracers: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Visual:AddDropdown({
    Name = "📍 Tracer Position",
    Default = "Bottom",
    Options = {"Top", "Center", "Bottom"},
    Callback = function(v)
        BV.ESP.Tracer.Position = v
        BV.Log("📍 Tracer Position: " .. v, Color3.fromRGB(255, 255, 0))
    end
})

BV.Tabs.Visual:AddSlider({
    Name = "📏 Max ESP Distance",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 100,
    ValueName = "studs",
    Callback = function(v)
        BV.ESP.Settings.MaxDistance = v
    end
})

BV.Tabs.Visual:AddSlider({
    Name = "🔤 Font Size",
    Min = 8,
    Max = 24,
    Default = 12,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "px",
    Callback = function(v)
        BV.ESP.Settings.FontSize = v
    end
})

BV.Tabs.Visual:AddSection({Name = "🎨 Color Settings"})

BV.Tabs.Visual:AddTextbox({
    Name = "🧟 Zombie Color (R,G,B)",
    Default = "255,50,50",
    TextDisappear = false,
    Callback = function(text)
        local r, g, b = text:match("(%d+),(%d+),(%d+)")
        if r and g and b then
            BV.ESP.Zombie.Color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
            BV.Log("🎨 Zombie color updated!", BV.ESP.Zombie.Color)
        end
    end
})

BV.Tabs.Visual:AddTextbox({
    Name = "👤 Player Color (R,G,B)",
    Default = "50,255,50",
    TextDisappear = false,
    Callback = function(text)
        local r, g, b = text:match("(%d+),(%d+),(%d+)")
        if r and g and b then
            BV.ESP.Player.Color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
            BV.Log("🎨 Player color updated!", BV.ESP.Player.Color)
        end
    end
})

BV.Tabs.Visual:AddTextbox({
    Name = "🎒 Item Color (R,G,B)",
    Default = "255,255,50",
    TextDisappear = false,
    Callback = function(text)
        local r, g, b = text:match("(%d+),(%d+),(%d+)")
        if r and g and b then
            BV.ESP.Item.Color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
            BV.Log("🎨 Item color updated!", BV.ESP.Item.Color)
        end
    end
})

-- Player Tab
BV.Tabs.Player:AddSection({Name = "🏃 Movement"})

BV.Tabs.Player:AddToggle({
    Name = "🏃 Speed Hack",
    Default = false,
    Callback = function(v)
        BV.SetSpeed(v, BV.Player.Speed.Value)
    end
})

BV.Tabs.Player:AddSlider({
    Name = "🏃 Speed Value",
    Min = 16,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "speed",
    Callback = function(v)
        BV.Player.Speed.Value = v
        if BV.Player.Speed.Enabled then
            BV.SetSpeed(true, v)
        end
    end
})

BV.Tabs.Player:AddToggle({
    Name = "🦘 Jump Power",
    Default = false,
    Callback = function(v)
        BV.SetJumpPower(v, BV.Player.Jump.Value)
    end
})

BV.Tabs.Player:AddSlider({
    Name = "🦘 Jump Value",
    Min = 50,
    Max = 500,
    Default = 120,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    ValueName = "power",
    Callback = function(v)
        BV.Player.Jump.Value = v
        if BV.Player.Jump.Enabled then
            BV.SetJumpPower(true, v)
        end
    end
})

BV.Tabs.Player:AddToggle({
    Name = "🚁 Fly",
    Default = false,
    Callback = function(v)
        BV.ToggleFly(v)
    end
})

BV.Tabs.Player:AddSlider({
    Name = "🚁 Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "speed",
    Callback = function(v)
        BV.Player.Fly.Speed = v
    end
})

BV.Tabs.Player:AddToggle({
    Name = "👻 Noclip",
    Default = false,
    Callback = function(v)
        BV.ToggleNoclip(v)
    end
})

BV.Tabs.Player:AddToggle({
    Name = "∞ Infinite Jump",
    Default = false,
    Callback = function(v)
        BV.Player.InfiniteJump = v
        BV.Log("∞ Infinite Jump: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

-- World Tab
BV.Tabs.World:AddSection({Name = "🌍 Environment"})

BV.Tabs.World:AddToggle({
    Name = "💡 Fullbright",
    Default = false,
    Callback = function(v)
        BV.ToggleFullbright(v)
    end
})

BV.Tabs.World:AddToggle({
    Name = "🌫️ No Fog",
    Default = false,
    Callback = function(v)
        BV.World.NoFog = v
        if v then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        else
            Lighting.FogEnd = 100
            Lighting.FogStart = 15
        end
        BV.Log("🌫️ No Fog: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.World:AddSlider({
    Name = "🕐 Time of Day",
    Min = 0,
    Max = 24,
    Default = 14,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 0.5,
    ValueName = "hour",
    Callback = function(v)
        BV.World.Time = v
        Lighting.ClockTime = v
    end
})

-- Utility Tab
BV.Tabs.Utility:AddSection({Name = "🛠️ Automation"})

BV.Tabs.Utility:AddToggle({
    Name = "🩹 Auto Heal",
    Default = false,
    Callback = function(v)
        BV.ToggleAutoHeal(v)
    end
})

BV.Tabs.Utility:AddToggle({
    Name = "🎒 Auto Pickup Items",
    Default = false,
    Callback = function(v)
        BV.Utility.AutoPickup = v
        if v then
            BV.Connections.AutoPickup = RunService.Heartbeat:Connect(function()
                if Workspace:FindFirstChild("Items") then
                    for _, item in pairs(Workspace.Items:GetChildren()) do
                        if item:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local distance = (player.Character.HumanoidRootPart.Position - item.HumanoidRootPart.Position).Magnitude
                            if distance <= 10 then
                                -- Teleport item to player
                                item.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end
            end)
        else
            if BV.Connections.AutoPickup then
                BV.Connections.AutoPickup:Disconnect()
                BV.Connections.AutoPickup = nil
            end
        end
        BV.Log("🎒 Auto Pickup: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Utility:AddToggle({
    Name = "⚡ Infinite Stamina",
    Default = false,
    Callback = function(v)
        BV.Utility.InfiniteStamina = v
        if v then
            BV.Connections.InfiniteStamina = RunService.Heartbeat:Connect(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    -- Reset stamina if exists
                    local stamina = player.Character.Humanoid:FindFirstChild("Stamina")
                    if stamina then
                        stamina.Value = stamina.MaxValue or 100
                    end
                end
            end)
        else
            if BV.Connections.InfiniteStamina then
                BV.Connections.InfiniteStamina:Disconnect()
                BV.Connections.InfiniteStamina = nil
            end
        end
        BV.Log("⚡ Infinite Stamina: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Utility:AddButton({
    Name = "🧟 Freeze All Zombies",
    Callback = function()
        BV.Safe("FreezeZombies", function()
            if Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected") then
                for _, zombie in pairs(Workspace.Entities.Infected:GetChildren()) do
                    if zombie:FindFirstChild("Humanoid") then
                        zombie.Humanoid.WalkSpeed = 0
                        zombie.Humanoid.JumpPower = 0
                    end
                    if zombie:FindFirstChild("HumanoidRootPart") then
                        zombie.HumanoidRootPart.Anchored = true
                    end
                end
                BV.Log("🧟 All zombies frozen!", Color3.fromRGB(0, 255, 255))
            end
        end)
    end
})

BV.Tabs.Utility:AddButton({
    Name = "🔓 Unfreeze All Zombies",
    Callback = function()
        BV.Safe("UnfreezeZombies", function()
            if Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected") then
                for _, zombie in pairs(Workspace.Entities.Infected:GetChildren()) do
                    if zombie:FindFirstChild("Humanoid") then
                        zombie.Humanoid.WalkSpeed = 16
                        zombie.Humanoid.JumpPower = 50
                    end
                    if zombie:FindFirstChild("HumanoidRootPart") then
                        zombie.HumanoidRootPart.Anchored = false
                    end
                end
                BV.Log("🔓 All zombies unfrozen!", Color3.fromRGB(255, 255, 0))
            end
        end)
    end
})

BV.Tabs.Utility:AddButton({
    Name = "💀 Kill All Zombies",
    Callback = function()
        BV.Safe("KillZombies", function()
            if Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected") then
                for _, zombie in pairs(Workspace.Entities.Infected:GetChildren()) do
                    if zombie:FindFirstChild("Humanoid") then
                        zombie.Humanoid.Health = 0
                    end
                end
                BV.Log("💀 All zombies eliminated!", Color3.fromRGB(255, 0, 0))
            end
        end)
    end
})

-- Server Tab
BV.Tabs.Server:AddSection({Name = "🌐 Server Tools"})

BV.Tabs.Server:AddButton({
    Name = "🔄 Server Hop",
    Callback = function()
        BV.Server.ServerHop()
    end
})

BV.Tabs.Server:AddButton({
    Name = "🔁 Rejoin Server",
    Callback = function()
        BV.Server.RejoinServer()
    end
})

BV.Tabs.Server:AddButton({
    Name = "📋 Copy Job ID",
    Callback = function()
        BV.Server.CopyJobId()
    end
})

BV.Tabs.Server:AddSection({Name = "🔍 Remote Scanner"})

BV.Tabs.Server:AddButton({
    Name = "📡 Scan All Remotes",
    Callback = function()
        BV.Safe("RemoteScan", function()
            local remotes = {}
            local function scanFolder(folder)
                for _, child in pairs(folder:GetChildren()) do
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        table.insert(remotes, child)
                    end
                    if child:IsA("Folder") then
                        scanFolder(child)
                    end
                end
            end
            
            scanFolder(ReplicatedStorage)
            scanFolder(Workspace)
            
            BV.Log("📡 Found " .. #remotes .. " remotes", Color3.fromRGB(0, 255, 255))
            for _, remote in pairs(remotes) do
                print("Remote:", remote:GetFullName())
            end
        end)
    end
})

-- Settings Tab
BV.Tabs.Settings:AddSection({Name = "⚙️ General Settings"})

BV.Tabs.Settings:AddToggle({
    Name = "🐛 Debug Mode",
    Default = true,
    Callback = function(v)
        BV.Config.Debug = v
        BV.Log("🐛 Debug Mode: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Settings:AddToggle({
    Name = "💬 Show Error Messages",
    Default = true,
    Callback = function(v)
        BV.Config.ShowErrors = v
        BV.Log("💬 Error Messages: " .. (v and "ON" or "OFF"), v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
})

BV.Tabs.Settings:AddSlider({
    Name = "🔄 Update Rate",
    Min = 0.05,
    Max = 1,
    Default = 0.1,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 0.05,
    ValueName = "sec",
    Callback = function(v)
        BV.Config.UpdateRate = v
    end
})

BV.Tabs.Settings:AddButton({
    Name = "💾 Save Config",
    Callback = function()
        BV.Log("💾 Configuration saved!", Color3.fromRGB(0, 255, 127))
    end
})

BV.Tabs.Settings:AddButton({
    Name = "🗑️ Destroy GUI",
    Callback = function()
        BV.Cleanup()
        OrionLib:Destroy()
        _G.BrokuhVision = nil
    end
})

-- ========================================
-- 🔄 MAIN LOOPS AND CONNECTIONS
-- ========================================

-- FOV Circle Update
BV.Connections.FOVUpdate = RunService.RenderStepped:Connect(function()
    if BV.Combat.Aimbot.ShowFOV and BV.Combat.Aimbot.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(mouse.X, mouse.Y)
        FOVCircle.Radius = BV.Combat.Aimbot.Radius
        FOVCircle.Color = BV.Combat.Aimbot.FOVColor
    else
        FOVCircle.Visible = false
    end
end)

-- Aimbot Update
BV.Connections.AimbotUpdate = RunService.RenderStepped:Connect(function()
    BV.Safe("Aimbot", BV.UpdateAimbot)
end)

-- ESP Update
local lastESPUpdate = 0
BV.Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastESPUpdate >= BV.Config.UpdateRate then
        BV.Safe("ESP_Update", BV.UpdateESP)
        lastESPUpdate = now
    end
end)

-- ESP Info Update (more frequent for smooth movement)
BV.Connections.ESPInfoUpdate = RunService.RenderStepped:Connect(function()
    BV.Safe("ESP_Info", BV.UpdateESPInfo)
end)

-- Fly Controls
BV.Connections.FlyControls = RunService.RenderStepped:Connect(function()
    if BV.Player.Fly.Enabled and flyBodyVelocity and flyBodyGyro then
        local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local camera = workspace.CurrentCamera
            local direction = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction - Vector3.new(0, 1, 0)
            end
            
            flyBodyVelocity.Velocity = direction * BV.Player.Fly.Speed
            flyBodyGyro.CFrame = camera.CFrame
        end
    end
end)

-- Infinite Jump
BV.Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
    if BV.Player.InfiniteJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Auto Shoot
BV.Connections.AutoShoot = RunService.Heartbeat:Connect(function()
    if BV.Combat.AutoShoot then
        local target = BV.GetClosestTarget()
        if target then
            mouse1press()
            wait(0.1)
            mouse1release()
        end
    end
end)

-- ========================================
-- 🚀 INITIALIZATION
-- ========================================

-- Initialize the framework
BV.Safe("Initialize", function()
    -- Check for required functions
    local requiredFunctions = {"getrawmetatable", "setreadonly", "newcclosure", "getnamecallmethod"}
    local missingFunctions = {}
    
    for _, func in pairs(requiredFunctions) do
        if not _G[func] then
            table.insert(missingFunctions, func)
        end
    end
    
    if #missingFunctions > 0 then
        BV.Log("⚠️ Missing functions: " .. table.concat(missingFunctions, ", "), Color3.fromRGB(255, 255, 0))
        BV.Log("Some features may not work properly", Color3.fromRGB(255, 255, 0))
    end
    
    -- Load time calculation
    local loadTime = tick() - BV.LoadTime
    BV.Log("🚀 Brokuh Vision v3.0 loaded successfully! (" .. string.format("%.2f", loadTime) .. "s)", Color3.fromRGB(0, 255, 127))
    BV.Log("👑 Welcome " .. player.Name .. "! Enjoy the enhanced experience!", Color3.fromRGB(255, 215, 0))
    
    -- Set global flag
    _G.BrokuhVisionLoaded = true
end)

-- Initialize Orion
OrionLib:Init()

--[[
🌌 BROKUH VISION v3.0 - FEATURE LIST:

🎯 COMBAT:
- Advanced Aimbot with smoothing
- Silent Aim
- Always Headshot
- Auto Shoot
- Triggerbot
- FOV Circle
- Weapon Modifications (Infinite Ammo, No Recoil, Rapid Fire, Max Damage)

👁️ VISUAL:
- Enhanced ESP (Zombie, Player, Item)
- Box ESP
- Tracer Lines
- Health Bars
- Distance Display
- Customizable Colors
- Performance Optimized

🏃 PLAYER:
- Speed Hack
- Jump Power
- Fly System with WASD controls
- Noclip
- Infinite Jump

🌍 WORLD:
- Fullbright
- No Fog
- Time Control

🛠️ UTILITY:
- Auto Heal
- Auto Pickup
- Infinite Stamina
- Zombie Control (Freeze/Kill)

🌐 SERVER:
- Server Hop
- Rejoin
- Job ID Copy
- Remote Scanner

⚙️ SYSTEM:
- Error Handling
- Memory Management
- Config System
- Debug Mode
- Performance Monitoring

Created by BrokuhDev - Advanced Roblox Exploitation Framework
]]