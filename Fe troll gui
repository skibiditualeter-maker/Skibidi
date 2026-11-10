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
