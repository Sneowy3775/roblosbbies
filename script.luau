local globalenv = getgenv and getgenv() or _G or shared
if globalenv and (globalenv.MDH_BB and not globalenv.MDH_DEBUG) then
    print("MDH BOOBIES IS ALREADY RUNNING")
    return
elseif globalenv then
    globalenv.MDH_BB = true
else
    print("GLOBAL ENVIRONMENTS FAILED (GETGENV / _G / SHARED)")
end

local function Load(Source, DebugName, ...)
    return loadstring(game:HttpGet(Source, true), DebugName)(...)
end

local Settings = {
    Breast = true,
    BreastSize = 1,
    Cheeks = true,
    CheeksSize = 1,
    Collisions = false,
    Simulate_Physics_On_LocalPlayer_Only = true,
    ForceAllRigs = false,
    Only_Others = false
}

local SpringClass = Load("https://gist.githubusercontent.com/insuretya/764f09a420c28447cc79006da83d1076/raw/fd615feec7a68c34c3a7f51caa8a63fde6580983/whenyou.lua", "Spring")

local FemaleRig = Load("https://gist.githubusercontent.com/insuretya/f857c06ec25da62f2de71da9f46aae51/raw/3cf687eef2b2d0e44e771cb0252e2f85348261fb/yomamasofat.lua", "FemaleRig", Settings.Collisions)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    Players.ChildAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local function Weld(p0, p1)
    local weld = Instance.new("Weld")
    weld.Parent = p0
    weld.Part0 = p0
    weld.Part1 = p1
    weld.C0 = CFrame.new()
    weld.C1 = CFrame.new()
    return weld
end

local function ApplyRig(Model, R6)
    print("Applying rig...")
    local NewModel = FemaleRig:Clone()

    local Parts = {}
    if R6 then
        Parts.Torso = Model:WaitForChild("Torso", math.huge)
        Parts.RightLeg = Model:WaitForChild("Right Leg", math.huge)
        Parts.LeftLeg = Model:WaitForChild("Left Leg", math.huge)
    else
        Parts.Torso = Model:WaitForChild("UpperTorso", math.huge)
        Parts.RightLeg = Model:WaitForChild("RightUpperLeg", math.huge)
        Parts.LeftLeg = Model:WaitForChild("LeftUpperLeg", math.huge)
    end

    -- Weld legs from FemaleRig to original legs
    for _, legPart in ipairs(NewModel.R:GetChildren()) do
        if legPart:IsA("BasePart") then
            Weld(legPart, Parts.RightLeg)
        end
    end
    for _, legPart in ipairs(NewModel.L:GetChildren()) do
        if legPart:IsA("BasePart") then
            Weld(legPart, Parts.LeftLeg)
        end
    end

    -- Hide new torso rig's torso completely (we keep original torso visible)
    if NewModel.T.Torso then
        NewModel.T.Torso.Transparency = 1
    end

    -- Keep original torso and legs visible
    Parts.Torso.Transparency = 0
    Parts.RightLeg.Transparency = 0
    Parts.LeftLeg.Transparency = 0

    -- Setup jiggle joints from FemaleRig torso if possible
    local BJJ = nil
    local BJ = nil
    if NewModel.T.Torso then
        if NewModel.T.Torso:FindFirstChild("BUJ") then
            BJJ = NewModel.T.Torso.BUJ:FindFirstChild("BJJ")
        end
        if NewModel.T.Torso:FindFirstChild("BTJ") then
            BJ = NewModel.T.Torso.BTJ:FindFirstChild("BJ")
        end
    end

    NewModel.Parent = nil -- don't parent to Model, keep invisible

    return {
        Torso = Parts.Torso,
        RightLeg = Parts.RightLeg,
        LeftLeg = Parts.LeftLeg,
        BJJ = BJJ,
        BJ = BJ,
    }
end

local function JigglePhysics(NewParts)
    print("Starting jiggle physics...")
    local Torso = NewParts.Torso
    local A = NewParts.BJ
    local SJ = NewParts.BJJ

    if not A or not SJ then
        warn("Missing jiggle joints, skipping jiggle physics")
        return
    end

    local OGC0 = SJ.C0
    local OGC02 = A.C0
    local OGY = Torso.Position.Y

    local breastScale = math.clamp(Settings.BreastSize, 0, 3)

    local BRSTSpring = SpringClass.new()
    BRSTSpring.Target = 5 * breastScale
    BRSTSpring.Speed = 10
    BRSTSpring.Damper = 0.2

    local BTTSpring = SpringClass.new()
    BTTSpring.Target = 3 * breastScale
    BTTSpring.Speed = 10
    BTTSpring.Damper = 0.1

    RunService.Stepped:Connect(function(_, deltatime)
        task.spawn(function()
            if LocalPlayer and LocalPlayer.Character and workspace.CurrentCamera then
                local Camera = workspace.CurrentCamera
                local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                if HRP and (HRP.Position - Camera.CFrame.Position).Magnitude < 50 then
                    local CURRY = Torso.Position.Y
                    local Calculated = OGY - CURRY
                    OGY = CURRY
                    BRSTSpring:TimeSkip(deltatime)
                    BRSTSpring:Impulse(Calculated)

                    BTTSpring:TimeSkip(deltatime)
                    BTTSpring:Impulse(Calculated)

                    SJ.C0 = OGC0 * CFrame.new(0, -0.02 * (BRSTSpring.Velocity / 10), 0)
                        * CFrame.Angles(-10 * math.rad(BRSTSpring.Velocity), 0, 0)
                    A.C0 = OGC02 * CFrame.new(0, -0.05 * (BTTSpring.Velocity / 10), 0)
                        * CFrame.Angles(2 * math.rad(BTTSpring.Velocity), 0, 0)
                end
            end
        end)
    end)
end

local function VerifyRigAndApply(instance, ApplyPhysics)
    print("VerifyRigAndApply called")
    task.spawn(function()
        if instance:IsA("Model") then
            local Humanoid
            repeat
                Humanoid = instance:FindFirstChildWhichIsA("Humanoid")
                if not Humanoid then
                    task.wait()
                end
            until Humanoid

            if not Settings.ForceAllRigs and instance:FindFirstChild("CustomRig") then
                print("CustomRig found, skipping")
                return
            end

            local NewParts = ApplyRig(instance, Humanoid.RigType == Enum.HumanoidRigType.R6)
            print("ApplyRig returned")

            if ApplyPhysics then
                JigglePhysics(NewParts)
            end
        end
    end)
end

local function AttachToLocalCharacter(character)
    print("Attaching to character...")
    VerifyRigAndApply(character, true)
end

if LocalPlayer.Character then
    AttachToLocalCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(AttachToLocalCharacter)
