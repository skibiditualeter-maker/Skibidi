--=====================================================================
--  CFly v8 — Native Joystick Fly + Executor Notifications
--  (Fixes: restores original WalkSpeed/JumpPower after fly)
--=====================================================================

--===================== Executor support check =======================
local StarterGui = game:GetService("StarterGui")
local CoreGui    = game:GetService("CoreGui")

local function Notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration
        })
    end)
    task.spawn(function()
        local notificationGui = CoreGui:FindFirstChild("RobloxGui")
            and CoreGui.RobloxGui:FindFirstChild("NotificationFrame")
        if not notificationGui then
            for _, v in pairs(CoreGui:GetDescendants()) do
                if v.Name == "NotificationFrame" or v.Name == "Notification" then
                    notificationGui = v
                    break
                end
            end
        end
        if notificationGui then
            notificationGui.AnchorPoint = Vector2.new(0, 0)
            notificationGui.Position    = UDim2.new(0, 20, 0, 80)
        end
    end)
end

local function getExecutorName()
    if identifyexecutor then
        local name, version = identifyexecutor()
        return name or "Unknown", version
    elseif getexecutorname then
        return getexecutorname(), nil
    end
    return "Unknown", nil
end

local function isSupported()
    local hasHttp       = typeof(game.HttpGet)  == "function"
    local hasLoadstring = typeof(loadstring)    == "function"
    local hasRequest    = typeof(request)       == "function"
                          or (syn and typeof(syn.request) == "function")
    return hasHttp and hasLoadstring and hasRequest
end

local execName, execVersion = getExecutorName()

if not isSupported() then
    Notify("CFly", "Executor not supported!\nDetected: " .. execName, 6)
    return
end

Notify("CFly", "Supported: " .. execName .. "\nLoading...", 3)
print("[CFly] Loading...")

--===================== Core services ================================
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

local T = {
    BG  = Color3.fromRGB(15, 16, 21),
    BG2 = Color3.fromRGB(25, 27, 35),
    BG3 = Color3.fromRGB(38, 41, 54),
    TXT = Color3.fromRGB(237, 240, 248),
    SUB = Color3.fromRGB(136, 142, 160),
    A1  = Color3.fromRGB(124, 92, 255),
    A2  = Color3.fromRGB(0, 209, 255),
}

local function new(cls, props, parent)
    local o = Instance.new(cls)
    if props then
        for k, v in pairs(props) do pcall(function() o[k] = v end) end
    end
    if parent then o.Parent = parent end
    return o
end

--===================== GUI parent ===================================
local parentGui
if gethui then pcall(function() parentGui = gethui() end) end
if not parentGui then pcall(function() parentGui = game:GetService("CoreGui") end) end
if not parentGui then parentGui = LP:WaitForChild("PlayerGui") end

local gui = new("ScreenGui", {
    Name = "CFly",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
}, parentGui)

--===================== Native Roblox joystick =======================
local controls
pcall(function()
    local ps = LP:WaitForChild("PlayerScripts", 10)
    if ps then
        local pm = ps:WaitForChild("PlayerModule", 10)
        if pm then
            controls = require(pm):GetControls()
        end
    end
end)

local function getMoveInput()
    if controls then
        local ok, vec = pcall(function() return controls:GetMoveVector() end)
        if ok and vec and vec.Magnitude > 0.001 then return vec end
    end
    local x, z = 0, 0
    if UIS:IsKeyDown(Enum.KeyCode.W) then z -= 1 end
    if UIS:IsKeyDown(Enum.KeyCode.S) then z += 1 end
    if UIS:IsKeyDown(Enum.KeyCode.D) then x += 1 end
    if UIS:IsKeyDown(Enum.KeyCode.A) then x -= 1 end
    return Vector3.new(x, 0, z)
end

--===================== State ========================================
local state = { flying = false, speed = 60 }
local flyCF = nil
local setFlyToggle

-- Saved original humanoid values (restored on fly-off)
local savedWalkSpeed  = nil
local savedJumpPower  = nil
local savedJumpHeight = nil
local usedJumpPower   = true

--===================== Draggable ====================================
local function makeDraggable(frame, handle, onClick)
    local dragging, moved, startPos, startMouse = false, false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startMouse, startPos = input.Position, frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - startMouse
        if d.Magnitude > 6 then moved = true end
        if moved then
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if not moved and onClick then onClick() end
        end
    end)
end

--===================== Fly logic ====================================
local function getVel()
    local cam = workspace.CurrentCamera
    if not cam then return Vector3.zero end
    local look  = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    local up    = cam.CFrame.UpVector

    local inp = getMoveInput()
    local move = right * inp.X + look * (-inp.Z)
    if move.Magnitude > 1 then move = move.Unit end

    local vert = 0
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vert += 1 end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift)
    or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vert -= 1 end

    return move * state.speed + up * (vert * state.speed)
end

RunService.RenderStepped:Connect(function(dt)
    if not state.flying or not flyCF then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyCF = flyCF + getVel() * dt
    hrp.CFrame = flyCF
end)

--===================== Save / restore humanoid ======================
local function saveHumanoid(hum)
    if not hum then return end
    if savedWalkSpeed ~= nil then return end -- already saved (avoid overwrite)
    savedWalkSpeed  = hum.WalkSpeed
    savedJumpPower  = hum.JumpPower
    savedJumpHeight = hum.JumpHeight
    usedJumpPower   = hum.UseJumpPower
end

local function restoreHumanoid(hum)
    if not hum then return end
    if savedWalkSpeed  ~= nil then hum.WalkSpeed  = savedWalkSpeed  end
    if savedJumpPower  ~= nil then hum.JumpPower  = savedJumpPower  end
    if savedJumpHeight ~= nil then hum.JumpHeight = savedJumpHeight end
    hum.UseJumpPower = usedJumpPower
    savedWalkSpeed, savedJumpPower, savedJumpHeight = nil, nil, nil
end

local function setFlying(v)
    if state.flying == v then return end
    state.flying = v

    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if v then
        -- Turning ON: save whatever the game has set, then freeze
        saveHumanoid(hum)
        if hrp then hrp.Anchored = true end
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
        end
        flyCF = hrp and hrp.CFrame or nil
    else
        -- Turning OFF: unanchor, then restore exact original values
        flyCF = nil
        if hrp then hrp.Anchored = false end
        restoreHumanoid(hum)
    end

    Notify("CFly", v and "Fly: ON" or "Fly: OFF", 2)
end

LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    task.wait(0.2)
    flyCF = nil
    -- Reset saved values on respawn so we capture fresh defaults next time
    savedWalkSpeed, savedJumpPower, savedJumpHeight = nil, nil, nil

    if state.flying then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = true; flyCF = hrp.CFrame end
        if hum then
            savedWalkSpeed  = hum.WalkSpeed
            savedJumpPower  = hum.JumpPower
            savedJumpHeight = hum.JumpHeight
            usedJumpPower   = hum.UseJumpPower
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
        end
    end
end)

--===================== Menu =========================================
local MENU_W, MENU_H = 200, 120
local menuExpanded = true

local menu = new("Frame", {
    Name = "Menu",
    Size = UDim2.fromOffset(MENU_W, MENU_H),
    Position = UDim2.fromOffset(70, 110),
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 20,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, menu)
new("UIStroke", { Color = T.BG3, Thickness = 1 }, menu)

new("UIGradient", { Color = ColorSequence.new(T.A1, T.A2) }, new("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = T.A1,
    BorderSizePixel = 0,
    ZIndex = 21,
}, menu))

local titleBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundTransparency = 1,
    ZIndex = 21,
}, menu)

new("UICorner", { CornerRadius = UDim.new(1, 0) }, new("Frame", {
    Size = UDim2.fromOffset(6, 6),
    Position = UDim2.fromOffset(14, 13),
    BackgroundColor3 = T.A2,
    BorderSizePixel = 0,
    ZIndex = 22,
}, titleBar))

new("TextLabel", {
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.fromOffset(26, 0),
    BackgroundTransparency = 1,
    Text = "CFLY",
    TextColor3 = T.TXT,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 22,
}, titleBar)

local minBtn = new("TextButton", {
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -30, 0, 5),
    BackgroundColor3 = T.BG2,
    Text = "−",
    TextColor3 = T.TXT,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    BorderSizePixel = 0,
    ZIndex = 22,
}, titleBar)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)

local body = new("Frame", {
    Size = UDim2.new(1, -28, 1, -44),
    Position = UDim2.fromOffset(14, 38),
    BackgroundTransparency = 1,
    ZIndex = 21,
}, menu)

--===================== Toggle =======================================
local function buildToggle(parent, y, label, default, onChange)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.fromOffset(0, y),
        BackgroundTransparency = 1,
        ZIndex = 21,
    }, parent)
    new("TextLabel", {
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = T.TXT,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 22,
    }, row)

    local sw = new("TextButton", {
        Size = UDim2.fromOffset(38, 20),
        Position = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = T.BG3,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 22,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(170, 175, 190),
        BorderSizePixel = 0,
        ZIndex = 23,
    }, sw)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local value = default
    local function render()
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = value and T.A1 or T.BG3,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = value and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2),
            BackgroundColor3 = value and Color3.new(1, 1, 1) or Color3.fromRGB(170, 175, 190),
        }):Play()
    end
    render()

    local function setValue(v, fire)
        value = v; render()
        if fire then onChange(value) end
    end
    sw.MouseButton1Click:Connect(function() setValue(not value, true) end)
    return setValue
end

--===================== Speed row ====================================
local function buildSpeedRow(parent, y, label, min, max, default, onChange)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, y),
        BackgroundTransparency = 1,
        ZIndex = 21,
    }, parent)

    new("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = T.TXT,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 22,
    }, row)

    local function ctrlBtn(x, txt, cb)
        local b = new("TextButton", {
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.fromOffset(x, 3),
            BackgroundColor3 = T.BG2,
            Text = txt,
            TextColor3 = T.TXT,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 22,
        }, row)
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        new("UIStroke", { Color = T.BG3, Thickness = 1 }, b)
        b.MouseButton1Click:Connect(cb)
    end

    local value = default

    local numBox = new("TextBox", {
        Size = UDim2.fromOffset(40, 24),
        Position = UDim2.fromOffset(100, 3),
        BackgroundColor3 = T.BG3,
        Text = tostring(default),
        TextColor3 = T.A2,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        ClearTextOnFocus = false,
        ZIndex = 23,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, numBox)

    local function setValue(v, fire)
        value = math.clamp(math.floor(v + 0.5), min, max)
        numBox.Text = tostring(value)
        if fire then onChange(value) end
    end

    ctrlBtn(74,  "−", function() setValue(value - 10, true) end)
    ctrlBtn(142, "+", function() setValue(value + 10, true) end)

    numBox.FocusLost:Connect(function()
        local n = tonumber(numBox.Text)
        if n then setValue(n, true) else numBox.Text = tostring(value) end
    end)

    return setValue
end

--===================== Populate menu ================================
setFlyToggle = buildToggle(body, 0, "Fly", false, function(v) setFlying(v) end)
buildSpeedRow(body, 32, "Speed", 10, 500, state.speed, function(v)
    state.speed = v
    Notify("CFly", "Speed set to " .. v, 2)
end)

--===================== Minimize / Expand ============================
local function setExpanded(v)
    menuExpanded = v
    if v then
        body.Visible = true
        minBtn.Text = "−"
        TweenService:Create(menu, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(MENU_W, MENU_H),
        }):Play()
    else
        minBtn.Text = "+"
        TweenService:Create(menu, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(MENU_W, 32),
        }):Play()
        task.delay(0.18, function()
            if not menuExpanded then body.Visible = false end
        end)
    end
end

minBtn.MouseButton1Click:Connect(function() setExpanded(not menuExpanded) end)
makeDraggable(menu, titleBar)

--===================== Keybind F ====================================
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        local v = not state.flying
        setFlying(v)
        if setFlyToggle then setFlyToggle(v, false) end
    end
end)

Notify("CFly", "Loaded! Press F to fly", 3)
print("[CFly] Ready!")
