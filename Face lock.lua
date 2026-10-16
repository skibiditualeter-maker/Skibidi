-- Face Lock — Mobile with Draggable Button (v7 - DETECTION FIXED)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===== CONFIG =====
local LOCK_RANGE     = 120
local ROTATION_SPEED = 25
local SHOW_INDICATOR = true
local HOLD_TIME      = 2
local REFIND_COOLDOWN = 0.35
local DEBUG          = true    -- set false when you're happy it works
-- ==================

local isLocked = false
local target = nil
local savedAutoRotate = true
local lastFindTime = 0

local function log(...)
	if DEBUG then print("[FaceLock]", ...) end
end

--=====================================================
-- UI
--=====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "FaceLockUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
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
-- Highlight
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
local function isCharacterAlive(char)
	if not char or not char.Parent then return false end
	if not char:IsDescendantOf(Workspace) then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return true
end

local function getRootOf(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
end

-- IMPORTANT: recurse into Folders only (never into Models), so it's fast.
local function collectCandidates()
	local list = {}
	local seen = {}

	local function add(char)
		if char and not seen[char] then
			seen[char] = true
			table.insert(list, char)
		end
	end

	-- Players
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			add(plr.Character)
		end
	end

	-- Workspace children + recurse into Folders only (depth-limited)
	local function scan(container, depth)
		if depth > 4 then return end
		for _, obj in ipairs(container:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
				add(obj)
			elseif obj:IsA("Folder") or obj:IsA("Model") then
				-- Models can contain folders too, so recurse once more
				scan(obj, depth + 1)
			end
		end
	end
	scan(Workspace, 0)

	return list
end

-- Fallback: raycast from camera center to find any Humanoid under the crosshair
local function raycastTarget()
	local char = player.Character
	if not char then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	params.IgnoreWater = true

	local result = Workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * LOCK_RANGE, params)
	if not result then return nil end

	local hit = result.Instance
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") and model ~= char then
			return model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function findTarget()
	local character = player.Character
	if not isCharacterAlive(character) then return nil end
	local root = getRootOf(character)
	if not root then return nil end

	local myPos = root.Position
	local camPos = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector

	local best, bestScore = nil, -math.huge
	local candidates = collectCandidates()
	log("candidates:", #candidates)

	for _, char in ipairs(candidates) do
		if char ~= character and isCharacterAlive(char) then
			local theirRoot = getRootOf(char)
			if theirRoot then
				local d = theirRoot.Position - myPos
				local dist = d.Magnitude
				if dist <= LOCK_RANGE then
					local dir = (theirRoot.Position - camPos).Unit
					local dot = camLook:Dot(dir)
					-- Loosened: was 0.3, now 0.1 — nearly anything on screen qualifies
					if dot > 0.1 then
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

	-- Fallback: nothing scored well → try raycast from crosshair
	if not best then
		local hit = raycastTarget()
		if hit then
			log("raycast fallback found:", hit.Name)
			best = hit
		end
	end

	if best then
		log("target:", best.Name)
	else
		log("no target found")
	end
	return best
end

local function updateIndicator()
	if SHOW_INDICATOR and target and target.Parent and target:IsDescendantOf(Workspace) then
		if highlight.Parent ~= target then
			highlight.Adornee = target
			highlight.Parent = target
		end
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
		local now = tick()
		if not newTarget and (now - lastFindTime) < REFIND_COOLDOWN and target then
			-- keep existing
		else
			target = newTarget or findTarget()
			lastFindTime = now
		end

		if not target then
			isLocked = false
			button.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
			log("lock failed: no target")
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
		setLocked(false); return
	end

	local myRoot = getRootOf(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not myRoot or not myRoot.Parent or not hum then
		setLocked(false); return
	end

	if not target or not target.Parent
		or not target:IsDescendantOf(Workspace)
		or not isCharacterAlive(target) then
		setLocked(false); return
	end

	local theirRoot = getRootOf(target)
	if not theirRoot or not theirRoot.Parent then
		setLocked(false); return
	end

	local delta = theirRoot.Position - myRoot.Position
	if delta.Magnitude > LOCK_RANGE * 1.5 then
		setLocked(false); return
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
-- Drag
--=====================================================
local HOLD_START     = nil
local DRAG_MODE      = false
local DRAG_OFFSET    = Vector2.new(0, 0)
local HOLD_TASK      = nil
local LAST_TOUCH_POS = nil

local function isPrimaryInput(input)
	return input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
end

local function inputToScreen(input)
	return Vector2.new(input.Position.X, input.Position.Y)
end

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

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		LAST_TOUCH_POS = inputToScreen(input)
	end
end)

button.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		LAST_TOUCH_POS = inputToScreen(input)
	end
end)

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
