--=====================================================================
--  ESP PRO MAX v3  |  Mobile + PC  |  Player + NPC + Chams + Outline
--=====================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Camera     = Workspace.CurrentCamera

if not Drawing then
    warn("[ESP] This executor does not support the Drawing API.")
    return
end

--=====================================================================
-- CONFIG  (soft white = 230,230,230 — not blinding)
--=====================================================================
local SOFT_WHITE = Color3.fromRGB(230, 230, 230)
local SOFT_TXT   = Color3.fromRGB(235, 235, 235)

local Config = {
    Enabled       = true,
    ShowChams     = true,
    ShowOutline   = true,
    ShowBox       = true,
    ShowName      = true,
    ShowDistance  = true,
    ShowHealth    = true,
    ShowTracer    = true,
    ShowSkeleton  = false,
    ShowNPCs      = true,
    TeamCheck     = true,
    FillBox       = false,
    MaxDistance   = 1500,

    BoxColor      = SOFT_WHITE,
    TracerColor   = SOFT_WHITE,
    TextColor     = SOFT_TXT,
    ChamsColor    = SOFT_WHITE,
    OutlineColor  = SOFT_WHITE,
}

--=====================================================================
-- GUI PARENT
--=====================================================================
local function guiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then
        local ok3 = pcall(function()
            local f = Instance.new("Folder"); f.Parent = cg; f:Destroy()
        end)
        if ok3 then return cg end
    end
    return LP:WaitForChild("PlayerGui")
end

--=====================================================================
-- UI
--=====================================================================
local ACCENT = Color3.fromRGB(0, 255, 150)
local BG     = Color3.fromRGB(17, 17, 21)
local ROW    = Color3.fromRGB(28, 28, 34)
local TXT    = Color3.fromRGB(232, 232, 238)
local OFF    = Color3.fromRGB(55, 55, 65)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESPProMax"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
do
    local p = guiParent()
    local ok = pcall(function() ScreenGui.Parent = p end)
    if not ok then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end
end

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.fromOffset(56, 56)
OpenBtn.Position = UDim2.new(0, 16, 0.5, -28)
OpenBtn.BackgroundColor3 = BG
OpenBtn.Text = "ESP"
OpenBtn.TextColor3 = ACCENT
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 15
OpenBtn.BorderSizePixel = 0
OpenBtn.AutoButtonColor = false
OpenBtn.Active = true
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
local openStroke = Instance.new("UIStroke", OpenBtn)
openStroke.Color = ACCENT
openStroke.Thickness = 1.5

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(290, 530)
Main.Position = UDim2.new(0.5, -145, 0.5, -265)
Main.BackgroundColor3 = BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(50, 50, 60)
mainStroke.Thickness = 1

local Title = Instance.new("Frame")
Title.Size = UDim2.new(1, 0, 0, 44)
Title.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Title.BorderSizePixel = 0
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ESP  PRO  MAX  v3"
TitleLabel.TextColor3 = ACCENT
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(32, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 15
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Title
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -16, 1, -58)
List.Position = UDim2.new(0, 8, 0, 50)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 3
List.ScrollBarImageColor3 = ACCENT
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = List

local order = 0

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

makeDraggable(Main, Title)
makeDraggable(OpenBtn, OpenBtn)

local function addToggle(name, key)
    order += 1
    local row = Instance.new("TextButton")
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -6, 0, 40)
    row.BackgroundColor3 = ROW
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = List
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -64, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = TXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(44, 22)
    track.Position = UDim2.new(1, -56, 0.5, -11)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local on = Config[key]
        track.BackgroundColor3 = on and ACCENT or OFF
        knob.Position = on and UDim2.new(1, -19, 0.5, -8)
                            or UDim2.new(0, 3, 0.5, -8)
    end

    row.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        refresh()
    end)

    refresh()
end

local function addSlider(name, key, minV, maxV)
    order += 1
    local row = Instance.new("Frame")
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -6, 0, 54)
    row.BackgroundColor3 = ROW
    row.BorderSizePixel = 0
    row.Parent = List
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. tostring(Config[key])
    lbl.TextColor3 = TXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 8)
    bar.Position = UDim2.new(0, 12, 0, 37)
    bar.BackgroundColor3 = OFF
    bar.BorderSizePixel = 0
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[key] - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setFromX(x)
        local ax = bar.AbsolutePosition.X
        local w  = math.max(bar.AbsoluteSize.X, 1)
        local a  = math.clamp((x - ax) / w, 0, 1)
        local v  = math.floor(minV + (maxV - minV) * a)
        Config[key] = v
        fill.Size = UDim2.new(a, 0, 1, 0)
        lbl.Text = name .. ": " .. tostring(v)
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function addButton(name, color, cb)
    order += 1
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, -6, 0, 40)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = List
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseButton1Click:Connect(cb)
end

addToggle("Master ESP",       "Enabled")
addToggle("Chams (fill)",     "ShowChams")
addToggle("Chams Outline",    "ShowOutline")
addToggle("Box",              "ShowBox")
addToggle("Fill Box",         "FillBox")
addToggle("Name",             "ShowName")
addToggle("Distance",         "ShowDistance")
addToggle("Health Bar",       "ShowHealth")
addToggle("Tracer",           "ShowTracer")
addToggle("Skeleton",         "ShowSkeleton")
addToggle("NPCs",             "ShowNPCs")
addToggle("Team Check",       "TeamCheck")
addSlider("Max Distance",     "MaxDistance", 100, 5000)

local function setOpen(open)
    Main.Visible = open
    OpenBtn.Visible = not open
end

OpenBtn.MouseButton1Click:Connect(function() setOpen(true) end)
CloseBtn.MouseButton1Click:Connect(function() setOpen(false) end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setOpen(not Main.Visible)
    end
end)

--=====================================================================
-- ESP DRAWING POOL  (shared for players + NPCs)
--=====================================================================
local espCache = {}

local function getESP(entity)
    local t = espCache[entity]
    if t then return t end

    t = {
        box    = Drawing.new("Square"),
        name   = Drawing.new("Text"),
        dist   = Drawing.new("Text"),
        hbBg   = Drawing.new("Square"),
        hbFill = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        skel   = {},
        cham   = nil,
    }

    t.box.Thickness = 1
    t.box.Filled    = false
    t.box.Transparency = 1

    t.name.Size    = 14
    t.name.Center  = true
    t.name.Outline = true
    t.name.Font    = 2

    t.dist.Size    = 13
    t.dist.Center  = true
    t.dist.Outline = true
    t.dist.Font    = 2

    t.hbBg.Filled   = true
    t.hbFill.Filled = true
    t.tracer.Thickness = 1

    espCache[entity] = t
    return t
end

local function hideESP(t)
    t.box.Visible    = false
    t.name.Visible   = false
    t.dist.Visible   = false
    t.hbBg.Visible   = false
    t.hbFill.Visible = false
    t.tracer.Visible = false
    for _, l in ipairs(t.skel) do l.Visible = false end
    if t.cham then t.cham.Enabled = false end
end

local function destroyESP(t)
    t.box:Remove(); t.name:Remove(); t.dist:Remove()
    t.hbBg:Remove(); t.hbFill:Remove(); t.tracer:Remove()
    for _, l in ipairs(t.skel) do l:Remove() end
    if t.cham then t.cham:Destroy() end
end

local function skelLine(t, i)
    local l = t.skel[i]
    if not l then
        l = Drawing.new("Line")
        l.Thickness = 1
        t.skel[i] = l
    end
    return l
end

local function applyChams(t, char)
    local want = Config.ShowChams or Config.ShowOutline
    if not want or not char or not char.Parent then
        if t.cham then t.cham.Enabled = false end
        return
    end

    local h = t.cham
    if not h or not h.Parent or h.Adornee ~= char then
        if h then h:Destroy() end
        h = Instance.new("Highlight")
        h.Name              = "ESPProMax_Cham"
        h.Adornee           = char
        h.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent            = char
        t.cham              = h
    end

    h.FillColor           = Config.ChamsColor
    h.FillTransparency    = Config.ShowChams   and 0.55 or 1
    h.OutlineColor        = Config.OutlineColor
    h.OutlineTransparency = Config.ShowOutline and 0    or 1
    h.Enabled             = true
end

--=====================================================================
-- SHARED RENDERER (used by players + NPCs)
--=====================================================================
local function renderDrawings(t, char, hum, hrp, head, displayName, dist)
    local top3 = head.Position + Vector3.new(0, 0.5, 0)
    local bot3 = hrp.Position  - Vector3.new(0, 3, 0)

    local top, onTop = Camera:WorldToViewportPoint(top3)
    local bot, onBot = Camera:WorldToViewportPoint(bot3)

    if not (onTop and onBot) or top.Z <= 0 or bot.Z <= 0 then
        t.box.Visible = false; t.name.Visible = false; t.dist.Visible = false
        t.hbBg.Visible = false; t.hbFill.Visible = false; t.tracer.Visible = false
        for _, l in ipairs(t.skel) do l.Visible = false end
        return
    end

    local height = math.abs(top.Y - bot.Y)
    local width  = height * 0.55
    local cx     = (top.X + bot.X) / 2
    local bx     = cx - width / 2
    local by     = math.min(top.Y, bot.Y)

    t.box.Position = Vector2.new(bx, by)
    t.box.Size     = Vector2.new(width, height)
    t.box.Color    = Config.BoxColor
    t.box.Filled   = Config.FillBox
    t.box.Visible  = Config.ShowBox

    t.name.Text     = displayName
    t.name.Position = Vector2.new(cx, by - 17)
    t.name.Color    = Config.TextColor
    t.name.Visible  = Config.ShowName

    t.dist.Text     = string.format("%d studs", math.floor(dist))
    t.dist.Position = Vector2.new(cx, by + height + 2)
    t.dist.Color    = Config.TextColor
    t.dist.Visible  = Config.ShowDistance

    local hp    = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local barW  = 3
    local fillH = height * hp
    t.hbBg.Position   = Vector2.new(bx - 7, by)
    t.hbBg.Size       = Vector2.new(barW, height)
    t.hbBg.Color      = Color3.fromRGB(0, 0, 0)
    t.hbBg.Visible    = Config.ShowHealth
    t.hbFill.Position = Vector2.new(bx - 7, by + (height - fillH))
    t.hbFill.Size     = Vector2.new(barW, fillH)
    t.hbFill.Color    = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
    t.hbFill.Visible  = Config.ShowHealth

    local vp = Camera.ViewportSize
    t.tracer.From    = Vector2.new(vp.X / 2, vp.Y)
    t.tracer.To      = Vector2.new(cx, by + height)
    t.tracer.Color   = Config.TracerColor
    t.tracer.Visible = Config.ShowTracer

    if Config.ShowSkeleton then
        local idx = 0
        for _, m in ipairs(char:GetDescendants()) do
            if m:IsA("Motor6D") and m.Part0 and m.Part1 then
                local p0, ok0 = Camera:WorldToViewportPoint(m.Part0.Position)
                local p1, ok1 = Camera:WorldToViewportPoint(m.Part1.Position)
                if ok0 and ok1 and p0.Z > 0 and p1.Z > 0 then
                    idx += 1
                    local l = skelLine(t, idx)
                    l.From    = Vector2.new(p0.X, p0.Y)
                    l.To      = Vector2.new(p1.X, p1.Y)
                    l.Color   = Config.BoxColor
                    l.Visible = true
                end
            end
        end
        for i = idx + 1, #t.skel do t.skel[i].Visible = false end
    else
        for _, l in ipairs(t.skel) do l.Visible = false end
    end
end

--=====================================================================
-- PLAYER PROCESSING
--=====================================================================
local function processPlayer(player)
    local t = getESP(player)

    if player == LP then hideESP(t) return end

    if Config.TeamCheck and player.Team and LP.Team
    and player.Team == LP.Team then
        hideESP(t) return
    end

    local char = player.Character
    if not char then hideESP(t) return end

    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")

    if not (hum and hrp and head) or hum.Health <= 0 then
        hideESP(t) return
    end

    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    if dist > Config.MaxDistance then hideESP(t) return end

    applyChams(t, char)
    renderDrawings(t, char, hum, hrp, head,
        player.DisplayName or player.Name, dist)
end

--=====================================================================
-- NPC SCANNER
--=====================================================================
local npcHumanoids = {}  -- [model] = humanoid
local npcTimer    = 0
local npcScanRate = 1    -- seconds

local function isPlayerChar(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return true end
    end
    return false
end

local function scanNPCs()
    local result = {}
    local seen   = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent then
            local model = obj.Parent
            if model:IsA("Model") and not seen[model] then
                -- Skip if this Model is a sub-rig of a larger NPC
                local isNested = false
                local anc = model.Parent
                while anc and anc ~= Workspace do
                    if anc:IsA("Model") and anc:FindFirstChildOfClass("Humanoid") then
                        isNested = true
                        break
                    end
                    anc = anc.Parent
                end
                if not isNested and not isPlayerChar(model) then
                    seen[model]   = true
                    result[model] = obj
                end
            end
        end
    end
    return result
end

-- Fallback rig resolution (covers custom rigs without HumanoidRootPart)
local function resolveR
