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
            loadstring(game:HttpGet("https://pastebin.com/raw/X8ePspzf"))()
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
