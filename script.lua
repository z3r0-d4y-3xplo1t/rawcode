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

-- Anti-detection bypass
local function setupAntiDetect()
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__index = newcclosure(function(self, key)
        if key == "Name" or key == "Parent" then
            return oldIndex(self, key)
        end
        return oldIndex(self, key)
    end)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            if math.random(1, 100) > 80 then
                return nil
            end
        end
        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
end

-- Tabel default untuk kapasitas amunisi
local defaultAmmo = {
    ["Pistol"] = {Mag = 15, Pool = 60},
    ["SMG"] = {Mag = 30, Pool = 120},
    ["Rifle"] = {Mag = 20, Pool = 80},
    ["Shotgun"] = {Mag = 8, Pool = 32},
    ["Sniper"] = {Mag = 5, Pool = 20}
}

-- Unlimited ammo dengan reload manual
local function EnableInfiniteAmmo()
    Interact.Update = function(...)
        local args = {...}
        local weapon = args[2]
        
        if weapon and weapon.Equipped and weapon.WeaponModule and weapon.WeaponModule.Stats then
            local weaponData = args[4] and args[4][weapon.Equipped]
            if not weaponData then
                print("Weapon data not found in args[4][weapon.Equipped]. Dumping args:")
                for i, v in pairs(args) do
                    print("args["..i.."]: ", v)
                end
                return OriginalUpdate(...)
            end

            -- Ambil nilai maksimum dari WeaponModule.Stats
            local maxMag = weapon.WeaponModule.Stats.Mag or defaultAmmo[weapon.Equipped] and defaultAmmo[weapon.Equipped].Mag or 15
            local maxPool = weapon.WeaponModule.Stats.Pool or defaultAmmo[weapon.Equipped] and defaultAmmo[weapon.Equipped].Pool or 60
            local currentMag = weaponData.Mag or 0

            -- Debugging: Cetak info senjata
            print("Weapon:", weapon.Equipped, "MaxMag:", maxMag, "CurrentMag:", currentMag, "MaxPool:", maxPool, "CurrentPool:", weaponData.Pool or 0)

            -- Isi ulang Mag hanya jika di bawah 20% dan Pool jika Mag diisi ulang
            if currentMag < maxMag * 0.2 then
                weaponData.Mag = maxMag
                weaponData.Pool = maxPool
            end
        else
            print("Invalid weapon or WeaponModule not found for:", weapon and weapon.Equipped or "nil")
        end
        
        return OriginalUpdate(...)
    end
end

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
    }
}

local Visuals = {
    FOV = 70,
    ShowFPS = false,
    ShowPing = false,
    ESPZombieBox = false,
    ESPZombieTracer = false,
    ESPPlayerBox = false,
    ESPPlayerTracer = false,
    TracerPosition = "Bottom"
}

local Performance = {
    BoostMode = false,
    UpdateFrequency = 1
}

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
        Color = Color3.fromRGB(0, 255, 0)
    }
}

local ESPDrawings = {}

local function addESP(model, color, type)
    if ESPDrawings[model] then return end

    ESPDrawings[model] = {spawnTime = tick()}

    local box = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = color
        line.Thickness = 2
        table.insert(box, line)
    end
    ESPDrawings[model].box = box

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = color
    tracer.Thickness = 2
    ESPDrawings[model].tracer = tracer

    if type == "Zombies" then
        table.insert(ESP.Zombies.Active, model)
    elseif type == "Players" then
        table.insert(ESP.Players.Active, model)
    end
end

local function removeESP(model)
    if ESPDrawings[model] then
        for _, line in ipairs(ESPDrawings[model].box) do
            line:Remove()
        end
        ESPDrawings[model].tracer:Remove()
        ESPDrawings[model] = nil
    end
end

local function clearESP(type)
    for _, model in ipairs(ESP[type].Active) do
        removeESP(model)
    end
    ESP[type].Active = {}
end

local function updateESP(type, models)
    if (type == "Zombies" and (Visuals.ESPZombieBox or Visuals.ESPZombieTracer)) or 
       (type == "Players" and (Visuals.ESPPlayerBox or Visuals.ESPPlayerTracer)) then
        for _, model in ipairs(models) do
            if model and model.Parent then
                addESP(model, ESP[type].Color, type)
            end
        end
    end
end

local function updateAllESP()
    clearESP("Zombies")
    clearESP("Players")
    
    if Visuals.ESPZombieBox or Visuals.ESPZombieTracer then
        local zombies = {}
        for _, model in ipairs(workspace.Entities.Infected:GetChildren()) do
            if model:IsA("Model") then
                table.insert(zombies, model)
            end
        end
        updateESP("Zombies", zombies)
    end
    
    if Visuals.ESPPlayerBox or Visuals.ESPPlayerTracer then
        local players = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                table.insert(players, plr.Character)
            end
        end
        updateESP("Players", players)
    end
end

local frameCounter = 0
local function updateESPDrawings()
    frameCounter = frameCounter + 1
    if Performance.BoostMode and frameCounter % Performance.UpdateFrequency ~= 0 then
        return
    end

    local closestZombie = nil
    local closestDistance = math.huge
    if Visuals.ESPZombieTracer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local playerPos = player.Character.HumanoidRootPart.Position
        for _, zombie in pairs(workspace.Entities.Infected:GetChildren()) do
            if zombie:FindFirstChild("HumanoidRootPart") then
                local distance = (playerPos - zombie.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestZombie = zombie
                end
            end
        end
    end

    for model, drawings in pairs(ESPDrawings) do
        if not model or not model.Parent or not model:FindFirstChild("HumanoidRootPart") or not model:FindFirstChild("Head") then
            removeESP(model)
            continue
        end

        local root = model.HumanoidRootPart
        local head = model.Head
        local headPos = head.Position + Vector3.new(0, 0.5, 0)
        local legPos = root.Position - Vector3.new(0, 3, 0)

        local head2d, onScreen = camera:WorldToViewportPoint(headPos)
        local leg2d = camera:WorldToViewportPoint(legPos)

        if not onScreen then
            for _, line in ipairs(drawings.box) do line.Visible = false end
            drawings.tracer.Visible = false
            continue
        end

        local boxHeight = (head2d - leg2d).Magnitude
        local boxWidth = boxHeight / 2.5
        local center2d = camera:WorldToViewportPoint(root.Position)

        local topLeft = Vector2.new(center2d.X - boxWidth / 2, head2d.Y)
        local topRight = Vector2.new(center2d.X + boxWidth / 2, head2d.Y)
        local bottomLeft = Vector2.new(center2d.X - boxWidth / 2, leg2d.Y)
        local bottomRight = Vector2.new(center2d.X + boxWidth / 2, leg2d.Y)

        local showBox = false
        local showTracer = false
        if table.find(ESP.Zombies.Active, model) then
            showBox = Visuals.ESPZombieBox
            showTracer = Visuals.ESPZombieTracer and model == closestZombie
        elseif table.find(ESP.Players.Active, model) then
            showBox = Visuals.ESPPlayerBox
            showTracer = Visuals.ESPPlayerTracer
        end

        drawings.box[1].Visible = showBox
        drawings.box[1].From = topLeft
        drawings.box[1].To = topRight

        drawings.box[2].Visible = showBox
        drawings.box[2].From = topRight
        drawings.box[2].To = bottomRight

        drawings.box[3].Visible = showBox
        drawings.box[3].From = bottomRight
        drawings.box[3].To = bottomLeft

        drawings.box[4].Visible = showBox
        drawings.box[4].From = bottomLeft
        drawings.box[4].To = topLeft

        if showTracer then
            local tracerFrom
            if Visuals.TracerPosition == "Bottom" then
                tracerFrom = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            elseif Visuals.TracerPosition == "Top" then
                tracerFrom = Vector2.new(camera.ViewportSize.X / 2, 0)
            elseif Visuals.TracerPosition == "Left" then
                tracerFrom = Vector2.new(0, camera.ViewportSize.Y / 2)
            elseif Visuals.TracerPosition == "Right" then
                tracerFrom = Vector2.new(camera.ViewportSize.X, camera.ViewportSize.Y / 2)
            end
            drawings.tracer.From = tracerFrom
            drawings.tracer.To = Vector2.new(leg2d.X, leg2d.Y)
            drawings.tracer.Visible = true
        else
            drawings.tracer.Visible = false
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
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, closest.Position)
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

local function UpdateFOV()
    camera.FieldOfView = Visuals.FOV
end

local fps = 0
local lastTime = os.clock()
local frameCounter = 0

local function UpdateStatsDisplay()
    frameCounter = frameCounter + 1
    local currentTime = os.clock()
    if currentTime - lastTime >= 1 then
        fps = math.floor(frameCounter / (currentTime - lastTime))
        frameCounter = 0
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

local Window = OrionLib:MakeWindow({
    Name = "🧟‍♂️ Those Who Remain | GUI 🧟‍♂️",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "ThoseWhoRemainConfig",
    IntroEnabled = false
})

local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local VisualTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name = "Unlimited Ammo (Max Ammo, With Reload)",
    Default = false,
    Callback = function(value)
        if value then EnableInfiniteAmmo() else Interact.Update = OriginalUpdate end
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

VisualTab:AddToggle({
    Name = "Zombie Box ESP",
    Default = false,
    Callback = function(value)
        Visuals.ESPZombieBox = value
        updateAllESP()
    end    
})

VisualTab:AddToggle({
    Name = "Zombie Tracer ESP (Nearest Only)",
    Default = false,
    Callback = function(value)
        Visuals.ESPZombieTracer = value
        updateAllESP()
    end    
})

VisualTab:AddToggle({
    Name = "Player Box ESP",
    Default = false,
    Callback = function(value)
        Visuals.ESPPlayerBox = value
        updateAllESP()
    end    
})

VisualTab:AddToggle({
    Name = "Player Tracer ESP",
    Default = false,
    Callback = function(value)
        Visuals.ESPPlayerTracer = value
        updateAllESP()
    end    
})

VisualTab:AddDropdown({
    Name = "Tracer Position",
    Default = "Bottom",
    Options = {"Bottom", "Top", "Left", "Right"},
    Callback = function(value)
        Visuals.TracerPosition = value
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

SettingsTab:AddToggle({
    Name = "Boost Mode (Anti-Lag)",
    Default = false,
    Callback = function(value)
        Performance.BoostMode = value
    end    
})

SettingsTab:AddSlider({
    Name = "Update Frequency (Higher = Less Lag)",
    Min = 1,
    Max = 10,
    Default = 1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    Callback = function(value)
        Performance.UpdateFrequency = value
    end    
})

-- Initialize anti-detection
setupAntiDetect()

RunService.RenderStepped:Connect(function()
    UpdateStatsDisplay()
    UpdateAimBot()
    updateESPDrawings()
end)

RunService.Heartbeat:Connect(function()
    updateAllESP()
end)

Players.PlayerAdded:Connect(function(plr)
    updateAllESP()
end)

Players.PlayerRemoving:Connect(function(plr)
    updateAllESP()
end)

workspace.Entities.Infected.ChildAdded:Connect(function()
    updateAllESP()
end)

workspace.Entities.Infected.ChildRemoved:Connect(function()
    updateAllESP()
end)

-- RGB GUI animation
spawn(function()
    while true do
        local hue = tick() % 6 / 6
        local orionGui = player.PlayerGui:FindFirstChild("Orion")
        if orionGui then
            for _, v in ipairs(orionGui:GetDescendants()) do
                if v:IsA("TextLabel") or v:IsA("TextButton") then
                    v.TextColor3 = Color3.fromHSV(hue, 1, 1)
                end
                if v:IsA("Frame") or v:IsA("ImageLabel") then
                    v.BackgroundColor3 = Color3.fromHSV(hue, 0.3, 0.3)
                end
            end
        end
        wait(0.1)
    end
end)

OrionLib:Init()
