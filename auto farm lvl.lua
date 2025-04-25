-- Services
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local workspace = game:GetService("Workspace")

-- Mod Menu UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 350)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.Parent = ScreenGui

local autoQuestButton = Instance.new("TextButton")
autoQuestButton.Size = UDim2.new(0, 180, 0, 50)
autoQuestButton.Position = UDim2.new(0, 10, 0, 10)
autoQuestButton.Text = "Toggle Auto Quest"
autoQuestButton.Parent = frame

local autoFarmButton = Instance.new("TextButton")
autoFarmButton.Size = UDim2.new(0, 180, 0, 50)
autoFarmButton.Position = UDim2.new(0, 10, 0, 70)
autoFarmButton.Text = "Toggle Auto Farm"
autoFarmButton.Parent = frame

local magnetButton = Instance.new("TextButton")
magnetButton.Size = UDim2.new(0, 180, 0, 50)
magnetButton.Position = UDim2.new(0, 10, 0, 130)
magnetButton.Text = "Toggle Magnet Enemy"
magnetButton.Parent = frame

local attackButton = Instance.new("TextButton")
attackButton.Size = UDim2.new(0, 180, 0, 50)
attackButton.Position = UDim2.new(0, 10, 0, 190)
attackButton.Text = "Toggle Auto Attack"
attackButton.Parent = frame

-- Mod Menu Toggles
local autoQuestActive = false
local autoFarmActive = false
local magnetEnemyActive = false
local autoAttackActive = false
local walkSpeed = 16

-- Toggle functions
autoQuestButton.MouseButton1Click:Connect(function()
    autoQuestActive = not autoQuestActive
    print("Auto Quest: " .. tostring(autoQuestActive))
end)

autoFarmButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    print("Auto Farm: " .. tostring(autoFarmActive))
end)

magnetButton.MouseButton1Click:Connect(function()
    magnetEnemyActive = not magnetEnemyActive
    print("Magnet Enemy: " .. tostring(magnetEnemyActive))
end)

attackButton.MouseButton1Click:Connect(function()
    autoAttackActive = not autoAttackActive
    print("Auto Attack: " .. tostring(autoAttackActive))
end)

-- Variables
local questNPCs = {}
local currentQuest = nil
local questCooldown = 2
local attackDistance = 10  -- Maximum distance to attack

-- Function to get all NPCs that give quests
local function getQuestNPCs()
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("QuestGiver") then
            table.insert(questNPCs, npc)
        end
    end
end

-- Function to find the closest quest NPC
local function findClosestQuestNPC()
    local closestNPC = nil
    local shortestDistance = math.huge

    for _, npc in pairs(questNPCs) do
        local npcPosition = npc.HumanoidRootPart.Position
        local distance = (humanoidRootPart.Position - npcPosition).Magnitude
        if distance < shortestDistance then
            closestNPC = npc
            shortestDistance = distance
        end
    end

    return closestNPC
end

-- Function to tween to the quest NPC
local function tweenToQuestNPC(npc)
    local npcPosition = npc.HumanoidRootPart.Position
    local tweenInfo = TweenInfo.new(
        (npcPosition - humanoidRootPart.Position).Magnitude / 50,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local goal = {Position = npcPosition}
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
    tween:Play()

    tween.Completed:Connect(function()
        print("Arrived at quest NPC: " .. npc.Name)
        acceptQuest(npc)
    end)
end

-- Function to accept the quest
local function acceptQuest(npc)
    if npc:FindFirstChild("QuestGiver") then
        print("Accepting quest from NPC: " .. npc.Name)
        currentQuest = npc.QuestGiver.Quest
        print("Current quest: " .. currentQuest.Name)
        startQuestFarming(currentQuest)
    end
end

-- Function to start farming or completing the quest
local function startQuestFarming(quest)
    print("Starting quest farming for: " .. quest.Name)
    local targetEnemy = findClosestEnemy()

    while targetEnemy do
        if targetEnemy then
            if magnetEnemyActive then
                magnetToEnemy(targetEnemy)
            end
            if autoAttackActive then
                attackEnemy(targetEnemy)
            end
        end
        wait(questCooldown)
    end
end

-- Function to find the closest enemy
local function findClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = attackDistance

    for _, enemy in pairs(workspace:GetChildren()) do
        if enemy:FindFirstChild("HumanoidRootPart") and enemy ~= player.Character then
            local enemyPosition = enemy.HumanoidRootPart.Position
            local distance = (humanoidRootPart.Position - enemyPosition).Magnitude
            if distance < shortestDistance then
                closestEnemy = enemy
                shortestDistance = distance
            end
        end
    end

    return closestEnemy
end

-- Function to magnet to the enemy (teleport)
local function magnetToEnemy(enemy)
    local enemyPosition = enemy.HumanoidRootPart.Position
    humanoidRootPart.CFrame = CFrame.new(enemyPosition)  -- Teleport to the enemy

    -- Once we are at the enemy, attack it
    attackEnemy(enemy)
end

-- Function to attack the enemy (example using melee)
local function attackEnemy(enemy)
    local humanoid = enemy:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        print("Attacking enemy: " .. enemy.Name)
        humanoid:TakeDamage(10)  -- Modify the damage as per your needs
    end
end

-- Function to automatically attack when the enemy is nearby
local function autoAttack()
    local targetEnemy = findClosestEnemy()

    while autoAttackActive do
        if targetEnemy then
            if (humanoidRootPart.Position - targetEnemy.HumanoidRootPart.Position).Magnitude < attackDistance then
                attackEnemy(targetEnemy)
            end
        end
        wait(0.1)
    end
end

-- Main Loop: Auto Quest, Magnet to Enemy, Auto Farm
game:GetService("RunService").Heartbeat:Connect(function()
    if autoFarmActive then
        getQuestNPCs()

        -- If Auto Quest is enabled, find and tween to quest NPC
        if autoQuestActive then
            local questNPC = findClosestQuestNPC()
            if questNPC then
                tweenToQuestNPC(questNPC)
            end
        end

        -- If Magnet Enemy is enabled, find the nearest enemy and teleport to it
        if magnetEnemyActive then
            local targetEnemy = findClosestEnemy()
            if targetEnemy then
                magnetToEnemy(targetEnemy)
            end
        end

        -- If Auto Attack is enabled, start attacking the closest enemy
        if autoAttackActive then
            autoAttack()
        end
    end
end)
