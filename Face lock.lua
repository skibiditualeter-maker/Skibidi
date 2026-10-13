-- Face Lock — Mobile with Draggable Button (v5 FINAL)
-- TAP      = toggle lock
-- HOLD 2s  = drag mode (button follows finger smoothly)
-- Auto-unlocks on death (yours or target's)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===== CONFIG =====
local LOCK_RANGE     = 100
local ROTATION_SPEED = 25
local SHOW_INDICATOR = true
local HOLD_TIME      = 2
-- ==================

local isLocked = false
local target = nil
local savedAutoRotate = true

--=====================================================
-- UI
--=====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "FaceLockUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false        -- IMPORTANT: keeps AbsolutePosition matching touch coords
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "FaceLockButton"
button.Size = UDim2.new(0, 80, 0, 80)
button.Position = UDim2.new(1, -110, 0.5, -40)
button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
button.BackgroundTransparency = 0.2
button.BorderSizePixel = 0
button.Text = "🎯"
button.TextSize = 36
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.AutoButtonColor = false
button.Active = true
button.ZIndex = 10
button.Parent = gui

Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.3
stroke.Parent = button

local ring = Instance.new("Frame")
ring.Name = "Ring"
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.new(0.5, 0, 0.5, 0)
ring.Size = UDim2.new(1, 14, 1, 14)
ring.BackgroundTransparency = 1
ring.ZIndex = 9
ring.Parent = button

Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)

local ringStroke = Instance.new("UIStroke")
ringStroke.Thickness = 4
ringStroke.Color = Color3.fromRGB(80, 200, 255)
ringStroke.Transparency = 1
ringStroke.Parent = ring

--=====================================================
-- Target highlight
--=====================================================
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 60, 60)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 0.7
highlight.OutlineTransparency = 0.3
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

--=====================================================
-- Shift Lock helper
--=====================================================
local function setShiftLockEnabled(enabled)
	local ps = player:FindFirstChild("PlayerScripts")
	if not ps then return end
	local pm = ps:FindFirstChild("PlayerModule")
	if not pm then return end
	local ok, mod = pcall(require, pm)
	if not ok then return end
	local controls = mod:GetControls()
	if not controls then return end
	if enabled then
		if controls.EnableShiftLock then pcall(function() controls:EnableShiftLock() end) end
	else
		if controls.DisableShiftLock then pcall(function() controls:DisableShiftLock() end) end
	end
end

--=====================================================
-- Helpers
--=====================================================
local function getCharacterFromPart(part)
	if not part then return nil end
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then return model end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function isCharacterAlive(char)
	if not char or not char.Parent then return false end
	if not char:IsDescendantOf(Workspace) then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or not root.Parent then return false end
	return true
end

local function findTarget()
	local character = player.Character
	if not isCharacterAlive(character) then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local myPos = root.Position
	local best, bestScore = nil, -math.huge

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Model") then
			local char = nil
			if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
				char = obj
			elseif obj:IsA("BasePart") then
				char = getCharacterFromPart(obj)
			end

			if char and char ~= character and isCharacterAlive(char) then
				local theirRoot = char:FindFirstChild("HumanoidRootPart")
					or char:FindFirstChild("Torso")
					or char:FindFirstChild("UpperTorso")
				if theirRoot then
					local dist = (theirRoot.Position - myPos).Magnitude
					if dist <= LOCK_RANGE then
						local dir = (theirRoot.Position - camera.CFrame.Position).Unit
						local dot = camera.CFrame.LookVector:Dot(dir)
						if dot > 0.3 then
							local score = dot * 100 - dist
							if score > bestScore then
								bestScore = score
								best = char
							end
						end
					end
				end
			end
		end
	end

	return best
end

local function updateIndicator()
	if SHOW_INDICATOR and target and target.Parent and target:IsDescendantOf(Workspace) then
		highlight.Adornee = target
		highlight.Parent = target
	else
		highlight.Adornee = nil
		highlight.Parent = nil
	end
end

local function clearTarget()
	target = nil
	highlight.Adornee = nil
	highlight.Parent = nil
end

local function setLocked(state, newTarget)
	isLocked = state
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")

	if state then
		target = newTarget or findTarget()
		if not target then
			isLocked = false
			button.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
			task.delay(0.3, function()
				if not isLocked then
					button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				end
			end)
			return
		end
		button.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		if hum then
			savedAutoRotate = hum.AutoRotate
			hum.AutoRotate = false
		end
		setShiftLockEnabled(false)
		updateIndicator()
	else
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		if hum then hum.AutoRotate = savedAutoRotate end
		setShiftLockEnabled(true)
		clearTarget()
	end
end

--=====================================================
-- Rotation
--=====================================================
RunService:BindToRenderStep("FaceLockRotate", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not isLocked then return end

	local character = player.Character
	if not isCharacterAlive(character) then
		setLocked(false)
		return
	end

	local myRoot = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not myRoot or not myRoot.Parent or not hum then
		setLocked(false)
		return
	end

	if not target
		or not target.Parent
		or not target:IsDescendantOf(Workspace)
		or not isCharacterAlive(target) then
		setLocked(false)
		return
	end

	local theirRoot = target:FindFirstChild("HumanoidRootPart")
		or target:FindFirstChild("UpperTorso")
		or target:FindFirstChild("Torso")
	if not theirRoot or not theirRoot.Parent then
		setLocked(false)
		return
	end

	local delta = theirRoot.Position - myRoot.Position
	if delta.Magnitude > LOCK_RANGE * 1.5 then
		setLocked(false)
		return
	end

	local flatDir = Vector3.new(delta.X, 0, delta.Z)
	if flatDir.Magnitude < 0.01 then return end
	flatDir = flatDir.Unit

	if hum.AutoRotate then hum.AutoRotate = false end

	local goalCFrame = CFrame.lookAt(myRoot.Position, myRoot.Position + flatDir)
	local alpha = math.clamp(ROTATION_SPEED * dt, 0, 1)
	myRoot.CFrame = myRoot.CFrame:Lerp(goalCFrame, alpha)
end)

--=====================================================
-- DRAG SYSTEM (rewritten)
--=====================================================
local HOLD_START     = nil       -- tick() when finger pressed
local DRAG_MODE      = false
local DRAG_OFFSET    = Vector2.new(0, 0)
local HOLD_TASK      = nil
local LAST_TOUCH_POS = nil       -- Vector2, updated every InputChanged

local function isPrimaryInput(input)
	return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
end

-- Convert any input (touch or mouse) to a screen Vector2 matching AbsolutePosition space
local function inputToScreen(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	-- Mouse: input.Position for MouseMovement/MouseButton1 also uses screen pixels
	return Vector2.new(input.Position.X, input.Position.Y)
end

-- Push button to new position with clamping
local function moveButtonTo(fingerPos)
	local viewport = camera.ViewportSize
	local bSize = button.AbsoluteSize
	local newPos = fingerPos - DRAG_OFFSET
	newPos = Vector2.new(
		math.clamp(newPos.X, 0, math.max(0, viewport.X - bSize.X)),
		math.clamp(newPos.Y, 0, math.max(0, viewport.Y - bSize.Y))
	)
	button.Position = UDim2.fromOffset(newPos.X, newPos.Y)
end

-- 1) Track finger position globally (fires many times per second)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		LAST_TOUCH_POS = inputToScreen(input)
	end
end)

-- 2) Also track via the button itself (fires reliably while it owns the touch)
button.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		LAST_TOUCH_POS = inputToScreen(input)
	end
end)

-- 3) While dragging, push the button every frame for buttery smoothness
RunService.RenderStepped:Connect(function()
	if DRAG_MODE and LAST_TOUCH_POS then
		moveButtonTo(LAST_TOUCH_POS)
	end
end)

button.InputBegan:Connect(function(input)
	if not isPrimaryInput(input) then return end

	LAST_TOUCH_POS = inputToScreen(input)
	HOLD_START = tick()
	DRAG_MODE = false
	ringStroke.Color = Color3.fromRGB(80, 200, 255)
	ringStroke.Transparency = 0.3

	if HOLD_TASK then pcall(task.cancel, HOLD_TASK) end
	HOLD_TASK = task.spawn(function()
		while HOLD_START do
			if (tick() - HOLD_START) >= HOLD_TIME then
				-- Enter drag mode: offset = current finger - button top-left
				local finger = LAST_TOUCH_POS or inputToScreen(input)
				local btnPos = Vector2.new(button.AbsolutePosition.X, button.AbsolutePosition.Y)
				DRAG_OFFSET = finger - btnPos

				DRAG_MODE = true
				ringStroke.Color = Color3.fromRGB(80, 255, 120)
				ringStroke.Transparency = 0
				break
			end
			task.wait(0.02)
		end
	end)
end)

local function finishInput(wasDrag, held)
	HOLD_START = nil
	DRAG_MODE = false
	if HOLD_TASK then pcall(task.cancel, HOLD_TASK) HOLD_TASK = nil end

	ringStroke.Transparency = 1
	ringStroke.Color = Color3.fromRGB(80, 200, 255)

	if not wasDrag and held and held < HOLD_TIME then
		if isLocked then
			setLocked(false)
		else
			setLocked(true)
		end
	end
end

button.InputEnded:Connect(function(input)
	if not isPrimaryInput(input) then return end
	local wasDrag = DRAG_MODE
	local held = HOLD_START and (tick() - HOLD_START) or 0
	finishInput(wasDrag, held)
end)

-- Safety net if finger releases outside the button
UserInputService.InputEnded:Connect(function(input)
	if not isPrimaryInput(input) then return end
	if not HOLD_START and not DRAG_MODE then return end
	local wasDrag = DRAG_MODE
	local held = HOLD_START and (tick() - HOLD_START) or 0
	finishInput(wasDrag, held)
end)

--=====================================================
-- Death / respawn
--=====================================================
local function watchHumanoid(char)
	if not char then return end
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	hum.Died:Connect(function() setLocked(false) end)
	hum.AncestryChanged:Connect(function()
		if not hum:IsDescendantOf(Workspace) then setLocked(false) end
	end)
end

player.CharacterRemoving:Connect(function() setLocked(false) end)
player.CharacterAdded:Connect(function(c) setLocked(false) watchHumanoid(c) end)
if player.Character then watchHumanoid(player.Character) end
