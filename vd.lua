if not game:IsLoaded() then game.Loaded:Wait() end
local Players=game:GetService("Players")
while not Players.LocalPlayer do task.wait() end
while not workspace.CurrentCamera do task.wait() end
local cloneref=(cloneref or clonereference or function(v)return v end)
local RunService=cloneref(game:GetService("RunService"))
local UserInputService=cloneref(game:GetService("UserInputService"))
local Lighting=cloneref(game:GetService("Lighting"))
local Stats=cloneref(game:GetService("Stats"))
local VirtualInputManager=cloneref(game:GetService("VirtualInputManager"))
local CoreGui=cloneref(game:GetService("CoreGui"))
local GuiService=cloneref(game:GetService("GuiService"))
local ReplicatedStorage=cloneref(game:GetService("ReplicatedStorage"))
local PathfindingService=cloneref(game:GetService("PathfindingService"))
local ProximityPromptService=cloneref(game:GetService("ProximityPromptService"))
local HttpService=cloneref(game:GetService("HttpService"))
local TeleportService  = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer=Players.LocalPlayer
local PlayerGui=LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- UI PARENT
-- =========================================================

local function GetUIParent()
    local ok,res=pcall(function()
        if gethui then
            return gethui()
        end
        if syn and syn.protect_gui then
            local gui=Instance.new("ScreenGui")
            syn.protect_gui(gui)
            gui.Parent=CoreGui
            return gui
        end
        return CoreGui
    end)
    return ok and res or CoreGui
end
local TargetGui=GetUIParent()

-- =========================================================
-- SAFE HTTPGET
-- =========================================================

local function SafeHttpGet(url)
    local ok,res=pcall(function()
        if game.HttpGet then
            return game:HttpGet(url)
        end
        if syn and syn.request then
            return syn.request({
                Url=url,
                Method="GET"
            }).Body
        end
        if http_request then
            return http_request({
                Url=url,
                Method="GET"
            }).Body
        end
        error("HttpGet unsupported")
    end)
    return ok and res or nil
end

-- =========================================================
-- LOAD WINDUI
-- =========================================================

local WindUI
do
    local src=SafeHttpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    )
    if src then
        local ok,res=pcall(function()
            return loadstring(src)()
        end)
        if ok then
            WindUI=res
        end
    end
end

if WindUI then
    print("[FORKT] WindUI Loaded")
else
    warn("[FORKT] Failed Load WindUI")
    pcall(function()
        game:GetService("StarterGui"):SetCore(
            "SendNotification",
            {
                Title="FORKT",
                Text="Failed loading WindUI"
            }
        )
    end)
    return
end

-- =========================================================
-- LOAD JUNKIE
-- =========================================================

local Junkie
do
    local src=SafeHttpGet(
        "https://jnkie.com/sdk/library.lua"
    )
    if src then
        local ok,res=pcall(function()
            return loadstring(src)()
        end)
        if ok then
            Junkie=res
        end
    end
end

if Junkie then

    Junkie.service="FORKT"
    Junkie.identifier="1041888"
    Junkie.provider="Mixed"
    print("[FORKT] Junkie Loaded")

else
    warn("[FORKT] Failed Load Junkie")
    pcall(function()
        game:GetService("StarterGui"):SetCore(
            "SendNotification",
            {
                Title="FORKT",
                Text="Junkie API failed"
            }
        )
    end)
end

-- =========================================================
-- ANTI MEMORY LEAK
-- =========================================================

getgenv().FORKT_CONNECTIONS=
    getgenv().FORKT_CONNECTIONS or {}
for _,conn in ipairs(getgenv().FORKT_CONNECTIONS) do
    pcall(function()
        RunService:UnbindFromRenderStep(
            "SmoothFOV"
        )
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end)
end

table.clear(getgenv().FORKT_CONNECTIONS)
getgenv().MoonwalkEnabled  = false
getgenv().isMobileFiring   = false
getgenv().AIFinalTarget    = nil
getgenv().CachedWaypoints  = nil
getgenv().AntiAura = false
getgenv().AuraRemoteCache = setmetatable({}, { __mode = "k" })
-- Nonaktifkan namecall hook lama (anti-stacking)
getgenv().FORKT_NamecallId = (getgenv().FORKT_NamecallId or 0) + 1
-- Cleanup fppHideConn lama yang tidak ditrack di FORKT_CONNECTIONS
if getgenv().FORKT_FPPConn then
    pcall(function() getgenv().FORKT_FPPConn:Disconnect() end)
    getgenv().FORKT_FPPConn = nil
end

-- Pastikan MouseBehavior bersih di mobile
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end)
end
----------------------------------------------------------------
-- ESP COLORS (Pengganti Config Manual)
----------------------------------------------------------------
local ESP_COLORS = {
    Killer = Color3.fromRGB(255, 93, 108), 
    Survivor = Color3.fromRGB(0, 255, 34),
    Generator = Color3.fromRGB(200, 100, 0), 
    Gate = Color3.fromRGB(255, 255, 255),
    Pallet = Color3.fromRGB(53, 189, 166), 
    Hook = Color3.fromRGB(252, 116, 116)
}
local MaskNames = {
    ["Abysswalker"] = "ABYSSWALKER",
    ["Cure"]        = "CURE",
    ["Hidden"]      = "HIDDEN",
    ["Killer"]      = "THE KILLER",
    ["Masked"]      = "PALA AYAM",
    ["Stalker"]     = "STALKER",
    ["Veil"]        = "VEIL",
    ["Slasher"]     = "SLASHER",
}

local MaskColors = {
    ["Abysswalker"] = Color3.fromRGB(110, 20, 255), -- Void Purple
    ["Cure"]        = Color3.fromRGB(0, 54, 156), -- blue
    ["Hidden"]      = Color3.fromRGB(170, 170, 170), -- Pale Grey
    ["Killer"]      = Color3.fromRGB(255, 40, 40), -- Blood Red
    ["Masked"]      = Color3.fromRGB(255, 90, 20), -- Deep Orange
    ["Stalker"]     = Color3.fromRGB(255, 0, 140), -- Neon Pink
    ["Veil"]        = Color3.fromRGB(0, 140, 255), -- Electric Blue
    ["Slasher"]     = Color3.fromRGB(180, 0, 255), -- Dark Magenta
}
local CachedMapObjects = {
    Generators = {},
    Pallets = {},
    Hooks = {},
    Gates = {}
}
local SpoofData = {
    Gears = 0,
    Screws = 0,
    Level = 0
}
local PrevESPState = { Generator = false, Hook = false, Pallet = false, Gate = false }
-- =========================================================
-- [NATIVE CACHE] MEMPERCEPAT KECEPATAN EKSEKUSI HINGGA 30%
-- =========================================================
local v3 = Vector3.new
local v2 = Vector2.new
local cnew = CFrame.new
local cangles = CFrame.Angles
local t_insert = table.insert
local t_remove = table.remove
local m_floor = math.floor
local m_round = math.round
local s_format = string.format
-- Gunakan table.clear() BUKAN {} untuk mencegah penumpukan tabel di RAM
local function ClearMapCache()
    table.clear(CachedMapObjects.Generators)
    table.clear(CachedMapObjects.Pallets)
    table.clear(CachedMapObjects.Hooks)
    table.clear(CachedMapObjects.Gates)
    
    if ActiveGenerators then table.clear(ActiveGenerators) end

    if PrevESPState then
        PrevESPState.Generator = false
        PrevESPState.Hook = false
        PrevESPState.Pallet = false
        PrevESPState.Gate = false
    end
end
local function UpdateMapCache()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    ClearMapCache()
    CachedMapObjects.Generators = {}
    CachedMapObjects.Pallets = {}
    CachedMapObjects.Hooks = {}
    CachedMapObjects.Gates = {}
    
    -- Ganti GetDescendants dengan penelusuran folder utama atau GetChildren tingkat pertama
    local function ScanContainer(container)
        for _, obj in ipairs(container:GetChildren()) do
            local n = obj.Name
            if n == "Generator" then 
                t_insert(CachedMapObjects.Generators, obj)
            elseif n == "Hook" then  
                t_insert(CachedMapObjects.Hooks, obj)
            elseif n == "Gate" then 
                t_insert(CachedMapObjects.Gates, obj)
            elseif n == "Pallet" or n == "Palletwrong" then 
                t_insert(CachedMapObjects.Pallets, obj)
            else
                -- Jika berupa folder bersarang, masuk 1 level lagi tanpa menyentuh seluruh Descendants
                if #obj:GetChildren() > 0 and not obj:IsA("Model") then
                    ScanContainer(obj)
                end
            end
        end
    end
    
    ScanContainer(map)

    if PrevESPState then
        PrevESPState.Generator = false
        PrevESPState.Hook = false
        PrevESPState.Pallet = false
        PrevESPState.Gate = false
    end
end

-- =========================================================
-- [OPTIMASI] LITE MAP DETECTOR (STREAMING-ENABLED FIX)
-- =========================================================
task.spawn(function() 
    local mapWasEmpty = true 
    local descendantConn = nil 
    
    while task.wait(2) do 
        if not getgenv().FORKT_RUNNING then 
            if descendantConn then descendantConn:Disconnect() end
            break 
        end
        
        local currentMap = workspace:FindFirstChild("Map")
        local hasContents = currentMap and #currentMap:GetChildren() > 0
        
        if hasContents and mapWasEmpty then
            mapWasEmpty = false 
            
            task.delay(6, function()
                if not getgenv().FORKT_RUNNING then return end
                if currentMap and #currentMap:GetChildren() > 0 then
                    UpdateMapCache() 
                    
                    if descendantConn then descendantConn:Disconnect() end
                    descendantConn = currentMap.DescendantAdded:Connect(function(obj)
                        local n = obj.Name
                        if n == "Generator" then 
                            t_insert(CachedMapObjects.Generators, obj)
                        elseif n == "Hook" then 
                            t_insert(CachedMapObjects.Hooks, obj)
                        elseif n == "Gate" then 
                            t_insert(CachedMapObjects.Gates, obj)
                        elseif n == "Pallet" or n == "Palletwrong" then 
                            t_insert(CachedMapObjects.Pallets, obj)
                        end
                    end)
                    
                    table.insert(getgenv().FORKT_CONNECTIONS, descendantConn)
                    
                    local palletCount = CachedMapObjects.Pallets and #CachedMapObjects.Pallets or 0
                    local genCount = CachedMapObjects.Generators and #CachedMapObjects.Generators or 0
                    
                    WindUI:Notify({ 
                        Title = "Map Loaded", 
                        Content = "Found " .. palletCount .. " Pallets & " .. genCount .. " Generators. Radar Active!", 
                        Icon = "lucide:radar" 
                    })
                end
            end)
            
        elseif not hasContents and not mapWasEmpty then
            mapWasEmpty = true 
            
            if descendantConn then 
                pcall(function() descendantConn:Disconnect() end)
                descendantConn = nil 
            end
            
            CachedMapObjects.Generators = {}
            CachedMapObjects.Pallets = {}
            CachedMapObjects.Hooks = {}
            CachedMapObjects.Gates = {}
            if ActiveGenerators then table.clear(ActiveGenerators) end
            
            if PrevESPState then
                PrevESPState.Generator = false; PrevESPState.Hook = false
                PrevESPState.Pallet = false; PrevESPState.Gate = false
            end
        end
    end 
end)

-- =========================================================
-- OPTIMIZED PLAYER CACHE SYSTEM
-- =========================================================
local CachedPlayers = {}
local CachedKillers = {}
local CachedSurvivors = {}

-- Fungsi untuk memperbarui cache player secara instan saat ada yang masuk/keluar/ganti team
local function RebuildPlayerCache()
    table.clear(CachedPlayers)
    table.clear(CachedKillers)
    table.clear(CachedSurvivors)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(CachedPlayers, p)
            local teamName = p.Team and string.lower(p.Team.Name) or ""
            if string.find(teamName, "killer") then
                table.insert(CachedKillers, p)
            else
                table.insert(CachedSurvivors, p)
            end
        end
    end
end

-- Hubungkan ke Event agar otomatis update tanpa perlu loop berat
Players.PlayerAdded:Connect(RebuildPlayerCache)
Players.PlayerRemoving:Connect(RebuildPlayerCache)
for _, p in ipairs(Players:GetPlayers()) do
    p:GetPropertyChangedSignal("Team"):Connect(RebuildPlayerCache)
end

-- Build pertama kali saat script dijalankan
RebuildPlayerCache()

getgenv().AutoFarmSpeed=17
getgenv().MoonwalkZigzagSpeed=11
getgenv().MoonwalkBoostPower=1.08
getgenv().ParryMatchup="Auto"
getgenv().AimStrictness=1.3
getgenv().ParryDelayOffset=0
getgenv().FORKT_RUNNING=true
getgenv().FORKT_SPAWN_TIME = os.clock()
getgenv().AimbotSmoothness=8
getgenv().AimbotPart = "Torso"
getgenv().AimbotTrigger = "Hold to Lock"

local KEY_TOGGLE=Enum.KeyCode.R

getgenv().GeneratorPerfectOffsetStart=102
getgenv().GeneratorPerfectOffsetEnd=108
local AutoGenerator=false
local AutoGeneratorMode="Perfect"

local AutoParry=false
local ParryDistance=10

local GenConnection=nil
local SpeedBoost=false
local Aimbot=false
local TargetPartCache=setmetatable({}, { __mode = "k" })
local WallCheck=true
local ShowFOVCircle=false

local CustomCameraFOV = false
local CameraFOVValue = 100
local DefaultFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
pcall(function()
    RunService:UnbindFromRenderStep("SmoothFOV")
end)
local function UpdateFOV()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    if CustomCameraFOV then
        camera.FieldOfView = CameraFOVValue
    else
        camera.FieldOfView = DefaultFOV
    end
end

local AimRadius=getgenv().AimRadius or 60
local AimDistance=getgenv().AimDistance or 80
local BoostSpeed=30
local CachedTarget
local LastTargetCheck=0

local AutoAttack     = false
local AttackRange    = 10
local AttackCount    = 1     -- berapa kali fire per trigger
local AttackDelay    = 0.10  -- jeda antar fire (detik)
local AttackCooldown = 0.80  -- cooldown antar trigger (detik)
local WarnKiller=true
local ActiveGenerators={}
local ThemeName="FORKT"
local AutoFarmBot=false

local AntiBlind              = false
local AntiBlindConn          = nil
local AutoBreakPallet        = false
local BreakPalletRadius      = 8
local BreakPalletCooldown    = 1.20
local AutoVault          = false
local FastVaultThreshold = 30
local VaultCooldown      = 0.80

local SilentAimPistol=false
local SilentAimFOV=180

local DoubleDamageGen=false
local MobileRotateBtn=nil

local SilentActions=false
local AntiFallDamage=false
local NotifyStun=false
local ESP_SCP = false

local ESP_F = {
    Survivor_Name=false, Survivor_Highlight=false,
    Killer_Name=false,   Killer_Highlight=false,
    Generator=false, Gate=false, Pallet=false, Hook=false
}
local UpdateParryRing, TriggerParryDagger, GetKillerProfile
local closestKillerDist=999
local LastESPRefresh=0

local TouchID=8822
local ActionPath = "Survivor-mob.Controls.action.check"
local FOVCircle=nil
local killerScanResult = { dist = 999 }
local CURSOR_ASSET_ID = "rbxassetid://14015304246"
local CursorEnabled   = false
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isMobile  = IS_MOBILE

local TICK = IS_MOBILE and {
    ESP        = 0.65,
    KillerScan = 0.20,
    Parry      = 0.12,
    AIBrain    = 0.50,
    AILegs     = 0.10,
    StunCheck  = 0.35,
    SCPScan    = 1.00,
} or {
    ESP        = 0.35,
    KillerScan = 0.10,
    Parry      = 0.08,
    AIBrain    = 0.35,
    AILegs     = 0.05,
    StunCheck  = 0.20,
    SCPScan    = 0.70,
}

-- Helper: cek apakah ada ESP yang aktif
local function IsAnyESPActive()
    return ESP_F.Survivor_Name  or ESP_F.Survivor_Highlight
        or ESP_F.Killer_Name    or ESP_F.Killer_Highlight
        or ESP_F.Generator      or ESP_F.Gate
        or ESP_F.Pallet         or ESP_F.Hook
        or (ESP_SCP == true)
end

-- Helper: cek apakah killer scan dibutuhkan
local function IsKillerScanNeeded()
    return WarnKiller or AutoParry or Aimbot or AutoVault
end
-- Default state sebelum cursor diaktifkan
local prevMouseBehavior    = Enum.MouseBehavior.LockCenter
local prevMouseIconEnabled = not isMobile  -- PC = true (cursor terlihat), Mobile = false

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "CustomCursor"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder   = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Enabled        = false
ScreenGui.Parent         = PlayerGui

local Cursor = Instance.new("ImageLabel")
Cursor.Name                   = "Cursor"
Cursor.BackgroundTransparency = 1
Cursor.Size                   = UDim2.fromOffset(32, 32)
Cursor.AnchorPoint            = Vector2.new(0.5, 0.5)
Cursor.ZIndex                 = 999999
Cursor.Image                  = CURSOR_ASSET_ID
Cursor.Parent                 = ScreenGui

local function SetCursorEnabled(state)
    CursorEnabled     = state
    ScreenGui.Enabled = state

    if state then
        -- Simpan state SEBELUM diubah agar bisa di-restore nanti
        prevMouseBehavior    = UserInputService.MouseBehavior
        prevMouseIconEnabled = UserInputService.MouseIconEnabled

        -- Cursor ON: bebaskan mouse, sembunyikan cursor bawaan
        UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = false
    else
        -- Cursor OFF: kembalikan persis ke state sebelum cursor aktif
        UserInputService.MouseBehavior    = prevMouseBehavior
        UserInputService.MouseIconEnabled = prevMouseIconEnabled
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        SetCursorEnabled(not CursorEnabled)
    end
end)
-- 1. SETUP FOV CIRCLE
local IndicatorGui = TargetGui:FindFirstChild("FORKT_Indicator") or Instance.new("ScreenGui")
IndicatorGui.Name = "FORKT_Indicator" 
IndicatorGui.IgnoreGuiInset = true 
IndicatorGui.ResetOnSpawn = false
IndicatorGui.Parent = TargetGui

if IndicatorGui:FindFirstChild("FOVCircle") then IndicatorGui.FOVCircle:Destroy() end
FOVCircle = Instance.new("Frame", IndicatorGui)
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.new(0, AimRadius * 2, 0, AimRadius * 2)
FOVCircle.AnchorPoint = v2(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = ShowFOVCircle

do
    local c = Instance.new("UICorner", FOVCircle)
    c.CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", FOVCircle)
    s.Color = Color3.new(1, 1, 1)
    s.Transparency = 0.5
    s.Thickness = 1.5
end
do
    ESP_SCP = ESP_SCP or false

    local SCPFolder = CoreGui:FindFirstChild("SCP_ESP") or Instance.new("Folder")
    SCPFolder.Name = "SCP_ESP"
    SCPFolder.Parent = CoreGui

    local SCPCache = setmetatable({}, { __mode = "k" })
    local SCPConnection

    local function RemoveSCP(model)
        local esp = SCPCache[model]
        if esp then pcall(function() esp:Destroy() end) end
        SCPCache[model] = nil
    end

    local function CreateSCP(model)
        if not ESP_SCP then return end
        if not (model and model.Parent) then return end
        if SCPCache[model] then return end
        local root = model:FindFirstChild("HumanoidRootPart",true)
            or model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart",true)
        if not root then return end
        local h = Instance.new("Highlight")
        h.Name="SCPESP"; h.Adornee=model
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillColor=Color3.fromRGB(170,0,255)
        h.OutlineColor=Color3.fromRGB(255,220,255)
        h.FillTransparency=0.78; h.OutlineTransparency=0.03
        h.Parent=SCPFolder
        SCPCache[model]=h
        model.AncestryChanged:Connect(function(_,p) if not p then RemoveSCP(model) end end)
        local hum=model:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function() RemoveSCP(model) end) end
    end

    local function GetSCPFolder()
        local map=workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("1")
    end

    local function ScanSCP()
        local folder=GetSCPFolder()
        if not folder then return end
        for _,model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and not SCPCache[model] then CreateSCP(model) end
        end
    end

    local function ConnectSCP()
        if SCPConnection then SCPConnection:Disconnect(); SCPConnection=nil end
        local folder=GetSCPFolder()
        if not folder then return end
        SCPConnection=folder.ChildAdded:Connect(function(model)
            if not ESP_SCP then return end
            task.wait(0.1)
            if model and model.Parent and model:IsA("Model") then CreateSCP(model) end
        end)
    end

    ConnectSCP()
    ScanSCP()
    task.spawn(function()
        while task.wait(TICK.SCPScan) do
            if not getgenv().FORKT_RUNNING then break end
            -- [OPTIM] Skip total jika ESP SCP mati
            if not ESP_SCP then
                for model in pairs(SCPCache) do RemoveSCP(model) end
                continue
            end
            for model, highlight in pairs(SCPCache) do
                if not (model and model.Parent and highlight and highlight.Parent) then
                    RemoveSCP(model)
                else
                    highlight.Adornee         = model
                    highlight.FillTransparency    = 0.78
                    highlight.OutlineTransparency = 0.03
                end
            end
            ScanSCP()
        end
    end)
end
local MoonwalkUI = Instance.new("ScreenGui")
local TweenService = game:GetService("TweenService")

do
    pcall(function()
        MoonwalkUI.Name          = "FORKT_MoonwalkUI"
        MoonwalkUI.Enabled       = false
        MoonwalkUI.ResetOnSpawn  = false
        MoonwalkUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        MoonwalkUI.Parent        = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    end)

    -- ── Container (invisible drag parent — semua anak ikut bergerak) ──
    local Container = Instance.new("Frame")
    Container.Name                = "MWContainer"
    Container.Parent              = MoonwalkUI
    Container.BackgroundTransparency = 1
    Container.Position            = UDim2.new(1, -104, 0.5, -44)
    Container.Size                = UDim2.new(0, 88, 0, 88)
    Container.ZIndex              = 1

    -- ── Glow radial di belakang tombol ──
    local Glow = Instance.new("ImageLabel")
    Glow.Name                = "Glow"
    Glow.Parent              = Container
    Glow.BackgroundTransparency = 1
    Glow.AnchorPoint         = Vector2.new(0.5, 0.5)
    Glow.Position            = UDim2.new(0.5, 0, 0.5, 0)
    Glow.Size                = UDim2.new(1, 0, 1, 0)
    Glow.Image               = "rbxassetid://7072725342"   -- radial gradient
    Glow.ImageColor3         = Color3.fromRGB(60, 60, 72)
    Glow.ImageTransparency   = 0.65
    Glow.ZIndex              = 1

    -- ── Tombol utama ──
    local Btn = Instance.new("Frame")
    Btn.Name         = "Btn"
    Btn.Parent       = Container
    Btn.AnchorPoint  = Vector2.new(0.5, 0.5)
    Btn.Position     = UDim2.new(0.5, 0, 0.5, 0)
    Btn.Size         = UDim2.new(0, 76, 0, 76)
    Btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Btn.ZIndex       = 2

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 20)
    BtnCorner.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color     = Color3.fromRGB(58, 58, 76)
    BtnStroke.Thickness = 1.5
    BtnStroke.Parent    = Btn

    local BtnGrad = Instance.new("UIGradient")
    BtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 44)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 20)),
    })
    BtnGrad.Rotation = 140
    BtnGrad.Parent   = Btn

    -- ── Shine tipis di bagian atas (efek kedalaman) ──
    local Shine = Instance.new("Frame")
    Shine.Parent               = Btn
    Shine.BackgroundColor3     = Color3.fromRGB(255, 255, 255)
    Shine.BackgroundTransparency = 0.86
    Shine.AnchorPoint          = Vector2.new(0.5, 0)
    Shine.Position             = UDim2.new(0.5, 0, 0, 3)
    Shine.Size                 = UDim2.new(0.58, 0, 0, 2)
    Shine.BorderSizePixel      = 0
    Shine.ZIndex               = 3
    Instance.new("UICorner", Shine).CornerRadius = UDim.new(1, 0)

    -- ── Ikon bulan ──
    local Icon = Instance.new("TextLabel")
    Icon.Parent               = Btn
    Icon.BackgroundTransparency = 1
    Icon.AnchorPoint          = Vector2.new(0.5, 0)
    Icon.Position             = UDim2.new(0.5, 0, 0, 8)
    Icon.Size                 = UDim2.new(1, 0, 0, 28)
    Icon.Font                 = Enum.Font.GothamBold
    Icon.Text                 = "🌙"
    Icon.TextColor3           = Color3.fromRGB(185, 185, 208)
    Icon.TextSize             = 22
    Icon.ZIndex               = 3

    -- ── Label "MOONWALK" kecil ──
    local NameLbl = Instance.new("TextLabel")
    NameLbl.Parent               = Btn
    NameLbl.BackgroundTransparency = 1
    NameLbl.AnchorPoint          = Vector2.new(0.5, 0)
    NameLbl.Position             = UDim2.new(0.5, 0, 0, 37)
    NameLbl.Size                 = UDim2.new(1, -4, 0, 12)
    NameLbl.Font                 = Enum.Font.GothamBold
    NameLbl.Text                 = "MOONWALK"
    NameLbl.TextColor3           = Color3.fromRGB(108, 108, 130)
    NameLbl.TextSize             = 7
    NameLbl.ZIndex               = 3

    -- ── Status pill (• OFF / • ON) ──
    local Pill = Instance.new("Frame")
    Pill.Parent          = Btn
    Pill.AnchorPoint     = Vector2.new(0.5, 0)
    Pill.Position        = UDim2.new(0.5, 0, 0, 53)
    Pill.Size            = UDim2.new(0, 44, 0, 15)
    Pill.BackgroundColor3 = Color3.fromRGB(48, 48, 64)
    Pill.ZIndex          = 3
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local PillDot = Instance.new("Frame")
    PillDot.Parent          = Pill
    PillDot.AnchorPoint     = Vector2.new(0, 0.5)
    PillDot.Position        = UDim2.new(0, 6, 0.5, 0)
    PillDot.Size            = UDim2.new(0, 6, 0, 6)
    PillDot.BackgroundColor3 = Color3.fromRGB(108, 108, 130)
    PillDot.ZIndex          = 4
    Instance.new("UICorner", PillDot).CornerRadius = UDim.new(1, 0)

    local PillTxt = Instance.new("TextLabel")
    PillTxt.Parent               = Pill
    PillTxt.BackgroundTransparency = 1
    PillTxt.Position             = UDim2.new(0, 16, 0, 0)
    PillTxt.Size                 = UDim2.new(1, -18, 1, 0)
    PillTxt.Font                 = Enum.Font.GothamBold
    PillTxt.Text                 = "OFF"
    PillTxt.TextColor3           = Color3.fromRGB(108, 108, 130)
    PillTxt.TextSize             = 9
    PillTxt.TextXAlignment       = Enum.TextXAlignment.Left
    PillTxt.ZIndex               = 4

    -- ── Overlay transparan untuk menangkap klik & drag ──
    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Parent               = Btn
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Size                 = UDim2.new(1, 0, 1, 0)
    ClickBtn.Text                 = ""
    ClickBtn.ZIndex               = 10

    -- ═══════════════════════════════
    --  DRAG SYSTEM (beda klik vs geser)
    -- ═══════════════════════════════
    local dragging, dragInput = false, nil
    local dragStart, startPos
    local wasDragged = false

    ClickBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            wasDragged = false
            dragStart  = input.Position
            startPos   = Container.Position
        end
    end)

    ClickBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                wasDragged = true
            end
            Container.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ═══════════════════════════════
    --  ANIMASI
    -- ═══════════════════════════════
    local tSmooth = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tFast   = TweenInfo.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
    local tBounce = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

    local ORANGE  = Color3.fromRGB(247, 107, 28)
    local pulseActive = false

    local function startPulse()
        pulseActive = true
        task.spawn(function()
            while pulseActive do
                TweenService:Create(Glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { ImageTransparency = 0.18 }):Play()
                task.wait(1)
                if not pulseActive then break end
                TweenService:Create(Glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { ImageTransparency = 0.55 }):Play()
                task.wait(1)
            end
        end)
    end

    local function stopPulse()
        pulseActive = false
        TweenService:Create(Glow, tSmooth, {
            ImageColor3      = Color3.fromRGB(60, 60, 72),
            ImageTransparency = 0.65,
        }):Play()
    end

    -- ═══════════════════════════════
    --  TOGGLE LOGIC
    -- ═══════════════════════════════
    local function ToggleMoonwalk()
        if not getgenv().FORKT_PREMIUM then
            if WindUI then
                WindUI:Notify({
                    Title   = "VIP Required",
                    Content = "Fitur ini hanya untuk member Premium!",
                    Icon    = "lucide:lock",
                })
            end
            return
        end

        getgenv().MoonwalkEnabled = not getgenv().MoonwalkEnabled

        -- Animasi bounce tekan
        TweenService:Create(Btn, tFast,   { Size = UDim2.new(0, 70, 0, 70) }):Play()
        task.delay(0.10, function()
            TweenService:Create(Btn, tBounce, { Size = UDim2.new(0, 76, 0, 76) }):Play()
        end)

        if getgenv().MoonwalkEnabled then
            -- ── ON ──
            TweenService:Create(BtnStroke, tSmooth, { Color      = ORANGE                         }):Play()
            TweenService:Create(Icon,      tSmooth, { TextColor3 = Color3.fromRGB(255, 178, 100)  }):Play()
            TweenService:Create(Pill,      tSmooth, { BackgroundColor3 = Color3.fromRGB(75,35,10) }):Play()
            TweenService:Create(PillDot,   tSmooth, { BackgroundColor3 = ORANGE                   }):Play()
            TweenService:Create(PillTxt,   tSmooth, { TextColor3 = ORANGE                         }):Play()
            TweenService:Create(Glow,      tSmooth, { ImageColor3 = ORANGE                        }):Play()
            PillTxt.Text = "ON"
            startPulse()
        else
            -- ── OFF ──
            TweenService:Create(BtnStroke, tSmooth, { Color      = Color3.fromRGB(58,58,76)       }):Play()
            TweenService:Create(Icon,      tSmooth, { TextColor3 = Color3.fromRGB(185,185,208)    }):Play()
            TweenService:Create(Pill,      tSmooth, { BackgroundColor3 = Color3.fromRGB(48,48,64) }):Play()
            TweenService:Create(PillDot,   tSmooth, { BackgroundColor3 = Color3.fromRGB(108,108,130) }):Play()
            TweenService:Create(PillTxt,   tSmooth, { TextColor3 = Color3.fromRGB(108,108,130)    }):Play()
            PillTxt.Text = "OFF"
            stopPulse()
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
    end

    ClickBtn.MouseButton1Click:Connect(function()
        if not wasDragged then ToggleMoonwalk() end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == KEY_TOGGLE then ToggleMoonwalk() end
    end)
end
--// CROSSHAIR SETUP
if TargetGui:FindFirstChild("VeilCrosshair") then
    TargetGui.VeilCrosshair:Destroy()
end

getgenv().CrosshairGui = Instance.new("ScreenGui")
getgenv().CrosshairGui.Name = "VeilCrosshair"
getgenv().CrosshairGui.IgnoreGuiInset = true
getgenv().CrosshairGui.ResetOnSpawn = false
getgenv().CrosshairGui.Enabled = false
getgenv().CrosshairGui.Parent = TargetGui

local crosshair = Instance.new("ImageLabel")
crosshair.Name = "Crosshair"
crosshair.Parent = getgenv().CrosshairGui
crosshair.AnchorPoint = Vector2.new(0.5,0.5)
crosshair.Position = UDim2.new(0.5,0,0.5,0)
crosshair.Size = UDim2.new(0,28,0,28)
crosshair.BackgroundTransparency = 1
crosshair.ImageColor3 = Color3.fromRGB(255,255,255)
crosshair.Image = "rbxassetid://9943168532"
local CrosshairImages = {
    Dot = "rbxassetid://9943168532",
    Scope = "rbxassetid://131437991032048",
    Circle = "rbxassetid://13441606488",
    Plus = "rbxassetid://11770691141",
    Cross = "rbxassetid://9988808810"
}

-- SETUP PARRY RING
do
    local r = TargetGui:FindFirstChild("FORKT_ParryRing")
    if r then r:Destroy() end
end

local ParryRing = Instance.new("CylinderHandleAdornment")
ParryRing.Name         = "FORKT_ParryRing"
ParryRing.Color3       = Color3.fromRGB(170, 40, 255)
ParryRing.Transparency = 0.25
ParryRing.AlwaysOnTop  = true
ParryRing.ZIndex       = 10
ParryRing.Height       = 0.08
ParryRing.Radius       = tonumber(ParryDistance) or 10
ParryRing.InnerRadius  = (tonumber(ParryDistance) or 10) - 0.35  -- hanya border tipis
ParryRing.CFrame       = CFrame.new(0, -2.8, 0) * CFrame.Angles(math.rad(90), 0, 0)
ParryRing.Visible      = false
ParryRing.Parent       = TargetGui

local function UpdateParryRingAdornee()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if ParryRing and hrp then
        ParryRing.Adornee = hrp
    end
end
UpdateParryRingAdornee()
----------------------------------------------------------------
-- UTILITY FUNCTIONS (ESP LOGIC) - OPTIMIZED
----------------------------------------------------------------
local function GetGameValue(obj, name)
    if typeof(obj) ~= "Instance" then return nil end 
    
    -- 1. Cek Attribute Dulu (Sangat Cepat, 0 Lag)
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child then
        if child:IsA("ValueBase") then 
            return child.Value 
        end
    end
    
    return nil
end

local function CreateBillboardTag(text, color, size, textSize)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TagESP"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 150, 0, 40)
    
    billboard.LightInfluence = 0 
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 12
    label.TextWrapped = true
    label.RichText = true 
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.2
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.2
    stroke.Parent = label
    
    label.Parent = billboard
    
    return billboard
end
local isFPP            = false
local fppHideConn      = nil
local fppAutoRotateSet = false
local fppLastChar      = nil
local savedMaxZoom     = 128

-- Cache head & aksesoris agar tidak loop setiap frame
local fppCachedHead        = nil
local fppCachedAccessories = {}

local function BuildFPPCache(char)
    fppCachedHead        = char:FindFirstChild("Head")
    fppCachedAccessories = {}
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") then
            local handle = obj:FindFirstChild("Handle")
            if handle then
                table.insert(fppCachedAccessories, handle)
            end
        end
    end
end

local function SetFPPVisibility(hidden)
    local mod = hidden and 1 or 0
    if fppCachedHead and fppCachedHead.Parent then
        fppCachedHead.LocalTransparencyModifier = mod
    end
    for _, handle in ipairs(fppCachedAccessories) do
        if handle and handle.Parent then
            handle.LocalTransparencyModifier = mod
        end
    end
end

-- Selisih sudut wrap-around safe (e.g. 359° vs 1° = -2°, bukan 358°)
local function AngleDiffDeg(a, b)
    return ((a - b + 180) % 360) - 180
end

local function SwitchCameraMode(toFPP)
    local lp   = Players.LocalPlayer
    local char = lp.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if toFPP then
        local t = lp.Team and lp.Team.Name:lower() or ""
        if t:find("killer") then return end
    end
    if toFPP then
        -- Simpan zoom asli sebelum diubah
        savedMaxZoom  = lp.CameraMaxZoomDistance
        lp.CameraMode = Enum.CameraMode.LockFirstPerson

        -- Build cache untuk karakter saat ini
        if char then BuildFPPCache(char) end
        fppAutoRotateSet = false
        fppLastChar      = char

        if not fppHideConn then
            fppHideConn = RunService.RenderStepped:Connect(function()
                local c   = lp.Character
                local h   = c and c:FindFirstChild("Humanoid")
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local cam = workspace.CurrentCamera
                if not c or not h or not hrp or not cam then return end

                -- Rebuild cache jika karakter respawn
                if c ~= fppLastChar then
                    fppLastChar      = c
                    fppAutoRotateSet = false
                    BuildFPPCache(c)
                end

                -- Set AutoRotate hanya sekali per karakter
                if not fppAutoRotateSet then
                    h.AutoRotate     = false
                    fppAutoRotateSet = true
                end

                -- Sembunyikan head & aksesoris (dari cache, tidak loop GetChildren)
                SetFPPVisibility(true)

                -- Sinkronisasi badan ke kamera (lerp + wrap-around safe)
                local _, lookY, _ = cam.CFrame:ToEulerAnglesYXZ()
                local diff        = AngleDiffDeg(math.deg(lookY), hrp.Orientation.Y)

                if math.abs(diff) > 0.5 then
                    local newY = math.rad(hrp.Orientation.Y + diff * 0.3)
                    hrp.CFrame = cnew(hrp.Position) * cangles(0, newY, 0)
                end
            end)
            getgenv().FORKT_FPPConn = fppHideConn
        end

    else
        -- Kembalikan kamera & zoom ke nilai asli
        lp.CameraMode            = Enum.CameraMode.Classic
        lp.CameraMaxZoomDistance = savedMaxZoom

        -- Disconnect FPP loop
        if fppHideConn then
            fppHideConn:Disconnect()
            fppHideConn      = nil
            getgenv().FORKT_FPPConn = nil
            fppAutoRotateSet = false
            fppLastChar      = nil
        end

        -- Kembalikan transparansi semua part yang disembunyikan
        SetFPPVisibility(false)

        -- Kembalikan AutoRotate
        if hum then hum.AutoRotate = true end

        -- Bersihkan cache
        fppCachedHead        = nil
        fppCachedAccessories = {}
    end
end
local function ApplyHighlight(object, color)
    local root = object:FindFirstChild("HumanoidRootPart") or object.PrimaryPart
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    local dist = 0
    if root and myRoot then
        dist = (root.Position - myRoot.Position).Magnitude
        if dist > 250 then 
            RemoveHighlight(object)
            return 
        end
    end

    -- [REUSE] Gunakan yang sudah ada, jangan buat baru jika tidak perlu
    local h = object:FindFirstChild("H")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "H"
        h.Adornee = object
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = object
    end

    if h.FillColor ~= color then
        h.FillColor = color
        h.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.2)
    end

    if dist > 120 then
        h.FillTransparency = 0.72; h.OutlineTransparency = 0.15
    elseif dist > 70 then
        h.FillTransparency = 0.63; h.OutlineTransparency = 0.08
    elseif dist > 30 then
        h.FillTransparency = 0.55; h.OutlineTransparency = 0.05
    else
        h.FillTransparency = 0.48; h.OutlineTransparency = 0.02
    end

    if not h.Enabled then h.Enabled = true end
end

local function RemoveHighlight(object)
    if object then
        local h = object:FindFirstChild("H")
        if h then h:Destroy() end
    end
end
local function RemovePlayerESP(player)
    local char = player.Character
    if char then
        RemoveHighlight(char)
        local bg = char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("TagESP")
        if bg then bg:Destroy() end
    end
end

local ESP_PlayerCache = {}
local function CreatePlayerESP(player, isKiller)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChild("Humanoid")

    if not root or not hum or hum.Health <= 0 then
        RemovePlayerESP(player)
        ESP_PlayerCache[player.UserId] = nil
        return
    end

    local myRoot = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local dist  = m_floor((root.Position - myRoot.Position).Magnitude)
    local color = isKiller and ESP_COLORS.Killer or ESP_COLORS.Survivor
    local statusText = nil

    ------------------------------------------------
    -- STATUS
    ------------------------------------------------

    if isKiller then
        local detectedMask =
            char:GetAttribute("CachedMask")
            or char:GetAttribute("KillerType")
            or char:GetAttribute("SelectedKiller")
            or GetGameValue(char, "SelectedKiller")
            or GetGameValue(player, "SelectedKiller")
            or GetGameValue(char, "Mask")
            or GetGameValue(player, "Mask")
            or char.Name

        if detectedMask then
            char:SetAttribute("CachedMask", detectedMask)
        end

        statusText = MaskNames[detectedMask] or "KILLER"
        color      = MaskColors[detectedMask] or color
    else
        local function IsActive(v)
            return v == true or (type(v) == "number" and v > 0)
        end

        local hooked  = IsActive(GetGameValue(char, "IsHooked"))
                     or IsActive(GetGameValue(player, "IsHooked"))
        local carried = IsActive(GetGameValue(char, "Carried"))
                     or IsActive(GetGameValue(char, "IsCarried"))
                     or IsActive(GetGameValue(char, "Grabbed"))
                     or IsActive(GetGameValue(player, "Carried"))
        local knocked = IsActive(GetGameValue(char, "Knocked"))
                     or IsActive(GetGameValue(char, "IsKnocked"))

        if hooked then
            color = Color3.fromRGB(255, 70, 140); statusText = "HOOKED"
        elseif carried then
            color = Color3.fromRGB(190, 90, 255); statusText = "CARRIED"
        elseif knocked then
            color = Color3.fromRGB(255, 170, 0);  statusText = "KNOCKED"
        elseif hum.Health < hum.MaxHealth then
            local pct = m_floor((hum.Health / hum.MaxHealth) * 100)
            color      = Color3.fromRGB(255, 220, 80)
            statusText = s_format("INJURED %d%%", pct)
        else
            color      = ESP_COLORS.Survivor
            statusText = nil
        end
    end

    ------------------------------------------------
    -- BUILD TEXT
    ------------------------------------------------

    local line1 = s_format(
        '<font color="#%s"><b>@%s</b></font>',
        color:ToHex(),
        player.Name
    )

    local line2
    if statusText then
        line2 = s_format(
            '<font color="#888888">%dm</font>  <font color="#%s">%s</font>',
            dist,
            color:ToHex(),
            statusText
        )
    else
        line2 = s_format('<font color="#888888">%dm</font>', dist)
    end

    local finalName = line1 .. "\n" .. line2

    ------------------------------------------------
    -- CACHE
    ------------------------------------------------

    ESP_PlayerCache[player.UserId] = { dist = dist, status = statusText }

    local showName      = isKiller and ESP_F.Killer_Name      or ESP_F.Survivor_Name
    local showHighlight = isKiller and ESP_F.Killer_Highlight or ESP_F.Survivor_Highlight

    if showHighlight then ApplyHighlight(char, color)
    else RemoveHighlight(char) end

    ------------------------------------------------
    -- BILLBOARD
    ------------------------------------------------

    local bg = root:FindFirstChild("TagESP")

    if showName then

        if not bg then
            bg               = Instance.new("BillboardGui")
            bg.Name          = "TagESP"
            bg.Adornee       = root
            bg.AlwaysOnTop   = true
            bg.LightInfluence = 0
            bg.ResetOnSpawn  = false
            bg.MaxDistance   = 1800
            bg.Size          = UDim2.new(0, 160, 0, 34)
            bg.StudsOffset   = v3(0, 3.6, 0)
            bg.Parent        = root

            local lbl                  = Instance.new("TextLabel")
            lbl.Name                   = "Label"
            lbl.Size                   = UDim2.fromScale(1, 1)
            lbl.BackgroundTransparency = 1
            lbl.RichText               = true
            lbl.TextScaled             = false
            lbl.TextWrapped            = false
            lbl.Font                   = Enum.Font.GothamBold
            lbl.TextSize               = 9
            lbl.TextStrokeTransparency = 1
            lbl.TextYAlignment         = Enum.TextYAlignment.Center
            lbl.TextXAlignment         = Enum.TextXAlignment.Center
            lbl.Text                   = finalName
            lbl.TextColor3             = color
            lbl.Parent                 = bg

            local stroke         = Instance.new("UIStroke")
            stroke.Thickness     = 1.4
            stroke.Transparency  = 0.1
            stroke.Color         = Color3.new(0, 0, 0)
            stroke.Parent        = lbl

            local constraint       = Instance.new("UITextSizeConstraint")
            constraint.MaxTextSize = 9
            constraint.MinTextSize = 5
            constraint.Parent      = lbl
        end

        local lbl = bg:FindFirstChild("Label")
        if lbl then
            lbl.Text       = finalName
            lbl.TextColor3 = color

            if dist > 220 then
                bg.Size = UDim2.new(0, 110, 0, 22); bg.StudsOffset = v3(0, 1.8, 0)
                lbl.TextSize = 6; lbl.TextTransparency = 0.2
            elseif dist > 150 then
                bg.Size = UDim2.new(0, 130, 0, 26); bg.StudsOffset = v3(0, 2.4, 0)
                lbl.TextSize = 7; lbl.TextTransparency = 0.1
            elseif dist > 90 then
                bg.Size = UDim2.new(0, 145, 0, 30); bg.StudsOffset = v3(0, 3.0, 0)
                lbl.TextSize = 8; lbl.TextTransparency = 0
            else
                bg.Size = UDim2.new(0, 160, 0, 34); bg.StudsOffset = v3(0, 3.6, 0)
                lbl.TextSize = 9; lbl.TextTransparency = 0
            end
        end

    elseif bg then
        bg:Destroy()
    end
end
local GEN_COLOR_MID=Color3.fromRGB(255,140,0)
local GEN_COLOR_END=Color3.fromRGB(0,255,120)

local function updateGeneratorProgress(generator)
    if not generator or not generator.Parent then
        return true
    end

    local percent=GetGameValue(generator,"RepairProgress") or GetGameValue(generator,"Progress") or 0
    local billboard=generator:FindFirstChild("GenBitchHook")

    if percent>=100 or not ESP_F.Generator then
        if billboard then
            billboard:Destroy()
        end
        RemoveHighlight(generator)
        generator:SetAttribute("LastESPPercent",nil)
        return percent>=100
    end

    local rounded=math.floor(percent*10)/10

    if generator:GetAttribute("LastESPPercent")==rounded and billboard then
        return false
    end

    generator:SetAttribute("LastESPPercent",rounded)

    local cp=math.clamp(percent,0,100)

    local finalColor=
        cp<50
        and ESP_COLORS.Generator:Lerp(GEN_COLOR_MID,cp/50)
        or GEN_COLOR_MID:Lerp(GEN_COLOR_END,(cp-50)/50)

    ApplyHighlight(generator,finalColor)

    local targetPart=
        generator:FindFirstChild("RootPart",true)
        or generator:FindFirstChild("defaultMaterial",true)
        or generator.PrimaryPart
        or generator:FindFirstChildWhichIsA("BasePart",true)
    
    if not targetPart then
        return false
    end
    
    local percentStr=s_format("%.1f%%",rounded)
    
    if not billboard then
    
        billboard=Instance.new("BillboardGui")
        billboard.Name="GenBitchHook"
        billboard.Parent=generator
        billboard.Adornee=targetPart
        billboard.AlwaysOnTop=true
        billboard.LightInfluence=0
        billboard.ResetOnSpawn=false
        billboard.MaxDistance=300
        billboard.Size=UDim2.new(0,125,0,24)
    
        local yOffset=2.8
    
        pcall(function()
    
            yOffset=
                math.clamp(
                    (targetPart.Size.Y*0.5)+1.15,
                    2.8,
                    4.2
                )
        end)
    
        billboard.StudsOffset=v3(0,yOffset,0)
    
        local lbl=Instance.new("TextLabel")
        lbl.Name="Label"
        lbl.Parent=billboard
        lbl.BackgroundTransparency=1
        lbl.Size=UDim2.fromScale(1,1)
        lbl.Font=Enum.Font.GothamBold
        lbl.TextSize=8
        lbl.TextScaled=false
        lbl.TextWrapped=false
        lbl.RichText=false
        lbl.TextXAlignment=Enum.TextXAlignment.Center
        lbl.TextYAlignment=Enum.TextYAlignment.Center
        lbl.Text=percentStr
        lbl.TextColor3=finalColor
    
        local stroke=Instance.new("UIStroke")
        stroke.Parent=lbl
        stroke.Thickness=1
        stroke.Transparency=0.2
        stroke.Color=Color3.new(0,0,0)
    
        local constraint=Instance.new("UITextSizeConstraint")
        constraint.Parent=lbl
        constraint.MaxTextSize=8
        constraint.MinTextSize=6
    
    else
    
        if billboard.Adornee~=targetPart then
            billboard.Adornee=targetPart
        end
    
        local yOffset=2.8
    
        pcall(function()
    
            yOffset=
                math.clamp(
                    (targetPart.Size.Y*0.5)+1.15,
                    2.8,
                    4.2
                )
        end)
    
        billboard.StudsOffset=v3(0,yOffset,0)
    
        local lbl=billboard:FindFirstChild("Label")
    
        if lbl then
            lbl.Text=percentStr
            lbl.TextColor3=finalColor
        end
    end
    return false
end
-- Taruh di luar RefreshESP agar tidak dibuat ulang tiap panggil
local function IsStatusActive(val)
    return val == true or (type(val) == "number" and val > 0)
end

-- Cache mesh parts tiap hook agar tidak GetDescendants() setiap refresh
local HookMeshCache = setmetatable({}, { __mode = "k" })

local function RefreshESP()
    if not workspace.CurrentCamera then return end

    local mapFolder = workspace:FindFirstChild("Map")
    local inRound   = mapFolder and mapFolder.Parent and #mapFolder:GetChildren() > 0
    if not inRound then return end

    local players = Players:GetPlayers()
    if #players <= 1 then return end

    ------------------------------------------------
    -- 1. PLAYER ESP
    ------------------------------------------------
    for _, p in ipairs(players) do
        if p == LocalPlayer then continue end

        local teamName = p.Team and p.Team.Name:lower() or ""
        local isKiller = teamName:find("killer") ~= nil
        local shouldESP = (isKiller     and (ESP_F.Killer_Name   or ESP_F.Killer_Highlight))
                       or (not isKiller and (ESP_F.Survivor_Name or ESP_F.Survivor_Highlight))

        if shouldESP then CreatePlayerESP(p, isKiller) else RemovePlayerESP(p) end
    end

    if not CachedMapObjects then return end

    ------------------------------------------------
    -- 2. GENERATOR ESP
    ------------------------------------------------
    if ESP_F.Generator then
        PrevESPState.Generator = true
        local gens          = CachedMapObjects.Generators
        local newActiveGens = {}

        for i = 1, #gens do
            local obj = gens[i]
            if obj and obj.Parent then
                if not updateGeneratorProgress(obj) then
                    t_insert(newActiveGens, obj)
                end
            end
        end

        CachedMapObjects.Generators = newActiveGens
        ActiveGenerators             = newActiveGens

    elseif PrevESPState.Generator then
        for _, obj in ipairs(CachedMapObjects.Generators) do
            if obj and obj.Parent then
                RemoveHighlight(obj)
                local b = obj:FindFirstChild("GenBitchHook")
                if b then b:Destroy() end
                obj:SetAttribute("LastESPPercent", nil)
            end
        end
        PrevESPState.Generator = false
    end

    ------------------------------------------------
    -- 3. PALLET ESP
    ------------------------------------------------
    if ESP_F.Pallet then
        PrevESPState.Pallet = true
        local pallets      = CachedMapObjects.Pallets
        local MAX_DISTANCE = 140

        for i = #pallets, 1, -1 do
            local pallet = pallets[i]

            -- Hapus jika tidak valid
            if not (pallet and pallet.Parent and pallet:IsDescendantOf(workspace)) then
                if pallet then
                    local tag = pallet:FindFirstChild("PalletTag")
                    if tag then tag:Destroy() end
                end
                t_remove(pallets, i)
                continue
            end

            local targetPart = (pallet:IsA("Model") and pallet.PrimaryPart)
                            or pallet:FindFirstChildWhichIsA("BasePart", true)
                            or (pallet:IsA("BasePart") and pallet)

            -- FIX: cache nama lowercase sebagai attribute (dihitung sekali saja)
            local nLower = pallet:GetAttribute("FORKT_NameLower")
            if not nLower then
                nLower = string.lower(pallet.Name)
                pallet:SetAttribute("FORKT_NameLower", nLower)
            end

            local isDropped = IsStatusActive(GetGameValue(pallet, "Dropped"))
                           or IsStatusActive(GetGameValue(pallet, "IsDropped"))
            local isBroken  = IsStatusActive(GetGameValue(pallet, "Broken"))
                           or IsStatusActive(GetGameValue(pallet, "IsBroken"))
                           or IsStatusActive(GetGameValue(pallet, "Destroyed"))
            local isFake    = nLower:find("fake") or nLower:find("broken") or nLower:find("destroyed")

            -- Cek visibilitas
            local hasVisibleParts = false
            if targetPart then
                if pallet:IsA("BasePart") then
                    hasVisibleParts = pallet.Transparency < 1
                else
                    local parts = pallet:GetDescendants()
                    for j = 1, #parts do
                        if parts[j]:IsA("BasePart") and parts[j].Transparency < 1 then
                            hasVisibleParts = true
                            break
                        end
                    end
                end
            end

            if isDropped or isBroken or isFake or not hasVisibleParts or not targetPart then
                local tag = pallet:FindFirstChild("PalletTag")
                if tag then tag:Destroy() end
                if isDropped or isBroken or isFake then
                    t_remove(pallets, i)
                end
            else
                local tag = pallet:FindFirstChild("PalletTag")
                if not tag then
                    local b = CreateBillboardTag("<b>[PALLET]</b>", ESP_COLORS.Pallet, UDim2.new(0, 50, 0, 18), 6)
                    b.Name        = "PalletTag"
                    b.Parent      = pallet
                    b.Adornee     = targetPart
                    b.MaxDistance = MAX_DISTANCE
                else
                    if not tag.Adornee then tag.Adornee = targetPart end
                    local lbl = tag:FindFirstChild("Label")
                    if lbl and lbl.TextColor3 ~= ESP_COLORS.Pallet then
                        lbl.TextColor3 = ESP_COLORS.Pallet
                    end
                end
            end
        end

    elseif PrevESPState.Pallet then
        for _, pallet in ipairs(CachedMapObjects.Pallets) do
            if pallet then
                local tag = pallet:FindFirstChild("PalletTag")
                if tag then tag:Destroy() end
            end
        end
        PrevESPState.Pallet = false
    end

    ------------------------------------------------
    -- 4. GATE ESP
    ------------------------------------------------
    if ESP_F.Gate then
        PrevESPState.Gate = true
        local gates = CachedMapObjects.Gates
        for i = #gates, 1, -1 do
            local gate = gates[i]
            if gate and gate.Parent then
                ApplyHighlight(gate, ESP_COLORS.Gate)
            else
                t_remove(gates, i)
            end
        end

    elseif PrevESPState.Gate then
        for _, gate in ipairs(CachedMapObjects.Gates) do
            if gate and gate.Parent then RemoveHighlight(gate) end
        end
        PrevESPState.Gate = false
    end

        ------------------------------------------------
    -- 5. HOOK ESP
    ------------------------------------------------
    if ESP_F.Hook then
        PrevESPState.Hook = true
        local hooks = CachedMapObjects.Hooks

        for i = #hooks, 1, -1 do
            local hook = hooks[i]
            if not (hook and hook.Parent) then
                HookMeshCache[hook] = nil
                t_remove(hooks, i)
                continue
            end

            -- Menggunakan GetChildren alih-alih GetDescendants yang berat
            local meshParts = HookMeshCache[hook]
            if not meshParts then
                meshParts = {}
                local m = hook:FindFirstChild("Model") or hook
                for _, p in ipairs(m:GetChildren()) do
                    if p:IsA("MeshPart") then t_insert(meshParts, p) end
                end
                HookMeshCache[hook] = meshParts
            end

            if #meshParts > 0 then
                for _, mp in ipairs(meshParts) do
                    if mp and mp.Parent then ApplyHighlight(mp, ESP_COLORS.Hook) end
                end
            else
                ApplyHighlight(hook, ESP_COLORS.Hook)
            end
        end

    elseif PrevESPState.Hook then
        for _, hook in ipairs(CachedMapObjects.Hooks) do
            if not (hook and hook.Parent) then continue end
            local meshParts = HookMeshCache[hook]
            if meshParts and #meshParts > 0 then
                for _, mp in ipairs(meshParts) do
                    if mp and mp.Parent then RemoveHighlight(mp) end
                end
            else
                RemoveHighlight(hook)
            end
            HookMeshCache[hook] = nil
        end
        PrevESPState.Hook = false
    end
end

-- =========================================================
-- UTILITY: OPTIMIZED RAYCAST (HANYA DITULIS 1 KALI)
-- =========================================================
local cachedRayFilter = {}
local globalRayParams = RaycastParams.new()
globalRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function IsVisible(targetPart)
    if not WallCheck then return true end
    
    local cam = workspace.CurrentCamera
    if not cam or not targetPart then return true end
    
    local origin = cam.CFrame.Position
    local direction = (targetPart.Position - origin)
    local myChar = LocalPlayer.Character
    
    table.clear(cachedRayFilter)
    table.insert(cachedRayFilter, cam)
    if myChar then table.insert(cachedRayFilter, myChar) end
    
    globalRayParams.FilterDescendantsInstances = cachedRayFilter
    
    local result = workspace:Raycast(origin, direction, globalRayParams)
    if result then 
        return result.Instance:IsDescendantOf(targetPart.Parent) 
    end
    
    return true
end

local function ResetScope()

    local char=LocalPlayer.Character

    if not char then
        return
    end

    local hum=
        char:FindFirstChild(
            "Humanoid"
        )

    if hum then

        for _,track in ipairs(
            hum:GetPlayingAnimationTracks()
        ) do

            local anim=track.Animation

            local name=
                (
                    anim
                    and anim.Name:lower()
                )
                or ""

            if name:find("aim")
            or name:find("scope")
            or name:find("gun") then

                pcall(function()
                    track:Stop(0)
                end)
            end
        end
    end

    workspace.CurrentCamera.FieldOfView=70
end

----------------------------------------------------------------
-- TARGET FINDER
----------------------------------------------------------------

local function GetClosestSilentTarget()
    local camera = workspace.CurrentCamera
    local center = camera.ViewportSize * 0.5

    local myTeam = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    if myTeam:find("killer") then return nil end

    local closest  = nil
    local shortest = SilentAimFOV or 250

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end

        local enemyTeam = (p.Team and p.Team.Name:lower()) or ""
        if not enemyTeam:find("killer") then continue end

        local char = p.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")

        if not root or not hum or hum.Health <= 0 then continue end

        -- Skip jika knocked/hooked
        if GetGameValue(char, "Knocked")
        or GetGameValue(char, "IsHooked") then continue end

        local screenPos, visible = camera:WorldToViewportPoint(root.Position)
        if not visible then continue end

        if WallCheck and not IsVisible(root) then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < shortest then
            shortest = dist
            closest  = root
        end
    end

    return closest
end

local function GetClosestPlayer(currentTarget)
    local camera   = workspace.CurrentCamera
    local center   = camera.ViewportSize * 0.5
    local camPos   = camera.CFrame.Position
    local myTeam   = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    local isKiller = myTeam:find("killer")

    -- Invalidasi cache jika AimbotPart berubah
    local currentPart = getgenv().AimbotPart or "Torso"
    if getgenv()._LastAimbotPart ~= currentPart then
        table.clear(TargetPartCache)
        getgenv()._LastAimbotPart = currentPart
    end

    ------------------------------------------------
    -- STICKY TARGET
    ------------------------------------------------
    if currentTarget and currentTarget.Parent then
        local parentChar = currentTarget.Parent
        local hum        = parentChar:FindFirstChildOfClass("Humanoid")

        if hum and hum.Health > 0 then
            -- FIX: validasi tim sebelum mempertahankan target
            local owner      = Players:GetPlayerFromCharacter(parentChar)
            local targetTeam = (owner and owner.Team and owner.Team.Name:lower()) or ""
            local isEnemy    = (isKiller and not targetTeam:find("killer"))
                            or (not isKiller and targetTeam:find("killer"))

            if isEnemy then
                local pos, visible = camera:WorldToViewportPoint(currentTarget.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist <= AimRadius then
                        if not WallCheck or IsVisible(currentTarget) then
                            return currentTarget
                        end
                    end
                end
            end
        end
    end

    ------------------------------------------------
    -- FIND NEW TARGET
    ------------------------------------------------
    local shortest  = AimRadius
    local bestTarget = nil  -- FIX: pakai local, jangan langsung assign CachedTarget di loop

    -- Tentukan list target berdasarkan apakah Anda Killer atau Survivor
    local targetList = isKiller and CachedSurvivors or CachedKillers

    for i = 1, #targetList do
        local p = targetList[i]
        if not p or not p.Character then continue end

        local char = p.Character
        local hum  = char:FindFirstChildOfClass("Humanoid")

        if not hum or hum.Health <= 0 then continue end

        -- Skip hooked / knocked (hanya jika Anda killer yang mengejar survivor)
        if isKiller then
            if GetGameValue(char, "Knocked") or GetGameValue(char, "IsHooked") then continue end
        end

        -- Target part (cache, repakai currentPart dari atas)
        local targetPart = TargetPartCache[char]
        if not targetPart or not targetPart.Parent then
            targetPart = (currentPart == "Head"          and char:FindFirstChild("Head"))
                      or (currentPart == "Body (RootPart)" and char:FindFirstChild("HumanoidRootPart"))
                      or char:FindFirstChild("UpperTorso")
                      or char:FindFirstChild("Torso")
                      or char:FindFirstChild("HumanoidRootPart")
                      or char.PrimaryPart
            TargetPartCache[char] = targetPart
        end

        if not targetPart then continue end

        -- 3D distance
        if (targetPart.Position - camPos).Magnitude > AimDistance then continue end

        -- Screen space
        local pos, visible = camera:WorldToViewportPoint(targetPart.Position)
        if not visible then continue end

        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < shortest then
            if not WallCheck or IsVisible(targetPart) then
                shortest   = dist
                bestTarget = targetPart
            end
        end
    end

    -- FIX: assign global hanya sekali di akhir, bukan di dalam loop
    CachedTarget = bestTarget
    return CachedTarget
end
-- =========================================================
-- REMOTE CACHE
-- =========================================================
local AIRemotes = {
    RepairEvent        = nil,
    SkillCheckResult   = nil,
    HealEvent          = nil,
}
-- =========================================================
-- STATE MACHINE
-- =========================================================
local AIState = {
    current       = "Idle",
    activeGen     = nil,
    activePoint   = nil,
    repairStarted = false,
    lastRepairFire = 0,
    lastSkillFire  = 0,
    evadeUntil     = 0,
}
local AIRemotesFound = false
local SetAIState

-- Bungkus helper functions (BUKAN AIRemotes/AIState/AIRemotesFound, tetap di luar):
do
    local function FindAIRemotes()
        if AIRemotesFound then return end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local genFolder = remotes:FindFirstChild("Generator")
        if genFolder then
            AIRemotes.RepairEvent      = genFolder:FindFirstChild("RepairEvent")
            AIRemotes.SkillCheckResult = genFolder:FindFirstChild("SkillCheckResultEvent")
        end
        local healFolder = remotes:FindFirstChild("Healing")
        if healFolder then AIRemotes.HealEvent = healFolder:FindFirstChild("HealEvent") end
        if AIRemotes.RepairEvent then AIRemotesFound = true end
    end

    local function GetNearestGenPoint(gen, myPos)
        local bestPart, bestDist = nil, math.huge
        -- Gunakan GetChildren atau PrimaryPart langsung jika ada, batasi pencarian
        for _, obj in ipairs(gen:GetChildren()) do
            if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "generatorpoint") then
                local d = (obj.Position - myPos).Magnitude
                if d < bestDist then bestDist = d; bestPart = obj end
            end
        end
        -- Fallback ke Model anak pertama jika tidak ketemu di tingkat 1
        if not bestPart then
            for _, modelChild in ipairs(gen:GetChildren()) do
                if modelChild:IsA("Model") then
                    for _, obj in ipairs(modelChild:GetChildren()) do
                        if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "generatorpoint") then
                            local d = (obj.Position - myPos).Magnitude
                            if d < bestDist then bestDist = d; bestPart = obj end
                        end
                    end
                end
            end
        end
        return bestPart
    end

    local function GetBestGenerator(myPos, killerPos)
        if not CachedMapObjects or not CachedMapObjects.Generators then return nil,nil end
        local bestGen,bestPoint,bestScore = nil,nil,-math.huge
        for _, gen in ipairs(CachedMapObjects.Generators) do
            if not gen or not gen.Parent then continue end
            local progress = GetGameValue(gen,"RepairProgress") or GetGameValue(gen,"Progress") or 0
            if progress >= 100 then continue end
            local ok, pivot = pcall(function() return gen:GetPivot().Position end)
            if not ok then continue end
            local distFromMe     = (pivot - myPos).Magnitude
            local distFromKiller = killerPos and (pivot - killerPos).Magnitude or 999
            local score = (distFromKiller*0.6) - (distFromMe*0.4) + (progress*0.2)
            if score > bestScore then
                local point = GetNearestGenPoint(gen, myPos)
                if point then bestScore=score; bestGen=gen; bestPoint=point end
            end
        end
        return bestGen, bestPoint
    end

    local function CountCompletedGens()
        local count = 0
        if not CachedMapObjects or not CachedMapObjects.Generators then return 0 end
        for _, gen in ipairs(CachedMapObjects.Generators) do
            local p = GetGameValue(gen,"RepairProgress") or GetGameValue(gen,"Progress") or 0
            if p >= 100 then count += 1 end
        end
        return count
    end

    local function GetNearestGate(myPos)
        if not CachedMapObjects or not CachedMapObjects.Gates then return nil end
        local best, bestDist = nil, math.huge
        for _, gate in ipairs(CachedMapObjects.Gates) do
            if gate and gate.Parent then
                local ok, pos = pcall(function() return gate:GetPivot().Position end)
                if ok then
                    local d = (pos - myPos).Magnitude
                    if d < bestDist then bestDist=d; best=pos end
                end
            end
        end
        return best
    end

    local function TeleportAwayFromKiller(root, killerPos, targetGenPos)
        local myPos  = root.Position
        local runDir = (myPos - killerPos).Unit
        if targetGenPos then
            runDir = (runDir + (targetGenPos - myPos).Unit * 0.5).Unit
        end
        local escapePos = myPos + runDir * 35
        escapePos = v3(escapePos.X, myPos.Y, escapePos.Z)
        pcall(function() root.CFrame = CFrame.new(escapePos) end)
    end

    SetAIState = function(newState)
        if AIState.current == newState then return end
        AIState.current = newState
        local icons = {
            Idle="lucide:coffee", Repairing="lucide:wrench",
            Evading="lucide:footprints", Healing="lucide:heart-handshake",
            Escaping="lucide:door-open"
        }
        WindUI:Notify({ Title="AI  "..string.upper(newState), Content="State: "..newState, Icon=icons[newState] or "lucide:bot", Duration=2.5 })
    end

    
    -- =========================================================
    -- THREAD 1: OTAK AI (0.35s interval)
    -- =========================================================
    task.spawn(function()
        while task.wait(TICK.AIBrain) do
            if not getgenv().FORKT_RUNNING then break end
            if not AutoFarmBot then
                AIState.current       = "Idle"
                AIState.activeGen     = nil
                AIState.activePoint   = nil
                AIState.repairStarted = false
                getgenv().AIFinalTarget  = nil
                getgenv().CachedWaypoints = nil
                continue
            end
    
            FindAIRemotes()
    
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if not myRoot or not myHum or myHum.Health <= 0 then return end
    
                local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
                if myTeam:find("killer") then return end
    
                -- Immobilized check
                if GetGameValue(myChar, "IsHooked") or myChar:GetAttribute("IsHooked")
                or GetGameValue(myChar, "Carried")  or myChar:GetAttribute("Carried") then
                    getgenv().AIFinalTarget   = nil
                    getgenv().CachedWaypoints = nil
                    AIState.repairStarted = false
                    return
                end
    
                local myPos = myRoot.Position
                local now   = os.clock()
    
                -- Scan killer
                local killerRoot = nil
                local killerDist = 999
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LocalPlayer or not p.Character then continue end
                    local eTeam = p.Team and p.Team.Name:lower() or ""
                    if not eTeam:find("killer") then continue end
                    local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if eRoot then
                        local d = (eRoot.Position - myPos).Magnitude
                        if d < killerDist then killerDist = d; killerRoot = eRoot end
                    end
                end
    
                local killerPos = killerRoot and killerRoot.Position
    
                -- Scan injured teammate
                local injuredChar, injuredDist = nil, 999
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LocalPlayer or not p.Character then continue end
                    local eTeam = p.Team and p.Team.Name:lower() or ""
                    if eTeam:find("killer") then continue end
                    local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    local eHum  = p.Character:FindFirstChildOfClass("Humanoid")
                    if eRoot and eHum then
                        local isKnocked = GetGameValue(p.Character, "Knocked")
                        local isInjured = eHum.Health < eHum.MaxHealth
                        local d = (eRoot.Position - myPos).Magnitude
                        if (isKnocked or isInjured) and d < injuredDist and d < 80 then
                            injuredDist = d; injuredChar = p.Character
                        end
                    end
                end
    
                local completedGens = CountCompletedGens()
    
                -- =============================================
                -- STATE LOGIC
                -- =============================================
    
                -- PRIORITAS 1: EVADE jika killer < 55 studs
                if killerDist <= 55 then
                    SetAIState("Evading")
                    AIState.repairStarted = false
                    AIState.evadeUntil    = now + 3.0
    
                    -- Cari gen terbaik untuk tujuan lari sekaligus
                    local _, bestPoint = GetBestGenerator(myPos, killerPos)
                    local targetPos = bestPoint and bestPoint.Position
    
                    -- Teleport jika killer < 25 studs (darurat)
                    if killerDist < 25 then
                        TeleportAwayFromKiller(myRoot, killerPos, targetPos)
                        task.wait(0.1)
                    end
    
                    -- Pathfind ke gen terjauh dari killer
                    if targetPos then
                        getgenv().AIFinalTarget = targetPos
                    else
                        local runDir = (myPos - killerPos).Unit
                        getgenv().AIFinalTarget = myPos + runDir * 50
                    end
    
                    -- Reset gen aktif agar cari gen baru setelah evade
                    AIState.activeGen   = nil
                    AIState.activePoint = nil
    
                -- PRIORITAS 2: ESCAPE jika 5 gen selesai
                elseif completedGens >= 5 then
                    SetAIState("Escaping")
                    AIState.repairStarted = false
                    local gatePos = GetNearestGate(myPos)
                    if gatePos then
                        getgenv().AIFinalTarget = gatePos
                    end
    
                -- PRIORITAS 3: HEAL teman
                elseif injuredChar and injuredDist < 80 then
                    SetAIState("Healing")
                    AIState.repairStarted = false
                    local injRoot = injuredChar:FindFirstChild("HumanoidRootPart")
                    if injRoot then
                        getgenv().AIFinalTarget = injRoot.Position
                    end
    
                -- PRIORITAS 4: REPAIR generator
                else
                    -- Validasi gen aktif masih valid
                    local genStillValid = AIState.activeGen
                        and AIState.activeGen.Parent
                        and (GetGameValue(AIState.activeGen, "RepairProgress")
                          or GetGameValue(AIState.activeGen, "Progress") or 0) < 100
    
                    if not genStillValid then
                        local bestGen, bestPoint = GetBestGenerator(myPos, killerPos)
                        AIState.activeGen     = bestGen
                        AIState.activePoint   = bestPoint
                        AIState.repairStarted = false
                    end
    
                    if AIState.activePoint then
                        SetAIState("Repairing")
                        getgenv().AIFinalTarget = AIState.activePoint.Position
                    end
                end
    
                -- =============================================
                -- PATHFIND ke target
                -- =============================================
                local finalTarget = getgenv().AIFinalTarget
                if finalTarget then
                    local lastCalc   = getgenv().LastPathCalc or 0
                    local lastTarget = getgenv().LastTargetPos or v3()
    
                    if (finalTarget - lastTarget).Magnitude > 4 or (now - lastCalc) > 1.8 then
                        getgenv().LastPathCalc  = now
                        getgenv().LastTargetPos = finalTarget
    
                        task.spawn(function()
                            pcall(function()
                                local path = PathfindingService:CreatePath({
                                    AgentRadius   = 2.5,
                                    AgentHeight   = 5,
                                    AgentCanJump  = true,
                                    WaypointSpacing = 4
                                })
                                path:ComputeAsync(myPos, finalTarget)
                                if path.Status == Enum.PathStatus.Success then
                                    getgenv().CachedWaypoints    = path:GetWaypoints()
                                    getgenv().CurrentWaypointIdx = 2
                                else
                                    -- Fallback: jalan langsung
                                    getgenv().CachedWaypoints = nil
                                end
                            end)
                        end)
                    end
                end
    
                -- =============================================
                -- REPAIR REMOTE: FireServer saat dekat gen
                -- =============================================
                if AIState.current == "Repairing"
                and AIState.activeGen
                and AIState.activePoint
                and AIRemotes.RepairEvent then
    
                    local distToGen = (AIState.activePoint.Position - myPos).Magnitude
    
                    if distToGen <= 8 then
                        -- Start repair jika belum
                        if not AIState.repairStarted
                        and (now - AIState.lastRepairFire) > 1.0 then
                            AIState.lastRepairFire = now
                            AIState.repairStarted  = true
    
                            pcall(function()
                                AIRemotes.RepairEvent:FireServer(
                                    AIState.activePoint,
                                    true
                                )
                            end)
                        end
    
                        -- Auto SkillCheck: kirim "success" setiap 0.6s
                        if AIState.repairStarted
                        and AIRemotes.SkillCheckResult
                        and (now - AIState.lastSkillFire) > 0.6 then
                            AIState.lastSkillFire = now
    
                            pcall(function()
                                AIRemotes.SkillCheckResult:FireServer(
                                    "success",
                                    1,
                                    AIState.activeGen,
                                    AIState.activePoint
                                )
                            end)
                        end
    
                    elseif distToGen > 8 and AIState.repairStarted then
                        -- Keluar dari range, reset
                        AIState.repairStarted = false
                    end
                end
    
                -- =============================================
                -- HEAL REMOTE saat dekat teman
                -- =============================================
                if AIState.current == "Healing"
                and injuredChar
                and injuredDist <= 8
                and AIRemotes.HealEvent then
                    local injRoot = injuredChar:FindFirstChild("HumanoidRootPart")
                    if injRoot then
                        pcall(function()
                            AIRemotes.HealEvent:FireServer(injRoot, true)
                        end)
                    end
    
                    getgenv().AIFinalTarget   = nil
                    getgenv().CachedWaypoints = nil
                    if myHum then myHum:MoveTo(myPos) end
                end
            end)
        end
    end)
    
    -- =========================================================
    -- THREAD 2: KAKI AI (0.05s - pergerakan halus)
    -- =========================================================
    task.spawn(function()
        while task.wait(TICK.AILegs) do
            if not getgenv().FORKT_RUNNING then break end
            if not AutoFarmBot then continue end
    
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if not myRoot or not myHum or myHum.Health <= 0 then return end
                local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
                if myTeam:find("killer") then return end
                local myPos    = myRoot.Position
                local waypoints = getgenv().CachedWaypoints
                local idx       = getgenv().CurrentWaypointIdx
    
                if waypoints and idx and idx <= #waypoints then
                    local nextPt = waypoints[idx]
                    local flat   = v3(nextPt.Position.X, myPos.Y, nextPt.Position.Z)
                    local dist2D = (flat - myPos).Magnitude
    
                    if dist2D < 4 then
                        getgenv().CurrentWaypointIdx = idx + 1
                        nextPt = waypoints[getgenv().CurrentWaypointIdx] or nextPt
                    end
    
                    if nextPt then
                        myHum:MoveTo(nextPt.Position)
                        if nextPt.Action == Enum.PathWaypointAction.Jump then
                            myHum.Jump = true
                        end
                    end
                elseif getgenv().AIFinalTarget then
                    myHum:MoveTo(getgenv().AIFinalTarget)
                end
    
                -- Anti-stuck
                local nowT        = os.clock()
                local lastBotPos  = getgenv().LastBotPos  or myPos
                local lastBotTime = getgenv().LastBotTime or nowT
    
                if getgenv().AIFinalTarget then
                    if (myPos - lastBotPos).Magnitude < 0.4 then
                        if nowT - lastBotTime > 1.2 then
                            myHum.Jump = true
                            pcall(function()
                                myRoot.CFrame = myRoot.CFrame
                                    * CFrame.new(math.random(-2, 2), 0, math.random(1, 3))
                            end)
                            getgenv().LastBotTime = nowT + 0.8
                        end
                    else
                        getgenv().LastBotPos  = myPos
                        getgenv().LastBotTime = nowT
                    end
                end
            end)
        end
    end)
end
----------------------------------------------------------------
-- AUTO GENERATOR
-- ALL DEVICE + ALL EXECUTOR SUPPORT
----------------------------------------------------------------

do
    local LastSkillHit    = 0
    local LastGoalRotation = 0
    local LastTriggerTick  = 0
    local LastStuckCheck   = 0
    local LastStuckPos     = nil
    local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
                  or (UserInputService.TouchEnabled and UserInputService.GamepadEnabled)
    local canFireSignal   = type(getgenv()["firesignal"])=="function" or type(_G["firesignal"])=="function"
    local canVirtualInput = pcall(function() return VirtualInputManager ~= nil end)
    local SkillCheckNames = {"SkillCheckPromptGui","SkillCheckPromptGui-con","SkillCheck","SkillCheckGui","CheckGui"}
    
    local function GetSkillCheck()
        -- Cari berdasarkan nama yang diketahui
        for _, guiName in ipairs(SkillCheckNames) do
            local gui = PlayerGui:FindFirstChild(guiName, true)
            if gui then
                local check = gui:FindFirstChild("Check", true)
                if check and check.Visible then
                    local line = check:FindFirstChild("Line", true)
                    local goal = check:FindFirstChild("Goal", true)
                    if line and goal then
                        return line, goal
                    end
                end
            end
        end
    
        -- Fallback: scan semua ScreenGui untuk elemen "Line" & "Goal"
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local check = gui:FindFirstChild("Check", true)
                if check and check.Visible then
                    local line = check:FindFirstChild("Line", true)
                    local goal = check:FindFirstChild("Goal", true)
                    if line and goal then
                        return line, goal
                    end
                end
            end
        end
    
        return nil, nil
    end
    
    ----------------------------------------------------------------
    -- PRESS SKILL (MULTI-METHOD)
    ----------------------------------------------------------------
    
    local function GetActionTarget()
        local current = PlayerGui
    
        for segment in string.gmatch(ActionPath, "[^%.]+") do
            current = current and current:FindFirstChild(segment)
        end
    
        return current
    end
    
    local function TriggerMobileButton()
        local b = GetActionTarget()
    
        if b and b:IsA("GuiObject") then
            local p = b.AbsolutePosition
            local s = b.AbsoluteSize
            local i = GuiService:GetGuiInset()
    
            local cx = p.X + (s.X / 2) + i.X
            local cy = p.Y + (s.Y / 2) + i.Y
    
            pcall(function()
                VirtualInputManager:SendTouchEvent(
                    TouchID,
                    Enum.UserInputState.Begin.Value,
                    cx,
                    cy
                )
    
                task.wait(0.01)
    
                VirtualInputManager:SendTouchEvent(
                    TouchID,
                    Enum.UserInputState.End.Value,
                    cx,
                    cy
                )
            end)
        end
    end
    
    local function PressSkill()
        if IsMobile then
            TriggerMobileButton()
        else
            pcall(function()
                VirtualInputManager:SendKeyEvent(
                    true,
                    Enum.KeyCode.Space,
                    false,
                    game
                )
    
                task.wait()
    
                VirtualInputManager:SendKeyEvent(
                    false,
                    Enum.KeyCode.Space,
                    false,
                    game
                )
            end)
        end
    end
    
    ----------------------------------------------------------------
    -- MAIN HEARTBEAT
    ----------------------------------------------------------------
    
    local VisibilityConnection
    local HeartbeatConnection
    
    local function InitializeAutoGenerator()
        task.spawn(function()
            local prompt = PlayerGui:WaitForChild("SkillCheckPromptGui", 10)
            if not prompt then return end
    
            local check = prompt:WaitForChild("Check", 10)
            if not check then return end
    
            local line = check:WaitForChild("Line")
            local goal = check:WaitForChild("Goal")
    
            if VisibilityConnection then VisibilityConnection:Disconnect() end
    
            VisibilityConnection = check:GetPropertyChangedSignal("Visible"):Connect(function()
                if check.Visible then
                    if HeartbeatConnection then HeartbeatConnection:Disconnect() end
                    HeartbeatConnection = RunService.Heartbeat:Connect(function()
                        if not AutoGenerator then return end
    
                        local lr = line.Rotation % 360
                        local gr = goal.Rotation % 360
    
                        local perfectStart = (gr + (getgenv().GeneratorPerfectOffsetStart or 102)) % 360
                        local perfectEnd   = (gr + (getgenv().GeneratorPerfectOffsetEnd   or 108)) % 360
    
                        local inside
                        if perfectStart > perfectEnd then
                            inside = (lr >= perfectStart or lr <= perfectEnd)
                        else
                            inside = (lr >= perfectStart and lr <= perfectEnd)
                        end
    
                        if inside then
                            PressSkill()
                            HeartbeatConnection:Disconnect()
                            HeartbeatConnection = nil
                        end
                    end)
                else
                    if HeartbeatConnection then
                        HeartbeatConnection:Disconnect()
                        HeartbeatConnection = nil
                    end
                end
            end)
    
            t_insert(getgenv().FORKT_CONNECTIONS, VisibilityConnection)
        end)
    end
    InitializeAutoGenerator()
    getgenv().FORKT_InitAutoGen = InitializeAutoGenerator
end

----------------------------------------------------------------
-- THEME: FORKT (Dark Violet)
----------------------------------------------------------------

-- ── Palette (biar warna gak keulang-ulang & gampang diganti) ─
local Palette = {
    Accent        = Color3.fromHex("#A78BFA"), -- warna utama, dipakai di semua elemen interaktif
    TextPrimary   = Color3.fromHex("#F1F1F5"),
    TextSecondary = Color3.fromHex("#C2C2D6"), -- [FIX] dinaikin dari #ABABC0 biar Dialog/Popup content lebih kebaca
    TextMuted     = Color3.fromHex("#A6A6BC"), -- [FIX] dinaikin dari #8A8AA0 — ini yang dipakai buat ElementDesc (Ping/FPS/dll)
    TextDim       = Color3.fromHex("#8C8CA8"), -- [FIX] dinaikin dari #72728A — placeholder text
    IconDefault   = Color3.fromHex("#D0D0E0"), -- [FIX] dinaikin dari #C4C4D4

    BgWindow  = Color3.fromHex("#0A0A0F"),
    BgPanel   = Color3.fromHex("#13131A"),
    BgElement = Color3.fromHex("#16161E"),
    BgButton  = Color3.fromHex("#18181F"),
    BgTab     = Color3.fromHex("#0E0E14"),

    Outline = Color3.fromHex("#242430"),
    Shadow  = Color3.fromHex("#000000"),
}

WindUI:AddTheme({
    Name = "FORKT",

    -- ── Accent ───────────────────────────────────────────────
    Accent = Palette.Accent,

    -- ── Background ───────────────────────────────────────────
    Background = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#060608"), Transparency = 0 },
        ["50"]  = { Color = Color3.fromHex("#0C0C10"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#131318"), Transparency = 0 },
    }, { Rotation = 135 }),
    BackgroundTransparency = 0,
    Outline                = Palette.Outline,

    -- ── Text ─────────────────────────────────────────────────
    Text        = Palette.TextPrimary,
    Placeholder = Palette.TextDim,

    -- ── Controls ─────────────────────────────────────────────
    Button = Palette.BgButton,
    Icon   = Palette.IconDefault,
    Hover  = Palette.Accent,

    -- ── Window ───────────────────────────────────────────────
    WindowBackground = Palette.BgWindow,
    WindowShadow     = Palette.Shadow,

    -- ── Topbar ───────────────────────────────────────────────
    WindowTopbarButtonIcon = Color3.fromHex("#D1D1E0"),
    WindowTopbarTitle      = Palette.TextPrimary,
    WindowTopbarAuthor     = Color3.fromHex("#9494B0"), -- [FIX] dinaikin dari #7C7C96
    WindowTopbarIcon       = Palette.Accent,

    -- ── Tabs ─────────────────────────────────────────────────
    TabBackground = Palette.BgTab,
    TabTitle      = Color3.fromHex("#E8E8F0"),
    TabIcon       = Color3.fromHex("#A8A8C0"), -- [FIX] dinaikin dari #9090A8

    -- ── Elements ─────────────────────────────────────────────
    ElementBackground = Palette.BgElement,
    ElementTitle      = Palette.TextPrimary,
    ElementDesc       = Palette.TextMuted,
    ElementIcon       = Palette.IconDefault,

    -- ── Dialog ───────────────────────────────────────────────
    DialogBackground              = Palette.BgPanel,
    DialogBackgroundTransparency = 0,
    DialogTitle                   = Palette.TextPrimary,
    DialogContent                 = Palette.TextSecondary,
    DialogIcon                    = Palette.Accent,

    -- ── Popup ────────────────────────────────────────────────
    PopupBackground              = Palette.BgPanel,
    PopupBackgroundTransparency  = 0,
    PopupTitle                   = Palette.TextPrimary,
    PopupContent                 = Palette.TextSecondary,
    PopupIcon                    = Palette.Accent,

    -- ── Toggle ───────────────────────────────────────────────
    Toggle    = Palette.Accent,
    ToggleBar = Color3.fromHex("#2A2A38"),

    -- ── Checkbox ─────────────────────────────────────────────
    Checkbox     = Palette.Accent,
    CheckboxIcon = Palette.BgWindow,

    -- ── Slider ───────────────────────────────────────────────
    Slider      = Palette.Accent,
    SliderThumb = Color3.fromHex("#EDE9FE"),
})
local function gradient(text,startColor,endColor,timeOffset)
    if type(text) ~= "string" or text == "" then
        return ""
    end

    local chars,result = {},{}
    for _,c in utf8.codes(text) do
        chars[#chars+1] = utf8.char(c)
    end

    local len = #chars
    local div = math.max(len-1,1)
    timeOffset = tonumber(timeOffset) or 0

    for i = 1,len do
        local t = math.abs((((i-1)/div)+timeOffset)%2-1)
        local color = startColor:Lerp(endColor,t)

        result[i] = string.format(
            '<font color="#%s">%s</font>',
            color:ToHex(),
            chars[i]
        )
    end

    return table.concat(result)
end

-- =========================================================
-- 2. TAMPILKAN POPUP TERLEBIH DAHULU
-- =========================================================
local popupClosed = false

local executorName = (identifyexecutor and identifyexecutor())
                  or (getexecutorname and getexecutorname())
                  or "Unknown"

local scriptVersion = getgenv().FORKT_VERSION or "v2.3.0"

local function codeBlock(lines)
    return "<font face='Code' size='14'>" .. table.concat(lines, "\n") .. "</font>"
end

WindUI:Popup({
    Title = gradient(
        "FORKTHUB V2",
        Color3.fromHex("#FFFFFF"),
        Color3.fromHex("#9CA3AF")
    ),
    Icon = "rbxassetid://12797629733",
    Content = codeBlock({
        string.format("<font color='#F1F1F5'><b>FORKT HUB V2</b></font>"),
        string.format("<font color='#9CA3AF'>Violence District Support</font>"),
        "",
        "────────────────────────────",
        "",
        "      <font color='#10B981'><b>✅ Script Loaded</b></font>",
        "",
        string.format("%-10s : <font color='#F1F1F5'>%s</font>", "Version", scriptVersion),
        string.format("%-10s : <font color='#10B981'>%s</font>", "Status", "Ready"),
        string.format("%-10s : <font color='#F1F1F5'>%s</font>", "Executor", executorName),
        "",
        "────────────────────────────",
        "",
        "⌨ <font color='#818CF8'><b>Controls</b></font>",
        string.format("%-4s  <font color='#9CA3AF'>Open / Close Menu</font>", "K"),
        string.format("%-4s  <font color='#9CA3AF'>Toggle Cursor</font>", "L"),
        "",
        "📱 <font color='#818CF8'><b>Mobile</b></font>",
        "<font color='#9CA3AF'>Floating Button → Open Menu</font>",
    }),
    Buttons = {
        {
            Title   = "Close",
            Icon    = "lucide:x",
            Variant = "Secondary",
            Callback = function()
                popupClosed = true
            end
        },
        {
            Title   = "Discord",
            Icon    = "lucide:message-square",
            Variant = "Secondary",
            Callback = function()
                pcall(function()
                    if setclipboard then
                        setclipboard("https://discord.gg/wCVUTHgsQV")
                    end
                end)
                WindUI:Notify({
                    Title = "Discord",
                    Content = "Link copied to clipboard!",
                    Icon = "lucide:copy"
                })
            end
        },
        {
            Title   = "ENTER HUB",
            Icon    = "lucide:arrow-right",
            Variant = "Primary",
            Callback = function()
                popupClosed = true
            end
        }
    }
})
-- Tahan jalannya script di sini sampai tombol diklik
repeat task.wait() until popupClosed
if isMobile then
    task.wait(0.15)
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end)
end
-- =========================================================
-- 3. BARU RENDER WINDOW UTAMA SETELAH POPUP DITUTUP
-- =========================================================
local TabProfile 
----------------------------------------------------------------
-- FORKT HUB V2 — MAIN WINDOW
----------------------------------------------------------------

-- ── Brand palette (dipakai ulang di beberapa properti) ───────
local Colors = {
    TitleFrom   = Color3.fromHex("#FFFFFF"),
    TitleTo     = Color3.fromHex("#9CA3AF"),
    AuthorFrom  = Color3.fromHex("#C4B5FD"),
    AuthorTo    = Color3.fromHex("#818CF8"),
    OpenBtnFrom = Color3.fromHex("#E0E7FF"),
    OpenBtnTo   = Color3.fromHex("#A5B4FC"),
}

local Window = WindUI:CreateWindow({
    Title  = "<b>" .. gradient("FORKT HUB", Colors.TitleFrom, Colors.TitleTo) .. "</b>",
    Author = gradient("Violence District", Colors.AuthorFrom, Colors.AuthorTo),
    Icon   = "rbxassetid://109078275720644",
    Theme  = "FORKT",

    -- ── Sizing ────────────────────────────────────────────────
    Size      = UDim2.fromOffset(IS_MOBILE and 620 or 640, IS_MOBILE and 380 or 440),
    MinSize   = v2(IS_MOBILE and 460 or 480, IS_MOBILE and 300 or 340),
    MaxSize   = v2(IS_MOBILE and 680 or 660, IS_MOBILE and 440 or 540),
    Resizable = true,

    -- ── Layout ───────────────────────────────────────────────
    Transparent          = false,
    NewElements          = true,
    ElementsRadius       = 13,
    SideBarWidth         = IS_MOBILE and 150 or 175,
    TopBarButtonIconSize = 16,
    HideSearchBar        = true,
    IgnoreAlerts         = true,

    -- ── Background ───────────────────────────────────────────
    Background                   = "https://www.image2url.com/r2/default/images/1779672375974-9c5c502e-bb1c-4679-8e77-11bdb938a6a6.png",
    BackgroundImageTransparency  = 0.82,

    -- ── System ───────────────────────────────────────────────
    Folder    = "ForktHubV2",
    ToggleKey = Enum.KeyCode.K,

    -- ── Open Button ──────────────────────────────────────────
    OpenButton = {
        Title = gradient("FORKT HUB", Colors.OpenBtnFrom, Colors.OpenBtnTo),
        Icon  = "rbxassetid://128864012857079",

        Enabled         = true,
        Draggable       = true,
        OnlyMobile      = false,
        CornerRadius    = UDim.new(1, 0),
        StrokeThickness = 1.8,
        Scale           = IS_MOBILE and 0.88 or 0.95,

        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromHex("#1E1E2E")),
            ColorSequenceKeypoint.new(0.30, Color3.fromHex("#6D28D9")),
            ColorSequenceKeypoint.new(0.55, Color3.fromHex("#7C3AED")),
            ColorSequenceKeypoint.new(0.80, Color3.fromHex("#8B5CF6")),
            ColorSequenceKeypoint.new(1,    Color3.fromHex("#1E1E2E")),
        }),
    },

    -- ── Topbar ───────────────────────────────────────────────
    Topbar = {
        Height      = IS_MOBILE and 38 or 44,
        ButtonsType = "Default",
    },

    -- ── Key System ───────────────────────────────────────────
    KeySystem = {
        Title   = "FORKT HUB — Key System",
        Note    = "Get your key at discord.gg/wCVUTHgsQV",
        URL     = "https://discord.gg/wCVUTHgsQV",
        SaveKey = true,

        KeyValidator = function(key)
            local ok, res = pcall(Junkie.check_key, key)
            if not (ok and res and res.valid) then
                return false
            end
        
            local upper   = string.upper(key)
            local tierLow = res.tier and string.lower(tostring(res.tier)) or ""
            local level   = tonumber(res.level)
        
            local isPremium = (tierLow == "premium" or tierLow == "vip")
                            or (level ~= nil and level >= 2)
                            or (upper:find("VIP")     ~= nil)
                            or (upper:find("PREMIUM") ~= nil)
                            or (upper:find("PAID")    ~= nil)
        
            getgenv().FORKT_PREMIUM  = not not isPremium
            getgenv().SCRIPT_KEY     = key
            getgenv().FORKT_KEY_DATA = res
        
            return true
        end,
    },
})
if not Window then
    warn("[FORKT HUB] Window gagal dibuat — cek apakah WindUI berhasil di-load.")
end
print("FORKT-HUB berhasil dimuat")
----------------------------------------------------------------
-- INTERACTIVE TAGS & TOPBAR BUTTONS
----------------------------------------------------------------
Window:Tag({
    Title  = "<b>" .. gradient("@sukitovone", Color3.fromHex("#60A5FA"), Color3.fromHex("#C084FC")) .. "</b>",
    Icon   = "rbxassetid://139747252343501",
    Border = true,
    Radius = 13,
    Color  = Color3.fromHex("#111111"),
})

-- ── Status Tag (Free / VIP) ──────────────────────────────────
local isPremium = getgenv().FORKT_PREMIUM == true

local statusTag = isPremium and {
    Label = "FORKT-V2 • VIP",
    From  = Color3.fromHex("#E9D5FF"),
    To    = Color3.fromHex("#A78BFA"),
    Bg    = Color3.fromHex("#241B3A"),
    Icon  = "lucide:crown",
} or {
    Label = "FORKT-V2 • FREE",
    From  = Color3.fromHex("#FFFFFF"),
    To    = Color3.fromHex("#6B7280"),
    Bg    = Color3.fromHex("#181818"),
    Icon  = "rbxassetid://77552546383351",
}

Window:Tag({
    Title  = "<b>" .. gradient(statusTag.Label, statusTag.From, statusTag.To) .. "</b>",
    Icon   = statusTag.Icon,
    Border = true,
    Radius = 13,
    Color  = statusTag.Bg,
})
Window:Divider()
----------------------------------------------------------------
-- TABS SETUP (SECTIONED & ORGANIZED)
----------------------------------------------------------------
TabProfile  = Window:Tab({ Title = "Profile", ShowTabTitle = true, Icon = "lucide:user" })
local kito        = Window:Tab({ Title = "VIP", ShowTabTitle = true, Icon = "rbxassetid://17410185360" })
Window:Divider()
local Tab1        = Window:Tab({ Title = "Survivor",  Icon = "lucide:shield" })
local TabKiller   = Window:Tab({ Title = "Killer",    Icon = "lucide:sword" })
local Tab3        = Window:Tab({ Title = "Combat",    Icon = "lucide:crosshair" })
Window:Divider()
-- ── Extras ───────────────────────────────────────────────
local Tab2        = Window:Tab({ Title = "Visuals",   Icon = "lucide:eye" })
local Spoof       = Window:Tab({ Title = "Spoofing",  Icon = "lucide:user-x" })
local TabSettings = Window:Tab({ Title = "Settings",  Icon = "lucide:settings-2" })
----------------------------------------------------------------
-- TAB: PROFILE (ACCOUNT, EXECUTOR, SCRIPT INFO & UTILITIES)
----------------------------------------------------------------
TabProfile:Select()
do
    ------------------------------------------------------------
    -- Data: Account
    ------------------------------------------------------------
    local jobIdShort = (game.JobId ~= "") and (game.JobId:sub(1, 6) .. "...") or "Studio"

    ------------------------------------------------------------
    -- Data: Executor / Device
    ------------------------------------------------------------
    local executorName = (identifyexecutor and identifyexecutor())
                      or (getexecutorname and getexecutorname())
                      or "Unknown"

    local platformMap = {
        [Enum.Platform.Windows] = "Windows",
        [Enum.Platform.OSX]     = "macOS",
        [Enum.Platform.IOS]     = "iOS",
        [Enum.Platform.Android] = "Android",
        [Enum.Platform.XBoxOne] = "Xbox",
        [Enum.Platform.PS4]     = "PlayStation",
        [Enum.Platform.PS5]     = "PlayStation",
    }
    local platformName = platformMap[UserInputService:GetPlatform()] or "Unknown"

    ------------------------------------------------------------
    -- Data: Script Info
    ------------------------------------------------------------
    local scriptVersion = getgenv().FORKT_VERSION or "v2.3.0"
    local scriptStatus  = getgenv().FORKT_STATUS  or "Active"

    ------------------------------------------------------------
    -- Data: Utilities callbacks
    ------------------------------------------------------------
    local function rejoinServer()
        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        WindUI:Notify({
            Title   = ok and "Rejoining..." or "Failed",
            Content = ok and "Teleporting back into server." or tostring(err),
            Icon    = ok and "lucide:refresh-cw" or "lucide:x-circle",
        })
    end

    local function serverHop()
        local ok, err = pcall(function()
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
            local data = HttpService:JSONDecode(game:HttpGet(url))
            local candidates = {}
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                    candidates[#candidates + 1] = srv.id
                end
            end
            if #candidates == 0 then error("No servers found") end
            local target = candidates[math.random(1, #candidates)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
        end)
        WindUI:Notify({
            Title   = ok and "Server Hopping..." or "Failed",
            Content = ok and "Searching public server." or tostring(err),
            Icon    = ok and "lucide:door-open" or "lucide:x-circle",
        })
    end

    local function codeBlock(lines)
        return "<font face='Code' size='11'>" .. table.concat(lines, "\n") .. "</font>"
    end

    ------------------------------------------------------------
    -- 👤 Profile Section
    ------------------------------------------------------------
    local avatarImage = string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png",
        LocalPlayer.UserId
    )
    
    TabProfile:Paragraph({
        Title     = "👤 Profile",
        Image     = avatarImage,
        ImageSize = 46,
        Desc = codeBlock({
            string.format("<font color='#F1F1F5'><b>%s</b></font>", LocalPlayer.DisplayName),
            string.format("<font color='#9CA3AF'>@%s</font>", LocalPlayer.Name),
            string.format("<font color='#818CF8'>ID : %d</font>", LocalPlayer.UserId),
        }),
    })

    TabProfile:Space()
    local SystemGroup = TabProfile:Group({})
      ------------------------------------------------------------
    -- 💻 System Section [LIVE: Ping & FPS]
    ------------------------------------------------------------
    local function buildSystemDesc(pingText, fpsText)
        return codeBlock({
            string.format("%-10s : <font color='#F1F1F5'>%s</font>", "Executor", executorName),
            string.format("%-10s : <font color='#F1F1F5'>%s</font>", "FPS", fpsText),
            string.format("%-10s : <font color='#F1F1F5'>%s</font>", "Ping", pingText),
            string.format("%-10s : <font color='#F1F1F5'>%s</font>", "Platform", platformName),
        })
    end
    
    local SystemParagraph = SystemGroup:Paragraph({
        Title     = "💻 System",
        Image     = "cpu",
        ImageSize = 20,
        Desc      = buildSystemDesc("— ms", "—"),
    })

    local function getPing()
        local ok, ping = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        return (ok and ping) and string.format("%d ms", math.floor(ping)) or "—"
    end

    TabProfile:Space()

    ------------------------------------------------------------
    -- 📜 Script Section
    ------------------------------------------------------------
    SystemGroup:Paragraph({
        Title     = "📜 Script",
        Image     = "file-text",
        ImageSize = 20,
        Desc = codeBlock({
            string.format("<font color='#F1F1F5'><b>FORKT HUB</b></font>"),
            string.format("<font color='#9CA3AF'>%s</font>", scriptVersion),
            string.format("Status : <font color='#10B981'>%s</font>", scriptStatus),
        }),
    })

    TabProfile:Space()

    ------------------------------------------------------------
    -- 🛠 Utilities Buttons Group
    ------------------------------------------------------------
    local UtilitiesGroup = TabProfile:Group({})
    
    UtilitiesGroup:Button({
        Title    = "Rejoin",
        Icon     = "lucide:refresh-cw",
        Justify  = "Center",
        Callback = rejoinServer,
    })
    
    UtilitiesGroup:Space()
    
    UtilitiesGroup:Button({
        Title    = "Server Hop",
        Icon     = "lucide:door-open",
        Justify  = "Center",
        Callback = serverHop,
    })
    
    ------------------------------------------------------------
    -- Footer Branding
    ------------------------------------------------------------
    TabProfile:Divider()
    
    TabProfile:Paragraph({
        Title = gradient("FORKT HUB V2", Color3.fromHex("#818CF8"), Color3.fromHex("#C084FC")),
        Desc  = "<font color='#6B7280' size='11'>© 2026 All rights reserved</font>",
        Image = "rbxassetid://128864012857079",
        ImageSize = 36,
    })
end

-----------------------------------------------------------
-- [TAB VIP] ULTIMATE AUTOMATION
-----------------------------------------------------------
local AISection = kito:Section({
    Title = gradient("Automatic System",Color3.fromHex("#F59E0B"),Color3.fromHex("#EF4444")),
    Box = true,
    TextXAlignment = "Left",
    TextSize = 18,
    Icon = "rbxassetid://110504092653012"
})
AISection:Toggle({
    Title    = "Auto Play (Smart AI)",
    Desc     = "AI automatically repairs generators, heals teammates, avoids the Killer & escapes.",
    Flag     = "F_AutoFarm",
    Value    = false,
    Locked   = not getgenv().FORKT_PREMIUM,
    Callback = function(v)
        AutoFarmBot = v

        if v then
            AutoGenerator      = true
            AutoGeneratorMode  = "Perfect"
            AIRemotesFound     = false -- reset agar re-search
            AIState.current    = "Idle"
            AIState.activeGen  = nil
            AIState.activePoint = nil
            AIState.repairStarted = false

            WindUI:Notify({
                Title   = "Smart AI Enabled",
                Content = "Bot aktif. Auto repair, heal & escape.",
                Icon    = "lucide:bot"
            })
        else
            -- Stop movement
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root then hum:MoveTo(root.Position) end

            getgenv().AIFinalTarget   = nil
            getgenv().CachedWaypoints = nil

            WindUI:Notify({
                Title   = "Smart AI Disabled",
                Content = "Bot dimatikan.",
                Icon    = "lucide:circle-off"
            })
        end
    end
})
kito:Space({ Columns = 1 })
local GenSection = kito:Section({
    Title = gradient("Generator",Color3.fromHex("#F59E0B"),Color3.fromHex("#EF4444")),
    Box = true,
    TextXAlignment = "Left",
    TextSize = 18,
    Icon = "rbxassetid://110504092653012"
})
GenSection:Toggle({
    Title="Auto Generator",
    Desc="Auto SkillCheck Generator.",
    Locked = not getgenv().FORKT_PREMIUM,
    Flag="F_AutoGen",
    Value=false,
    Callback=function(v)
        AutoGenerator=v
        if not v then
            if GenConnection then
                GenConnection:Disconnect()
                GenConnection = nil
            end
            end
    end
})

GenSection:Dropdown({
    Title="SkillCheck Mode",
    Desc="Perfect = bonus | Neutral = lebih aman",
    Values={"Perfect","Neutral"},
    Value="Perfect",
    Flag="F_GenMode",
    Callback=function(option)
        AutoGeneratorMode=option
        if option=="Perfect" then
            getgenv().GeneratorPerfectOffsetStart=102
            getgenv().GeneratorPerfectOffsetEnd=108

        else
            getgenv().GeneratorPerfectOffsetStart=102
            getgenv().GeneratorPerfectOffsetEnd=114
        end
    end
})
kito:Space({ Columns = 1 })
local MoonSection = kito:Section({
    Title = gradient("MoonWalk",Color3.fromHex("#F59E0B"),Color3.fromHex("#EF4444")),
    Box = true,
    TextXAlignment = "Left",
    TextSize = 18,
    Icon = "rbxassetid://110504092653012"
})
MoonSection:Toggle({
    Title = "Moonwalk",
    Desc  = "Automatic zigzag movement to dodge the Killer.",
    Flag = "F_Moonwalk",
    Value = false,
    Locked = not getgenv().FORKT_PREMIUM,
    Callback = function(v)
        getgenv().MoonwalkEnabled = v

        if MoonwalkUI then
            MoonwalkUI.Enabled = v
        end

        -- Ganti di Moonwalk toggle callback:
        if not v then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end

        WindUI:Notify({
            Title   = v and "Moonwalk Enabled" or "Moonwalk Disabled",
            Content = v and "Press button/R to start zigzag movement." or "Moonwalk has been disabled.",
            Icon    = v and "lucide:orbit" or "lucide:circle-off"
        })
    end
})

MoonSection:Slider({
    Title = "Moonwalk Intensity",
    Desc  = "Higher value means more aggressive zigzag.",
    Step = 1,
    Flag = "F_ZigzagIntense",
    Locked = not getgenv().FORKT_PREMIUM,
    Value = {Min = 5, Max = 50, Default = 11},
    Callback = function(v)
        local val = tonumber(type(v) == "table" and v.Value or v) or 11
        getgenv().MoonwalkZigzagSpeed = val
        getgenv().MoonwalkZigzagAmount = val * 4
    end
})

MoonSection:Slider({
    Title = "Moonwalk Speed Boost",
    Desc  = "Movement multiplier when Moonwalk is active.",
    Step = 0.01,
    Flag = "F_MoveBoost",
    Locked = not getgenv().FORKT_PREMIUM,
    Value = {Min = 1, Max = 1.5, Default = 1.08},
    Callback = function(v)
        getgenv().MoonwalkBoostPower = type(v) == "table" and v.Value or v
    end
})
kito:Space({ Columns = 1 })
-----------------------------------------------------------
-- SURVIVOR DEFENSE
-----------------------------------------------------------
local DefenseSection = kito:Section({
    Title = gradient("Item VIP",Color3.fromHex("#F59E0B"),Color3.fromHex("#EF4444")),
    Box = true,
    TextXAlignment = "Left",
    TextSize = 18,
    Icon = "rbxassetid://110504092653012"
})
DefenseSection:Toggle({
    Title = "Silent Aim Pistol",
    Desc  = "Bullets automatically lock onto the nearest Killer.",
    Flag="F_SilentAimPistol",
   Locked=not getgenv().FORKT_PREMIUM,
    Value=false,
    Callback=function(v)
        SilentAimPistol=v
        if not v then
            ResetScope()
        end
        WindUI:Notify({
            Title   = v and "Silent Aim Enabled" or "Silent Aim Disabled",
            Content = v and "Auto lock is now active." or "Silent Aim has been disabled.",
            Icon    = v and "lucide:crosshair" or "lucide:circle-off"
        })
    end
})
----------------------------------------------------------------
-- AUTO DAGGER
----------------------------------------------------------------

DefenseSection:Toggle({
    Title    = "Auto Dagger",
    Desc     = "Automatically parry when the Killer approaches.",
    Flag     = "F_AutoParry",
    Value    = AutoParry,
    Locked   = not getgenv().FORKT_PREMIUM,
    Callback = function(v)
        AutoParry = v
        UpdateParryRing()  -- handles Visible + Radius sekaligus
        WindUI:Notify({
            Title   = "Auto Dagger",
            Content = v and "Auto Dagger is now active." or "Auto Dagger has been disabled.",
            Icon    = v and "lucide:shield-check" or "lucide:shield-off"
        })
    end
})

----------------------------------------------------------------
-- KILLER MATCHUP
----------------------------------------------------------------

DefenseSection:Dropdown({
    Title = "Killer Matchup",
    Desc  = "Optimize Auto Dagger timing per Killer type.",
    Flag     = "F_ParryMatchup",
    Locked   = not getgenv().FORKT_PREMIUM,
    Values   = { "Auto", "Abysswalker", "Hidden", "Killer", "Masked", "Stalker", "Veil", "Slasher", "Cure" },
    Value    = "Auto",
    Callback = function(v)
        getgenv().ParryMatchup = v
    end
})

----------------------------------------------------------------
-- PARRY DISTANCE
----------------------------------------------------------------

DefenseSection:Slider({
    Title = "Parry Distance",
    Desc  = "Auto Dagger detection range (studs).",
    Step     = 1,
    Flag     = "F_ParryDist",
    Locked   = not getgenv().FORKT_PREMIUM,
    Value    = { Min = 3, Max = 25, Default = ParryDistance },
    Callback = function(v)
        local val = tonumber(type(v) == "table" and v.Value or v) or 10
        ParryDistance = math.clamp(val, 3, 25)
        UpdateParryRing()
        if ParryRing then
            ParryRing.Radius = ParryDistance
        end
    end
})

----------------------------------------------------------------
-- AIM STRICTNESS
----------------------------------------------------------------

DefenseSection:Slider({
    Title = "Aim Strictness",
    Desc  = "Killer movement prediction accuracy.",
    Step     = 0.1,
    Flag     = "F_AimStrict",
    Locked   = not getgenv().FORKT_PREMIUM,
    Value    = { Min = 0.5, Max = 3, Default = getgenv().AimStrictness or 1.3 },
    Callback = function(v)
        local val = tonumber(type(v) == "table" and (v.Value or v.Default) or v) or 1.3
        getgenv().AimStrictness = math.clamp(val, 0.5, 3)
    end
})

----------------------------------------------------------------
-- PARRY DELAY
----------------------------------------------------------------

DefenseSection:Slider({
    Title = "Parry Delay",
    Desc  = "Custom Auto Dagger timing (ms). Negative = earlier trigger.",
    Step     = 10,
    Flag     = "F_ParryDelay",
    Locked   = not getgenv().FORKT_PREMIUM,
    Value    = { Min = -150, Max = 1000, Default = (getgenv().ParryDelayOffset or 0) * 1000 },
    Callback = function(v)
        local val = tonumber(type(v) == "table" and (v.Value or v.Default) or v) or 0
        getgenv().ParryDelayOffset = math.clamp(val, -150, 1000) / 1000
    end
})
kito:Space({ Columns = 1 })
----------------------------------------------------------------
-- TAB 1: SURVIVOR (MOVEMENT & HEALTH)
----------------------------------------------------------------
Tab1:Section({ Title = "Movement Modification" })

Tab1:Toggle({ 
    Title = "Speed Boost", 
    Flag = "F_SpeedBoost", 
    Locked = false, 
    Value = false, 
    Callback = function(v) 
        SpeedBoost = v 
    end 
})

Tab1:Slider({
    Title = "Speed Boost Power",
    Desc = "Additional speed percentage.",
    Step = 1,
    IsTooltip = true,
    Locked = false,
    LockedTitle = "Maintenance",
    Flag = "F_BoostSpeed",
    Value = {
        Min = 0,
        Max = 150,
        Default = 8
    },
    Callback = function(v)
        BoostSpeed = tonumber(
            type(v) == "table" and (v.Value or v.Default) or v
        ) or 0
    end
})

Tab1:Space({ Columns = 1 })

Tab1:Section({ Title = "More" })

Tab1:Toggle({ 
    Title = "Silent Actions (Anti-Noise)", 
    Desc = "Block notifications to Killer when you run or jump through windows.", 
    Flag = "F_SilentActions", 
    Value = false, 
    Callback = function(v) SilentActions = v end 
})

Tab1:Toggle({ 
    Title = "Anti Fall Slow", 
    Desc = "Prevent animation when falling from high places.", 
    Flag = "F_AntiFall", 
    Value = false, 
    Callback = function(v) AntiFallDamage = v end 
})

Tab1:Toggle({ 
    Title = "Anti Aura (No Detect)", 
    Desc = "Block the tracking signal! Killer won't be able to see your Aura.", 
    Flag = "F_AntiAura", 
    Value = false, 
    Callback = function(v) getgenv().AntiAura = v end 
})

Tab1:Toggle({ 
    Title = "Notify Killer Stun", 
    Desc = "Displays a global notification if the Killer is stunned (Pallet/Dagger).", 
    Flag = "F_NotifyStun", 
    Value = false, 
    Callback = function(v) NotifyStun = v end 
})
-- Membuka 2 Kolom untuk Heal dan Anti Knock
Tab1:Space({ Columns = 2 }) 
----------------------------------------------------------------
-- TAB: KILLER (KHUSUS KILLER)
----------------------------------------------------------------
TabKiller:Section({ Title = "Killer Advantages" })
TabKiller:Toggle({ Title = "Double Damage Generator", Desc = "Deals double damage when kicking a Generator.", Flag = "F_DoubleDamage", Value = false, Callback = function(v) DoubleDamageGen = v end })

TabKiller:Button({ Title = "Activate Killer Power", Desc = "Instantly triggers the Killer's special power.", Icon = "sfsymbols:starFill", Callback = function()
    pcall(function() ReplicatedStorage.Remotes.Killers.Killer.ActivatePower:FireServer() end)
end })
TabKiller:Space({ Columns = 1 })
TabKiller:Section({ Title = "Anti Blind" })

TabKiller:Toggle({
    Title    = "Anti Blind",
    Desc     = "Blocks and instantly clears flashlight blind effects when playing as Killer.",
    Flag     = "F_AntiBlind",
    Value    = false,
    Callback = function(v)
        AntiBlind = v
        if v then
            getgenv().FORKT_ConnectAntiBlind()
        else
            -- Disconnect semua listener blind
            if getgenv().FORKT_ConnectAntiBlind then
                AntiBlind = false
                getgenv().FORKT_ConnectAntiBlind()
            end
        end
        WindUI:Notify({
            Title   = v and "Anti Blind Enabled" or "Anti Blind Disabled",
            Content = v and "Flashlight blind effects will be instantly cleared." or "Anti Blind disabled.",
            Icon    = v and "lucide:eye" or "lucide:circle-off",
        })
    end,
})

TabKiller:Space({ Columns = 1 })

TabKiller:Section({ Title = "Pallet Breaker" })

TabKiller:Toggle({
    Title    = "Auto Break Pallets",
    Desc     = "Automatically breaks dropped Pallets when you are within range.",
    Flag     = "F_AutoBreakPallet",
    Value    = false,
    Callback = function(v)
        AutoBreakPallet = v
        WindUI:Notify({
            Title   = v and "Auto Break Enabled" or "Auto Break Disabled",
            Content = v and "Will automatically break dropped Pallets nearby." or "Auto Break Pallet disabled.",
            Icon    = v and "lucide:hammer" or "lucide:circle-off",
        })
    end,
})

TabKiller:Slider({
    Title     = "Break Radius (Studs)",
    Desc      = "Maximum distance to detect and break a dropped Pallet.",
    Step      = 1,
    IsTooltip = true,
    Flag      = "F_BreakPalletRadius",
    Value     = { Min = 3, Max = 20, Default = 8 },
    Callback  = function(v)
        BreakPalletRadius = type(v) == "table" and (tonumber(v.Value) or 8) or tonumber(v) or 8
    end,
})

TabKiller:Slider({
    Title     = "Break Cooldown (s)",
    Desc      = "Cooldown between each automatic pallet break.",
    Step      = 0.05,
    IsTooltip = true,
    Flag      = "F_BreakPalletCooldown",
    Value     = { Min = 0.50, Max = 3.0, Default = 1.20 },
    Callback  = function(v)
        BreakPalletCooldown = type(v) == "table" and (tonumber(v.Value) or 1.20) or tonumber(v) or 1.20
    end,
})
TabKiller:Space({ Columns = 1 })

TabKiller:Section({ Title = "Auto Attack" })
TabKiller:Toggle({
    Title    = "Enable Auto Attack",
    Desc     = "Automatically attacks the nearest Survivor.",
    Flag     = "F_AutoAttack",
    Value    = false,
    Callback = function(v) AutoAttack = v end,
})

TabKiller:Slider({
    Title     = "Attack Range (Studs)",
    Step      = 1,
    IsTooltip = true,
    Flag      = "F_AttackRange",
    Value     = { Min = 5, Max = 30, Default = 10 },
    Callback  = function(v)
        AttackRange = type(v) == "table" and (tonumber(v.Value) or 10) or tonumber(v) or 10
    end,
})

TabKiller:Slider({
    Title     = "Attack Count",
    Desc      = "How many slashes per trigger.",
    Step      = 1,
    IsTooltip = true,
    Flag      = "F_AttackCount",
    Value     = { Min = 1, Max = 3, Default = 1 },
    Callback  = function(v)
        AttackCount = type(v) == "table" and (tonumber(v.Value) or 1) or tonumber(v) or 1
    end,
})

TabKiller:Slider({
    Title     = "Attack Delay (s)",
    Desc      = "Pause between each slash in one trigger.",
    Step      = 0.05,
    IsTooltip = true,
    Flag      = "F_AttackDelay",
    Value     = { Min = 0.05, Max = 1.0, Default = 0.10 },
    Callback  = function(v)
        AttackDelay = type(v) == "table" and (tonumber(v.Value) or 0.10) or tonumber(v) or 0.10
    end,
})

TabKiller:Slider({
    Title     = "Attack Cooldown (s)",
    Desc      = "Minimum delay between two attack triggers.",
    Step      = 0.05,
    IsTooltip = true,
    Flag      = "F_AttackCooldown",
    Value     = { Min = 0.30, Max = 3.0, Default = 0.80 },
    Callback  = function(v)
        AttackCooldown = type(v) == "table" and (tonumber(v.Value) or 0.80) or tonumber(v) or 0.80
    end,
})
Tab3:Space({ Columns = 1 }) 
-----------------------------------------------------------
-- CAMERA & VIEWPORT
-----------------------------------------------------------
local CameraSection = Tab2:Section({
    Title = gradient("Camera Settings",Color3.fromHex("#6366F1"),Color3.fromHex("#06B6D4")),
    Box = true,
    TextXAlignment = "Left",
    TextSize = 18,
    Icon = "lucide:camera"
})
CameraSection:Toggle({
    Title = "Custom FOV",
    Desc = "Adjust the camera's viewing distance.",
    Flag = "F_CustomFOV",
    Value = false,

    Callback = function(v)
        CustomCameraFOV = v
        UpdateFOV()
    end
})

CameraSection:Slider({
    Title = "Field Of View",
    Desc = "The higher the wider the view.",
    Step = 1,
    IsTooltip = true,
    Flag = "F_FOVValue",
    Value = {
        Min = 70,
        Max = 120,
        Default = 100
    },

    Callback = function(v)
        CameraFOVValue =
            type(v) == "table"
            and (tonumber(v.Value) or 100)
            or (tonumber(v) or 100)

        UpdateFOV()
    end
})
CameraSection:Toggle({
    Title = "FPP / TPP Mode",
    Desc = "Switch antara First Person & Third Person.",
    Flag = "F_CameraToggle",
    Value = false,
    Callback = function(v)
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        if isMobile then
            if MobileRotateBtn then
                MobileRotateBtn.Visible = v
                if not v and getgenv().FORKT_ResetMobileBtn then
                    getgenv().FORKT_ResetMobileBtn()
                end
            end
        else
            isFPP = v
            SwitchCameraMode(v)
        end
    end
})
local CrosshairSection = Tab2:Section({
    Title = gradient("Crosshair Settings",Color3.fromHex("#6366F1"),Color3.fromHex("#06B6D4")),
    Box = true,
    TextXAlignment = "Left",
    TextSize = 18,
    Icon = "lucide:camera"
})
CrosshairSection:Toggle({
    Title = "Crosshair",
    Desc = "Show crosshair at center screen.",
    Flag = "F_Crosshair",
    Value = false,

    Callback = function(v)
        local gui = getgenv().CrosshairGui
        if gui then
            gui.Enabled = v
        end
    end
})

CrosshairSection:Dropdown({
    Title = "Crosshair Style",
    Desc = "Select crosshair image.",
    Values = {"Dot","Scope","Circle","Plus","Cross"},
    Value = "Dot",
    Flag = "F_CrosshairStyle",

    Callback = function(v)
        local gui = getgenv().CrosshairGui
        if gui and gui:FindFirstChild("Crosshair") then
            gui.Crosshair.Image = CrosshairImages[v]
        end
    end
})

CrosshairSection:Slider({
    Title = "Crosshair Size",
    Desc = "Adjust crosshair size.",
    Step = 1,
    Flag = "F_CrosshairSize",
    Value = {Min = 10, Max = 80, Default = 28},

    Callback = function(v)
        local size = type(v) == "table" and (tonumber(v.Value) or 28) or tonumber(v) or 28
        local gui = getgenv().CrosshairGui

        if gui and gui:FindFirstChild("Crosshair") then
            gui.Crosshair.Size = UDim2.new(0,size,0,size)
        end
    end
})
CrosshairSection:Slider({
    Title = "Horizontal Offset",
    Desc = "Move crosshair left/right.",
    Step = 1,
    Flag = "F_CrosshairOffsetX",
    Value = {Min = -100, Max = 100, Default = 0},

    Callback = function(v)
        local offset = type(v) == "table"
            and (tonumber(v.Value) or 0)
            or tonumber(v) or 0

        local gui = getgenv().CrosshairGui

        if gui and gui:FindFirstChild("Crosshair") then
            local y = gui.Crosshair.Position.Y.Offset

            gui.Crosshair.Position = UDim2.new(
                0.5,
                offset,
                0.5,
                y
            )
        end
    end
})

CrosshairSection:Slider({
    Title = "Vertical Offset",
    Desc = "Move crosshair up/down.",
    Step = 1,
    Flag = "F_CrosshairOffsetY",
    Value = {Min = -100, Max = 100, Default = 0},

    Callback = function(v)
        local offset = type(v) == "table"
            and (tonumber(v.Value) or 0)
            or tonumber(v) or 0

        local gui = getgenv().CrosshairGui

        if gui and gui:FindFirstChild("Crosshair") then
            local x = gui.Crosshair.Position.X.Offset

            gui.Crosshair.Position = UDim2.new(
                0.5,
                x,
                0.5,
                offset
            )
        end
    end
})
-- Kembalikan ke 1 Kolom
Tab2:Space({ Columns = 2 })
Tab2:Section({ Title = "Player & Entity Visuals" })

local PlayerGroup1 = Tab2:Group()
PlayerGroup1:Toggle({ Title = "ESP Survivor (Name)", Flag = "F_ESPSurvivorName", Value = false, Callback = function(v) ESP_F.Survivor_Name = v; RefreshESP() end })
PlayerGroup1:Space()
PlayerGroup1:Toggle({ Title = "ESP Survivor (Highlight)", Flag = "F_ESPSurvivorHighlight", Value = false, Callback = function(v) ESP_F.Survivor_Highlight = v; RefreshESP() end })

local PlayerGroup2 = Tab2:Group()
PlayerGroup2:Toggle({ Title = "ESP Killer (Name)", Flag = "F_ESPKillerName", Value = false, Callback = function(v) ESP_F.Killer_Name = v; RefreshESP() end })
PlayerGroup2:Space()
PlayerGroup2:Toggle({ Title = "ESP Killer (Highlight)", Flag = "F_ESPKillerHighlight", Value = false, Callback = function(v) ESP_F.Killer_Highlight = v; RefreshESP() end })
local PlayerGroup3 = Tab2:Group()
PlayerGroup3:Toggle({
    Title="ESP SCP/Zombie",
    Desc="Menampilkan SCP & Zombie",
    Flag="F_ESP_SCP",
    Value=false,
    Callback=function(v)
        ESP_SCP=v
    end
})
PlayerGroup3:Toggle({
    Title = "Warn Killer Proximity",
    Desc = "Display the ! indicator above the head when the Killer approaches.",
    Flag = "F_WarnKiller",
    Value = true,
    Callback = function(v)
        WarnKiller = v
        -- Hapus billboard jika dimatikan
        if not v then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local warn = root:FindFirstChild("KillerWarn")
                if warn then warn:Destroy() end
            end
        end
    end
})
-- Kembalikan ke 1 Kolom
Tab2:Space({ Columns = 1 }) 
Tab2:Section({ Title = "Object Visuals" })
local ObjectGroup1 = Tab2:Group()
ObjectGroup1:Toggle({ Title = "ESP Generator", Desc = "Displays unfinished Gens.", Flag = "F_ESPGen", Value = false, Callback = function(v) ESP_F.Generator = v; RefreshESP() end })
ObjectGroup1:Space()
ObjectGroup1:Toggle({ Title = "ESP Pallet", Desc = "Displays Pallets.", Flag = "F_ESPPallet", Value = false, Callback = function(v) ESP_F.Pallet = v; RefreshESP() end })

local ObjectGroup2 = Tab2:Group()
ObjectGroup2:Toggle({ Title = "ESP Exit Gate", Desc = "Displays Exit Gates.", Flag = "F_ESPGate", Value = false, Callback = function(v) ESP_F.Gate = v; RefreshESP() end })
ObjectGroup2:Space()
ObjectGroup2:Toggle({ Title = "ESP Hook", Desc = "Displays Hook locations.", Flag = "F_ESPHook", Value = false, Callback = function(v) ESP_F.Hook = v; RefreshESP() end })

-- Kembalikan ke 1 Kolom
Tab2:Space({ Columns = 1 }) 

Tab2:Section({ Title = "World Optimization", Box = true })
Tab2:Toggle({ 
    Title = "Remove All Visual Effects", 
    Desc = "Wipes out all Blur, Bloom, DoF, SunRays, and Fog effects.", 
    Flag = "F_RemoveDoF", 
    Value = false, 
    Callback = function(v) 
        if v then
            -- [1] NYALAKAN: Simpan dan Sembunyikan Efek
            getgenv().FORKT_HiddenEffects = getgenv().FORKT_HiddenEffects or {}
            table.clear(getgenv().FORKT_HiddenEffects) -- Pastikan cache bersih
            
            local function hideEffects(parent)
                for _, effect in ipairs(parent:GetDescendants()) do
                    local n = string.lower(effect.Name)
                    
                    if effect:IsA("PostEffect") or effect:IsA("Clouds") or effect:IsA("Atmosphere") or n:find("bloom") or n:find("dof") or n:find("sunray") or n:find("blur") then
                        
                        if effect:IsA("Atmosphere") then
                            t_insert(getgenv().FORKT_HiddenEffects, {Obj = effect, OldParent = effect.Parent})
                            effect.Parent = nil
                        else
                            -- Khusus Objek Filter (Simpan status aslinya, lalu matikan)
                            pcall(function()
                                if effect.Enabled then
                                    t_insert(getgenv().FORKT_HiddenEffects, {Obj = effect, WasEnabled = true})
                                    effect.Enabled = false
                                end
                            end)
                        end
                    end
                end
            end

            -- Eksekusi penyapuan
            hideEffects(Lighting)
            hideEffects(workspace.CurrentCamera)
            
            -- Hapus Kabut Klasik (Simpan nilai aslinya dulu)
            getgenv().FORKT_OldFogStart = Lighting.FogStart
            getgenv().FORKT_OldFogEnd = Lighting.FogEnd
            Lighting.FogStart = 9e9
            Lighting.FogEnd = 9e9
            
            WindUI:Notify({ 
                Title = "Vision Cleared", 
                Content = "All screen filters and fog are successfully hidden.!", 
                Icon = "lucide:eye-off" 
            })
            
        else
            -- [2] MATIKAN: Kembalikan Semua ke Kondisi Asli
            if getgenv().FORKT_HiddenEffects then
                for _, data in ipairs(getgenv().FORKT_HiddenEffects) do
                    if data.Obj then
                        -- Jika itu Atmosphere, kembalikan ke induknya
                        if data.OldParent then
                            data.Obj.Parent = data.OldParent
                        -- Jika itu PostEffect, nyalakan kembali
                        elseif data.WasEnabled then
                            pcall(function() data.Obj.Enabled = true end)
                        end
                    end
                end
                table.clear(getgenv().FORKT_HiddenEffects)
            end
            
            -- Kembalikan Kabut Klasik
            if getgenv().FORKT_OldFogStart then
                Lighting.FogStart = getgenv().FORKT_OldFogStart
                Lighting.FogEnd = getgenv().FORKT_OldFogEnd
            end
            
            WindUI:Notify({ 
                Title = "Vision Restored", 
                Content = "The game's native visual effects are restored.", 
                Icon = "lucide:eye" 
            })
        end
    end 
})

Tab2:Space({ Columns = 1 }) 
local World = Tab2:Group({})

World:Button({ 
    Title = "Force Fullbright", 
    Icon = "lucide:sun", 
    Justify  = "Center", 
    Color = Color3.fromRGB(195, 250, 30),
    Callback = function() 
        -- [FIX] Pencahayaan seimbang
        Lighting.Ambient = Color3.fromRGB(170, 170, 170)
        Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.Brightness = 1.9
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false 
        
        -- [FIX KABUT KLASIK] Dorong jarak mulai dan akhir kabut hingga tak terhingga
        Lighting.FogStart = 9e9
        Lighting.FogEnd = 9e9
        
        for _, effect in ipairs(Lighting:GetDescendants()) do 
            if effect:IsA("Atmosphere") or effect:IsA("Sky") then
                pcall(function() effect:Destroy() end)
            elseif effect:IsA("PostEffect") or effect:IsA("Clouds") then 
                pcall(function() effect.Enabled = false end)
            end 
        end
    end 
})

World:Space()

World:Button({ 
    Title = "Potato Mode", 
    Icon = "lucide:cpu", 
    Justify  = "Center",
    Color = Color3.fromRGB(255, 159, 50), 
    Callback = function() 
        WindUI:Notify({ 
            Title = "Potato Mode", 
            Content = "Optimizing the map for potato HP... Don't close the game!", 
            Icon = "lucide:hourglass" 
        })

        task.spawn(function()
            -- 1. OPTIMASI LANGIT & CAHAYA
            Lighting.GlobalShadows = false
            Lighting.ShadowSoftness = 0
            Lighting.FogEnd = 9e9
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            
            for _, effect in ipairs(Lighting:GetDescendants()) do 
                if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Clouds") then 
                    pcall(function() effect.Enabled = false end)
                end 
            end

            -- 2. OPTIMASI TERRAIN (AIR & RUMPUT)
            local terrain = workspace.Terrain
            if terrain then
                pcall(function()
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 0
                    terrain.Decoration = false
                end)
            end

            -- 3. CHUNKING EKSEKUSI OBJEK MAP YANG AMAN
            local function ProcessObjectFast(v)
                local class = v.ClassName
                if class == "Part" or class == "MeshPart" or class == "UnionOperation" then
                    pcall(function()
                        if v.Material ~= Enum.Material.SmoothPlastic then v.Material = Enum.Material.SmoothPlastic end
                        if v.Reflectance ~= 0 then v.Reflectance = 0 end
                        if v.CastShadow then v.CastShadow = false end
                    end)
                elseif class == "Decal" or class == "Texture" or class == "SurfaceAppearance" then
                    pcall(function() v:Destroy() end)
                elseif class == "ParticleEmitter" or class == "Trail" or class == "Beam" or class == "Smoke" or class == "Fire" or class == "Sparkles" then
                    pcall(function() v.Enabled = false end)
                end
            end

            -- Hanya ambil bagian workspace yang penting (cth: folder Map dan karakter)
            local targetFolders = {workspace:FindFirstChild("Map"), workspace:FindFirstChild("Characters")}
            for _, folder in ipairs(targetFolders) do
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do
                        ProcessObjectFast(child)
                        for _, subChild in ipairs(child:GetChildren()) do
                            ProcessObjectFast(subChild)
                        end
                    end
                end
            end
            
            -- Karena loop sekarang dilindungi pcall, notifikasi ini DIJAMIN akan selalu muncul!
            WindUI:Notify({ 
                Title = "Optimization Complete!", 
                Content = "Potato Mode successfully applied. Textures removed, FPS Boosted!", 
                Icon = "lucide:check-circle" 
            })
        end)
    end 
})

----------------------------------------------------------------
-- TAB 3: COMBAT (AIMBOT, HITBOX, PARRY)
----------------------------------------------------------------
Tab3:Section({ Title = "Targeting System" })
Tab3:Toggle({
    Title = "Aimbot",
    Desc = "Locks onto target.",
    Flag = "F_Aimbot",
    Value = false,
    Callback = function(v)
        Aimbot = v

        if not v then
            CachedTarget = nil
        end
    end
})

Tab3:Dropdown({
    Title = "Aimbot Target",
    Desc = "Choose target part.",
    Values = {
        "Head",
        "Torso",
        "Body (RootPart)"
    },
    Value = "Torso",
    Flag = "F_AimPart",
    Callback = function(v)
        getgenv().AimbotPart = v
    end
})

Tab3:Dropdown({
    Title = "Aimbot Trigger",
    Desc = "Aim activation mode.",
    Values = {
        "Hold to Lock",
        "Auto Lock (Always)"
    },
    Value = "Hold to Lock",
    Flag = "F_AimTrigger",
    Callback = function(v)
        getgenv().AimbotTrigger = v
    end
})

Tab3:Slider({ 
    Title = "Aim Radius", 
    Step = 5, 
    IsTooltip = true, 
    IsTextbox = true, 
    Flag = "F_AimRadius", 
    Value = { Min = 30, Max = 150, Default = 55 }, 
    Callback = function(v) 
        -- [FIX CRASH FATAL (Table * 2)]
        local val = type(v) == "table" and (tonumber(v.Value) or 55) or tonumber(v) or 55
        AimRadius = val
        if FOVCircle then 
            FOVCircle.Size = UDim2.new(0, val*2, 0, val*2) 
        end 
    end 
})
Tab3:Toggle({ Title = "Show Aim Radius", Desc = "Displays aim radius on screen.", Flag = "F_ShowFOV", Value = false, Callback = function(v) 
    ShowFOVCircle = v; if FOVCircle then FOVCircle.Visible = v end 
end })

-- SPOOFING PROFILE
Spoof:Section({ Title = "Client-Sided (Visual Only)", Justify = "Center" })

-- 1. Input Box untuk Gears
Spoof:Input({
    Title = "Custom Gears",
    Desc = "Enter the number of Gears.",
    PlaceholderText = "Jumlah Gears...",
    Callback = function(text)
        SpoofData.Gears = tonumber(text) or 0
    end
})

-- 2. Input Box untuk Screws
Spoof:Input({
    Title = "Custom Screws",
    Desc = "Enter the number of Screws.",
    PlaceholderText = "Jumlah Screws...",
    Callback = function(text)
        SpoofData.Screws = tonumber(text) or 0
    end
})

-- 3. Input Box untuk Level
Spoof:Input({
    Title = "Custom Level",
    Desc = "Enter the Level number.",
    PlaceholderText = "Angka Level...",
    Callback = function(text)
        SpoofData.Level = tonumber(text) or 0
    end
})

Spoof:Space({ Columns = 2 }) 

-- 4. Tombol Eksekusi Brutal ke LocalPlayer
Spoof:Button({
    Title = "Apply Spoof Data",
    Icon = "lucide:scan-face",
    Justify = "Center",
    Color = Color3.fromRGB(0, 255, 150),
    Callback = function()
        local p = game.Players.LocalPlayer
        if not p then return end

        local function InjectValue(targetName, amount)
            if not amount or amount <= 0 then return end
            
            local targetLower = string.lower(targetName)
            local injectedCount = 0

            -- [METODE 1] Suntik ke Attribute (Game Modern)
            pcall(function() p:SetAttribute(targetName, amount) end)
            pcall(function() p:SetAttribute(targetName.."s", amount) end)

            -- [METODE 2] Bruteforce pencarian Value Object (leaderstats / folder mata uang)
            for _, obj in ipairs(p:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
                    local n = string.lower(obj.Name)
                    -- Mencari kata kunci seperti "gear", "gears", "level", "playerlevel"
                    if string.find(n, targetLower) then
                        if obj:IsA("StringValue") then
                            pcall(function() obj.Value = tostring(amount) end)
                        else
                            pcall(function() obj.Value = amount end)
                        end
                        injectedCount = injectedCount + 1
                    end
                end
            end
            
            -- [METODE 3] Cari langsung di UI (PlayerGui) untuk merubah teks secara instan
            local pGui = p:FindFirstChild("PlayerGui")
            if pGui then
                for _, ui in ipairs(pGui:GetDescendants()) do
                    if ui:IsA("TextLabel") or ui:IsA("TextButton") then
                        local uiName = string.lower(ui.Name)
                        if string.find(uiName, targetLower) and (string.find(uiName, "amount") or string.find(uiName, "count") or string.find(uiName, "text") or uiName == targetLower) then
                            pcall(function() ui.Text = tostring(amount) end)
                        end
                    end
                end
            end
        end

        -- Eksekusi Suntikan
        InjectValue("Gear", SpoofData.Gears)
        InjectValue("Screw", SpoofData.Screws)
        InjectValue("Level", SpoofData.Level)

        WindUI:Notify({ 
            Title = "Spoof Applied!", 
            Content = "Data has been successfully manipulated visually! Please check your profile UI..", 
            Icon = "lucide:check-circle" 
        })
    end
})
----------------------------------------------------------------
-- SETTINGS & CONFIG SYSTEM (WINDUI NATIVE)
----------------------------------------------------------------
local ConfigManager = Window.ConfigManager
local SaveName       = "FORKT-HUBV2"

-- Ambil daftar tema dengan aman
local Themes = {}
pcall(function()
    for themeName, _ in pairs(WindUI:GetThemes()) do
        t_insert(Themes, themeName)
    end
end)

------------------------------------------------------------
-- 1. Configuration
------------------------------------------------------------
TabSettings:Section({ Title = "Configuration" })

local ConfigGroup = TabSettings:Group({})

ConfigGroup:Button({
    Title    = "Save Config",
    Justify  = "Center",
    Icon     = "lucide:save",
    Callback = function()
        local ok = pcall(function()
            Window.CurrentConfig = ConfigManager:Config(SaveName)
            Window.CurrentConfig:Save()
        end)
        WindUI:Notify({
            Title   = ok and "Config Saved" or "Save Failed",
            Content = ok and "Semua pengaturan berhasil disimpan."
                          or "Executor kamu tidak mendukung penyimpanan.",
            Icon    = ok and "lucide:check-circle" or "lucide:x-circle",
        })
    end,
})

ConfigGroup:Space()

ConfigGroup:Button({
    Title    = "Load Config",
    Justify  = "Center",
    Icon     = "lucide:folder-open",
    Callback = function()
        local ok = pcall(function()
            Window.CurrentConfig = ConfigManager:CreateConfig(SaveName)
            Window.CurrentConfig:Load()
        end)
        WindUI:Notify({
            Title   = ok and "Config Loaded" or "Load Failed",
            Content = ok and "Pengaturan berhasil dimuat."
                          or "Tidak ada config yang ditemukan.",
            Icon    = ok and "lucide:check-circle" or "lucide:x-circle",
        })
    end,
})

TabSettings:Space()

------------------------------------------------------------
-- 2. Window & Interface
------------------------------------------------------------
TabSettings:Section({ Title = "Window & Interface" })

TabSettings:Dropdown({
    Title    = "Select Theme",
    Desc     = "Pilih tema warna antarmuka FORKT-HUB.",
    Flag     = "F_Theme",
    Value = ThemeName, 
    Values = Themes, 
    Callback = function(v)
        pcall(function() WindUI:SetTheme(v) end)
    end,
})

TabSettings:Space()

TabSettings:Keybind({
    Title    = "Toggle Keybind",
    Desc     = "Tombol untuk membuka/menutup UI FORKT-HUB.",
    Flag     = "F_ToggleKey",
    Value    = "K",
    Callback = function(v)
        pcall(function() Window:SetToggleKey(Enum.KeyCode[v]) end)
    end,
})

TabSettings:Space()

TabSettings:Button({
    Title    = "Unload FORKT-HUB",
    Desc     = "Cancels all functions, clears the UI, and clears the screen.",
    Icon     = "lucide:power",
    Color    = Color3.fromHex("#E74C3C"), -- Alizarin Red (Merah elegan, tidak silau)
    Justify  = "Left",
    Callback = function()
        getgenv().FORKT_RUNNING = false

        -- Kembalikan cursor & kamera sebelum bersih
        pcall(function() SetCursorEnabled(false) end)
        pcall(function() if isFPP then SwitchCameraMode(false) end end)

        pcall(function() Window:Destroy() end)
        pcall(function() RunService:UnbindFromRenderStep("SmoothFOV") end)

        -- Putuskan semua event koneksi yang terdaftar di FORKT_CONNECTIONS (termasuk Unified Loop)
        if getgenv().FORKT_CONNECTIONS then
            for _, conn in ipairs(getgenv().FORKT_CONNECTIONS) do
                if conn and conn.Disconnect then conn:Disconnect() end
            end
            table.clear(getgenv().FORKT_CONNECTIONS)
        end

        -- Hapus GUI tambahan (Crosshair, Moonwalk, Indicator, Mobile Rotation, SCP Folder)
        local cg = getgenv().CrosshairGui
        if cg then pcall(function() cg:Destroy() end); getgenv().CrosshairGui = nil end

        if MoonwalkUI then pcall(function() MoonwalkUI:Destroy() end) end
        if ParryRing then pcall(function() ParryRing:Destroy() end); ParryRing = nil end
        if IndicatorGui then pcall(function() IndicatorGui:Destroy() end); IndicatorGui = nil end
        
        local mobileBtns = CoreGui:FindFirstChild("FORKT_MobileButtons")
        if mobileBtns then pcall(function() mobileBtns:Destroy() end) end

        local scpFolder = CoreGui:FindFirstChild("SCP_ESP")
        if scpFolder then pcall(function() scpFolder:Destroy() end) end

        -- Bersihkan Highlight dan Tag ESP dari semua pemain
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local h = p.Character:FindFirstChild("H")
                if h then h:Destroy() end
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local tag = root:FindFirstChild("TagESP")
                    if tag then tag:Destroy() end
                end
            end
        end

        -- Bersihkan Map Object Highlights
        if CachedMapObjects then
            for _, list in pairs(CachedMapObjects) do
                for _, obj in ipairs(list) do
                    if obj and obj.Parent then
                        local h = obj:FindFirstChild("H")
                        if h then h:Destroy() end
                    end
                end
            end
        end
    end,
})

TabSettings:Space()

------------------------------------------------------------
-- 3. About
------------------------------------------------------------
TabSettings:Section({ Title = "About" })

local scriptVersion = getgenv().FORKT_VERSION or "v2.0.0"

TabSettings:Paragraph({
    Title = "Script Version",
    Desc  = scriptVersion,
    Image = "lucide:tag",
})

TabSettings:Space()

TabSettings:Button({
    Title    = "Changelog",
    Desc     = "Lihat daftar perubahan versi terbaru.",
    Icon     = "lucide:scroll-text",
    Callback = function()
        WindUI:Popup({
            Title   = "Changelog — " .. scriptVersion,
            Icon    = "lucide:scroll-text",
            Content = getgenv().FORKT_CHANGELOG or "Belum ada catatan changelog untuk versi ini.",
            Buttons = {
                { Title = "Tutup", Icon = "x", Variant = "Tertiary" },
            },
        })
    end,
})

TabSettings:Space()

TabSettings:Button({
    Title    = "Credits",
    Desc     = "Tim & kontributor di balik FORKT-HUB.",
    Icon     = "lucide:users",
    Callback = function()
        WindUI:Popup({
            Title   = "Credits",
            Icon    = "lucide:users",
            Content = "Developer: Forkt\nUI Library: WindUI by Footagesus\nCommunity: @sukitovone",
            Buttons = {
                { Title = "Tutup", Icon = "x", Variant = "Tertiary" },
            },
        })
    end,
})

TabSettings:Space()

TabSettings:Button({
    Title    = "Check Update",
    Desc     = "Cek apakah ada versi FORKT-HUB terbaru.",
    Icon     = "lucide:refresh-cw",
    Callback = function()
        local ok, latest = pcall(function()
            local url = getgenv().FORKT_VERSION_URL
            if not url then error("no update url configured") end
            return game:HttpGet(url)
        end)

        if not ok or not latest then
            WindUI:Notify({
                Title   = "Check Update",
                Content = "Gagal cek update — coba lagi nanti.",
                Icon    = "lucide:x-circle",
            })
            return
        end

        latest = latest:gsub("%s+", "")
        local upToDate = latest == scriptVersion

        WindUI:Notify({
            Title   = upToDate and "Sudah Versi Terbaru" or "Update Tersedia",
            Content = upToDate
                          and ("Kamu sudah pakai " .. scriptVersion .. ".")
                          or  ("Versi terbaru: " .. latest .. " (kamu: " .. scriptVersion .. ")"),
            Icon    = upToDate and "lucide:check-circle" or "lucide:arrow-up-circle",
        })
    end,
})
----------------------------------------------------------------
-- [MOBILE UI] FPP/TPP TOGGLE BUTTON — IMPROVED
----------------------------------------------------------------
local isMobileDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobileDevice then
    local TweenService = game:GetService("TweenService")

    local coreSuccess, coreResult = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    local SafeGuiFolder = coreSuccess and coreResult or PlayerGui

    -- Bersihkan instance lama (re-execute safe)
    local oldGui = SafeGuiFolder:FindFirstChild("FORKT_MobileButtons")
    if oldGui then oldGui:Destroy() end

    local combatGui = Instance.new("ScreenGui")
    combatGui.Name           = "FORKT_MobileButtons"
    combatGui.ResetOnSpawn   = false
    combatGui.IgnoreGuiInset = true
    combatGui.Parent         = SafeGuiFolder

    -- Frame utama
    local Btn = Instance.new("Frame")
    Btn.Name             = "RotateBtn"
    Btn.AnchorPoint      = Vector2.new(1, 0.5)
    Btn.Position         = UDim2.new(1, -12, 0.5, 30)
    Btn.Size             = UDim2.new(0, 72, 0, 72)
    Btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Btn.Visible          = false
    Btn.ZIndex           = 2
    Btn.Parent           = combatGui
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 18)

    local BtnStroke = Instance.new("UIStroke", Btn)
    BtnStroke.Color     = Color3.fromRGB(75, 150, 255)
    BtnStroke.Thickness = 1.5

    local BtnGrad = Instance.new("UIGradient", Btn)
    BtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 20)),
    })
    BtnGrad.Rotation = 140

    -- Shine tipis atas
    local Shine = Instance.new("Frame", Btn)
    Shine.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    Shine.BackgroundTransparency = 0.87
    Shine.AnchorPoint            = Vector2.new(0.5, 0)
    Shine.Position               = UDim2.new(0.5, 0, 0, 3)
    Shine.Size                   = UDim2.new(0.55, 0, 0, 2)
    Shine.BorderSizePixel        = 0
    Shine.ZIndex                 = 3
    Instance.new("UICorner", Shine).CornerRadius = UDim.new(1, 0)

    -- Ikon kamera
    local Icon = Instance.new("TextLabel", Btn)
    Icon.BackgroundTransparency = 1
    Icon.AnchorPoint            = Vector2.new(0.5, 0)
    Icon.Position               = UDim2.new(0.5, 0, 0, 9)
    Icon.Size                   = UDim2.new(1, 0, 0, 26)
    Icon.Font                   = Enum.Font.GothamBold
    Icon.Text                   = "🎥"
    Icon.TextColor3             = Color3.fromRGB(120, 175, 255)
    Icon.TextSize               = 20
    Icon.ZIndex                 = 3

    -- Label mode
    local ModeLbl = Instance.new("TextLabel", Btn)
    ModeLbl.BackgroundTransparency = 1
    ModeLbl.AnchorPoint            = Vector2.new(0.5, 0)
    ModeLbl.Position               = UDim2.new(0.5, 0, 0, 36)
    ModeLbl.Size                   = UDim2.new(1, -4, 0, 12)
    ModeLbl.Font                   = Enum.Font.GothamBold
    ModeLbl.Text                   = "TPP"
    ModeLbl.TextColor3             = Color3.fromRGB(120, 175, 255)
    ModeLbl.TextSize               = 10
    ModeLbl.ZIndex                 = 3

    -- Status pill
    local Pill = Instance.new("Frame", Btn)
    Pill.AnchorPoint      = Vector2.new(0.5, 0)
    Pill.Position         = UDim2.new(0.5, 0, 0, 52)
    Pill.Size             = UDim2.new(0, 40, 0, 12)
    Pill.BackgroundColor3 = Color3.fromRGB(30, 52, 90)
    Pill.ZIndex           = 3
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local PillDot = Instance.new("Frame", Pill)
    PillDot.AnchorPoint      = Vector2.new(0, 0.5)
    PillDot.Position         = UDim2.new(0, 5, 0.5, 0)
    PillDot.Size             = UDim2.new(0, 5, 0, 5)
    PillDot.BackgroundColor3 = Color3.fromRGB(75, 150, 255)
    PillDot.ZIndex           = 4
    Instance.new("UICorner", PillDot).CornerRadius = UDim.new(1, 0)

    local PillTxt = Instance.new("TextLabel", Pill)
    PillTxt.BackgroundTransparency = 1
    PillTxt.Position               = UDim2.new(0, 13, 0, 0)
    PillTxt.Size                   = UDim2.new(1, -15, 1, 0)
    PillTxt.Font                   = Enum.Font.GothamBold
    PillTxt.Text                   = "OFF"
    PillTxt.TextColor3             = Color3.fromRGB(75, 150, 255)
    PillTxt.TextSize               = 7
    PillTxt.TextXAlignment         = Enum.TextXAlignment.Left
    PillTxt.ZIndex                 = 4

    -- Click area transparan
    local ClickBtn = Instance.new("TextButton", Btn)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Size                   = UDim2.new(1, 0, 1, 0)
    ClickBtn.Text                   = ""
    ClickBtn.ZIndex                 = 10

    -- Referensi untuk Tab toggle
    MobileRotateBtn = Btn

    -- ── Palette ──────────────────────────────────────────────
    local BLUE        = Color3.fromRGB(75, 150, 255)
    local ORANGE      = Color3.fromRGB(255, 110, 50)
    local BLUE_DIM    = Color3.fromRGB(30, 52, 90)
    local ORANGE_DIM  = Color3.fromRGB(75, 35, 12)
    local ICON_BLUE   = Color3.fromRGB(120, 175, 255)
    local ICON_ORANGE = Color3.fromRGB(255, 160, 100)

    local tSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tFast   = TweenInfo.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
    local tBounce = TweenInfo.new(0.20, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

    -- ── Update visual sesuai state ────────────────────────────
    local function ApplyFPPState(active)
        local accent  = active and ORANGE     or BLUE
        local dim     = active and ORANGE_DIM or BLUE_DIM
        local iconCol = active and ICON_ORANGE or ICON_BLUE

        TweenService:Create(BtnStroke, tSmooth, { Color            = accent  }):Play()
        TweenService:Create(Icon,      tSmooth, { TextColor3       = iconCol }):Play()
        TweenService:Create(ModeLbl,   tSmooth, { TextColor3       = accent  }):Play()
        TweenService:Create(Pill,      tSmooth, { BackgroundColor3 = dim     }):Play()
        TweenService:Create(PillDot,   tSmooth, { BackgroundColor3 = accent  }):Play()
        TweenService:Create(PillTxt,   tSmooth, { TextColor3       = accent  }):Play()

        ModeLbl.Text = active and "FPP" or "TPP"
        PillTxt.Text = active and "ON"  or "OFF"
        Icon.Text    = active and "👁️"   or "🎥"
    end

    -- Expose reset ke Tab toggle FPP/TPP
    getgenv().FORKT_ResetMobileBtn = function()
        isFPP = false
        SwitchCameraMode(false)
        ApplyFPPState(false)
    end

    -- ── Input ─────────────────────────────────────────────────
    ClickBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(Btn, tFast, { Size = UDim2.new(0, 66, 0, 66) }):Play()
        end
    end)

    ClickBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(Btn, tBounce, { Size = UDim2.new(0, 72, 0, 72) }):Play()
            isFPP = not isFPP
            SwitchCameraMode(isFPP)
            ApplyFPPState(isFPP)
        end
    end)
end
----------------------------------------------------------------
-- NAMECALL HOOK — SUPER OPTIMIZED FOR MOBILE
----------------------------------------------------------------
local SILENT_KEYWORDS = {"noise", "scream", "vaultalert", "spotted", "alert", "ping", "loud", "notify", "notification", "sound"}
local AURA_KEYWORDS = {"aura", "reveal", "highlight", "sense", "spotted", "vision", "radar", "detect", "tracking", "hunter"}

local myHookId = getgenv().FORKT_NamecallId
local RemoteNameCache =  setmetatable({}, { __mode = "k" })

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if getgenv().FORKT_NamecallId ~= myHookId or checkcaller() then
        return oldNamecall(self, ...)
    end

    local method = getnamecallmethod()
    if method ~= "FireServer" or typeof(self) ~= "Instance" then
        return oldNamecall(self, ...)
    end

    -- Fast String Caching (Mengurangi beban CPU Mobile)
    local n = RemoteNameCache[self]
    if not n then
        n = string.lower(self.Name)
        RemoteNameCache[self] = n
    end

    local args = { ... }

    -- Double Damage Generator
    if DoubleDamageGen and n == "breakgenevent" then -- Gunakan equality jika memungkinkan
        local team = LocalPlayer.Team
        if team and string.find(string.lower(team.Name), "killer") then
            local saved = args
            local result = oldNamecall(self, unpack(saved))

            task.spawn(function()
                for _ = 1, 4 do
                    task.wait(0.08)
                    pcall(oldNamecall, self, unpack(saved))
                end
                
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if hum and root then
                    root.Anchored = false
                    hum.PlatformStand = false
                    hum.AutoRotate = true
                    hum.Sit = false

                    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                        if track.Animation then
                            local animName = string.lower(track.Animation.Name)
                            if string.find(animName, "break") or string.find(animName, "generator") or string.find(animName, "kick") then
                                pcall(function() track:Stop(0) end)
                            end
                        end
                    end
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
            return result
        end
    end

    -- Silent Actions (Early Break Loop)
    if SilentActions then
        local isSilent = false
        for i = 1, #SILENT_KEYWORDS do
            if string.find(n, SILENT_KEYWORDS[i]) then isSilent = true; break end
        end
        
        if not isSilent and typeof(args[1]) == "string" then
            local firstArg = string.lower(args[1])
            for i = 1, #SILENT_KEYWORDS do
                if string.find(firstArg, SILENT_KEYWORDS[i]) then isSilent = true; break end
            end
        end
        if isSilent then return end
    end

    -- Anti Fall Damage
    if AntiFallDamage and (n == "falldamage" or n == "ragdollfall" or n == "fall") then
        return
    end

    -- Anti Aura (Gunakan string hashing ringan)
    if getgenv().AntiAura then
        local cache = getgenv().AuraRemoteCache
        if cache[self] == nil then
            local score = 0
            local mentions = false

            for i = 1, #AURA_KEYWORDS do
                if string.find(n, AURA_KEYWORDS[i]) then score = score + 2 end
            end

            if score >= 2 then
                local lim = math.min(3, #args)
                for i = 1, lim do
                    if args[i] == LocalPlayer or args[i] == LocalPlayer.Character then
                        mentions = true
                        break
                    end
                end
            end
            cache[self] = (score >= 4 and mentions)
        end
        if cache[self] then return end
    end

    -- Silent Aim Pistol
    if SilentAimPistol and n == "fire" then
        local selfParent = self.Parent
        local selfGrandParent = selfParent and selfParent.Parent

        if selfGrandParent and selfGrandParent.Name == "Items" then
            local myTeam = LocalPlayer.Team
            if myTeam and not string.find(string.lower(myTeam.Name), "killer") then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Tool") then
                    local target = GetClosestSilentTarget()
                    if target and target.Parent then
                        local ping = 0.08
                        pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
                        
                        local vel = target.AssemblyLinearVelocity or Vector3.zero
                        if vel.Magnitude > 40 then vel = vel.Unit * 40 end

                        local predicted = target.Position + vel * (0.10 + math.clamp(ping, 0.04, 0.20))
                        args[2] = (predicted - workspace.CurrentCamera.CFrame.Position).Unit
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
    end

    return oldNamecall(self, ...)
end))

----------------------------------------------------------------
-- KILLER: AUTO ATTACK LOGIC
----------------------------------------------------------------
do
    local CachedBasicAttack    = nil
    local SearchedAttackRemote = false
    local lastAttackStrike     = 0

    task.spawn(function()
        while task.wait(0.15) do
            if not getgenv().FORKT_RUNNING then break end
            if not AutoAttack then continue end

            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myRoot or not myHum or myHum.Health <= 0 then continue end

            local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
            if not myTeam:find("killer") then continue end

            if GetGameValue(myChar, "Carrying") or GetGameValue(myChar, "IsCarrying")
            or GetGameValue(myChar, "Stunned")  or GetGameValue(myChar, "Attacking")
            or GetGameValue(myChar, "IsAttacking") then continue end

            if not SearchedAttackRemote or not CachedBasicAttack then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local attacks = remotes:FindFirstChild("Attacks")
                                 or remotes:FindFirstChild("attacks")
                                 or remotes:FindFirstChild("Attack")
                    if attacks then
                        CachedBasicAttack    = attacks:FindFirstChild("BasicAttack")
                                           or attacks:FindFirstChild("basicattack")
                        SearchedAttackRemote = CachedBasicAttack ~= nil
                    end
                end
            end

            if not CachedBasicAttack then continue end

            local targetFound = false
            -- Menggunakan CachedSurvivors
            for i = 1, #CachedSurvivors do
                local p = CachedSurvivors[i]
                if p and p.Character then
                    local ec = p.Character
                    local eh = ec:FindFirstChildOfClass("Humanoid")
                    local er = ec:FindFirstChild("HumanoidRootPart")
                    if ec and eh and er and eh.Health > 0 then
                        if not GetGameValue(ec, "Knocked") and not GetGameValue(ec, "IsHooked") then
                            local dist = (er.Position - myRoot.Position).Magnitude
                            local range = eh.MoveDirection.Magnitude > 0 and (AttackRange + 3) or AttackRange
                            if dist <= range then targetFound = true; break end
                        end
                    end
                end
            end

            local now = os.clock()
            if not targetFound or (now - lastAttackStrike) < AttackCooldown then continue end

            if not CachedBasicAttack.Parent then
                CachedBasicAttack = nil; SearchedAttackRemote = false; continue
            end

            lastAttackStrike = now
            for i = 1, AttackCount do
                pcall(function() CachedBasicAttack:FireServer(false) end)
                if i < AttackCount then task.wait(AttackDelay) end
            end
        end
    end)
end
----------------------------------------------------------------
-- AUTO PARRY (STABLE REWRITE & OPTIMIZED)
----------------------------------------------------------------
do
    local IgnoreSkills = {
        "Veil","Masked","Stalker","Invisible",
        "Ghost","Phase","Dash","Warp","Teleport"
    }
    local KillerProfiles = {
        Killer      = { BonusDist = 1.0, Delay = 0.04 },
        Abysswalker = { BonusDist = 3.5, Delay = 0.12 },
        Hidden      = { BonusDist = 2.2, Delay = 0.00 },
        Masked      = { BonusDist = 1.5, Delay = 0.05 },
        Stalker     = { BonusDist = 1.8, Delay = 0.00 },
        Veil        = { BonusDist = 3.2, Delay = 0.04 },
        Slasher     = { BonusDist = 1.2, Delay = 0.05 },
        Cure        = { BonusDist = 2.0, Delay = 0.03 },
    }

    local LastParryTick    = 0      
    local CFG_Cooldown     = 0.30   
    local CFG_MaxVelocity  = 32
    local CFG_Prediction   = true

    -- Cache RaycastParams di luar loop
    local parryRayParams = RaycastParams.new()
    parryRayParams.FilterType = Enum.RaycastFilterType.Exclude

    local CachedParryRemote = nil

    local function GetParryRemoteFast()
        if CachedParryRemote and CachedParryRemote.Parent then 
            return CachedParryRemote 
        end
        
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return nil end
    
        -- Perbaikan pencarian rekursif menggunakan 'or' agar akurat
        CachedParryRemote = remotes:FindFirstChild("Parrying Dagger", true) 
            or remotes:FindFirstChild("parry", true)
            or remotes:FindFirstChild("ParryEvent", true)
            or remotes:FindFirstChild("DaggerParry", true)
    
        return CachedParryRemote
    end

    local function GetPing()
        local ping = 0.09
        pcall(function()
            ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        end)
        return math.clamp(ping, 0.03, 0.25)
    end

    local IgnoreSkillMap = {}
    for _, v in ipairs(IgnoreSkills) do IgnoreSkillMap[v] = true end

    local function IsKillerUsingSkill(char)
        for skill in pairs(IgnoreSkillMap) do
            if char:GetAttribute(skill) or GetGameValue(char, skill) then
                return true
            end
        end
        return false
    end

    GetKillerProfile = function(char)
        local selected = getgenv().ParryMatchup or "Auto"
        if selected ~= "Auto" then
            return KillerProfiles[selected] or { BonusDist = 1, Delay = 0 }
        end
        local detect = string.upper(tostring(
            char:GetAttribute("KillerType")
            or char:GetAttribute("Mask")
            or char.Name
        ))
        for profileKey, maskName in pairs(MaskNames) do
            if detect:find(string.upper(maskName)) then
                return KillerProfiles[profileKey] or { BonusDist = 1, Delay = 0 }
            end
        end
        return { BonusDist = 1, Delay = 0 }
    end

    local function HasParryTool(char)
        if char:FindFirstChild("Parrying Dagger") then return true end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then
                local nm = obj.Name:lower()
                if nm:find("parry") or nm:find("dagger") then return true end
            end
        end
        return false
    end

    local function IsKillerTeam(player)
        local team = player.Team
        return team and team.Name:lower():find("killer") ~= nil
    end

    local function IsSurvivorTeam(player)
        local team = player.Team
        return team and not team.Name:lower():find("killer")
    end

    UpdateParryRing = function()
        if not ParryRing then return end
        ParryRing.Visible     = AutoParry
        ParryRing.Radius      = tonumber(ParryDistance) or 10
        ParryRing.InnerRadius = (tonumber(ParryDistance) or 10) - 0.35
    end

    TriggerParryDagger = function()
        local now = os.clock()  
        if now - LastParryTick < CFG_Cooldown then return end
        if not IsSurvivorTeam(LocalPlayer) then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not (root and hum) or hum.Health <= 0 then return end

        -- Skip jika player sedang immobilized
        if GetGameValue(char, "IsHooked")
        or GetGameValue(char, "Carried")
        or GetGameValue(char, "Knocked")
        or char:GetAttribute("IsHooked")
        or char:GetAttribute("Carried") then return end

        if not HasParryTool(char) then return end

        -- Memanggil fungsi GetParryRemoteFast yang sudah dioptimalkan
        local remote = GetParryRemoteFast()
        if not remote then return end

        local ping       = GetPing()
        local bestTarget = nil
        local bestDist   = math.huge

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer or not plr.Character then continue end
            if not IsKillerTeam(plr) then continue end

            local eChar = plr.Character
            local eRoot = eChar:FindFirstChild("HumanoidRootPart")
            local eHum  = eChar:FindFirstChildOfClass("Humanoid")
            if not eRoot or not eHum or eHum.Health <= 0 then continue end
            if IsKillerUsingSkill(eChar) then continue end

            local profile     = GetKillerProfile(eChar)
            local vel         = eRoot.AssemblyLinearVelocity
            local speedFactor = math.clamp(vel.Magnitude / 18, 0, 2)
            local maxDist     = (tonumber(ParryDistance) or 10)
                + profile.BonusDist
                + ping * 8
                + speedFactor

            local predictPos = eRoot.Position
            if CFG_Prediction then
                local clampedVel = vel.Magnitude > CFG_MaxVelocity
                    and vel.Unit * CFG_MaxVelocity or vel
                local strict = math.clamp(getgenv().AimStrictness or 1.3, 0.5, 3)
                predictPos = predictPos + clampedVel * (ping + strict * 0.045)
            end

            -- Pakai cached RaycastParams, update filter saja
            parryRayParams.FilterDescendantsInstances = { char, eChar }
            local hit = workspace:Raycast(
                root.Position,
                predictPos - root.Position,
                parryRayParams
            )
            if hit then continue end

            local dist = (predictPos - root.Position).Magnitude
            if dist <= maxDist and dist < bestDist then
                bestDist   = dist
                bestTarget = { Root = eRoot, Profile = profile }
            end
        end

        if not bestTarget then return end

        LastParryTick = now

        local finalDelay = math.max(
            (bestTarget.Profile.Delay or 0) + (getgenv().ParryDelayOffset or 0),
            0
        )

        task.spawn(function()
            if finalDelay > 0 then task.wait(finalDelay) end

            local burst = bestDist <= 5 and 1
                       or bestDist <= 8 and 2
                       or 3

            for i = 1, burst do
                if not AutoParry then break end
                if not remote or not remote.Parent then break end
                pcall(function() remote:FireServer() end)
                if i < burst then task.wait(0.06) end
            end
        end)
    end
end
do
    -- Cache color correction yang dibuat oleh efek blind
    local blindConns = {}

    local function ClearBlindEffects()
        -- Hapus ColorCorrection & BlurEffect milik blind dari kamera
        local cam = workspace.CurrentCamera
        if cam then
            for _, obj in ipairs(cam:GetChildren()) do
                local n = string.lower(obj.Name)
                if n:find("blind") or n:find("flash") or n:find("stun") then
                    pcall(function() obj:Destroy() end)
                end
                if obj:IsA("ColorCorrectionEffect") then
                    -- Blind biasanya push Brightness ke -1 atau Contrast ekstrem
                    if obj.Brightness < -0.5 or obj.Contrast > 2 then
                        pcall(function() obj:Destroy() end)
                    end
                end
                if obj:IsA("BlurEffect") and obj.Size > 10 then
                    pcall(function() obj:Destroy() end)
                end
            end
        end

        -- Hapus attribute blind dari karakter
        local myChar = LocalPlayer.Character
        if myChar then
            pcall(function() myChar:SetAttribute("Blinded",   false) end)
            pcall(function() myChar:SetAttribute("IsBlinded", false) end)
            pcall(function() myChar:SetAttribute("Stunned",   false) end)

            -- Kembalikan CameraMaxZoomDistance jika dikunci oleh efek blind
            local lp = Players.LocalPlayer
            if lp.CameraMaxZoomDistance < 5 then
                pcall(function() lp.CameraMaxZoomDistance = 12 end)
            end
        end
    end

    local function ConnectAntiBlind()
        -- Disconnect koneksi lama
        for _, c in ipairs(blindConns) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(blindConns)

        if not AntiBlind then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        -- Watch setiap ChildAdded di kamera
        local c1 = cam.ChildAdded:Connect(function(obj)
            if not AntiBlind then return end
            local n = string.lower(obj.Name)
            if n:find("blind") or n:find("flash") or n:find("stun") then
                task.defer(function() pcall(function() obj:Destroy() end) end)
                return
            end
            if obj:IsA("ColorCorrectionEffect") then
                task.defer(function()
                    if obj.Brightness < -0.5 or obj.Contrast > 2 then
                        pcall(function() obj:Destroy() end)
                    end
                end)
            end
            if obj:IsA("BlurEffect") and obj.Size > 10 then
                task.defer(function() pcall(function() obj:Destroy() end) end)
            end
        end)

        -- Watch perubahan attribute Blinded pada karakter
        local myChar = LocalPlayer.Character
        if myChar then
            local c2 = myChar:GetAttributeChangedSignal("Blinded"):Connect(function()
                if not AntiBlind then return end
                if myChar:GetAttribute("Blinded") then
                    pcall(function() myChar:SetAttribute("Blinded", false) end)
                    ClearBlindEffects()
                end
            end)
            local c3 = myChar:GetAttributeChangedSignal("IsBlinded"):Connect(function()
                if not AntiBlind then return end
                if myChar:GetAttribute("IsBlinded") then
                    pcall(function() myChar:SetAttribute("IsBlinded", false) end)
                    ClearBlindEffects()
                end
            end)
            table.insert(blindConns, c2)
            table.insert(blindConns, c3)
        end

        table.insert(blindConns, c1)
    end

    -- Re-connect setiap respawn agar karakter baru juga terlindungi
    t_insert(getgenv().FORKT_CONNECTIONS, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if AntiBlind then
            ClearBlindEffects()
            ConnectAntiBlind()
        end
    end))

    -- Polling fallback: tiap 0.2s bersihkan sisa efek yang lolos dari event
    task.spawn(function()
        while task.wait(0.2) do
            if not getgenv().FORKT_RUNNING then break end
            if not AntiBlind then continue end

            local myChar = LocalPlayer.Character
            local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
            if not myTeam:find("killer") then continue end

            ClearBlindEffects()
        end
    end)

    -- Expose connect function agar bisa dipanggil dari toggle
    getgenv().FORKT_ConnectAntiBlind = ConnectAntiBlind
end

----------------------------------------------------------------
-- AUTO BREAK DROPPED PALLETS (KILLER ONLY)
----------------------------------------------------------------
do
    local lastBreakTick         = 0
    local CachedBreakRemote     = nil
    local SearchedBreakRemote   = false

    -- Cache pallet terdekat yang sudah dropped agar tidak scan tiap frame
    local cachedDroppedPallet   = nil
    local lastPalletScan        = 0
    local PALLET_SCAN_INTERVAL  = 0.8

    local function FindNearestDroppedPallet(myPos)
        local best, bestDist = nil, BreakPalletRadius

        if CachedMapObjects and CachedMapObjects.Pallets then
            for i = 1, #CachedMapObjects.Pallets do
                local obj = CachedMapObjects.Pallets[i]
                if obj and obj.Parent then
                    local isDropped = IsStatusActive(GetGameValue(obj, "Dropped")) or IsStatusActive(GetGameValue(obj, "IsDropped")) or obj:GetAttribute("Dropped")
                    
                    if isDropped then
                        local part = (obj:IsA("Model") and obj.PrimaryPart) or obj:FindFirstChildWhichIsA("BasePart", true) or (obj:IsA("BasePart") and obj)
                        if part then
                            local d = (part.Position - myPos).Magnitude
                            if d < bestDist then
                                bestDist = d
                                best = obj
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    task.spawn(function()
        while task.wait(0.10) do
            if not getgenv().FORKT_RUNNING then break end
            if not AutoBreakPallet then continue end

            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myRoot or not myHum or myHum.Health <= 0 then continue end

            local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
            if not myTeam:find("killer") then continue end

            if GetGameValue(myChar, "Stunned")
            or GetGameValue(myChar, "Carrying")
            or GetGameValue(myChar, "IsCarrying") then continue end

            -- Cache break remote
            if not SearchedBreakRemote or not CachedBreakRemote then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local folder = remotes:FindFirstChild("Pallets")
                                or remotes:FindFirstChild("Pallet")
                                or remotes:FindFirstChild("Objects")
                                or remotes:FindFirstChild("Items")
                    if folder then
                        CachedBreakRemote = folder:FindFirstChild("BreakPallet")
                                         or folder:FindFirstChild("Break")
                                         or folder:FindFirstChild("BreakEvent")
                                         or folder:FindFirstChild("DestroyPallet")
                    end
                    if not CachedBreakRemote then
                        CachedBreakRemote = remotes:FindFirstChild("BreakPallet", true)
                                         or remotes:FindFirstChild("BreakEvent",  true)
                                         or remotes:FindFirstChild("DestroyPallet", true)
                    end
                    SearchedBreakRemote = CachedBreakRemote ~= nil
                end
            end

            if not CachedBreakRemote or not CachedBreakRemote.Parent then
                CachedBreakRemote   = nil
                SearchedBreakRemote = false
                continue
            end

            local now   = os.clock()
            local myPos = myRoot.Position

            -- Re-scan pallet setiap interval
            if now - lastPalletScan > PALLET_SCAN_INTERVAL then
                cachedDroppedPallet = FindNearestDroppedPallet(myPos)
                lastPalletScan      = now
            end

            if not cachedDroppedPallet
            or not cachedDroppedPallet.Parent then
                cachedDroppedPallet = nil
                continue
            end

            if now - lastBreakTick < BreakPalletCooldown then continue end

            -- Validasi masih dropped
            local stillDropped = IsStatusActive(GetGameValue(cachedDroppedPallet, "Dropped"))
                              or IsStatusActive(GetGameValue(cachedDroppedPallet, "IsDropped"))
                              or cachedDroppedPallet:GetAttribute("Dropped")
            if not stillDropped then
                cachedDroppedPallet = nil
                continue
            end

            -- Cek jarak lagi dengan posisi terkini
            local part = (cachedDroppedPallet:IsA("Model") and cachedDroppedPallet.PrimaryPart)
                      or cachedDroppedPallet:FindFirstChildWhichIsA("BasePart", true)
                      or (cachedDroppedPallet:IsA("BasePart") and cachedDroppedPallet)
            if not part then continue end

            local dist = (part.Position - myPos).Magnitude
            if dist > BreakPalletRadius then continue end

            pcall(function() CachedBreakRemote:FireServer(cachedDroppedPallet) end)
            lastBreakTick       = now
            cachedDroppedPallet = nil  -- force re-scan setelah break
        end
    end)
end
do
    local lastVaultTick       = 0
    local CachedVaultRemote   = nil
    local SearchedVaultRemote = false

    -- [CACHE] Simpan objek vault terdekat agar tidak scan setiap frame
    local cachedVaultObj     = nil
    local lastVaultObjScan   = 0
    local VAULT_OBJ_INTERVAL = 1.0  -- re-scan setiap 1 detik

    local VaultKeywords = { "window", "vault", "pallet" }

    local function FindNearestVaultObject(myPos)
        local best, bestDist = nil, 5.5

        -- Gunakan cache Pallets & Gates secara eksklusif (Menghindari GetDescendants)
        if CachedMapObjects then
            local objectsToCheck = {}
            for i=1, #CachedMapObjects.Pallets do objectsToCheck[#objectsToCheck+1] = CachedMapObjects.Pallets[i] end
            
            for i = 1, #objectsToCheck do
                local obj = objectsToCheck[i]
                if obj and obj.Parent then
                    local part = (obj:IsA("Model") and obj.PrimaryPart) or obj:FindFirstChildWhichIsA("BasePart", true) or (obj:IsA("BasePart") and obj)
                    if part then
                        local d = (part.Position - myPos).Magnitude
                        if d < bestDist then
                            bestDist = d
                            best = obj
                        end
                    end
                end
            end
        end
        return best
    end

    task.spawn(function()
        while task.wait(0.08) do
            if not getgenv().FORKT_RUNNING then break end
            if not AutoVault then continue end

            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myRoot or not myHum or myHum.Health <= 0 then continue end

            local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
            if myTeam:find("killer") then continue end

            if GetGameValue(myChar, "IsHooked")
            or GetGameValue(myChar, "Carried")
            or GetGameValue(myChar, "Knocked")
            or myChar:GetAttribute("IsHooked") then continue end

            -- Cache remote
            if not SearchedVaultRemote or not CachedVaultRemote then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local folder = remotes:FindFirstChild("Actions")
                                or remotes:FindFirstChild("Movement")
                                or remotes:FindFirstChild("Survivor")
                    if folder then
                        CachedVaultRemote = folder:FindFirstChild("VaultEvent")
                                         or folder:FindFirstChild("Vault")
                                         or folder:FindFirstChild("WindowVault")
                    end
                    if not CachedVaultRemote then
                        CachedVaultRemote = remotes:FindFirstChild("VaultEvent", true)
                                         or remotes:FindFirstChild("WindowVault", true)
                                         or remotes:FindFirstChild("Vault", true)
                    end
                    SearchedVaultRemote = CachedVaultRemote ~= nil
                end
            end

            if not CachedVaultRemote or not CachedVaultRemote.Parent then
                CachedVaultRemote   = nil
                SearchedVaultRemote = false
                continue
            end

            local now        = os.clock()
            local killerDist = killerScanResult.dist
            local isFastVault = killerDist <= FastVaultThreshold

            -- Hanya vault jika bergerak ATAU killer sangat dekat
            if not isFastVault and myHum.MoveDirection.Magnitude < 0.1 then continue end
            if now - lastVaultTick < VaultCooldown then continue end

            -- Re-scan objek vault setiap interval
            if now - lastVaultObjScan > VAULT_OBJ_INTERVAL then
                cachedVaultObj   = FindNearestVaultObject(myRoot.Position)
                lastVaultObjScan = now
            end

            if not cachedVaultObj then continue end

            -- Validasi objek masih ada
            if not cachedVaultObj.Parent then
                cachedVaultObj = nil
                continue
            end

            pcall(function() CachedVaultRemote:FireServer(cachedVaultObj, isFastVault) end)

            -- Fast vault: dorong karakter sedikit agar animasi tidak stuck
            if isFastVault then
                pcall(function()
                    local dir = myHum.MoveDirection.Magnitude > 0.05
                        and myHum.MoveDirection
                        or  myRoot.CFrame.LookVector
                    myRoot.CFrame = myRoot.CFrame + dir * 3.5
                end)
            end

            lastVaultTick = now
        end
    end)
end
----------------------------------------------------------------
-- CACHED KILLER SCAN (adaptive interval)
----------------------------------------------------------------
task.spawn(function()
    while task.wait(0.12) do
        if not getgenv().FORKT_RUNNING then break end
        if not IsKillerScanNeeded() and not AutoParry then
            continue
        end
        -- 1. Killer Proximity & Distance Scan (Super Ringan)
        if IsKillerScanNeeded() then
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end

                local myPos = myRoot.Position
                local minDist = 999

                -- Menggunakan Cache, bukan Players:GetPlayers() lagi!
                for i = 1, #CachedKillers do
                    local p = CachedKillers[i]
                    if p and p.Character then
                        local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
                        if eRoot then
                            local d = (eRoot.Position - myPos).Magnitude
                            if d < minDist then minDist = d end
                        end
                    end
                end

                killerScanResult.dist = minDist
            end)
        else
            killerScanResult.dist = 999
        end

        -- 2. Auto Dagger / Parry Logic
        if AutoParry then
            pcall(TriggerParryDagger)
        end
    end
end)
----------------------------------------------------------------
-- STUN DETECTOR (adaptive interval)
----------------------------------------------------------------
-- [WORKER 2] SLOW/DYNAMIC LOOP (Interval Sedang & Variabel: AI Bot, ESP, Stun, & Safety Net)
local killerStunStates = setmetatable({}, { __mode = "k" })

task.spawn(function()
    while task.wait(0.40) do
        if not getgenv().FORKT_RUNNING then break end
        local espActive = IsAnyESPActive()
        if not espActive and not NotifyStun then
            -- Hanya jalankan safety net dasar saja yang sangat ringan
            pcall(function()
                local myChar = LocalPlayer.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if myHum and not myHum.AutoRotate then myHum.AutoRotate = true end
            end)
            continue
        end
        -- 1. ESP Refresh (Hanya jalan jika ada ESP aktif)
        if IsAnyESPActive() then
            pcall(RefreshESP)
        end

        -- 2. Stun Detector (Menggunakan CachedKillers yang super ringan)
        if NotifyStun then
            pcall(function()
                for i = 1, #CachedKillers do
                    local p = CachedKillers[i]
                    if p and p.Character then
                        local kChar = p.Character
                        local stunVal = GetGameValue(kChar, "Stunned") or GetGameValue(kChar, "IsStunned")
                        local isStunned = (stunVal == true or (type(stunVal) == "number" and stunVal > 0))
                        
                        -- Notifikasi hanya muncul sekali saat pertama kali killer terkena stun
                        if isStunned and not killerStunStates[p.UserId] then
                            WindUI:Notify({
                                Title = "KILLER STUNNED!",
                                Content = p.Name .. " berhasil stunned!!",
                                Icon = "lucide:dizzy",
                                Duration = 2.5
                            })
                        end
                        killerStunStates[p.UserId] = isStunned
                    end
                end
            end)
        else
            if next(killerStunStates) ~= nil then table.clear(killerStunStates) end
        end

        -- 3. Safety Net (AutoRotate & PlatformStand Fixer)
        pcall(function()
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHum and myRoot then
                if not getgenv().MoonwalkEnabled and not isFPP and not myHum.AutoRotate then
                    myHum.AutoRotate = true
                end
                if myRoot.Anchored then myRoot.Anchored = false end
                if myHum.PlatformStand then myHum.PlatformStand = false end
            end
        end)
    end
end)

-- =========================================================
-- EKSEKUSI WIPER & SPEED SYNC SETIAP KALI RESPAWN
-- =========================================================
t_insert(getgenv().FORKT_CONNECTIONS, LocalPlayer.CharacterAdded:Connect(function(char)
    getgenv().FORKT_SPAWN_TIME = os.clock()

    local hum  = char:WaitForChild("Humanoid", 8)
    local root = char:WaitForChild("HumanoidRootPart", 8)
    if not hum or not root then return end
    task.wait(0.8)
    if not char.Parent then return end  -- Karakter dihapus selama wait

    pcall(function()
        hum.AutoRotate    = true
        hum.PlatformStand = false
        hum.Sit           = false
        root.Anchored     = false
    end)

    -- [FIX] Restore mouse behavior mobile setelah respawn
    if IS_MOBILE then
        task.wait(0.3)
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end)
    end

    -- Speed sync
    if SpeedBoost then
        local baseSpeed    = 17
        local percentValue = tonumber(BoostSpeed) or 0
        pcall(function()
            hum.WalkSpeed = baseSpeed + (baseSpeed * (percentValue / 100))
        end)
    end

    task.wait(0.1)
    UpdateParryRingAdornee()

    -- Update DefaultFOV
    task.spawn(function()
        task.wait(0.5)
        local cam = workspace.CurrentCamera
        if cam and not CustomCameraFOV then
            DefaultFOV = cam.FieldOfView
        end
    end)

    -- Re-init AutoGenerator
    if getgenv().FORKT_InitAutoGen then
        task.spawn(function()
            task.wait(2)
            getgenv().FORKT_InitAutoGen()
        end)
    end

    -- [FIX] Re-connect Anti Blind jika aktif
    if AntiBlind and getgenv().FORKT_ConnectAntiBlind then
        task.spawn(function()
            task.wait(0.5)
            getgenv().FORKT_ConnectAntiBlind()
        end)
    end

    -- [FIX] Double-check AutoRotate setelah delay (game mungkin set ulang)
    task.spawn(function()
        task.wait(1.5)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h and not getgenv().MoonwalkEnabled and not isFPP then
            pcall(function() h.AutoRotate = true end)
        end
    end)
end))
-- =========================================================
-- [ANTI-MEMORY LEAK] PEMBERSIH CACHE OTOMATIS
-- =========================================================
t_insert(getgenv().FORKT_CONNECTIONS, Players.PlayerRemoving:Connect(function(player)
    -- Bersihkan cache ESP pemain yang keluar
    if ESP_PlayerCache then
        ESP_PlayerCache[player.UserId] = nil
    end

    -- Bersihkan TargetPartCache untuk karakter pemain ini
    if player.Character then
        TargetPartCache[player.Character] = nil

        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local tag = root:FindFirstChild("TagESP")
            if tag then tag:Destroy() end
        end
    end
end))
-- =========================================================
-- CENTRALIZED ROBLOX LOOPS (SUPER OPTIMIZED)
-- =========================================================
local UnifiedVariables = {
    frameCount = 0,
    timeAccum = 0,
    lastRenderCheck = 0,
    cachedIsCarrying = false,
    CurrentMoonwalkYaw = 0,
    CurrentMoonwalkSway = 0,
    SearchedHBRemotes = false
}

-- [1] UNIFIED RENDERSTEPPED (Menangani Visual & Kamera)
local UnifiedRender = RunService.RenderStepped:Connect(function(deltaTime)
    if not getgenv().FORKT_RUNNING then return end
    if not CursorEnabled and not getgenv().MoonwalkEnabled and not Aimbot and not CustomCameraFOV then
        return
    end
    -- 1. Custom Cursor
    if CursorEnabled and Cursor then
        local pos = UserInputService:GetMouseLocation()
        Cursor.Position = UDim2.fromOffset(pos.X, pos.Y)
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    -- 2. Smooth FOV
    if not isFPP then
        local targetFOV = CustomCameraFOV and CameraFOVValue or DefaultFOV
        local currentFOV = camera.FieldOfView
        local diff = targetFOV - currentFOV

        if math.abs(diff) > 0.05 then
            -- Exponential smoothing agar frame-rate independent
            local alpha = 1 - math.exp(-deltaTime * 8)
            camera.FieldOfView = currentFOV + diff * alpha
        elseif currentFOV ~= targetFOV then
            camera.FieldOfView = targetFOV
        end
    end

    -- 3. Cek Karakter
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChild("Humanoid")
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    local moonActive = getgenv().MoonwalkEnabled
    local aimActive = Aimbot

    if not moonActive and not aimActive then return end

    -- 4. Moonwalk Physics
    if moonActive then
        local myRole = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
        if not string.find(myRole, "killer") then
            if myHum.AutoRotate then myHum.AutoRotate = false end

            local look = camera.CFrame.LookVector
            local targetYaw = math.deg(math.atan2(look.X, look.Z)) + 180
            local diff = ((targetYaw - UnifiedVariables.CurrentMoonwalkYaw + 180) % 360) - 180

            UnifiedVariables.CurrentMoonwalkYaw = UnifiedVariables.CurrentMoonwalkYaw + diff * (0.22 * math.clamp(deltaTime * 60, 0, 3))

            local moving = myHum.MoveDirection.Magnitude > 0.01
            local sway = 0

            if moving then
                sway = math.sin(time() * (getgenv().MoonwalkZigzagSpeed or 11)) * (getgenv().MoonwalkZigzagAmount or 48)
            end

            UnifiedVariables.CurrentMoonwalkSway = UnifiedVariables.CurrentMoonwalkSway + (sway - UnifiedVariables.CurrentMoonwalkSway) * 0.38
            myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, math.rad(UnifiedVariables.CurrentMoonwalkYaw + UnifiedVariables.CurrentMoonwalkSway), 0)

            if moving then
                myHum:Move(myHum.MoveDirection * (getgenv().MoonwalkBoostPower or 1.08), false)
            end
        end
    else
        if not myHum.AutoRotate then pcall(function() myHum.AutoRotate = true end) end
    end

    -- 5. Aimbot Logic
    if aimActive then
        local now = time()
        if now - UnifiedVariables.lastRenderCheck > 0.25 then
            UnifiedVariables.cachedIsCarrying = GetGameValue(myChar, "Carrying") or GetGameValue(myChar, "IsCarrying") or false
            UnifiedVariables.lastRenderCheck = now
        end

        if not UnifiedVariables.cachedIsCarrying then
            if now - LastTargetCheck > 0.12 then
                CachedTarget = GetClosestPlayer(CachedTarget)
                LastTargetCheck = now
            end

            local target = CachedTarget
            if target and target.Parent and target:IsDescendantOf(workspace) then
                local isAlwaysLock = (getgenv().AimbotTrigger or "Hold to Lock") == "Auto Lock (Always)"
                local firing = isAlwaysLock or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or getgenv().isMobileFiring

                if firing then
                    local camPos = camera.CFrame.Position
                    local targetPos = target.Position
                    local dirToTarget = (targetPos - camPos).Unit
                    
                    if camera.CFrame.LookVector:Dot(dirToTarget) < 0.5 then
                        CachedTarget = nil
                        LastTargetCheck = 0
                    else
                        local mouseDelta = UserInputService:GetMouseDelta()
                        local thresh = getgenv().AimbotMouseOverride or 6
                        local overrideFactor = mouseDelta.Magnitude > thresh and math.clamp(thresh / mouseDelta.Magnitude, 0.05, 0.5) or 1.0
                        local smooth = math.clamp(deltaTime * (getgenv().AimbotSmoothness or 8) * overrideFactor, 0.03, 0.28)
                        
                        camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, targetPos), smooth)
                    end
                end
            else
                CachedTarget = nil
            end
        end
    end
end)


-- [2] UNIFIED HEARTBEAT (Menangani Game Logic, Sinkronisasi & UI)
local UnifiedHeartbeat = RunService.Heartbeat:Connect(function(dt)
    if not getgenv().FORKT_RUNNING then return end
    if not WarnKiller and not SpeedBoost then return end
    local now = os.clock()

        -- 1. FPS & Ping Updater (Throttled 1 Detik untuk UI)
    UnifiedVariables.frameCount = UnifiedVariables.frameCount + 1
    UnifiedVariables.timeAccum = UnifiedVariables.timeAccum + dt
    if UnifiedVariables.timeAccum >= 1 then
        if SystemParagraph and buildSystemDesc and getPing then
            local fpsText = string.format("%d", math.floor(UnifiedVariables.frameCount / UnifiedVariables.timeAccum))
            local pingText = getPing()
            pcall(function() SystemParagraph:SetDesc(buildSystemDesc(pingText, fpsText)) end)
        end
        UnifiedVariables.frameCount, UnifiedVariables.timeAccum = 0, 0
    end

    -- 2. Cek Karakter untuk Logic Mobile
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myHum or not myRoot then return end

    local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
    local isKiller = string.find(myTeam, "killer") ~= nil

    -- Bypass logic bawah jika tidak digunakan
    if not WarnKiller and not (SpeedBoost and not isKiller) then return end

    -- 3. Warn Killer Logic
    if WarnKiller and killerScanResult then
        local closestKillerDist = killerScanResult.dist
        local warnGui = myRoot:FindFirstChild("KillerWarn")

        if closestKillerDist <= 60 then
            local isChased = closestKillerDist <= 40
            local txt = isChased and "!!" or "!"
            local col = isChased and Color3.new(1,0,0) or Color3.new(1,0.6,0)

            if not warnGui then
                warnGui = CreateBillboardTag(txt, col, UDim2.new(0,15,0,15), 16)
                warnGui.Name = "KillerWarn"
                warnGui.StudsOffset = Vector3.new(0, 4, 0)
                warnGui.Parent = myRoot
            else
                local lbl = warnGui:FindFirstChild("Label")
                if lbl then lbl.Text = txt; lbl.TextColor3 = col end
            end
        elseif warnGui then
            warnGui:Destroy()
        end
    end

    -- 4. SpeedBoost & Critical Animation Validation
    if SpeedBoost and not isKiller then
        local isDoingCriticalAction = false
        local lastAnimCheck = myChar:GetAttribute("FORKT_LastAnimCheck") or 0
        
        if now - lastAnimCheck > 0.3 then
            myChar:SetAttribute("FORKT_LastAnimCheck", now)
            for _, track in ipairs(myHum:GetPlayingAnimationTracks()) do
                if track.Animation then
                    local n = string.lower(track.Animation.Name)
                    if string.find(n, "hook") or string.find(n, "grab") or string.find(n, "pickup") or string.find(n, "place") then
                        isDoingCriticalAction = true
                        break
                    end
                end
            end
            myChar:SetAttribute("FORKT_CriticalAction", isDoingCriticalAction)
        else
            isDoingCriticalAction = myChar:GetAttribute("FORKT_CriticalAction") or false
        end

        if myHum.Health > 0 and (now - (getgenv().FORKT_SPAWN_TIME or 0)) > 2.5 then
            local isImmobilized = GetGameValue(myChar, "IsHooked") or GetGameValue(myChar, "Carried") or myChar:GetAttribute("IsHooked") or myChar:GetAttribute("Carried") or myChar:GetAttribute("Grabbed")
            
            if not isImmobilized and not isDoingCriticalAction and myHum.MoveDirection.Magnitude > 0.1 then
                local pct = math.clamp(tonumber(BoostSpeed) or 0, 0, 150)
                local extra = myHum.WalkSpeed * (pct / 100)
                if extra > 0.5 then
                    pcall(function() myRoot.CFrame = myRoot.CFrame + myHum.MoveDirection * (extra * dt) end)
                end
            end
        end
    end
end)

table.insert(getgenv().FORKT_CONNECTIONS, UnifiedRender)
table.insert(getgenv().FORKT_CONNECTIONS, UnifiedHeartbeat)

local n = WindUI:Notify({ 
    Title = "Welcome to FORKT-HUB!", 
    Content = "God-AI Systems Initialized.\n💻 PC User: Press [Keybind K] to open/hide the UI.", 
    Duration = 10,
    CanClose = false,
    Icon = "lucide:sparkles" 
})
WindUI:SetNotificationLower(true)
task.wait(4.5)
n:Close()