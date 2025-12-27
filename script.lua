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
    Transparency = 0.6
}

local HitboxStorage = {}
local ActiveConnections = {}

local function GenerateID(length)
    local buffer = {}
    for i = 1, length do buffer[i] = string.char(math.random(97, 122)) end
    return table.concat(buffer)
end

local StorageUnit = Instance.new("Folder", Workspace.Terrain or Workspace)
StorageUnit.Name = GenerateID(12)

local Interface = Instance.new("ScreenGui", CoreGui)
Interface.Name = GenerateID(10)
Interface.ResetOnSpawn = false

-- Создаем иконку для разворачивания (свернутое состояние)
local MinimizedBtn = Instance.new("TextButton")
MinimizedBtn.Size = UDim2.new(0, 45, 0, 45)
MinimizedBtn.Position = UDim2.new(0, 10, 0.5, -22)
MinimizedBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MinimizedBtn.Text = "H"
MinimizedBtn.TextColor3 = Config.Color
MinimizedBtn.Font = Enum.Font.GothamBold
MinimizedBtn.TextSize = 20
MinimizedBtn.Visible = false
MinimizedBtn.Parent = Interface
Instance.new("UICorner", MinimizedBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MinimizedBtn).Color = Color3.fromRGB(40, 40, 45)

local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0, 260, 0, 250)
MainContainer.Position = UDim2.new(0.5, -130, 0.35, 0)
MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainContainer.BorderSizePixel = 0
MainContainer.ClipsDescendants = false
MainContainer.Parent = Interface
Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainContainer)
MainStroke.Color = Color3.fromRGB(35, 35, 40)

-- Система перетаскивания (Touch/Mouse)
local Dragging, DragInput, DragStart, StartPos
local function UpdateDrag(input)
    local delta = input.Position - DragStart
    MainContainer.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
end

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundTransparency = 1
Header.Parent = MainContainer

Header.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        Dragging = true
        DragStart = input.Position
        StartPos = MainContainer.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then UpdateDrag(input) end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "HITBOX <font color='rgb(0,140,255)'>ULTRA</font>"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.RichText = true
Title.TextXAlignment = "Left"
Title.Parent = Header

-- Кнопки управления (Свернуть / Закрыть)
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -34, 0, 2)
CloseBtn.Text = "×"; CloseBtn.TextColor3 = Color3.fromRGB(220, 60, 60); CloseBtn.BackgroundTransparency = 1; CloseBtn.TextSize = 22

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -66, 0, 2)
MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MinBtn.BackgroundTransparency = 1; MinBtn.TextSize = 20

MinBtn.MouseButton1Click:Connect(function()
    MainContainer.Visible = false
    MinimizedBtn.Visible = true
end)

MinimizedBtn.MouseButton1Click:Connect(function()
    MainContainer.Visible = true
    MinimizedBtn.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(ActiveConnections) do c:Disconnect() end
    for _, d in pairs(HitboxStorage) do if d.Part then d.Part:Destroy() end end
    StorageUnit:Destroy()
    Interface:Destroy()
end)

local Content = Instance.new("Frame", MainContainer)
Content.Size = UDim2.new(1, -20, 1, -45)
Content.Position = UDim2.new(0, 10, 0, 40)
Content.BackgroundTransparency = 1
local List = Instance.new("UIListLayout", Content)
List.Padding = UDim.new(0, 6)

local function CreateSwitch(text, state, callback)
    local btn = Instance.new("TextButton", Content)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    btn.Text = text
    btn.TextColor3 = state and Color3.new(1,1,1) or Color3.fromRGB(150,150,150)
    btn.Font = "GothamMedium"; btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", btn)
    s.Color = state and Config.Color or Color3.fromRGB(40,40,45)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        s.Color = state and Config.Color or Color3.fromRGB(40,40,45)
        btn.TextColor3 = state and Color3.new(1,1,1) or Color3.fromRGB(150,150,150)
        callback(state)
    end)
end

-- Размер хитбокса
local SizeBox = Instance.new("TextBox", Content)
SizeBox.Size = UDim2.new(1, 0, 0, 32)
SizeBox.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
SizeBox.Text = tostring(Config.Size)
SizeBox.PlaceholderText = "Hitbox Size"
SizeBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0, 6)
SizeBox.FocusLost:Connect(function()
    Config.Size = tonumber(SizeBox.Text) or Config.Size
    SizeBox.Text = tostring(Config.Size)
end)

CreateSwitch("Active", false, function(v) Config.Enabled = v end)
CreateSwitch("Visible", true, function(v) Config.Visuals = v end)
CreateSwitch("Stealth Mode", false, function(v) Config.Silent = v end)

-- Выпадающее меню Shape
local ShapeBtn = Instance.new("TextButton", Content)
ShapeBtn.Size = UDim2.new(1, 0, 0, 32)
ShapeBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
ShapeBtn.Text = "Shape: " .. Config.Shape
ShapeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", ShapeBtn).CornerRadius = UDim.new(0, 6)

local ShapeFrame = Instance.new("Frame", Interface)
ShapeFrame.Size = UDim2.new(0, 120, 0, 100)
ShapeFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ShapeFrame.Visible = false
Instance.new("UICorner", ShapeFrame)
Instance.new("UIStroke", ShapeFrame).Color = Config.Color

local function CreateShapeOpt(name)
    local b = Instance.new("TextButton", ShapeFrame)
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundTransparency = 1
    b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamMedium"
    b.MouseButton1Click:Connect(function()
        Config.Shape = name
        ShapeBtn.Text = "Shape: " .. name
        ShapeFrame.Visible = false
    end)
end

Instance.new("UIListLayout", ShapeFrame)
CreateShapeOpt("Box"); CreateShapeOpt("Sphere"); CreateShapeOpt("Cylinder")

ShapeBtn.MouseButton1Click:Connect(function()
    ShapeFrame.Visible = not ShapeFrame.Visible
    ShapeFrame.Position = UDim2.new(0, ShapeBtn.AbsolutePosition.X + MainContainer.AbsolutePosition.X, 0, ShapeBtn.AbsolutePosition.Y + 70)
end)

-- Сама работа хитбоксов
local function BuildHitbox(player)
    local hb = Instance.new("Part", StorageUnit)
    hb.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
    hb.CanCollide = false; hb.CastShadow = false; hb.Massless = true
    hb.Color = Config.Color; hb.Material = "SmoothPlastic"
    
    if Config.Shape == "Sphere" then
        local m = Instance.new("SpecialMesh", hb); m.MeshType = "Sphere"
    elseif Config.Shape == "Cylinder" then
        Instance.new("CylinderMesh", hb)
    end

    local bp = Instance.new("BodyPosition", hb)
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bp.P = 15000
    local bg = Instance.new("BodyGyro", hb)
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

    HitboxStorage[player] = {Part = hb, BP = bp, BG = bg}
    return HitboxStorage[player]
end

ActiveConnections.Heartbeat = RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local data = HitboxStorage[p] or BuildHitbox(p)
            local root = p.Character.HumanoidRootPart
            data.Part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
            data.Part.Transparency = Config.Silent and 1 or (Config.Visuals and Config.Transparency or 1)
            data.BP.Position = root.Position
            data.BG.CFrame = root.CFrame
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if HitboxStorage[p] then HitboxStorage[p].Part:Destroy(); HitboxStorage[p] = nil end
end)
