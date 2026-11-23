--============================================================
--  FE Troll GUI  |  Rayfield Gen2
--============================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "FE Troll GUI",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
})

local tab = window:CreateTab({ name = "Troll", icon = 93364949241311 })

--============================================================
--  SCRIPTS
--============================================================
tab:CreateButton({
    name = "Touch Fling",
    callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Universal-Touch-fling-27515"))()
    end,
})

local instantPromptConn
tab:CreateButton({
    name = "Instant Proximity Prompt",
    callback = function()
        local function setInstantPrompt(prompt)
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end
        for _, descendant in ipairs(workspace:GetDescendants()) do
            setInstantPrompt(descendant)
        end
        if instantPromptConn then instantPromptConn:Disconnect() end
        instantPromptConn = workspace.DescendantAdded:Connect(setInstantPrompt)
    end,
})

tab:CreateButton({
    name = "God Mode",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Rawbr10/Roblox-Scripts/refs/heads/main/God%20Mode%20Script%20Universal"))()
    end,
})

tab:CreateButton({
    name = "Better God Mode",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/miglels33/God-Mode-Script/refs/heads/main/GodModeScript.md"))()
    end,
})

tab:CreateButton({
    name = "ULTIMATE FPS TOOLS",
    callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/BuNcwb2t"))()
    end,
})

tab:CreateButton({
    name = "Touch Fling V2",
    callback = function()
        loadstring(game:HttpGet("https://pastefy.app/atxaw8zH/raw"))()
    end,
})

tab:CreateButton({
    name = "AN Universal",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GUI-Offical/FileTest/refs/heads/main/ANHUBB.lua"))()
    end,
})

tab:CreateButton({
    name = "Esp",
    callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://sneekysscripts.uk/Scripts/Universal_ESP/main.luau"))()
        end)
        if not ok then warn("[Esp] Error: " .. tostring(err)) end
    end,
})

tab:CreateButton({
    name = "Noclip",
    callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://pastebin.com/raw/tYSdPEDD"))()
        end)
        if not ok then warn("[Noclip] Error: " .. tostring(err)) end
    end,
})

tab:CreateButton({
    name = "Hitbox Extender",
    callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Vcsk/RobloxScripts/main/HitboxExpander.lua"))()
        end)
        if not ok then warn("[Hitbox Extender] Error: " .. tostring(err)) end
    end,
})

tab:CreateButton({
    name = "Fullbright",
    callback = function()
        local ok, err = pcall(function()
            -- MADE BY MAPSLOVER - Fullbright
            local lighting = game:GetService("Lighting")
            local screenGui = Instance.new("ScreenGui", game.CoreGui)
            local frame = Instance.new("Frame", screenGui)
            frame.Size = UDim2.new(0, 180, 0, 70)
            frame.Position = UDim2.new(0.2, 0, 0.5, 0)
            frame.Active = true
            frame.Draggable = true
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

            local title = Instance.new("TextLabel", frame)
            title.Size = UDim2.new(1, 0, 0.5, 0)
            title.Text = "MADE BY MAPSLOVER"
            title.BackgroundTransparency = 1
            task.spawn(function()
                while title.Parent do
                    for i = 0, 1, 0.01 do
                        title.TextColor3 = Color3.fromHSV(i, 1, 1)
                        task.wait(0.05)
                    end
                end
            end)

            local fbButton = Instance.new("TextButton", frame)
            fbButton.Size = UDim2.new(0.9, 0, 0.4, 0)
            fbButton.Position = UDim2.new(0.05, 0, 0.55, 0)
            fbButton.Text = "Enable Fullbright"
            fbButton.MouseButton1Click:Connect(function()
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
                lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                lighting.Brightness = 2
            end)
        end)
        if not ok then warn("[Fullbright] Error: " .. tostring(err)) end
    end,
})

tab:CreateButton({
    name = "Vex Emotes",
    callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://vexroscripts.com.tr/vexroemotes.luau"))()
        end)
        if not ok then warn("[Vex Emotes] Error: " .. tostring(err)) end
    end,
})

tab:CreateButton({
    name = "Cfly",
    callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/skibiditualeter-maker/Skibidi/refs/heads/main/Cfly.lua"))()
        end)
        if not ok then warn("[Cfly] Error: " .. tostring(err)) end
    end,
})
