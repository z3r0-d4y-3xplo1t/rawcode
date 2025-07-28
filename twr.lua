-- 🌌 BROKUH VISION SYSTEM - DELTA COMPATIBLE REWRITE
-- 🚀 Advanced Roblox Exploit Framework with Enhanced Features (Delta Supported)

-- 🧠 Load OrionLib UI Framework (Delta compatible)
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
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[BV] " .. tostring(text),
            Color = finalColor,
            Font = Enum.Font.GothamBold,
            FontSize = Enum.FontSize.Size18
        })
    end)
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
    for _, connection in pairs(BV.Connections) do
        if connection then connection:Disconnect() end
    end
    BV.Connections = {}
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

-- 🎯 FOV Circle (Delta: Drawing API)
local Drawing = Drawing or getgenv().Drawing
local FOVCircle = Drawing and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Visible = false
    FOVCircle.Filled = false
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    table.insert(BV.DrawingObjects, FOVCircle)
end

-- 🔫 Get Closest Target
function BV.GetClosestTarget()
    local closest = nil
    local shortestDistance = math.huge
    local infectedFolder = Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected")
    if not infectedFolder then return nil end
    for _, target in pairs(infectedFolder:GetChildren()) do
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

-- 🎯 Always Headshot Hook (Delta compatible)
-- Delta does NOT support getrawmetatable/setreadonly/newcclosure/getnamecallmethod natively.
-- So this feature will be disabled unless Delta supports it via its environment.
BV.EnableAlwaysHeadshot = function()
    BV.Log("🎯 Always Headshot is not supported on Delta. (missing metatable patching functions)", Color3.fromRGB(255, 200, 0))
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
        Position = "Bottom",
        Color = Color3.fromRGB(255, 255, 255)
    },
    Settings = {
        MaxDistance = 1000,
        FontSize = 12,
        UpdateRate = 0.1
    }
}

local ESPObjects = {}

function BV.ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Billboard then obj.Billboard:Destroy() end
        if obj.Tracer and obj.Tracer.Remove then obj.Tracer:Remove() end
        if obj.Box and obj.Box.Remove then obj.Box:Remove() end
    end
    ESPObjects = {}
end

function BV.CreateESP(object, espType)
    if not object or not object:FindFirstChild("Head") then return end
    local config = BV.ESP[espType]
    if not config or not config.Enabled then return end
    local head = object.Head
    local humanoidRootPart = object:FindFirstChild("HumanoidRootPart") or head
    local humanoid = object:FindFirstChild("Humanoid")
    local espData = { Object = object, Type = espType }
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
    -- Health Bar
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
    if Drawing and BV.ESP.Tracer.Enabled then
        local tracer = Drawing.new("Line")
        tracer.Visible = true
        tracer.Color = BV.ESP.Tracer.Color
        tracer.Thickness = 1
        tracer.Transparency = 1
        espData.Tracer = tracer
        table.insert(BV.DrawingObjects, tracer)
    end
    -- Box ESP
    if Drawing and BV.ESP.Box.Enabled then
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

function BV.UpdateESP()
    BV.ClearESP()
    local infectedFolder = Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected")
    if BV.ESP.Zombie.Enabled and infectedFolder then
        BV.Safe("ZombieESP", function()
            for _, zombie in pairs(infectedFolder:GetChildren()) do
                BV.CreateESP(zombie, "Zombie")
            end
        end)
    end
    if BV.ESP.Player.Enabled then
        BV.Safe("PlayerESP", function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    BV.CreateESP(plr.Character, "Player")
                end
            end
        end)
    end
    if BV.ESP.Item.Enabled and Workspace:FindFirstChild("Items") then
        BV.Safe("ItemESP", function()
            for _, item in pairs(Workspace.Items:GetChildren()) do
                BV.CreateESP(item, "Item")
            end
        end)
    end
end

function BV.UpdateESPInfo()
    for _, espData in pairs(ESPObjects) do
        if espData.Billboard and espData.Object then
            local object = espData.Object
            local config = BV.ESP[espData.Type]
            if object:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - object.HumanoidRootPart.Position).Magnitude
                if distance <= BV.ESP.Settings.MaxDistance then
                    local text = ""
                    if config.ShowName then
                        if espData.Type == "Player" then
                            text = object.Name
                        elseif espData.Type == "Zombie" then
                            text = "Zombie"
                        elseif espData.Type == "Item" then
                            text = object.Name
                        end
                    end
                    if config.ShowDistance then
                        text = text .. (text ~= "" and " " or "") .. "[" .. math.floor(distance) .. "m]"
                    end
                    espData.Billboard.TextLabel.Text = text
                    espData.Billboard.Visible = true
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
                    if Drawing and espData.Tracer then
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
                    if Drawing and espData.Box then
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
                    if Drawing and espData.Tracer then espData.Tracer.Visible = false end
                    if Drawing and espData.Box then espData.Box.Visible = false end
                end
            end
        end
    end
end

-- ========================================
-- 🏃 PLAYER SYSTEM
-- ========================================
BV.Player = {
    Speed = { Enabled = false, Value = 16 },
    Jump = { Enabled = false, Value = 50 },
    Fly = { Enabled = false, Speed = 50 },
    Noclip = false,
    InfiniteJump = false,
    Godmode = false
}

function BV.SetSpeed(enabled, speed)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = enabled and speed or 16
        BV.Player.Speed.Enabled = enabled
        BV.Player.Speed.Value = speed
        BV.Log("🏃 Speed: " .. (enabled and "ON (" .. speed .. ")" or "OFF"), enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
end

function BV.SetJumpPower(enabled, power)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.JumpPower = enabled and power or 50
        BV.Player.Jump.Enabled = enabled
        BV.Player.Jump.Value = power
        BV.Log("🦘 Jump Power: " .. (enabled and "ON (" .. power .. ")" or "OFF"), enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    end
end

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

function BV.ToggleAutoHeal(enabled)
    BV.Utility.AutoHeal = enabled
    if enabled then
        BV.Connections.AutoHeal = RunService.Heartbeat:Connect(function()
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health < humanoid.MaxHealth * 0.5 then
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
-- 🔄 MAIN LOOPS AND CONNECTIONS (Delta compatible)
-- ========================================
BV.Connections.FOVUpdate = RunService.RenderStepped:Connect(function()
    if FOVCircle and BV.Combat.Aimbot.ShowFOV and BV.Combat.Aimbot.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(mouse.X, mouse.Y)
        FOVCircle.Radius = BV.Combat.Aimbot.Radius
        FOVCircle.Color = BV.Combat.Aimbot.FOVColor
    elseif FOVCircle then
        FOVCircle.Visible = false
    end
end)

BV.Connections.AimbotUpdate = RunService.RenderStepped:Connect(function()
    BV.Safe("Aimbot", BV.UpdateAimbot)
end)

local lastESPUpdate = 0
BV.Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastESPUpdate >= BV.Config.UpdateRate then
        BV.Safe("ESP_Update", BV.UpdateESP)
        lastESPUpdate = now
    end
end)

BV.Connections.ESPInfoUpdate = RunService.RenderStepped:Connect(function()
    BV.Safe("ESP_Info", BV.UpdateESPInfo)
end)

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

BV.Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
    if BV.Player.InfiniteJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

BV.Connections.AutoShoot = RunService.Heartbeat:Connect(function()
    if BV.Combat.AutoShoot then
        local target = BV.GetClosestTarget()
        if target then
            -- Delta does NOT support mouse1press/mouse1release natively; you must use fireclickdetector or tool:Activate()
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("ClickDetector") then
                fireclickdetector(tool.ClickDetector)
            elseif tool and tool.Activate then
                tool:Activate()
            end
        end
    end
end)

-- ========================================
-- 🚀 INITIALIZATION (Delta compatible)
-- ========================================
BV.Safe("Initialize", function()
    BV.Log("🚀 Brokuh Vision v3.0 loaded successfully!", Color3.fromRGB(0, 255, 127))
    BV.Log("👑 Welcome " .. player.Name .. "! Enjoy the enhanced experience!", Color3.fromRGB(255, 215, 0))
    _G.BrokuhVisionLoaded = true
end)

OrionLib:Init()

-- ========================================
-- 📝 CATATAN DELTA
-- ========================================
-- Fitur yang membutuhkan getrawmetatable/setreadonly/newcclosure/getnamecallmethod akan nonaktif di Delta, seperti Always Headshot.
-- Fitur GUI, ESP, Combat, Player, Utility, dan World berjalan normal di Delta.
-- Untuk update Delta, pastikan API seperti Drawing, fireclickdetector, setclipboard sudah tersedia.
