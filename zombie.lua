local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Interact = require(player.PlayerScripts.Client.Interact)
local OriginalUpdate = Interact.Update

-- Config untuk save/load
local ConfigName = "MyConfig"

-- Struktur data untuk fitur
local Combat = {
    AimBot = {
        Enabled = false, 
        Radius = 25
    },
    SilentAim = {
        Enabled = false, 
        Radius = 25
    },
    HitBox = {
        Enabled = false, 
        Size = 5
    },
    AlwaysHS = {
        Enabled = false,
        OriginalNamecall = nil
    },
    KillAura = {
        Enabled = false,
        Radius = 15
    },
    NoRecoil = {
        Enabled = false
    },
    TriggerBot = {
        Enabled = false,
        Delay = 0.1
    },
    SpeedHack = {
        Enabled = false,
        Speed = 32
    },
    GodMode = {
        Enabled = false
    }
}

local Visuals = {
    FOV = 70,
    ShowFPS = false,
    ShowPing = false,
    ESPZombies = false,
    ESPPlayers = false,
    TracerZombies = false,
    TracerPlayers = false,
    TracerZombieColor = Color3.fromRGB(255, 0, 0), -- Merah untuk zombie
    TracerPlayerColor = Color3.fromRGB(0, 255, 0)  -- Hijau untuk player
}

local Items = {
    ESP = {
        Enabled = false,
        Active = {},
        Color = Color3.fromRGB(255, 215, 0) -- Gold untuk item
    },
    AutoPickup = {
        Enabled = false,
        Radius = 10
    }
}

local AutoFarm = {
    Enabled = false
}

-- Drawing objects
local circle = Drawing.new("Circle")
circle.Visible = false
circle.Radius = Combat.AimBot.Radius
circle.Color = Color3.new(1, 0, 0)
circle.Thickness = 2
circle.Filled = false
circle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

local silentAimCircle = Drawing.new("Circle")
silentAimCircle.Visible = false
silentAimCircle.Radius = Combat.SilentAim.Radius
silentAimCircle.Color = Color3.fromRGB(0, 255, 0)
silentAimCircle.Thickness = 2
silentAimCircle.Filled = false
silentAimCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

local fpsText = Drawing.new("Text")
fpsText.Visible = false
fpsText.Color = Color3.new(1, 1, 1)
fpsText.Size = 18
fpsText.Position = Vector2.new(10, camera.ViewportSize.Y - 50)
fpsText.Text = "FPS: 0"

local pingText = Drawing.new("Text")
pingText.Visible = false
pingText.Color = Color3.new(1, 1, 1)
pingText.Size = 18
pingText.Position = Vector2.new(10, camera.ViewportSize.Y - 30)
pingText.Text = "Ping: 0ms"

local ESP = {
    Zombies = {
        Active = {},
        Color = Color3.fromRGB(255, 0, 0)
    },
    Players = {
        Active = {},
        Color = Color3.fromRGB(0, 0, 255)
    }
}

local Tracers = {
    Zombies = {
        Active = {}
    },
    Players = {
        Active = {}
    }
}

-- Fungsi utilitas
local function isEnemy(model)
    if model.Parent == workspace.Entities.Infected then
        return true -- Zombie selalu musuh
    elseif Players:GetPlayerFromCharacter(model) then
        local plr = Players:GetPlayerFromCharacter(model)
        return plr.Team ~= player.Team -- Cuma target player beda tim
    end
    return false
end

local function clearESP(type)
    for _, highlight in pairs(ESP[type].Active) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    ESP[type].Active = {}
end

local function clearTracers(type)
    for _, line in pairs(Tracers[type].Active) do
        if line then
            line:Remove()
        end
    end
    Tracers[type].Active = {}
end

local function clearItemESP()
    for _, highlight in pairs(Items.ESP.Active) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    Items.ESP.Active = {}
end

local function updateESP(type, models)
    if not Visuals["ESP"..type] then return end
    
    for _, model in pairs(models) do
        if model and model.Parent and isEnemy(model) then
            local existingHighlight = model:FindFirstChildOfClass("Highlight")
            if existingHighlight then
                if (type == "Zombies" and existingHighlight.Name == "ZombieHighlight") or
                   (type == "Players" and existingHighlight.Name == "PlayerHighlight") then
                    existingHighlight:Destroy()
                else
                    continue
                end
            end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = type.."Highlight"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.FillColor = ESP[type].Color
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = model
            table.insert(ESP[type].Active, highlight)
        end
    end
end

local function updateTracers(type, models)
    if not Visuals["Tracer"..type] then return end
    
    clearTracers(type)
    
    for _, model in pairs(models) do
        if model and model.Parent and model:FindFirstChild("HumanoidRootPart") and isEnemy(model) then
            local line = Drawing.new("Line")
            line.Visible = true
            line.Color = type == "Zombies" and Visuals.TracerZombieColor or Visuals.TracerPlayerColor
            line.Thickness = 1
            line.Transparency = 1
            table.insert(Tracers[type].Active, line)
        end
    end
end

local function renderTracers(type, models)
    if not Visuals["Tracer"..type] then return end
    
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local index = 1
    
    for _, model in pairs(models) do
        if model and model.Parent and model:FindFirstChild("HumanoidRootPart") and isEnemy(model) then
            local root = model.HumanoidRootPart
            local _, onScreen = camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local pos = camera:WorldToViewportPoint(root.Position)
                local line = Tracers[type].Active[index]
                if line then
                    line.From = screenCenter
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Visible = true
                end
            else
                local line = Tracers[type].Active[index]
                if line then
                    line.Visible = false
                end
            end
            index = index + 1
        end
    end
end

local function updateItemESP()
    clearItemESP()
    if not Items.ESP.Enabled then return end
    
    for _, item in pairs(workspace.Entities.Items:GetChildren()) do -- Sesuain path
        if item:IsA("Model") or item:IsA("BasePart") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ItemHighlight"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.FillColor = Items.ESP.Color
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = item
            table.insert(Items.ESP.Active, highlight)
        end
    end
end

local function updateAllVisuals()
    clearESP("Zombies")
    clearESP("Players")
    clearTracers("Zombies")
    clearTracers("Players")
    clearItemESP()
    
    local zombies = {}
    for _, model in pairs(workspace.Entities.Infected:GetChildren()) do
        if model:IsA("Model") then
            table.insert(zombies, model)
        end
    end
    
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            table.insert(players, plr.Character)
        end
    end
    
    if Visuals.ESPZombies then
        updateESP("Zombies", zombies)
    end
    
    if Visuals.ESPPlayers then
        updateESP("Players", players)
    end
    
    if Visuals.TracerZombies then
        updateTracers("Zombies", zombies)
    end
    
    if Visuals.TracerPlayers then
        updateTracers("Players", players)
    end
    
    if Items.ESP.Enabled then
        updateItemESP()
    end
end

local function EnableInfiniteAmmo()
    Interact.Update = function(...)
        local args = {...}
        local weapon = args[2]
        
        if weapon and weapon.Equipped then
            args[4][weapon.Equipped].Mag = weapon.WeaponModule.Stats.Mag
            args[4][weapon.Equipped].Pool = weapon.WeaponModule.Stats.Pool
            if Combat.NoRecoil.Enabled then
                weapon.WeaponModule.Stats.Recoil = 0
                weapon.WeaponModule.Stats.Spread = 0
            end
        end
        
        return OriginalUpdate(...)
    end
end

local function UpdateKillAura()
    if not Combat.KillAura.Enabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local playerPos = player.Character.HumanoidRootPart.Position
    local radiusSqr = Combat.KillAura.Radius * Combat.KillAura.Radius
    
    for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
        if zombie:FindFirstChild("Humanoid") and zombie:FindFirstChild("HumanoidRootPart") then
            local distanceSqr = (playerPos - zombie.HumanoidRootPart.Position).Magnitude^2
            if distanceSqr <= radiusSqr then
                zombie.Humanoid.Health = 0
            end
        end
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart") and isEnemy(plr.Character) then
            local distanceSqr = (playerPos - plr.Character.HumanoidRootPart.Position).Magnitude^2
            if distanceSqr <= radiusSqr then
                plr.Character.Humanoid.Health = 0
            end
        end
    end
end

local function UpdateAimBot()
    circle.Visible = Combat.AimBot.Enabled
    circle.Radius = Combat.AimBot.Radius
    silentAimCircle.Visible = Combat.SilentAim.Enabled
    silentAimCircle.Radius = Combat.SilentAim.Radius

    if Combat.AimBot.Enabled then
        local closest, dist = nil, math.huge
        for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
            if zombie:FindFirstChild("Head") then
                local pos = camera:WorldToViewportPoint(zombie.Head.Position)
                local magnitude = (Vector2.new(pos.X, pos.Y) - circle.Position).Magnitude
                if magnitude < Combat.AimBot.Radius and magnitude < dist then
                    closest = zombie.Head
                    dist = magnitude
                end
            end
        end
        if closest then
            local randomOffset = Vector3.new(
                math.random(-0.5, 0.5),
                math.random(-0.5, 0.5),
                math.random(-0.5, 0.5)
            )
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, closest.Position + randomOffset)
        end
    end
end

local function UpdateTriggerBot()
    if Combat.TriggerBot.Enabled then
        for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
            if zombie:FindFirstChild("Head") then
                local pos = camera:WorldToViewportPoint(zombie.Head.Position)
                local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                if magnitude < Combat.AimBot.Radius then
                    Interact:Fire() -- Sesuain sama mekanisme tembak
                    wait(Combat.TriggerBot.Delay)
                    break
                end
            end
        end
    end
end

local hitboxLoop
local function UpdateHitBox()
    if hitboxLoop then hitboxLoop:Disconnect() end

    if Combat.HitBox.Enabled then
        hitboxLoop = RunService.Heartbeat:Connect(function()
            for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
                if zombie:FindFirstChild("Head") then
                    zombie.Head.Size = Vector3.new(Combat.HitBox.Size, Combat.HitBox.Size, Combat.HitBox.Size)
                    zombie.Head.CanCollide = false
                    zombie.Head.Transparency = 0.5
                end
            end
        end)
    else
        for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
            if zombie:FindFirstChild("Head") then
                zombie.Head.Size = Vector3.new(1, 1, 1)
                zombie.Head.CanCollide = true
                zombie.Head.Transparency = 0
            end
        end
    end
end

local function UpdateSpeedHack()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Combat.SpeedHack.Enabled and Combat.SpeedHack.Speed or 16
    end
end

local function EnableGodMode()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if Combat.GodMode.Enabled then
                player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
            end
        end)
    end
end

local function UpdateAutoPickup()
    if Items.AutoPickup.Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local playerPos = player.Character.HumanoidRootPart.Position
        for _, item in pairs(workspace.Entities.Items:GetChildren()) do -- Sesuain path
            if item:IsA("Model") or item:IsA("BasePart") then
                local distance = (playerPos - item.Position).Magnitude
                if distance <= Items.AutoPickup.Radius then
                    Interact:Pickup(item) -- Ganti dengan fungsi pickup game
                end
            end
        end
    end
end

local function UpdateFOV()
    camera.FieldOfView = Visuals.FOV
end

local fps = 0
local lastTime = os.clock()
local frameCount = 0

local function UpdateStatsDisplay()
    frameCount = frameCount + 1
    local currentTime = os.clock()
    if currentTime - lastTime >= 1 then
        fps = math.floor(frameCount / (currentTime - lastTime))
        frameCount = 0
        lastTime = currentTime
    end
    
    if Visuals.ShowFPS then
        fpsText.Text = "FPS: "..fps
        fpsText.Visible = true
    else
        fpsText.Visible = false
    end
    
    if Visuals.ShowPing then
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        pingText.Text = "Ping: "..ping.."ms"
        pingText.Visible = true
    else
        pingText.Visible = false
    end
end

local function ToggleAlwaysHeadshot(value)
    Combat.AlwaysHS.Enabled = value
    if Combat.AlwaysHS.Enabled then
        local mt = getrawmetatable(game)
        Combat.AlwaysHS.OriginalNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            if getnamecallmethod() == 'FireServer' and self.Name == 'RE' then
                if args[1] == "aa" then
                    args[2][1] = {
                        ["AI"] = args[2][1]["AI"],
                        ["Velocity"] = args[2][1]["Velocity"],
                        ["Special"] = "H"
                    }
                end
            end
            return Combat.AlwaysHS.OriginalNamecall(self, unpack(args))
        end)
    else
        if Combat.AlwaysHS.OriginalNamecall then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = Combat.AlwaysHS.OriginalNamecall
            setreadonly(mt, true)
        end
    end
end

local function UpdateAutoFarm()
    if AutoFarm.Enabled then
        Combat.KillAura.Enabled = true
        local closest, dist = nil, math.huge
        for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
            if zombie:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - zombie.HumanoidRootPart.Position).Magnitude
                if distance < dist then
                    closest = zombie.HumanoidRootPart
                    dist = distance
                end
            end
        end
        if closest and player.Character then
            player.Character.HumanoidRootPart.CFrame = closest.CFrame + Vector3.new(0, 5, 0)
        end
    end
end

-- GUI Setup
local Window = OrionLib:MakeWindow({
    Name = "🧟‍♂️ Those Who Remain | GUI 🧟‍♂️",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "ThoseWhoRemainConfig",
    IntroEnabled = false
})

local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "🔫",
    PremiumOnly = false
})

local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "⚔️",
    PremiumOnly = false
})

local VisualTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "👁️",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "⚙️",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name = "Infinite Ammo",
    Default = false,
    Callback = function(value)
        if value then EnableInfiniteAmmo() else Interact.Update = OriginalUpdate end
    end    
})

MainTab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(value)
        AutoFarm.Enabled = value
        if not value then Combat.KillAura.Enabled = false end
    end
})

MainTab:AddButton({
    Name = "Teleport ke Spawn",
    Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(0, 10, 0)) -- Ganti koordinat
            OrionLib:MakeNotification({
                Name = "Teleport",
                Content = "Teleport ke spawn!",
                Time = 2
            })
        end
    end
})

MainTab:AddToggle({
    Name = "Auto Pickup",
    Default = false,
    Callback = function(value)
        Items.AutoPickup.Enabled = value
    end
})

MainTab:AddTextbox({
    Name = "Pickup Radius",
    Default = "10",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 5 and num <= 30 then
            Items.AutoPickup.Radius = num
        end
    end
})

CombatTab:AddToggle({
    Name = "AimBot",
    Default = false,
    Callback = function(value)
        Combat.AimBot.Enabled = value
    end    
})

CombatTab:AddTextbox({
    Name = "AimBot Radius",
    Default = "25",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 10 and num <= 500 then
            Combat.AimBot.Radius = num
        end
    end
})

CombatTab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Callback = function(value)
        Combat.SilentAim.Enabled = value
    end    
})

CombatTab:AddTextbox({
    Name = "Silent Aim Radius",
    Default = "25",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 10 and num <= 500 then
            Combat.SilentAim.Radius = num
        end
    end
})

CombatTab:AddToggle({
    Name = "HitBox Expander",
    Default = false,
    Callback = function(value)
        Combat.HitBox.Enabled = value
        UpdateHitBox()
    end    
})

CombatTab:AddTextbox({
    Name = "HitBox Size",
    Default = "5",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 1 and num <= 15 then
            Combat.HitBox.Size = num
        end
    end
})

CombatTab:AddToggle({
    Name = "Always Headshot",
    Default = false,
    Callback = function(value)
        ToggleAlwaysHeadshot(value)
    end    
})

CombatTab:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Callback = function(value)
        Combat.KillAura.Enabled = value
    end    
})

CombatTab:AddTextbox({
    Name = "Kill Aura Radius",
    Default = "15",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 5 and num <= 50 then
            Combat.KillAura.Radius = num
        end
    end
})

CombatTab:AddToggle({
    Name = "No Recoil/Spread",
    Default = false,
    Callback = function(value)
        Combat.NoRecoil.Enabled = value
        if value then EnableInfiniteAmmo() else Interact.Update = OriginalUpdate end
    end
})

CombatTab:AddToggle({
    Name = "TriggerBot",
    Default = false,
    Callback = function(value)
        Combat.TriggerBot.Enabled = value
    end
})

CombatTab:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Callback = function(value)
        Combat.SpeedHack.Enabled = value
        UpdateSpeedHack()
    end
})

CombatTab:AddTextbox({
    Name = "Walk Speed",
    Default = "32",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 16 and num <= 100 then
            Combat.SpeedHack.Speed = num
            UpdateSpeedHack()
        end
    end
})

CombatTab:AddToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(value)
        Combat.GodMode.Enabled = value
        if value then EnableGodMode() end
    end
})

CombatTab:AddBind({
    Name = "Toggle Kill Aura",
    Default = Enum.KeyCode.Q,
    Hold = false,
    Callback = function()
        Combat.KillAura.Enabled = not Combat.KillAura.Enabled
        OrionLib:MakeNotification({
            Name = "Kill Aura",
            Content = "Kill Aura " .. (Combat.KillAura.Enabled and "Nyala" or "Mati"),
            Time = 2
        })
    end
})

VisualTab:AddToggle({
    Name = "Zombie ESP",
    Default = false,
    Callback = function(value)
        Visuals.ESPZombies = value
        updateAllVisuals()
    end    
})

VisualTab:AddToggle({
    Name = "Player ESP",
    Default = false,
    Callback = function(value)
        Visuals.ESPPlayers = value
        updateAllVisuals()
    end    
})

VisualTab:AddToggle({
    Name = "Zombie Tracer",
    Default = false,
    Callback = function(value)
        Visuals.TracerZombies = value
        updateAllVisuals()
    end    
})

VisualTab:AddToggle({
    Name = "Player Tracer",
    Default = false,
    Callback = function(value)
        Visuals.TracerPlayers = value
        updateAllVisuals()
    end    
})

VisualTab:AddToggle({
    Name = "Item ESP",
    Default = false,
    Callback = function(value)
        Items.ESP.Enabled = value
        updateItemESP()
    end
})

VisualTab:AddTextbox({
    Name = "Field of View",
    Default = "70",
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 60 and num <= 120 then
            Visuals.FOV = num
            UpdateFOV()
        end
    end
})

SettingsTab:AddToggle({
    Name = "Show FPS",
    Default = false,
    Callback = function(value)
        Visuals.ShowFPS = value
    end    
})

SettingsTab:AddToggle({
    Name = "Show Ping",
    Default = false,
    Callback = function(value)
        Visuals.ShowPing = value
    end    
})

SettingsTab:AddTextbox({
    Name = "Config Name",
    Default = "MyConfig",
    TextDisappear = false,
    Callback = function(value)
        ConfigName = value
    end
})

SettingsTab:AddButton({
    Name = "Save Config",
    Callback = function()
        OrionLib:SaveConfig(ConfigName)
        OrionLib:MakeNotification({
            Name = "Config",
            Content = "Konfigurasi disimpan: " .. ConfigName,
            Time = 2
        })
    end
})

SettingsTab:AddButton({
    Name = "Load Config",
    Callback = function()
        OrionLib:LoadConfig(ConfigName)
        OrionLib:MakeNotification({
            Name = "Config",
            Content = "Konfigurasi dimuat: " .. ConfigName,
            Time = 2
        })
    end
})

-- Event handlers
RunService.RenderStepped:Connect(function()
    UpdateStatsDisplay()
    UpdateAimBot()
    UpdateTriggerBot()
    
    local zombies = {}
    for _, model in pairs(workspace.Entities.Infected:GetChildren()) do
        if model:IsA("Model") then
            table.insert(zombies, model)
        end
    end
    
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            table.insert(players, plr.Character)
        end
    end
    
    renderTracers("Zombies", zombies)
    renderTracers("Players", players)
end)

local VisualUpdateInterval = 0.5
local lastVisualUpdate = 0
local KillAuraUpdateInterval = 0.2
local lastKillAuraUpdate = 0
local AutoPickupInterval = 0.3
local lastAutoPickupUpdate = 0
local AutoFarmInterval = 1
local lastAutoFarmUpdate = 0

RunService.Heartbeat:Connect(function()
    if os.clock() - lastVisualUpdate >= VisualUpdateInterval then
        updateAllVisuals()
        lastVisualUpdate = os.clock()
    end
    
    if os.clock() - lastKillAuraUpdate >= KillAuraUpdateInterval then
        UpdateKillAura()
        lastKillAuraUpdate = os.clock()
    end
    
    if os.clock() - lastAutoPickupUpdate >= AutoPickupInterval then
        UpdateAutoPickup()
        lastAutoPickupUpdate = os.clock()
    end
    
    if os.clock() - lastAutoFarmUpdate >= AutoFarmInterval then
        UpdateAutoFarm()
        lastAutoFarmUpdate = os.clock()
    end
end)

player.CharacterAdded:Connect(function(character)
    if Combat.SpeedHack.Enabled then
        UpdateSpeedHack()
    end
    if Combat.GodMode.Enabled then
        EnableGodMode()
    end
end)

Players.PlayerAdded:Connect(function(plr)
    updateAllVisuals()
end)

Players.PlayerRemoving:Connect(function(plr)
    updateAllVisuals()
end)

workspace.Entities.Infected.ChildAdded:Connect(function()
    updateAllVisuals()
end)

workspace.Entities.Infected.ChildRemoved:Connect(function(child)
    updateAllVisuals()
end)

workspace.Entities.Items.ChildAdded:Connect(function()
    updateItemESP()
end)

workspace.Entities.Items.ChildRemoved:Connect(function()
    updateItemESP()
end)

game:BindToClose(function()
    if hitboxLoop then hitboxLoop:Disconnect() end
    circle:Remove()
    silentAimCircle:Remove()
    fpsText:Remove()
    pingText:Remove()
    clearESP("Zombies")
    clearESP("Players")
    clearTracers("Zombies")
    clearTracers("Players")
    clearItemESP()
end)

OrionLib:Init()
