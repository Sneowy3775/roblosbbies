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

local finder, globalcontainer =
	Load("https://gist.githubusercontent.com/insuretya/a2823e13aa750cc02d70b8d6e2bc9f34/raw/98d1994486ae749a1a88e1a16e4035cbe6a3f02d/UniversalMethodFinder.lua", "UniversalMethodFinder")

finder({
	quetp = '(...):find("queue") and (...):find("tele") and not ((...):find("run") or (...):find("script"))',
	protgui = '(...):find("protect") and (...):find("gui") and not (...):find("un")',
})

if globalcontainer.quetp then
	local players = game:GetService("Players")
	local client = players.LocalPlayer
	while not client do
		players.ChildAdded:Wait()
		client = players.LocalPlayer
	end
	client.OnTeleport:Connect(function(State)
		globalcontainer.quetp(
			'loadstring(game:HttpGet("https://gist.githubusercontent.com/htt-py/92db22eeefad0042a6da9117501ad827/raw/BBies.luau", true))()'
		)
	end)
end

local Settings = {
    Breast = true,
    BreastSize = 1,  -- scale 0 to ~3
    Cheeks = true,
    CheeksSize = 1,  -- scale 0 to ~3
    Collisions = false,
    Simulate_Physics_On_LocalPlayer_Only = true,
    ForceAllRigs = false,
    Only_Others = false
}

local SpringClass = Load(
	"https://gist.githubusercontent.com/insuretya/764f09a420c28447cc79006da83d1076/raw/fd615feec7a68c34c3a7f51caa8a63fde6580983/whenyou.lua",
	"Spring"
)

local FemaleRig = Load(
	"https://gist.githubusercontent.com/insuretya/f857c06ec25da62f2de71da9f46aae51/raw/3cf687eef2b2d0e44e771cb0252e2f85348261fb/yomamasofat.lua",
	"FemaleRig",
	Settings.Collisions
)

local function RandomString()
	local randomarray = {}
	for i = 1, math.random(10, 20) do
		randomarray[i] = string.char(math.random(32, 126))
	end
	return table.concat(randomarray)
end

local function Protect(instance)
	instance.Name = RandomString()
	for _, desc in ipairs(instance:GetDescendants()) do
		desc.Name = RandomString()
	end

	if globalcontainer.protgui and not (is_sirhurt_closure or (syn and DrawingImmediate)) then
		globalcontainer.protgui(instance)
	end
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

local function DressUp(Model, NewModel)
	local Shirt, Pants = Model:FindFirstChildOfClass("Shirt"), Model:FindFirstChildOfClass("Pants")
	Shirt = Shirt and Shirt.ShirtTemplate
	Pants = Pants and Pants.PantsTemplate

	for _, desc in ipairs(NewModel:GetDescendants()) do
		if desc:IsA("Decal") then
			desc.Texture = (desc.Name == "Shirt" and Shirt or desc.Name == "Pants" and Pants or "")
		end
	end
end

local function ApplyRig(Model, R6)
	local NewModel = FemaleRig:Clone()
	local NewParts = {
		Torso = NewModel.T.Torso,
		RightLeg = NewModel.R["Right Leg"],
		LeftLeg = NewModel.L["Left Leg"],
	}
	local Parts = {}
	if R6 then
		Parts.Torso = "Torso"
		Parts.RightLeg = "Right Leg"
		Parts.LeftLeg = "Left Leg"
	else
		Parts.Torso = "UpperTorso"
		Parts.RightLeg = "RightUpperLeg"
		Parts.LeftLeg = "LeftUpperLeg"
	end

	Parts.Torso = Model:WaitForChild(Parts.Torso, math.huge)
	Parts.RightLeg = Model:WaitForChild(Parts.RightLeg, math.huge)
	Parts.LeftLeg = Model:WaitForChild(Parts.LeftLeg, math.huge)

	NewParts.Torso.Color = Parts.Torso.Color
	NewParts.Torso.Part.BRSTVisual.Color = Parts.Torso.Color
	NewParts.Torso.Model.RightCHK.Color = Parts.RightLeg.Color
	NewParts.Torso.Model.LeftCHK.Color = Parts.LeftLeg.Color

	-- Correct scaling using Mesh.Scale or MeshPart.Size
	if Settings.Breast and NewParts.Torso.Part and NewParts.Torso.Part.BRSTVisual then
		local scale = math.clamp(Settings.BreastSize, 0, 3)
		local brstVisual = NewParts.Torso.Part.BRSTVisual
		if brstVisual:IsA("MeshPart") then
			brstVisual.Size = Vector3.new(1, 1, 1) * scale
		else
			local mesh = brstVisual:FindFirstChildWhichIsA("SpecialMesh") or brstVisual:FindFirstChildWhichIsA("Mesh")
			if mesh then
				mesh.Scale = Vector3.new(1, 1, 1) * scale
			else
				brstVisual.Size = Vector3.new(1, 1, 1) * scale
			end
		end
		brstVisual.Transparency = 0 -- breasts visible
	end

	if Settings.Cheeks then
		local scaleCheeks = math.clamp(Settings.CheeksSize, 0, 3)
		local function scalePart(part)
			if part then
				if part:IsA("MeshPart") then
					part.Size = Vector3.new(1, 1, 1) * scaleCheeks
				else
					local mesh = part:FindFirstChildWhichIsA("SpecialMesh") or part:FindFirstChildWhichIsA("Mesh")
					if mesh then
						mesh.Scale = Vector3.new(1, 1, 1) * scaleCheeks
					else
						part.Size = Vector3.new(1, 1, 1) * scaleCheeks
					end
				end
				part.Transparency = 1 -- cheeks invisible
			end
		end
		scalePart(NewParts.Torso.Model.RightCHK)
		scalePart(NewParts.Torso.Model.LeftCHK)
	end

	if R6 then
		NewParts.RightLeg.Color = Parts.RightLeg.Color
		NewParts.LeftLeg.Color = Parts.LeftLeg.Color
		NewParts.RightLeg = NewModel.R
		NewParts.LeftLeg = NewModel.L
	else
		NewParts.RightLeg = nil
		NewParts.LeftLeg = nil
	end

	NewParts.Torso = NewModel.T
	DressUp(Model, NewModel)

	Model.ChildAdded:Connect(function(child)
		if child:IsA("Clothing") then
			DressUp(Model, NewModel)
		end
	end)

	for name, part in next, NewParts do
		Weld(part, Parts[name])
		if name == "RightLeg" or name == "LeftLeg" then
			Parts[name].Transparency = 0 -- legs visible
		elseif name == "Torso" then
			Parts[name].Transparency = 0 -- original torso visible
			part.Transparency = 1 -- new rig torso invisible
		else
			Parts[name].Transparency = 0 -- breasts visible
		end
	end

	NewParts.BJJ = NewParts.Torso.Torso.BUJ.BJJ
	NewParts.BJ = NewParts.Torso.Torso.BTJ.BJ
	Protect(NewModel)
	NewModel.Parent = Model
	return NewParts
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
	Players.ChildAdded:Wait()
	LocalPlayer = Players.LocalPlayer
end

local function JigglePhysics(NewParts)
	local Torso = NewParts.Torso
	local A = NewParts.BJ
	local SJ = NewParts.BJJ
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
				return
			end

			local NewParts = ApplyRig(instance, Humanoid.RigType == Enum.HumanoidRigType.R6)

			if ApplyPhysics then
				JigglePhysics(NewParts)
			end
		end
	end)
end

local function AttachToLocalCharacter(character)
	VerifyRigAndApply(character, true)
end

if LocalPlayer.Character then
	AttachToLocalCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(AttachToLocalCharacter)
