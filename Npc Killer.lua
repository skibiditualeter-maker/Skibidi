--[[
    ╔══════════════════════════════════════════╗
    ║   NPC KILLER — v15.1 FULL EDITION         ║
    ║   Attach No-Collision • Quest Aura        ║
    ╚══════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Debris           = game:GetService("Debris")

local LP       = Players.LocalPlayer
local Mouse    = LP:GetMouse()
local Cam      = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local DrawLib = Drawing
if not DrawLib then pcall(function() DrawLib = drawings end) end

-- ============ CONFIG ============
local CONFIG = { KillRange=500, FlingPower=500, VoidY=-500 }

local AURA = {
    Enabled = false, Range = 15, Mode = "legit",
    HitCooldown = 0.35, TeleportOffset = 3, TeleportWait = 0.12,
    AutoSwapWeapon = true, AutoCombatMode = true, ShowRangeRing = true,
    Debug = false, RingPart = nil,
    LastHitTime = 0, Hits = 0, Kills = 0, InRange = 0,
    CurrentTool = "—", LastMode = "idle",
}

local ATTACH = {
    Enabled = false, Range = 20, Mode = "teleport",
    OnlyWithTool = true, TargetPlayers = true, TargetNPCs = true,
    IgnoreFriends = true, IgnoreSelf = true, TeamCheck = false,
    Distance = 3, YOffset = 0, FaceTarget = true,
    AttachedParts = {}, LastCount = 0,
    CollisionStates = {}, NoCollision = true,
}

local PAURA = {
    Enabled=false, Range=15, Interval=0.15, LastTick=0, Hits=0,
    TargetMode="all", IgnoreFriends=true, IgnoreSelf=true, TeamCheck=false,
    Method="teleport", AutoAim=true, TPBack=true, TPTime=0.05,
}
local AIMBOT = {
    Enabled=false, TargetPart="Head", FOV=200, Smoothness=0.2,
    AutoFire=false, WallCheck=false,
    TargetPlayers=true, TargetNPCs=true,
    IgnoreFriends=true, IgnoreSelf=true, TeamCheck=false,
    FireDelay=0.1, LastFire=0, CurrentTarget=nil,
}
local SILENT = {
    Enabled=false, TargetPart="Head", FOV=200, WallCheck=false,
    TargetPlayers=true, TargetNPCs=true,
    IgnoreFriends=true, IgnoreSelf=true, TeamCheck=false,
    HitChance=100, CurrentTarget=nil, Debug=false,
    MaxOrigin=200, MinShot=5,
}
local FOV_VIS = {
    Aimbot = { Show=true, Shape="circle", Color=Color3.fromRGB(90,220,255),
        Thickness=1.5, Transparency=0.3, DrawTargets=true,
        TargetColor=Color3.fromRGB(255,60,120), DotSize=5 },
    Silent = { Show=true, Shape="circle", Color=Color3.fromRGB(255,120,200),
        Thickness=1.5, Transparency=0.3, DrawTargets=true,
        TargetColor=Color3.fromRGB(255,60,120), DotSize=5 },
}

local COLORS = {
    Bg=Color3.fromRGB(18,18,24), Bg2=Color3.fromRGB(28,28,38),
    Card=Color3.fromRGB(36,36,48), CardHover=Color3.fromRGB(50,50,68),
    Accent=Color3.fromRGB(120,90,255), Accent2=Color3.fromRGB(255,60,120),
    Text=Color3.fromRGB(240,240,255), Sub=Color3.fromRGB(160,160,190),
    Danger=Color3.fromRGB(220,60,60), Success=Color3.fromRGB(60,200,120),
    Gold=Color3.fromRGB(255,200,90), Cyan=Color3.fromRGB(90,220,255),
    Pink=Color3.fromRGB(255,120,200),
}

-- ============ HELPERS ============
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t,tr) local s=Instance.new("UIStroke"); s.Color=c or Color3.fromRGB(80,80,110); s.Thickness=t or 1; s.Transparency=tr or 0; s.Parent=p; return s end
local function gradient(p,c1,c2,rot) local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c1,c2); g.Rotation=rot or 0; g.Parent=p; return g end
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NPCKillerAura"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0,56,0,56)
ToggleBtn.Position = UDim2.new(0,20,0.35,0)
ToggleBtn.BackgroundColor3 = COLORS.Bg
ToggleBtn.AutoButtonColor = false
ToggleBtn.Text = "💀"
ToggleBtn.TextSize = 26
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = COLORS.Text
ToggleBtn.Active = true
ToggleBtn.Parent = ScreenGui
corner(ToggleBtn, 28); stroke(ToggleBtn, COLORS.Accent, 2)
gradient(ToggleBtn, COLORS.Accent, COLORS.Accent2, 45)
local ToggleScale = Instance.new("UIScale", ToggleBtn)
task.spawn(function()
    while ToggleBtn.Parent do
        TweenService:Create(ToggleScale, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale=1.08}):Play()
        task.wait(1.2)
        TweenService:Create(ToggleScale, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale=1}):Play()
        task.wait(1.2)
    end
end)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,300,0,680)
Main.Position = UDim2.new(0,90,0.02,0)
Main.BackgroundColor3 = COLORS.Bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.Parent = ScreenGui
corner(Main, 14); stroke(Main, COLORS.Accent, 1.5, 0.35)
local MainGrad = gradient(Main, COLORS.Bg, COLORS.Bg2, 90)
MainGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,0.3)})

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,52)
Header.BackgroundColor3 = COLORS.Bg2
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 14)
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1,0,0,20)
HeaderFix.Position = UDim2.new(0,0,1,-20)
HeaderFix.BackgroundColor3 = COLORS.Bg2
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header
local HeaderGrad = gradient(Header, COLORS.Accent, COLORS.Accent2, 0)
HeaderGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0.55), NumberSequenceKeypoint.new(1,0.75)})

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-60,1,0)
Title.Position = UDim2.new(0,20,0,0)
Title.BackgroundTransparency = 1
Title.Text = "NPC KILLER"
Title.TextColor3 = COLORS.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1,-60,0,14)
Subtitle.Position = UDim2.new(0,20,0,34)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "v15.1 — attach no-collision"
Subtitle.TextColor3 = COLORS.Sub
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local CloseX = Instance.new("TextButton")
CloseX.Size = UDim2.new(0,30,0,30)
CloseX.Position = UDim2.new(1,-40,0,11)
CloseX.BackgroundColor3 = COLORS.Danger
CloseX.Text = "✕"
CloseX.TextColor3 = COLORS.Text
CloseX.Font = Enum.Font.GothamBold
CloseX.TextSize = 14
CloseX.AutoButtonColor = false
CloseX.Parent = Header
corner(CloseX, 8)
makeDraggable(Main, Header)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,-24,1,-70)
Scroll.Position = UDim2.new(0,12,0,60)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = COLORS.Accent
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0,8)
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll
local SectionPad = Instance.new("UIPadding")
SectionPad.PaddingTop = UDim.new(0,6)
SectionPad.Parent = Scroll

local order = 0
local function nextOrder() order += 1; return order end

local function makeSection(text)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,22)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = nextOrder()
    holder.Parent = Scroll
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "— " .. text .. " —"
    lbl.TextColor3 = COLORS.Sub
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Parent = holder
end

local function makeButton(text, icon, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,40)
    btn.BackgroundColor3 = COLORS.Card
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = nextOrder()
    btn.Parent = Scroll
    corner(btn, 10)
    local st = stroke(btn, COLORS.Accent, 1, 0.75)
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0,36,1,0)
    ic.Position = UDim2.new(0,6,0,0)
    ic.BackgroundTransparency = 1
    ic.Text = icon or "▶"
    ic.TextColor3 = color or COLORS.Text
    ic.Font = Enum.Font.GothamBold
    ic.TextSize = 18
    ic.Parent = btn
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0)
    lbl.Position = UDim2.new(0,46,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLORS.Text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn
    local bounce = Instance.new("UIScale", btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=COLORS.CardHover}):Play()
        TweenService:Create(st, TweenInfo.new(0.15), {Transparency=0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=COLORS.Card}):Play()
        TweenService:Create(st, TweenInfo.new(0.15), {Transparency=0.75}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(bounce, TweenInfo.new(0.08), {Scale=0.95}):Play()
        task.wait(0.08)
        TweenService:Create(bounce, TweenInfo.new(0.12), {Scale=1}):Play()
        pcall(callback)
    end)
    return btn
end

local function makeInput(label, icon, initialValue, color, onCommit)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,40)
    holder.BackgroundColor3 = COLORS.Card
    holder.LayoutOrder = nextOrder()
    holder.Parent = Scroll
    corner(holder, 10); stroke(holder, COLORS.Accent, 1, 0.75)
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0,36,1,0)
    ic.Position = UDim2.new(0,6,0,0)
    ic.BackgroundTransparency = 1
    ic.Text = icon or "▶"
    ic.TextColor3 = color or COLORS.Text
    ic.Font = Enum.Font.GothamBold
    ic.TextSize = 18
    ic.Parent = holder
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-140,1,0)
    lbl.Position = UDim2.new(0,46,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = COLORS.Text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0,82,0,28)
    box.Position = UDim2.new(1,-90,0,6)
    box.BackgroundColor3 = COLORS.Bg2
    box.Text = tostring(initialValue)
    box.TextColor3 = COLORS.Accent2
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.PlaceholderText = "0"
    box.PlaceholderColor3 = COLORS.Sub
    box.Parent = holder
    corner(box, 6); stroke(box, COLORS.Accent, 1, 0.4)
    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(45,45,65)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3=COLORS.Bg2}):Play()
        local num = tonumber(box.Text)
        if num then onCommit(num) else box.Text = tostring(initialValue) end
    end)
    return holder, box
end

local function bindToggle(btn, label, initial, onToggle, onText, offText, onColor, offColor)
    local state = initial
    for _, c in ipairs(btn:GetChildren()) do
        if c:IsA("TextLabel") and c.Text:match(label) then
            c.Text = label .. ": " .. (state and onText or offText)
            c.TextColor3 = state and onColor or offColor
        end
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        onToggle(state)
        for _, c in ipairs(btn:GetChildren()) do
            if c:IsA("TextLabel") and c.Text:match(label) then
                c.Text = label .. ": " .. (state and onText or offText)
                c.TextColor3 = state and onColor or offColor
            end
        end
    end)
end

local function bindCycler(btn, label, values, initial, onCycle)
    local idx = 1
    for i,v in ipairs(values) do if v == initial then idx = i break end end
    for _, c in ipairs(btn:GetChildren()) do
        if c:IsA("TextLabel") and c.Text:match(label) then
            c.Text = label .. ": " .. values[idx]:upper()
        end
    end
    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #values then idx = 1 end
        onCycle(values[idx])
        for _, c in ipairs(btn:GetChildren()) do
            if c:IsA("TextLabel") and c.Text:match(label) then
                c.Text = label .. ": " .. values[idx]:upper()
            end
        end
    end)
end

-- ============ TARGET LOGIC ============
local function getRoot(x) return x:FindFirstChild("HumanoidRootPart") or x.PrimaryPart end
local function isFriend(plr)
    local ok, res = pcall(function() return LP:IsFriendsWith(plr.UserId) end)
    return ok and res == true
end

local function getValidPlayers(cfg)
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP or not cfg.IgnoreSelf then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local ok = true
                    if cfg.IgnoreFriends and isFriend(plr) then ok = false end
                    if cfg.TeamCheck and LP.Team and plr.Team and LP.Team == plr.Team then ok = false end
                    if ok then table.insert(list, plr) end
                end
            end
        end
    end
    return list
end

local npcCache, npcCacheTime = {}, 0
local function getValidNPCs()
    if tick() - npcCacheTime > 2 then
        npcCache = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model")
            and not Players:GetPlayerFromCharacter(obj)
            and obj ~= LP.Character
            and (obj:FindFirstChildOfClass("Humanoid")
                or (obj:FindFirstChild("Health") and obj.Health:IsA("ValueBase"))) then
                table.insert(npcCache, obj)
            end
        end
        npcCacheTime = tick()
    end
    local list = {}
    for _, npc in ipairs(npcCache) do
        if npc.Parent then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then table.insert(list, npc)
            elseif not hum then
                local healthVal = npc:FindFirstChild("Health")
                if healthVal and healthVal:IsA("ValueBase") and healthVal.Value > 0 then
                    table.insert(list, npc)
                end
            end
        end
    end
    return list
end

local function worldToScreenDist(pos)
    local sp, on = Cam:WorldToViewportPoint(pos)
    if not on then return math.huge end
    local c = Cam.ViewportSize / 2
    local dx, dy = sp.X - c.X, sp.Y - c.Y
    return math.sqrt(dx*dx + dy*dy)
end

local function getTargetPart(char, partName)
    if partName == "Nearest" then
        local best, bestDist = nil, math.huge
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                local d = worldToScreenDist(p.Position)
                if d < bestDist then bestDist = d; best = p end
            end
        end
        return best
    end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

local function canSee(from, to, ignoreChar)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ig = {LP.Character}
    if ignoreChar then table.insert(ig, ignoreChar) end
    rp.FilterDescendantsInstances = ig
    return Workspace:Raycast(from, to - from, rp) == nil
end

local function getHitPart(npc)
    if not npc then return nil end
    for _, name in ipairs({"Head","UpperTorso","HumanoidRootPart","Torso","Chest","Body"}) do
        local p = npc:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    for _, p in ipairs(npc:GetDescendants()) do
        if p:IsA("BasePart") then return p end
    end
    return nil
end

-- ============ TOOL UTILS ============
local PASSIVE_PATTERNS = {
    "start combat","combat","toggle combat","enter combat","battle mode",
    "pvp","fight","engage","attack mode","start battle","toggle battle",
    "switch combat","ready","enter battle",
}
local WEAPON_KEYWORDS = {"sword","blade","gun","axe","knife","staff","wand","bow","dagger","katana","mace","hammer","spear","shuriken","claw","fist"}

local function isPassiveTool(tool)
    if not tool then return true end
    if not tool:FindFirstChild("Handle") then return true end
    local n = tool.Name:lower()
    for _, pat in ipairs(PASSIVE_PATTERNS) do
        if n:find(pat, 1, true) then return true end
    end
    return false
end

local function equipTool(tool)
    local char = LP.Character; if not char or not tool then return false end
    if tool.Parent == char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and tool.Parent == LP:FindFirstChild("Backpack") then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.08)
        return tool.Parent == char
    end
    return false
end

local function findCombatWeapon()
    local char = LP.Character; if not char then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and not isPassiveTool(equipped) then return equipped end
    local bp = LP:FindFirstChild("Backpack"); if not bp then return nil end
    local bestWeapon, bestScore = nil, 0
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Handle") and not isPassiveTool(t) then
            local score = 1
            local n = t.Name:lower()
            for _, kw in ipairs(WEAPON_KEYWORDS) do
                if n:find(kw) then score = 10; break end
            end
            if score > bestScore then bestWeapon = t; bestScore = score end
        end
    end
    return bestWeapon
end

-- ============ LEGIT KILL ============
local function legitKill(tool, npc, npcPart)
    local char = LP.Character; if not char then return false, 0 end
    local myRoot = char:FindFirstChild("HumanoidRootPart"); if not myRoot then return false, 0 end

    local origCF = myRoot.CFrame
    local origVel = myRoot.AssemblyLinearVelocity
    local wasAnch = myRoot.Anchored
    local hum = npc:FindFirstChildOfClass("Humanoid")
    local hpBefore = hum and hum.Health or 0

    myRoot.Anchored = true
    local targetPos = npcPart.Position
    local offset = Vector3.new(0, 1.5, AURA.TeleportOffset)
    myRoot.CFrame = CFrame.lookAt(targetPos + offset, targetPos)

    pcall(function()
        if not tool.Enabled then tool.Enabled = true end
        tool:Activate()
    end)

    local handle = tool:FindFirstChild("Handle")
    if firetouchinterest and handle and handle:IsA("BasePart") then
        pcall(function()
            firetouchinterest(handle, npcPart, 0)
            task.wait(0.02)
            firetouchinterest(handle, npcPart, 1)
        end)
    end

    task.wait(AURA.TeleportWait)
    myRoot.CFrame = origCF
    myRoot.Anchored = wasAnch
    pcall(function() myRoot.AssemblyLinearVelocity = origVel end)

    local hpAfter = hum and hum.Health or 0
    return hpAfter < hpBefore, hpBefore - hpAfter
end

local function bruteDamage(tool, npc, part)
    local any = false
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj.ClassName == "UnreliableRemoteEvent" then
            pcall(function() obj:FireServer(part) end)
            pcall(function() obj:FireServer(part.Position) end)
            pcall(function() obj:FireServer(npc) end)
            pcall(function() obj:FireServer(part.Parent) end)
            any = true
        elseif obj:IsA("RemoteFunction") then
            pcall(function() obj:InvokeServer(part) end)
            pcall(function() obj:InvokeServer(npc) end)
        end
    end
    local handle = tool:FindFirstChild("Handle")
    if firetouchinterest and handle and handle:IsA("BasePart") then
        pcall(function()
            firetouchinterest(handle, part, 0)
            firetouchinterest(handle, part, 1)
        end)
        any = true
    end
    pcall(function()
        if not tool.Enabled then tool.Enabled = true end
        tool:Activate()
    end)
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:TakeDamage(math.max(10, hum.MaxHealth * 0.1)) end) end
    return any
end

local function findNearestNPCInRange(myRoot)
    local best, bestDist = nil, math.huge
    for _, npc in ipairs(getValidNPCs()) do
        local part = getHitPart(npc)
        if part then
            local d = (part.Position - myRoot.Position).Magnitude
            if d <= AURA.Range and d < bestDist then
                bestDist = d
                best = {npc = npc, part = part, dist = d}
            end
        end
    end
    return best
end

local function updateAuraRing()
    if not AURA.Enabled or not AURA.ShowRangeRing then
        if AURA.RingPart then pcall(function() AURA.RingPart:Destroy() end); AURA.RingPart = nil end
        return
    end
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if not AURA.RingPart or not AURA.RingPart.Parent then
        local ring = Instance.new("Part")
        ring.Name = "AuraRingVisual"
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.3, AURA.Range * 2, AURA.Range * 2)
        ring.Material = Enum.Material.Neon
        ring.Color = Color3.fromRGB(120, 90, 255)
        ring.CanCollide = false
        ring.CanQuery = false
        ring.CanTouch = false
        ring.Anchored = true
        ring.Transparency = 0.5
        ring.Parent = Workspace
        AURA.RingPart = ring
    end
    AURA.RingPart.Size = Vector3.new(0.3, AURA.Range * 2, AURA.Range * 2)
    AURA.RingPart.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
end

RunService.Heartbeat:Connect(function()
    if not AURA.Enabled then
        if AURA.RingPart then pcall(function() AURA.RingPart:Destroy() end); AURA.RingPart = nil end
        return
    end
    local char = LP.Character; if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    updateAuraRing()

    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and isPassiveTool(equipped) then
        if AURA.AutoCombatMode then
            pcall(function()
                if not equipped.Enabled then equipped.Enabled = true end
                equipped:Activate()
            end)
        end
        if AURA.AutoSwapWeapon then
            local weapon = findCombatWeapon()
            if weapon then equipTool(weapon); equipped = char:FindFirstChildOfClass("Tool") end
        end
    end
    AURA.CurrentTool = equipped and equipped.Name or "—"

    local targets = getValidNPCs()
    local inRangeCount = 0
    for _, npc in ipairs(targets) do
        local part = getHitPart(npc)
        if part and (part.Position - myRoot.Position).Magnitude <= AURA.Range then
            inRangeCount += 1
        end
    end
    AURA.InRange = inRangeCount

    if not equipped or isPassiveTool(equipped) then
        AURA.LastMode = "passive-tool"; return
    end
    if inRangeCount == 0 then AURA.LastMode = "no-targets"; return end
    if tick() - AURA.LastHitTime < AURA.HitCooldown then return end

    if AURA.Mode == "legit" then
        local target = findNearestNPCInRange(myRoot)
        if target then
            AURA.LastHitTime = tick()
            local ok, damage = legitKill(equipped, target.npc, target.part)
            if ok then
                AURA.Hits += 1
                AURA.LastMode = "hit"
                local hum = target.npc:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then AURA.Kills += 1 end
                if AURA.Debug then
                    print(string.format("[Aura-Legit] Hit %s dmg=%s hits=%d kills=%d",
                        target.npc.Name, tostring(math.floor(damage)), AURA.Hits, AURA.Kills))
                end
            else
                AURA.LastMode = "no-dmg"
                if AURA.Debug then print("[Aura-Legit] 0 dmg on " .. target.npc.Name) end
            end
        end
    else
        AURA.LastHitTime = tick()
        local hits = 0
        for _, npc in ipairs(targets) do
            local part = getHitPart(npc)
            if part and (part.Position - myRoot.Position).Magnitude <= AURA.Range then
                if bruteDamage(equipped, npc, part) then hits += 1 end
            end
        end
        AURA.Hits += hits
        AURA.LastMode = hits > 0 and "brute-hit" or "brute-nodmg"
    end
end)

-- ============ ATTACH FEATURE ============
local function getHrp(m)
    return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
end

local function getMyHead(char)
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function cleanAttachConstraints(hrp)
    if not hrp then return end
    for _, name in ipairs({"AttachBodyPos","AttachBodyGyro","AttachAlignPos"}) do
        local c = hrp:FindFirstChild(name)
        if c then pcall(function() c:Destroy() end) end
    end
end

local function disableCollision(target)
    if not ATTACH.NoCollision then return end
    local states = {}
    for _, part in ipairs(target:GetDescendants()) do
        if part:IsA("BasePart") then
            states[part] = part.CanCollide
            pcall(function() part.CanCollide = false end)
        end
    end
    ATTACH.CollisionStates[target] = states
end

local function restoreCollision(target)
    local states = ATTACH.CollisionStates[target]
    if not states then return end
    for part, canCollide in pairs(states) do
        if part and part.Parent then
            pcall(function() part.CanCollide = canCollide end)
        end
    end
    ATTACH.CollisionStates[target] = nil
end

local function attachOne(target, hrp, myHead)
    if not hrp or not hrp.Parent or not myHead then return end
    local attachPos = (myHead.CFrame * CFrame.new(0, ATTACH.YOffset, -ATTACH.Distance)).Position
    local lookCF = ATTACH.FaceTarget
        and CFrame.lookAt(attachPos, myHead.Position)
        or CFrame.new(attachPos)

    if ATTACH.Mode == "anchor" then
        cleanAttachConstraints(hrp)
        hrp.CFrame = lookCF
        hrp.Anchored = true
    elseif ATTACH.Mode == "teleport" then
        cleanAttachConstraints(hrp)
        if hrp.Anchored then hrp.Anchored = false end
        hrp.CFrame = lookCF
    elseif ATTACH.Mode == "physics" then
        if hrp.Anchored then hrp.Anchored = false end
        local bp = hrp:FindFirstChild("AttachBodyPos")
        if not bp then
            bp = Instance.new("BodyPosition")
            bp.Name = "AttachBodyPos"
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bp.P = 50000; bp.D = 500
            bp.Parent = hrp
        end
        bp.Position = attachPos
        if ATTACH.FaceTarget then
            local bg = hrp:FindFirstChild("AttachBodyGyro")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "AttachBodyGyro"
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bg.P = 10000; bg.D = 500
                bg.Parent = hrp
            end
            bg.CFrame = lookCF
        end
    end
    ATTACH.AttachedParts[target] = hrp
    if not ATTACH.CollisionStates[target] then
        disableCollision(target)
    end
end

local function detachTarget(target)
    local hrp = ATTACH.AttachedParts[target]
    if hrp then
        pcall(function()
            if hrp.Parent then
                hrp.Anchored = false
                cleanAttachConstraints(hrp)
            end
        end)
        restoreCollision(target)
        ATTACH.AttachedParts[target] = nil
    end
end

local function detachAll()
    for target, hrp in pairs(ATTACH.AttachedParts) do
        pcall(function()
            if hrp and hrp.Parent then
                hrp.Anchored = false
                cleanAttachConstraints(hrp)
            end
        end)
        restoreCollision(target)
    end
    for target in pairs(ATTACH.CollisionStates) do
        restoreCollision(target)
    end
    ATTACH.AttachedParts = {}
    ATTACH.CollisionStates = {}
    ATTACH.LastCount = 0
end

RunService.Heartbeat:Connect(function()
    if not ATTACH.Enabled then
        if next(ATTACH.AttachedParts) then detachAll() end
        return
    end
    local char = LP.Character
    if not char then detachAll(); return end
    local myHead = getMyHead(char)
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myHead or not myRoot then detachAll(); return end

    if ATTACH.OnlyWithTool then
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then detachAll(); return end
    end

    local targets = {}
    if ATTACH.TargetNPCs then
        for _, npc in ipairs(getValidNPCs()) do table.insert(targets, npc) end
    end
    if ATTACH.TargetPlayers then
        for _, plr in ipairs(getValidPlayers(ATTACH)) do
            if plr.Character then table.insert(targets, plr.Character) end
        end
    end

    local stillAttached = {}
    for _, target in ipairs(targets) do
        local hrp = getHrp(target)
        if hrp and (hrp.Position - myRoot.Position).Magnitude <= ATTACH.Range then
            attachOne(target, hrp, myHead)
            stillAttached[target] = true
        end
    end
    for t in pairs(ATTACH.AttachedParts) do
        if not stillAttached[t] then detachTarget(t) end
    end
    local n = 0
    for _ in pairs(ATTACH.AttachedParts) do n += 1 end
    ATTACH.LastCount = n
end)

-- ============ FOV VISUALIZER ============
local FOV_SHAPES = {
    Aimbot = { circle=nil, triangle=nil, cube=nil, dots={} },
    Silent = { circle=nil, triangle=nil, cube=nil, dots={} },
}

local function createFOVObjects(name)
    if not DrawLib then return end
    local set = FOV_SHAPES[name]
    pcall(function() set.circle = DrawLib.new("Circle"); set.circle.Visible = false; set.circle.Filled = false; set.circle.NumSides = 64 end)
    pcall(function() set.triangle = DrawLib.new("Triangle"); set.triangle.Visible = false; set.triangle.Filled = false end)
    pcall(function() set.cube = DrawLib.new("Square"); set.cube.Visible = false; set.cube.Filled = false end)
end
createFOVObjects("Aimbot")
createFOVObjects("Silent")

local function hideAllShapes(name)
    local set = FOV_SHAPES[name]; if not set then return end
    for _, k in ipairs({"circle","triangle","cube"}) do
        if set[k] then set[k].Visible = false end
    end
end

local function clearDots(name)
    local set = FOV_SHAPES[name]; if not set then return end
    for _, d in ipairs(set.dots) do pcall(function() d.Visible = false end) end
end

local function drawFOV(name, active, fov, cfg)
    if not DrawLib then return end
    local set = FOV_SHAPES[name]; if not set then return end
    if not active or not cfg.Show then hideAllShapes(name); clearDots(name); return end
    local center = Cam.ViewportSize / 2
    local r = fov
    hideAllShapes(name)
    if cfg.Shape == "circle" and set.circle then
        set.circle.Visible = true
        set.circle.Position = Vector2.new(center.X, center.Y)
        set.circle.Radius = r
        set.circle.Color = cfg.Color
        set.circle.Thickness = cfg.Thickness
        set.circle.Transparency = cfg.Transparency
    elseif cfg.Shape == "triangle" and set.triangle then
        set.triangle.Visible = true
        local r3 = math.sqrt(3)
        set.triangle.PointA = Vector2.new(center.X, center.Y - r)
        set.triangle.PointB = Vector2.new(center.X - r * r3 / 2, center.Y + r / 2)
        set.triangle.PointC = Vector2.new(center.X + r * r3 / 2, center.Y + r / 2)
        set.triangle.Color = cfg.Color
        set.triangle.Thickness = cfg.Thickness
        set.triangle.Transparency = cfg.Transparency
    elseif cfg.Shape == "cube" and set.cube then
        set.cube.Visible = true
        set.cube.Size = Vector2.new(r * 2, r * 2)
        set.cube.Position = Vector2.new(center.X - r, center.Y - r)
        set.cube.Color = cfg.Color
        set.cube.Thickness = cfg.Thickness
        set.cube.Transparency = cfg.Transparency
    end
    if cfg.DrawTargets then
        local targets = {}
        local filterCfg = (name == "Aimbot") and AIMBOT or SILENT
        local function consider(char)
            local part = getTargetPart(char, filterCfg.TargetPart or "Head")
            if part and worldToScreenDist(part.Position) <= fov then table.insert(targets, part) end
        end
        if filterCfg.TargetPlayers then
            for _, plr in ipairs(getValidPlayers(filterCfg)) do
                if plr.Character then consider(plr.Character) end
            end
        end
        if filterCfg.TargetNPCs then
            for _, npc in ipairs(getValidNPCs()) do consider(npc) end
        end
        for i, part in ipairs(targets) do
            local dot = set.dots[i]
            if not dot then
                pcall(function()
                    dot = DrawLib.new("Circle")
                    dot.Filled = true; dot.NumSides = 14; dot.Transparency = 0.2
                end)
                set.dots[i] = dot
            end
            if dot then
                local sp, on = Cam:WorldToViewportPoint(part.Position)
                if on then
                    dot.Visible = true
                    dot.Position = Vector2.new(sp.X, sp.Y)
                    dot.Radius = cfg.DotSize or 5
                    dot.Color = cfg.TargetColor or Color3.new(1,0,0)
                else dot.Visible = false end
            end
        end
        for i = #targets + 1, #set.dots do
            pcall(function() set.dots[i].Visible = false end)
        end
    else clearDots(name) end
end

-- ============ AIMBOT ============
local function getAimbotTarget()
    local cfg = AIMBOT
    local camPos = Cam.CFrame.Position
    local best, bestDist = nil, math.huge
    local function consider(char, isPlayer)
        local part = getTargetPart(char, cfg.TargetPart)
        if not part then return end
        local sd = worldToScreenDist(part.Position)
        if sd > cfg.FOV then return end
        if cfg.WallCheck and not canSee(camPos, part.Position, char) then return end
        if sd < bestDist then bestDist = sd; best = {char=char, part=part, isPlayer=isPlayer} end
    end
    if cfg.TargetPlayers then
        for _, plr in ipairs(getValidPlayers(cfg)) do
            if plr.Character then consider(plr.Character, true) end
        end
    end
    if cfg.TargetNPCs then
        for _, npc in ipairs(getValidNPCs()) do consider(npc, false) end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if DrawLib then
        pcall(drawFOV, "Aimbot", AIMBOT.Enabled, AIMBOT.FOV, FOV_VIS.Aimbot)
        pcall(drawFOV, "Silent", SILENT.Enabled, SILENT.FOV, FOV_VIS.Silent)
    end
    if not AIMBOT.Enabled then return end
    local target = getAimbotTarget()
    AIMBOT.CurrentTarget = target
    if not target then return end
    local desired = CFrame.lookAt(Cam.CFrame.Position, target.part.Position)
    if AIMBOT.Smoothness >= 1 then Cam.CFrame = desired
    else Cam.CFrame = Cam.CFrame:Lerp(desired, AIMBOT.Smoothness) end
    if AIMBOT.AutoFire and tick() - AIMBOT.LastFire >= AIMBOT.FireDelay then
        AIMBOT.LastFire = tick()
        local char = LP.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then pcall(function() if not tool.Enabled then tool.Enabled = true end; tool:Activate() end) end
        if mouse1click then pcall(mouse1click) end
    end
end)

-- ============ SILENT AIM ============
local silentReady, hookStatus = false, "not installed"
local reEntry = false
local cachedTarget, lastCacheTime = nil, 0
local interceptCount = 0

local function passSilentFilters(plr)
    if plr == LP and SILENT.IgnoreSelf then return false end
    if SILENT.IgnoreFriends and isFriend(plr) then return false end
    if SILENT.TeamCheck and LP.Team and plr.Team and LP.Team == plr.Team then return false end
    return true
end

local function pickSilentTarget()
    if not SILENT.Enabled then return nil end
    if cachedTarget and tick() - lastCacheTime < 0.15 then
        local c = cachedTarget.Parent
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return cachedTarget end
    end
    if math.random(1, 100) > SILENT.HitChance then cachedTarget = nil; return nil end
    lastCacheTime = tick()
    local camPos = Cam.CFrame.Position
    local bestPart, bestDist = nil, math.huge
    local MAX_WORLD = 1500
    if SILENT.TargetPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if passSilentFilters(plr) and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 and (hrp.Position - camPos).Magnitude < MAX_WORLD then
                    local part = getTargetPart(plr.Character, SILENT.TargetPart)
                    if part then
                        local sd = worldToScreenDist(part.Position)
                        if sd <= SILENT.FOV and sd < bestDist then
                            if not SILENT.WallCheck or canSee(camPos, part.Position, plr.Character) then
                                bestDist = sd; bestPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    if SILENT.TargetNPCs then
        for _, npc in ipairs(getValidNPCs()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp and (hrp.Position - camPos).Magnitude < MAX_WORLD then
                local part = getTargetPart(npc, SILENT.TargetPart)
                if part then
                    local sd = worldToScreenDist(part.Position)
                    if sd <= SILENT.FOV and sd < bestDist then
                        if not SILENT.WallCheck or canSee(camPos, part.Position, npc) then
                            bestDist = sd; bestPart = part
                        end
                    end
                end
            end
        end
    end
    cachedTarget = bestPart
    return bestPart
end

local function installSilentAim()
    if silentReady then return end
    if not hookmetamethod or not newcclosure or not checkcaller
    or not getnamecallmethod or not getrawmetatable then
        hookStatus = "executor missing hook tools"; return
    end
    local mt = getrawmetatable(game)
    if not mt then hookStatus = "no metatable"; return end
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if not SILENT.Enabled or checkcaller() or reEntry or self ~= Workspace then
            return oldNamecall(self, ...)
        end
        local method = getnamecallmethod()
        if method ~= "Raycast" and method ~= "FindPartOnRay" then return oldNamecall(self, ...) end
        local args = {...}
        local origin, direction
        if method == "Raycast" then origin, direction = args[1], args[2]
        else
            local ray = args[1]
            if typeof(ray) ~= "Ray" then return oldNamecall(self, ...) end
            origin, direction = ray.Origin, ray.Direction
        end
        if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return oldNamecall(self, ...) end
        if (origin - Cam.CFrame.Position).Magnitude > SILENT.MaxOrigin then return oldNamecall(self, ...) end
        if direction.Magnitude < SILENT.MinShot then return oldNamecall(self, ...) end
        if SILENT.Debug then
            interceptCount += 1
            print("[Silent] Raycast #" .. interceptCount)
        end
        reEntry = true
        local target = pickSilentTarget()
        local result
        if target then
            result = oldNamecall(self, origin, target.Position - origin, args[3])
            if SILENT.Debug then print("[Silent] -> " .. target:GetFullName()) end
        else
            result = oldNamecall(self, ...)
        end
        reEntry = false
        return result
    end)
    setreadonly(mt, true)
    silentReady = true
    hookStatus = "installed ✓"
end
pcall(installSilentAim)

-- ============ NPC MASS ACTIONS ============
local function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    if model == LP.Character then return false end
    return true
end
local function getNPCs()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isNPC(obj) then table.insert(list, obj) end
    end
    return list
end
local function getNPCFromInstance(inst)
    while inst and inst ~= Workspace do
        if inst:IsA("Model") and isNPC(inst) then return inst end
        inst = inst.Parent
    end
    return nil
end

local function killNPC(npc)
    if not npc or not npc.Parent then return end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = 0 end)
        pcall(function() hum:TakeDamage(hum.MaxHealth * 10) end)
    end
end
local function voidNPC(npc)
    if not npc or not npc.Parent then return end
    pcall(function() npc:PivotTo(CFrame.new(0, CONFIG.VoidY, 0)) end)
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.Health = 0 end) end
end
local function flingNPC(npc)
    if not npc or not npc.Parent then return end
    local hrp = getRoot(npc); if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    bv.Velocity = Vector3.new(
        math.random(-CONFIG.FlingPower, CONFIG.FlingPower),
        math.random(CONFIG.FlingPower, CONFIG.FlingPower*2),
        math.random(-CONFIG.FlingPower, CONFIG.FlingPower))
    bv.Parent = hrp; Debris:AddItem(bv, 0.5)
end
local function freezeNPC(npc)
    if not npc or not npc.Parent then return end
    local hrp = getRoot(npc); if hrp then hrp.Anchored = true end
end
local function unanchorNPC(npc)
    if not npc or not npc.Parent then return end
    local hrp = getRoot(npc); if hrp then hrp.Anchored = false end
end
local function igniteNPC(npc)
    if not npc or not npc.Parent then return end
    for _, p in ipairs(npc:GetDescendants()) do
        if p:IsA("BasePart") then
            local f = Instance.new("Fire"); f.Size=8; f.Heat=20
            f.Parent = p; Debris:AddItem(f, 3)
        end
    end
    killNPC(npc)
end
local function explodeNPC(npc)
    if not npc or not npc.Parent then return end
    local hrp = getRoot(npc); if not hrp then return end
    local ex = Instance.new("Explosion")
    ex.BlastRadius=10; ex.BlastPressure=500000
    ex.Position = hrp.Position; ex.Parent = Workspace
    killNPC(npc)
end
local function ragdollNPC(npc)
    if not npc or not npc.Parent then return end
    for _, p in ipairs(npc:GetDescendants()) do
        if p:IsA("Motor6D") then
            local s = Instance.new("BallSocketConstraint")
            local a0 = Instance.new("Attachment", p.Part0)
            local a1 = Instance.new("Attachment", p.Part1)
            s.Attachment0 = a0; s.Attachment1 = a1
            s.LimitsEnabled = true; s.TwistLimitsEnabled = true
            s.Parent = p.Parent; p:Destroy()
        end
    end
end
local function applyToAllInRange(fn)
    local n = 0
    local char = LP.Character; if not char then return 0 end
    local myRoot = char:FindFirstChild("HumanoidRootPart"); if not myRoot then return 0 end
    for _, npc in ipairs(getNPCs()) do
        local hrp = getRoot(npc)
        if hrp and (hrp.Position - myRoot.Position).Magnitude <= CONFIG.KillRange then
            fn(npc); n += 1
        end
    end
    return n
end

-- ============ PLAYER AURA ============
local function teleportHitPlayer(tool, myRoot, targetHrp)
    local origCF = myRoot.CFrame
    local origVel = myRoot.AssemblyLinearVelocity
    local wasAnch = myRoot.Anchored
    myRoot.Anchored = true
    myRoot.CFrame = CFrame.lookAt(targetHrp.Position + Vector3.new(0,1.5,0), targetHrp.Position)
    pcall(function() if not tool.Enabled then tool.Enabled = true end; tool:Activate() end)
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            pcall(function() obj:FireServer(targetHrp) end)
            pcall(function() obj:FireServer(targetHrp.Parent) end)
        end
    end
    if firetouchinterest then
        local handle = tool:FindFirstChild("Handle")
        if handle then pcall(function()
            firetouchinterest(handle, targetHrp, 0)
            firetouchinterest(handle, targetHrp, 1)
        end) end
    end
    task.wait(PAURA.TPTime)
    if PAURA.TPBack then myRoot.CFrame = origCF end
    myRoot.Anchored = wasAnch
    pcall(function() myRoot.AssemblyLinearVelocity = origVel end)
    return true
end

RunService.Heartbeat:Connect(function()
    if not PAURA.Enabled then return end
    if tick() - PAURA.LastTick < PAURA.Interval then return end
    PAURA.LastTick = tick()
    local char = LP.Character; if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    local tool = char:FindFirstChildOfClass("Tool"); if not tool then return end
    if not tool:FindFirstChild("Handle") then return end
    if not tool.Enabled then pcall(function() tool.Enabled = true end) end
    local inRange = {}
    for _, plr in ipairs(getValidPlayers(PAURA)) do
        local c = plr.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - myRoot.Position).Magnitude
            if d <= PAURA.Range then table.insert(inRange, {plr=plr, hrp=hrp, dist=d}) end
        end
    end
    table.sort(inRange, function(a,b) return a.dist < b.dist end)
    local toHit = PAURA.TargetMode == "nearest" and {inRange[1]} or inRange
    local hits = 0
    for _, t in ipairs(toHit) do
        if t and t.hrp then
            if PAURA.Method == "teleport" then teleportHitPlayer(tool, myRoot, t.hrp); hits += 1
            else
                if PAURA.AutoAim then
                    local look = CFrame.lookAt(myRoot.Position, t.hrp.Position)
                    local _, y, _ = look:ToEulerAnglesXYZ()
                    myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, y, 0)
                end
                pcall(function() tool:Activate() end)
                hits += 1
            end
        end
    end
    if hits > 0 then PAURA.Hits += hits end
end)

-- ============ CLICK MODES ============
local clickModes = { kill=false, void=false, fling=false, ignite=false, explode=false, freeze=false }
local ClickStatus
local function updateClickStatus()
    if not ClickStatus then return end
    local on = {}
    for k,v in pairs(clickModes) do if v then table.insert(on, k) end end
    ClickStatus.Text = #on == 0 and "CLICK MODE: OFF" or ("CLICK: " .. table.concat(on, " · "):upper())
    ClickStatus.TextColor3 = #on == 0 and COLORS.Sub or COLORS.Accent2
end
Mouse.Button1Down:Connect(function()
    local target = Mouse.Target; if not target then return end
    local npc = getNPCFromInstance(target); if not npc then return end
    if clickModes.kill then killNPC(npc) end
    if clickModes.void then voidNPC(npc) end
    if clickModes.fling then flingNPC(npc) end
    if clickModes.ignite then igniteNPC(npc) end
    if clickModes.explode then explodeNPC(npc) end
    if clickModes.freeze then freezeNPC(npc) end
end)

-- ============ MENU ============
makeSection("⚡ NPC AURA (QUEST MODE)")

local AuraInfo = Instance.new("TextButton")
AuraInfo.Size = UDim2.new(1,0,0,66)
AuraInfo.BackgroundColor3 = COLORS.Bg2
AuraInfo.Text = ""
AuraInfo.AutoButtonColor = false
AuraInfo.LayoutOrder = nextOrder()
AuraInfo.Parent = Scroll
corner(AuraInfo, 8); stroke(AuraInfo, COLORS.Gold, 1, 0.5)

local AIT = Instance.new("TextLabel")
AIT.Size = UDim2.new(1,-10,0,16)
AIT.Position = UDim2.new(0,5,0,2)
AIT.BackgroundTransparency = 1
AIT.Text = "Tool: —"
AIT.TextColor3 = COLORS.Gold
AIT.Font = Enum.Font.GothamBold
AIT.TextSize = 11
AIT.TextXAlignment = Enum.TextXAlignment.Left
AIT.Parent = AuraInfo

local AIS = Instance.new("TextLabel")
AIS.Size = UDim2.new(1,-10,0,16)
AIS.Position = UDim2.new(0,5,0,18)
AIS.BackgroundTransparency = 1
AIS.Text = "Mode: idle"
AIS.TextColor3 = COLORS.Sub
AIS.Font = Enum.Font.GothamSemibold
AIS.TextSize = 10
AIS.TextXAlignment = Enum.TextXAlignment.Left
AIS.Parent = AuraInfo

local AIModeLbl = Instance.new("TextLabel")
AIModeLbl.Size = UDim2.new(1,-10,0,16)
AIModeLbl.Position = UDim2.new(0,5,0,34)
AIModeLbl.BackgroundTransparency = 1
AIModeLbl.Text = "Targets: 0  •  Hits: 0  •  Kills: 0"
AIModeLbl.TextColor3 = COLORS.Sub
AIModeLbl.Font = Enum.Font.GothamSemibold
AIModeLbl.TextSize = 10
AIModeLbl.TextXAlignment = Enum.TextXAlignment.Left
AIModeLbl.Parent = AuraInfo

local AIStatus = Instance.new("TextLabel")
AIStatus.Size = UDim2.new(1,-10,0,16)
AIStatus.Position = UDim2.new(0,5,0,50)
AIStatus.BackgroundTransparency = 1
AIStatus.Text = "Mode: LEGIT (quest credit)"
AIStatus.TextColor3 = COLORS.Success
AIStatus.Font = Enum.Font.GothamBold
AIStatus.TextSize = 10
AIStatus.TextXAlignment = Enum.TextXAlignment.Left
AIStatus.Parent = AuraInfo

task.spawn(function()
    while AuraInfo.Parent do
        AIT.Text = "Tool: " .. AURA.CurrentTool
        AIS.Text = "Mode: " .. AURA.LastMode
        AIModeLbl.Text = string.format("Targets: %d  •  Hits: %d  •  Kills: %d",
            AURA.InRange, AURA.Hits, AURA.Kills)
        if AURA.Mode == "legit" then
            AIStatus.Text = "Mode: LEGIT (quest credit ✓)"
            AIStatus.TextColor3 = COLORS.Success
        else
            AIStatus.Text = "Mode: BRUTE (raw dmg — no credit)"
            AIStatus.TextColor3 = COLORS.Danger
        end
        local sCol = COLORS.Sub
        if AURA.LastMode == "hit" then sCol = COLORS.Success
        elseif AURA.LastMode == "no-dmg" then sCol = COLORS.Gold
        elseif AURA.LastMode == "passive-tool" then sCol = COLORS.Danger end
        AIS.TextColor3 = sCol
        task.wait(0.2)
    end
end)

local AuraBtn = makeButton("NPC Aura: OFF", "⚡", COLORS.Gold, function() end)
bindToggle(AuraBtn, "NPC Aura", AURA.Enabled, function(s) AURA.Enabled = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)

local ModeSwitch = makeButton("Aura Mode: LEGIT", "📋", COLORS.Success, function() end)
ModeSwitch.MouseButton1Click:Connect(function()
    AURA.Mode = (AURA.Mode == "legit") and "brute" or "legit"
    for _, c in ipairs(ModeSwitch:GetChildren()) do
        if c:IsA("TextLabel") and c.Text:match("Aura Mode") then
            c.Text = "Aura Mode: " .. AURA.Mode:upper()
            c.TextColor3 = AURA.Mode == "legit" and COLORS.Success or COLORS.Danger
        end
    end
end)

local AuraSwap = makeButton("Auto Weapon Swap: ON", "🔄", COLORS.Cyan, function() end)
bindToggle(AuraSwap, "Auto Weapon Swap", AURA.AutoSwapWeapon,
    function(s) AURA.AutoSwapWeapon = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AuraCombat = makeButton("Auto Combat Mode: ON", "⚔", COLORS.Cyan, function() end)
bindToggle(AuraCombat, "Auto Combat Mode", AURA.AutoCombatMode,
    function(s) AURA.AutoCombatMode = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AuraRing = makeButton("Show Range Ring: ON", "⭕", COLORS.Cyan, function() end)
bindToggle(AuraRing, "Show Range Ring", AURA.ShowRangeRing,
    function(s) AURA.ShowRangeRing = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AuraDebug = makeButton("Aura Debug: OFF", "🐞", COLORS.Cyan, function() end)
bindToggle(AuraDebug, "Aura Debug", AURA.Debug,
    function(s) AURA.Debug = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

makeInput("Aura Range", "📐", AURA.Range, COLORS.Accent, function(n)
    AURA.Range = math.clamp(math.floor(n), 1, 500)
end)
makeInput("Hit Cooldown (s)", "⏱", AURA.HitCooldown, COLORS.Accent, function(n)
    AURA.HitCooldown = math.clamp(n, 0.05, 10)
end)
makeInput("Teleport Wait (s)", "⏳", AURA.TeleportWait, COLORS.Accent, function(n)
    AURA.TeleportWait = math.clamp(n, 0.05, 1)
end)
makeButton("Force Equip Best Weapon", "🗡", COLORS.Success, function()
    local w = findCombatWeapon()
    if w then equipTool(w); print("[Aura] Equipped: " .. w.Name)
    else print("[Aura] No weapon in backpack") end
end)

-- ATTACH
makeSection("🧲 ATTACH (face magnet)")

local AttachInfo = Instance.new("TextButton")
AttachInfo.Size = UDim2.new(1,0,0,32)
AttachInfo.BackgroundColor3 = COLORS.Bg2
AttachInfo.Text = ""
AttachInfo.AutoButtonColor = false
AttachInfo.LayoutOrder = nextOrder()
AttachInfo.Parent = Scroll
corner(AttachInfo, 8); stroke(AttachInfo, COLORS.Gold, 1, 0.5)
local AttachInfoLabel = Instance.new("TextLabel")
AttachInfoLabel.Size = UDim2.new(1,-10,1,0)
AttachInfoLabel.Position = UDim2.new(0,5,0,0)
AttachInfoLabel.BackgroundTransparency = 1
AttachInfoLabel.Text = "Attached: 0"
AttachInfoLabel.TextColor3 = COLORS.Gold
AttachInfoLabel.Font = Enum.Font.GothamBold
AttachInfoLabel.TextSize = 11
AttachInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
AttachInfoLabel.Parent = AttachInfo
task.spawn(function()
    while AttachInfo.Parent do
        AttachInfoLabel.Text = string.format("Attached: %d  •  Mode: %s  •  NoCollide: %s",
            ATTACH.LastCount, ATTACH.Mode:upper(), ATTACH.NoCollision and "ON" or "OFF")
        task.wait(0.3)
    end
end)

local AttachBtn = makeButton("Attach: OFF", "🧲", COLORS.Gold, function() end)
bindToggle(AttachBtn, "Attach", ATTACH.Enabled, function(s)
    ATTACH.Enabled = s
    if not s then detachAll() end
end, "ON", "OFF", COLORS.Success, COLORS.Text)

local AttachMode = makeButton("Attach Mode: TELEPORT", "⚙", COLORS.Cyan, function() end)
bindCycler(AttachMode, "Attach Mode", {"teleport","physics","anchor"}, ATTACH.Mode,
    function(v) ATTACH.Mode = v; detachAll() end)

local AttachTool = makeButton("Only With Tool: ON", "🗡", COLORS.Cyan, function() end)
bindToggle(AttachTool, "Only With Tool", ATTACH.OnlyWithTool,
    function(s) ATTACH.OnlyWithTool = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AttachFace = makeButton("Face Target: ON", "👁", COLORS.Cyan, function() end)
bindToggle(AttachFace, "Face Target", ATTACH.FaceTarget,
    function(s) ATTACH.FaceTarget = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AttachCollision = makeButton("No Collision: ON", "🚫", COLORS.Cyan, function() end)
bindToggle(AttachCollision, "No Collision", ATTACH.NoCollision,
    function(s)
        ATTACH.NoCollision = s
        if not s then
            for target in pairs(ATTACH.CollisionStates) do
                restoreCollision(target)
            end
        end
    end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AttachPlayers = makeButton("Attach Players: ON", "👤", COLORS.Cyan, function() end)
bindToggle(AttachPlayers, "Attach Players", ATTACH.TargetPlayers,
    function(s) ATTACH.TargetPlayers = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AttachNPCs = makeButton("Attach NPCs: ON", "🤖", COLORS.Cyan, function() end)
bindToggle(AttachNPCs, "Attach NPCs", ATTACH.TargetNPCs,
    function(s) ATTACH.TargetNPCs = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AttachFriends = makeButton("Attach Ignore Friends: ON", "🤝", COLORS.Cyan, function() end)
bindToggle(AttachFriends, "Attach Ignore Friends", ATTACH.IgnoreFriends,
    function(s) ATTACH.IgnoreFriends = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

local AttachTeam = makeButton("Attach Team Check: OFF", "🛡", COLORS.Cyan, function() end)
bindToggle(AttachTeam, "Attach Team Check", ATTACH.TeamCheck,
    function(s) ATTACH.TeamCheck = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)

makeInput("Attach Range", "📐", ATTACH.Range, COLORS.Gold, function(n)
    ATTACH.Range = math.clamp(math.floor(n), 1, 200)
end)
makeInput("Attach Distance", "📏", ATTACH.Distance, COLORS.Gold, function(n)
    ATTACH.Distance = math.clamp(n, 0.5, 20)
end)
makeInput("Attach Y Offset", "↕", ATTACH.YOffset, COLORS.Gold, function(n)
    ATTACH.YOffset = math.clamp(n, -10, 10)
end)
makeButton("Detach All", "🔓", COLORS.Danger, function() detachAll() end)

-- MASS ACTIONS
makeSection("MASS ACTIONS (NPCs)")
makeButton("Kill All NPCs (no quest credit)", "💀", COLORS.Danger, function() applyToAllInRange(killNPC) end)
makeButton("Void All NPCs", "🕳", Color3.fromRGB(180,120,255), function() applyToAllInRange(voidNPC) end)
makeButton("Fling All NPCs", "🚀", Color3.fromRGB(255,160,60), function() applyToAllInRange(flingNPC) end)
makeButton("Ignite All NPCs", "🔥", Color3.fromRGB(255,100,60), function() applyToAllInRange(igniteNPC) end)
makeButton("Explode All NPCs", "💥", Color3.fromRGB(255,80,140), function() applyToAllInRange(explodeNPC) end)
makeButton("Freeze All NPCs", "🧊", Color3.fromRGB(90,180,255), function() applyToAllInRange(freezeNPC) end)
makeButton("Unfreeze All NPCs", "🔓", COLORS.Success, function() applyToAllInRange(unanchorNPC) end)
makeButton("Ragdoll All NPCs", "🦴", Color3.fromRGB(220,200,90), function() applyToAllInRange(ragdollNPC) end)

-- AIMBOT
makeSection("🎯 AIMBOT")
local AimbotInfo = Instance.new("TextButton")
AimbotInfo.Size = UDim2.new(1,0,0,32)
AimbotInfo.BackgroundColor3 = COLORS.Bg2
AimbotInfo.Text = ""
AimbotInfo.AutoButtonColor = false
AimbotInfo.LayoutOrder = nextOrder()
AimbotInfo.Parent = Scroll
corner(AimbotInfo, 8); stroke(AimbotInfo, COLORS.Cyan, 1, 0.5)
local AimbotInfoLabel = Instance.new("TextLabel")
AimbotInfoLabel.Size = UDim2.new(1,-10,1,0)
AimbotInfoLabel.Position = UDim2.new(0,5,0,0)
AimbotInfoLabel.BackgroundTransparency = 1
AimbotInfoLabel.Text = "Target: —"
AimbotInfoLabel.TextColor3 = COLORS.Cyan
AimbotInfoLabel.Font = Enum.Font.GothamBold
AimbotInfoLabel.TextSize = 11
AimbotInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
AimbotInfoLabel.Parent = AimbotInfo
task.spawn(function()
    while AimbotInfo.Parent do
        local t = AIMBOT.CurrentTarget
        AimbotInfoLabel.Text = t
            and ("Target: " .. (t.char.Name or "?") .. " (" .. (t.isPlayer and "player" or "npc") .. ")")
            or "Target: —"
        task.wait(0.15)
    end
end)

local AimbotBtn = makeButton("Aimbot: OFF", "🎯", COLORS.Cyan, function() end)
bindToggle(AimbotBtn, "Aimbot", AIMBOT.Enabled, function(s) AIMBOT.Enabled = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)
local AimbotPart = makeButton("Aimbot Part: HEAD", "🦴", COLORS.Cyan, function() end)
AimbotPart.MouseButton1Click:Connect(function()
    local ord = {"Head","HumanoidRootPart","Nearest"}
    local idx = 1
    for i,v in ipairs(ord) do if v == AIMBOT.TargetPart then idx = i break end end
    idx = idx + 1; if idx > #ord then idx = 1 end
    AIMBOT.TargetPart = ord[idx]
    for _, c in ipairs(AimbotPart:GetChildren()) do
        if c:IsA("TextLabel") and c.Text:match("Aimbot Part") then
            c.Text = "Aimbot Part: " .. AIMBOT.TargetPart:upper()
        end
    end
end)
makeInput("Aimbot FOV", "🔭", AIMBOT.FOV, COLORS.Cyan, function(n) AIMBOT.FOV = math.clamp(math.floor(n), 10, 2000) end)
makeInput("Aimbot Smooth", "🎞", AIMBOT.Smoothness, COLORS.Cyan, function(n) AIMBOT.Smoothness = math.clamp(n, 0.01, 1) end)
makeInput("Auto-Fire Delay", "⏱", AIMBOT.FireDelay, COLORS.Cyan, function(n) AIMBOT.FireDelay = math.clamp(n, 0.01, 5) end)
local AimbotFire = makeButton("Auto-Fire: OFF", "🔥", COLORS.Danger, function() end)
bindToggle(AimbotFire, "Auto%-Fire", AIMBOT.AutoFire, function(s) AIMBOT.AutoFire = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)
local AimbotWall = makeButton("Wall Check: OFF", "🧱", COLORS.Cyan, function() end)
bindToggle(AimbotWall, "Wall Check", AIMBOT.WallCheck, function(s) AIMBOT.WallCheck = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)
local AimbotPlayers = makeButton("Aimbot Players: ON", "👤", COLORS.Cyan, function() end)
bindToggle(AimbotPlayers, "Aimbot Players", AIMBOT.TargetPlayers, function(s) AIMBOT.TargetPlayers = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local AimbotNPCs = makeButton("Aimbot NPCs: ON", "🤖", COLORS.Cyan, function() end)
bindToggle(AimbotNPCs, "Aimbot NPCs", AIMBOT.TargetNPCs, function(s) AIMBOT.TargetNPCs = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local AimbotFriends = makeButton("Aimbot Ignore Friends: ON", "🤝", COLORS.Cyan, function() end)
bindToggle(AimbotFriends, "Aimbot Ignore Friends", AIMBOT.IgnoreFriends, function(s) AIMBOT.IgnoreFriends = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local AimbotTeam = makeButton("Aimbot Team Check: OFF", "🛡", COLORS.Cyan, function() end)
bindToggle(AimbotTeam, "Aimbot Team Check", AIMBOT.TeamCheck, function(s) AIMBOT.TeamCheck = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)

makeSection("🎯 AIMBOT FOV VISUAL")
local AFOVShow = makeButton("Aimbot FOV Show: ON", "👁", COLORS.Cyan, function() end)
bindToggle(AFOVShow, "Aimbot FOV Show", FOV_VIS.Aimbot.Show,
    function(s) FOV_VIS.Aimbot.Show = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)
local AFOVShape = makeButton("Aimbot FOV Shape: CIRCLE", "⭕", COLORS.Cyan, function() end)
bindCycler(AFOVShape, "Aimbot FOV Shape", {"circle","triangle","cube"}, FOV_VIS.Aimbot.Shape,
    function(v) FOV_VIS.Aimbot.Shape = v end)
local AFOVDots = makeButton("Aimbot FOV Dots: ON", "📍", COLORS.Cyan, function() end)
bindToggle(AFOVDots, "Aimbot FOV Dots", FOV_VIS.Aimbot.DrawTargets,
    function(s) FOV_VIS.Aimbot.DrawTargets = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)
makeInput("FOV Size", "🔵", AIMBOT.FOV, COLORS.Cyan, function(n) AIMBOT.FOV = math.clamp(math.floor(n), 10, 2000) end)
makeInput("Aimbot FOV Thickness", "📏", FOV_VIS.Aimbot.Thickness, COLORS.Cyan, function(n)
    FOV_VIS.Aimbot.Thickness = math.clamp(n, 0.5, 10)
end)
makeInput("Aimbot FOV Alpha %", "🫥", math.floor((1-FOV_VIS.Aimbot.Transparency)*100), COLORS.Cyan, function(n)
    FOV_VIS.Aimbot.Transparency = 1 - math.clamp(n/100, 0, 1)
end)
makeInput("Aimbot Dot Size", "🔴", FOV_VIS.Aimbot.DotSize, COLORS.Cyan, function(n)
    FOV_VIS.Aimbot.DotSize = math.clamp(math.floor(n), 2, 30)
end)

-- SILENT AIM
makeSection("🔇 SILENT AIM")
local SilentInfo = Instance.new("TextButton")
SilentInfo.Size = UDim2.new(1,0,0,32)
SilentInfo.BackgroundColor3 = COLORS.Bg2
SilentInfo.Text = ""
SilentInfo.AutoButtonColor = false
SilentInfo.LayoutOrder = nextOrder()
SilentInfo.Parent = Scroll
corner(SilentInfo, 8); stroke(SilentInfo, COLORS.Pink, 1, 0.5)
local SilentInfoLabel = Instance.new("TextLabel")
SilentInfoLabel.Size = UDim2.new(1,-10,1,0)
SilentInfoLabel.Position = UDim2.new(0,5,0,0)
SilentInfoLabel.BackgroundTransparency = 1
SilentInfoLabel.Text = "Hook: " .. hookStatus
SilentInfoLabel.TextColor3 = COLORS.Pink
SilentInfoLabel.Font = Enum.Font.GothamBold
SilentInfoLabel.TextSize = 11
SilentInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
SilentInfoLabel.Parent = SilentInfo
task.spawn(function()
    while SilentInfo.Parent do
        SilentInfoLabel.Text = "Hook: " .. hookStatus .. "  •  Hits: " .. interceptCount
        task.wait(0.5)
    end
end)
local SilentBtn = makeButton("Silent Aim: OFF", "🔇", COLORS.Pink, function() end)
bindToggle(SilentBtn, "Silent Aim", SILENT.Enabled, function(s) SILENT.Enabled = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)
local SilentPart = makeButton("Silent Part: HEAD", "🦴", COLORS.Pink, function() end)
SilentPart.MouseButton1Click:Connect(function()
    local ord = {"Head","HumanoidRootPart","Nearest"}
    local idx = 1
    for i,v in ipairs(ord) do if v == SILENT.TargetPart then idx = i break end end
    idx = idx + 1; if idx > #ord then idx = 1 end
    SILENT.TargetPart = ord[idx]
    for _, c in ipairs(SilentPart:GetChildren()) do
        if c:IsA("TextLabel") and c.Text:match("Silent Part") then
            c.Text = "Silent Part: " .. SILENT.TargetPart:upper()
        end
    end
end)
makeInput("Silent FOV", "🔭", SILENT.FOV, COLORS.Pink, function(n) SILENT.FOV = math.clamp(math.floor(n), 10, 2000) end)
makeInput("Hit Chance %", "🎲", SILENT.HitChance, COLORS.Pink, function(n) SILENT.HitChance = math.clamp(math.floor(n), 1, 100) end)
makeInput("Max Ray Origin", "📍", SILENT.MaxOrigin, COLORS.Pink, function(n) SILENT.MaxOrigin = math.clamp(math.floor(n), 10, 5000) end)
makeInput("Min Shot Length", "📏", SILENT.MinShot, COLORS.Pink, function(n) SILENT.MinShot = math.clamp(math.floor(n), 1, 500) end)
local SilentWall = makeButton("Silent Wall Check: OFF", "🧱", COLORS.Pink, function() end)
bindToggle(SilentWall, "Silent Wall Check", SILENT.WallCheck, function(s) SILENT.WallCheck = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)
local SilentPlayers = makeButton("Silent Players: ON", "👤", COLORS.Pink, function() end)
bindToggle(SilentPlayers, "Silent Players", SILENT.TargetPlayers, function(s) SILENT.TargetPlayers = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local SilentNPCs = makeButton("Silent NPCs: ON", "🤖", COLORS.Pink, function() end)
bindToggle(SilentNPCs, "Silent NPCs", SILENT.TargetNPCs, function(s) SILENT.TargetNPCs = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local SilentFriends = makeButton("Silent Ignore Friends: ON", "🤝", COLORS.Pink, function() end)
bindToggle(SilentFriends, "Silent Ignore Friends", SILENT.IgnoreFriends, function(s) SILENT.IgnoreFriends = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local SilentTeam = makeButton("Silent Team Check: OFF", "🛡", COLORS.Pink, function() end)
bindToggle(SilentTeam, "Silent Team Check", SILENT.TeamCheck, function(s) SILENT.TeamCheck = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local SilentDebug = makeButton("Silent Debug: OFF", "🐞", COLORS.Pink, function() end)
bindToggle(SilentDebug, "Silent Debug", SILENT.Debug, function(s) SILENT.Debug = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)

makeSection("🔇 SILENT FOV VISUAL")
local SFOVShow = makeButton("Silent FOV Show: ON", "👁", COLORS.Pink, function() end)
bindToggle(SFOVShow, "Silent FOV Show", FOV_VIS.Silent.Show,
    function(s) FOV_VIS.Silent.Show = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)
local SFOVShape = makeButton("Silent FOV Shape: CIRCLE", "⭕", COLORS.Pink, function() end)
bindCycler(SFOVShape, "Silent FOV Shape", {"circle","triangle","cube"}, FOV_VIS.Silent.Shape,
    function(v) FOV_VIS.Silent.Shape = v end)
local SFOVDots = makeButton("Silent FOV Dots: ON", "📍", COLORS.Pink, function() end)
bindToggle(SFOVDots, "Silent FOV Dots", FOV_VIS.Silent.DrawTargets,
    function(s) FOV_VIS.Silent.DrawTargets = s end, "ON", "OFF", COLORS.Success, COLORS.Danger)
makeInput("FOV Size", "🔵", SILENT.FOV, COLORS.Pink, function(n) SILENT.FOV = math.clamp(math.floor(n), 10, 2000) end)
makeInput("Silent FOV Thickness", "📏", FOV_VIS.Silent.Thickness, COLORS.Pink, function(n)
    FOV_VIS.Silent.Thickness = math.clamp(n, 0.5, 10)
end)
makeInput("Silent FOV Alpha %", "🫥", math.floor((1-FOV_VIS.Silent.Transparency)*100), COLORS.Pink, function(n)
    FOV_VIS.Silent.Transparency = 1 - math.clamp(n/100, 0, 1)
end)
makeInput("Silent Dot Size", "🔴", FOV_VIS.Silent.DotSize, COLORS.Pink, function(n)
    FOV_VIS.Silent.DotSize = math.clamp(math.floor(n), 2, 30)
end)

-- PLAYER AURA
makeSection("PLAYER AURA")
local PInfoHolder = Instance.new("TextButton")
PInfoHolder.Size = UDim2.new(1,0,0,32)
PInfoHolder.BackgroundColor3 = COLORS.Bg2
PInfoHolder.Text = ""
PInfoHolder.AutoButtonColor = false
PInfoHolder.LayoutOrder = nextOrder()
PInfoHolder.Parent = Scroll
corner(PInfoHolder, 8); stroke(PInfoHolder, COLORS.Pink, 1, 0.5)
local PInfoLabel = Instance.new("TextLabel")
PInfoLabel.Size = UDim2.new(1,-10,1,0)
PInfoLabel.Position = UDim2.new(0,5,0,0)
PInfoLabel.BackgroundTransparency = 1
PInfoLabel.Text = "Player hits: 0"
PInfoLabel.TextColor3 = COLORS.Pink
PInfoLabel.Font = Enum.Font.GothamBold
PInfoLabel.TextSize = 11
PInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
PInfoLabel.Parent = PInfoHolder
task.spawn(function()
    while PInfoHolder.Parent do
        PInfoLabel.Text = string.format("Nearby: %d  •  Hits: %d  •  %s",
            #getValidPlayers(PAURA), PAURA.Hits, PAURA.Method:upper())
        task.wait(0.5)
    end
end)
local PAuraBtn = makeButton("Player Aura: OFF", "🎯", COLORS.Pink, function() end)
bindToggle(PAuraBtn, "Player Aura", PAURA.Enabled, function(s) PAURA.Enabled = s end,
    "ON", "OFF", COLORS.Success, COLORS.Text)
makeInput("Player Aura Range", "📐", PAURA.Range, COLORS.Pink, function(n) PAURA.Range = math.clamp(math.floor(n), 1, 500) end)
makeInput("Player Aura Speed", "⏱", PAURA.Interval, COLORS.Pink, function(n) PAURA.Interval = math.clamp(n, 0.01, 10) end)
makeInput("TP Hold (s)", "⏳", PAURA.TPTime, COLORS.Pink, function(n) PAURA.TPTime = math.clamp(n, 0.01, 0.5) end)
local TPBackBtn = makeButton("Return After Hit: ON", "↩", COLORS.Cyan, function() end)
bindToggle(TPBackBtn, "Return After Hit", PAURA.TPBack, function(s) PAURA.TPBack = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local ModeBtn = makeButton("Target Mode: ALL", "🎯", COLORS.Cyan, function() end)
ModeBtn.MouseButton1Click:Connect(function()
    PAURA.TargetMode = (PAURA.TargetMode == "all") and "nearest" or "all"
    for _, c in ipairs(ModeBtn:GetChildren()) do
        if c:IsA("TextLabel") and c.Text:match("Target Mode") then
            c.Text = "Target Mode: " .. PAURA.TargetMode:upper()
        end
    end
end)
local FriendsBtn = makeButton("Ignore Friends: ON", "🤝", COLORS.Cyan, function() end)
bindToggle(FriendsBtn, "Ignore Friends", PAURA.IgnoreFriends, function(s) PAURA.IgnoreFriends = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)
local PAuraTeam = makeButton("Aura Team Check: OFF", "🛡", COLORS.Cyan, function() end)
bindToggle(PAuraTeam, "Aura Team Check", PAURA.TeamCheck, function(s) PAURA.TeamCheck = s end,
    "ON", "OFF", COLORS.Success, COLORS.Danger)

-- CLICK MODES
makeSection("CLICK MODES (NPCs)")
local statusBtn = Instance.new("TextButton")
statusBtn.Size = UDim2.new(1,0,0,32)
statusBtn.BackgroundColor3 = COLORS.Bg2
statusBtn.Text = ""
statusBtn.AutoButtonColor = false
statusBtn.LayoutOrder = nextOrder()
statusBtn.Parent = Scroll
corner(statusBtn, 8); stroke(statusBtn, COLORS.Accent, 1, 0.6)
ClickStatus = Instance.new("TextLabel")
ClickStatus.Size = UDim2.new(1,0,1,0)
ClickStatus.BackgroundTransparency = 1
ClickStatus.Text = "CLICK MODE: OFF"
ClickStatus.TextColor3 = COLORS.Sub
ClickStatus.Font = Enum.Font.GothamBold
ClickStatus.TextSize = 11
ClickStatus.Parent = statusBtn
for _, def in ipairs({
    {"Kill","kill"},{"Void","void"},{"Fling","fling"},
    {"Ignite","ignite"},{"Explode","explode"},{"Freeze","freeze"}
}) do
    local name, key = def[1], def[2]
    local btn = makeButton("Toggle Click " .. name, "○", COLORS.Sub, function() end)
    btn.MouseButton1Click:Connect(function()
        clickModes[key] = not clickModes[key]
        for _, c in ipairs(btn:GetChildren()) do
            if c:IsA("TextLabel") and (c.Text == "○" or c.Text == "●") then
                c.Text = clickModes[key] and "●" or "○"
                c.TextColor3 = clickModes[key] and COLORS.Accent2 or COLORS.Sub
            end
        end
        updateClickStatus()
    end)
end

-- SETTINGS
makeSection("SETTINGS")
makeInput("Mass Range", "📏", CONFIG.KillRange, COLORS.Accent, function(n)
    CONFIG.KillRange = math.clamp(math.floor(n), 1, 5000)
end)
makeInput("Fling Power", "💨", CONFIG.FlingPower, Color3.fromRGB(255,160,60), function(n)
    CONFIG.FlingPower = math.clamp(math.floor(n), 10, 5000)
end)
makeInput("Void Y", "🕳", CONFIG.VoidY, Color3.fromRGB(180,120,255), function(n)
    CONFIG.VoidY = math.floor(n)
end)

-- ============ OPEN / CLOSE ============
local menuOpen = false
local function openMenu()
    menuOpen = true
    Main.Visible = true
    Main.Size = UDim2.new(0,300,0,1)
    TweenService:Create(Main, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Size = UDim2.new(0,300,0,680)}):Play()
end
local function closeMenu()
    menuOpen = false
    local tw = TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {Size = UDim2.new(0,300,0,1)})
    tw:Play()
    tw.Completed:Connect(function() if not menuOpen then Main.Visible = false end end)
end
ToggleBtn.MouseButton1Click:Connect(function() if menuOpen then closeMenu() else openMenu() end end)
CloseX.MouseButton1Click:Connect(closeMenu)

do
    local dragging, dragStart, startPos, moved
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; moved = false
            dragStart = input.Position
            startPos = ToggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then moved = true end
            if moved then
                ToggleBtn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
end

if isMobile then
    ToggleBtn.Size = UDim2.new(0,62,0,62)
    Main.Position = UDim2.new(0.5,-150,0.5,-340)
end

updateClickStatus()
print("[NPC Killer] v15.1 loaded ✓")
print("Silent hook: " .. hookStatus)
print("Drawing lib: " .. (DrawLib and "available" or "NOT AVAILABLE"))
print("Aura Mode: LEGIT (quest credit)")
print("Attach: ready — No-Collision ON by default")
