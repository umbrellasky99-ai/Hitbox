local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Config = {
    Size = 8,
    Enabled = false,
    Silent = false,
    Visuals = true,
    Color = Color3.fromRGB(0, 140, 255),
    Shape = "Box",
    Transparency = 0.6,
    Hotkey = Enum.KeyCode.RightControl
}

local HitboxStorage = {}
local ActiveConnections = {}

local function GenerateID(length)
    local buffer = {}
    for i = 1, length do
        buffer[i] = string.char(math.random(97, 122))
    end
    return table.concat(buffer)
end

local ContainerID = GenerateID(12)
local StorageUnit = Instance.new("Folder")
StorageUnit.Name = ContainerID
StorageUnit.Parent = Workspace.Terrain or Workspace

local Interface = Instance.new("ScreenGui")
Interface.Name = GenerateID(10)
Interface.Parent = CoreGui
Interface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Interface.ResetOnSpawn = false
Interface.IgnoreGuiInset = true

local MainContainer = Instance.new("Frame")
MainContainer.Name = "Core"
MainContainer.Size = UDim2.new(0, 260, 0, 240)
MainContainer.Position = UDim2.new(0.5, -130, 0.35, 0)
MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainContainer.BorderSizePixel = 0
MainContainer.ClipsDescendants = true
MainContainer.Parent = Interface

local ContainerCorner = Instance.new("UICorner")
ContainerCorner.CornerRadius = UDim.new(0, 8)
ContainerCorner.Parent = MainContainer

local ContainerStroke = Instance.new("UIStroke")
ContainerStroke.Color = Color3.fromRGB(35, 35, 40)
ContainerStroke.Thickness = 1
ContainerStroke.Parent = MainContainer

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundTransparency = 1
Header.Parent = MainContainer

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "<font color=\"rgb(230,230,230)\">HITBOX</font> <font color=\"rgb(0,140,255)\">ULTRA</font>"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.RichText = true
Title.Parent = Header

local EmergencyButton = Instance.new("TextButton")
EmergencyButton.Size = UDim2.new(0, 32, 0, 32)
EmergencyButton.Position = UDim2.new(1, -34, 0, 0)
EmergencyButton.BackgroundTransparency = 1
EmergencyButton.Text = "×"
EmergencyButton.TextColor3 = Color3.fromRGB(220, 60, 60)
EmergencyButton.TextSize = 22
EmergencyButton.Font = Enum.Font.GothamBold
EmergencyButton.Parent = Header

local DragActive, DragInput, DragOrigin, FrameOrigin
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        DragActive = true
        DragOrigin = input.Position
        FrameOrigin = MainContainer.Position
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and DragActive then
        local delta = input.Position - DragOrigin
        TweenService:Create(MainContainer, TweenInfo.new(0.05), {
            Position = UDim2.new(FrameOrigin.X.Scale, FrameOrigin.X.Offset + delta.X, FrameOrigin.Y.Scale, FrameOrigin.Y.Offset + delta.Y)
        }):Play()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        DragActive = false
    end
end)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -42)
Content.Position = UDim2.new(0, 10, 0, 37)
Content.BackgroundTransparency = 1
Content.Parent = MainContainer

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 6)
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = Content

local function BuildElement(class, properties, parent)
    local element = Instance.new(class)
    for property, value in pairs(properties) do
        element[property] = value
    end
    element.Parent = parent
    return element
end

local SizeControl = BuildElement("TextBox", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    Text = "8",
    PlaceholderText = "Hitbox Size",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    LayoutOrder = 1
}, Content)

BuildElement("UICorner", {CornerRadius = UDim.new(0, 6)}, SizeControl)

SizeControl.FocusLost:Connect(function()
    local value = tonumber(SizeControl.Text)
    if value then
        Config.Size = math.clamp(value, 1, 50)
        SizeControl.Text = tostring(Config.Size)
    else
        SizeControl.Text = tostring(Config.Size)
    end
end)

local function CreateSwitch(label, initialState, order, callback)
    local Switch = BuildElement("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(22, 22, 26),
        Text = label,
        TextColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = false,
        LayoutOrder = order
    }, Content)
    
    local SwitchStroke = BuildElement("UIStroke", {
        Color = Color3.fromRGB(40, 40, 45),
        Thickness = 1
    }, Switch)
    
    BuildElement("UICorner", {CornerRadius = UDim.new(0, 6)}, Switch)
    
    local State = initialState
    local function UpdateAppearance()
        local targetColor = State and Config.Color or Color3.fromRGB(22, 22, 26)
        local targetText = State and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        
        TweenService:Create(SwitchStroke, TweenInfo.new(0.2), {Color = targetColor}):Play()
        TweenService:Create(Switch, TweenInfo.new(0.2), {TextColor3 = targetText}):Play()
    end
    
    UpdateAppearance()
    
    Switch.MouseButton1Click:Connect(function()
        State = not State
        UpdateAppearance()
        callback(State)
    end)
    
    return Switch, State
end

local EnableSwitch = CreateSwitch("Active", false, 2, function(state)
    Config.Enabled = state
    if not state then
        for _, data in pairs(HitboxStorage) do
            if data.Part then data.Part:Destroy() end
        end
        HitboxStorage = {}
    end
end)

local VisualSwitch = CreateSwitch("Visible", true, 3, function(state)
    Config.Visuals = state
end)

local StealthSwitch = CreateSwitch("Stealth Mode", false, 4, function(state)
    Config.Silent = state
end)

local ShapeSelector = BuildElement("TextBox", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    Text = "Box",
    PlaceholderText = "Shape (Box/Sphere/Cylinder)",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    LayoutOrder = 5
}, Content)

BuildElement("UICorner", {CornerRadius = UDim.new(0, 6)}, ShapeSelector)

ShapeSelector.FocusLost:Connect(function()
    local shape = ShapeSelector.Text:lower()
    if shape == "box" or shape == "sphere" or shape == "cylinder" then
        Config.Shape = shape:sub(1,1):upper() .. shape:sub(2)
        ShapeSelector.Text = Config.Shape
    else
        ShapeSelector.Text = Config.Shape
    end
end)

EmergencyButton.MouseButton1Click:Connect(function()
    for _, conn in pairs(ActiveConnections) do
        pcall(function() conn:Disconnect() end)
    end
    
    for _, data in pairs(HitboxStorage) do
        pcall(function() data.Part:Destroy() end)
    end
    
    pcall(function() StorageUnit:Destroy() end)
    pcall(function() Interface:Destroy() end)
end)

local function BuildHitbox(player)
    if HitboxStorage[player] then
        if HitboxStorage[player].Part and HitboxStorage[player].Part.Parent then
            return HitboxStorage[player]
        end
    end
    
    local hitbox = Instance.new("Part")
    hitbox.Name = GenerateID(6)
    hitbox.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    hitbox.Transparency = Config.Silent and 1 or (Config.Visuals and Config.Transparency or 1)
    hitbox.CanCollide = false
    hitbox.CanTouch = false
    hitbox.CanQuery = false
    hitbox.CastShadow = false
    hitbox.Massless = true
    hitbox.Material = Enum.Material.SmoothPlastic
    hitbox.Color = Config.Color
    hitbox.Anchored = false
    hitbox.Parent = StorageUnit
    
    if Config.Shape == "Sphere" then
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = hitbox
    elseif Config.Shape == "Cylinder" then
        local mesh = Instance.new("CylinderMesh")
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = hitbox
    end
    
    local positioner = Instance.new("BodyPosition")
    positioner.MaxForce = Vector3.new(40000, 40000, 40000)
    positioner.P = 12000
    positioner.D = 800
    positioner.Parent = hitbox
    
    local rotator = Instance.new("BodyGyro")
    rotator.MaxTorque = Vector3.new(40000, 40000, 40000)
    rotator.P = 5000
    rotator.D = 500
    rotator.Parent = hitbox
    
    HitboxStorage[player] = {
        Part = hitbox,
        Positioner = positioner,
        Rotator = rotator,
        LastUpdate = tick()
    }
    
    return HitboxStorage[player]
end

local function UpdateHitbox(player, data)
    if not data or not data.Part then return end
    
    local character = player.Character
    if not character then
        data.Part:Destroy()
        HitboxStorage[player] = nil
        return
    end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        data.Part:Destroy()
        HitboxStorage[player] = nil
        return
    end
    
    local currentTime = tick()
    if currentTime - data.LastUpdate < 0.016 then return end
    data.LastUpdate = currentTime
    
    if data.Part.Size.X ~= Config.Size then
        data.Part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    end
    
    if Config.Silent then
        data.Part.Transparency = 1
    else
        data.Part.Transparency = Config.Visuals and Config.Transparency or 1
    end
    
    data.Positioner.Position = root.Position
    data.Rotator.CFrame = root.CFrame
end

ActiveConnections.Heartbeat = RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local data = BuildHitbox(player)
            UpdateHitbox(player, data)
        else
            if HitboxStorage[player] then
                HitboxStorage[player].Part:Destroy()
                HitboxStorage[player] = nil
            end
        end
    end
end)

ActiveConnections.PlayerRemoved = Players.PlayerRemoving:Connect(function(player)
    if HitboxStorage[player] then
        HitboxStorage[player].Part:Destroy()
        HitboxStorage[player] = nil
    end
end)

ActiveConnections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Config.Hotkey then
        Config.Enabled = not Config.Enabled
    elseif input.KeyCode == Enum.KeyCode.Print then
        Interface.Enabled = false
        task.wait(0.5)
        Interface.Enabled = true
    end
end)

task.spawn(function()
    while task.wait(10) do
        for player, data in pairs(HitboxStorage) do
            if not Players:FindFirstChild(player.Name) then
                data.Part:Destroy()
                HitboxStorage[player] = nil
            end
        end
    end
end)

local Success, Error = pcall(function()
    if not Workspace:FindFirstChild(ContainerID) then
        StorageUnit.Parent = Workspace
    end
end)

if not Success then
    StorageUnit.Parent = Workspace
end

Interface.DisplayOrder = 999
UserInputService.MouseIconEnabled = true
