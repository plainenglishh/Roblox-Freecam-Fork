------------------------------------------------
--
-- Freecam.lua
-- Written by: Fractality
-- Edited by: TheGamer101, to make it work without the screen gui, remove the Class library
-- and add alternative key bindings.
------------------------------------------------

-- To exit and enter free camera, use key shortcut Left Shift + P

local player = game:GetService("Players")
while not player.LocalPlayer do player.Changed:wait() end
player = player.LocalPlayer
local camera = workspace.CurrentCamera

local RS  = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")


local Spring = {}
Spring.__index = Spring

-- Fort Bragg

function BraggToggle()
	if game.GameId == 2772166173 then
        _G.Toggle = _G.Toggle or 1;

        local Players = game:GetService("Players");
        local Notif = require(Players.LocalPlayer.Character["C:Main"].Util.CreateNotification)

        local Enabled = false;

        if _G.Toggle == 1 then
            _G.Toggle = 0;
            Enabled = false;
            Notif("Success", "Disabled name plates!");
        else
            _G.Toggle = 1;
            Enabled = true;
            Notif("Success", "Enabled name plates!");
        end

        for _, Player in pairs(Players:GetPlayers()) do
            if Player.Character then
                for _, NP in pairs(Player.Character:GetChildren()) do
                    if NP.Name == "Nameplate" then
                        NP.Enabled = Enabled;
                    end
                end
            end
        end
	end
end

function Spring:Update(dt)
	local t, k, d, x0, v0 = self.t, self.k, self.d, self.x, self.v
	local a0 = k*(t - x0) + v0*d
	local v1 = v0 + a0*(dt/2)
	local a1 = k*(t - (x0 + v0*(dt/2))) + v1*d
	local v2 = v0 + a1*(dt/2)
	local a2 = k*(t - (x0 + v1*(dt/2))) + v2*d
	local v3 = v0 + a2*dt
	local x4 = x0 + (v0 + 2*(v1 + v2) + v3)*(dt/6)
	self.x, self.v = x4, v0 + (a0 + 2*(a1 + a2) + k*(t - (x0 + v2*dt)) + v3*d)*(dt/6)
	return x4
end

function Spring.new(stiffness, dampingCoeff, dampingRatio, initialPos)
	local self = setmetatable({}, Spring)

	dampingRatio = dampingRatio or 1
	local m = dampingCoeff*dampingCoeff/(4*stiffness*dampingRatio*dampingRatio)
	self.k = stiffness/m
	self.d = -dampingCoeff/m
	self.x = initialPos
	self.t = initialPos
	self.v = initialPos*0

	return self
end

-- Maid class

local destructors = {
	['function'] = function(item)
		item()
	end;
	['RBXScriptConnection'] = function(item)
		item:Disconnect()
	end;
	['Instance'] = function(item)
		item:Destroy()
	end;
}

local Maidx = {}
Maidx.__index = Maidx

function Maidx:Mark(item)
	if destructors[typeof(item)] then
		self.trash[#self.trash + 1] = item
	else
		error(('Maid does not support type "%s"'):format(typeof(item)), 2)
	end
end

function Maidx:Unmark(item)
	if item then
		local trash = self.trash
		for i = 1, #trash do
			if trash[i] == item then
				table.remove(trash, i)
				break
			end
		end
	else
		self.trash = {}
	end
end

function Maidx:Sweep()
	local trash = self.trash
	for i = 1, #trash do
		local item = trash[i]
		destructors[typeof(item)](item)
	end
	self.trash = {}
end

function Maidx.new()
	local self = setmetatable({}, Maidx)
	self.trash = {}
	return self
end

Maid = Maidx.new()

local WasGuiVisible = {}
function ToggleGui(on)
	if not on then
		WasGuiVisible["PointsNotificationsActive"] = StarterGui:GetCore("PointsNotificationsActive")
		WasGuiVisible["BadgesNotificationsActive"] = StarterGui:GetCore("BadgesNotificationsActive")
		WasGuiVisible["Health"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		WasGuiVisible["Backpack"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		WasGuiVisible["PlayerList"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		WasGuiVisible["Chat"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
	end

	local function GuiOn(name)
		if on == false then
			return false
		end
		if WasGuiVisible[name] ~= nil then
			return WasGuiVisible[name]
		end
		return true
	end

	StarterGui:SetCore("PointsNotificationsActive", GuiOn("PointsNotificationsActive"))
	StarterGui:SetCore("BadgesNotificationsActive", GuiOn("BadgesNotificationsActive"))

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, GuiOn("Health"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, GuiOn("Backpack"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, GuiOn("PlayerList"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, GuiOn("Chat"))
end

------------------------------------------------

local DEF_FOV = 70
local NM_ZOOM = math.tan(DEF_FOV * math.pi/360)
local LVEL_GAIN = Vector3.new(1, 0.75, 1)
local RVEL_GAIN = Vector2.new(0.85, 1)/128
local FVEL_GAIN = -330
local DEADZONE = 0.125
local FOCUS_OFFSET = CFrame.new(0, 0, -16)

local DIRECTION_LEFT = 1
local DIRECTION_RIGHT = 2
local DIRECTION_FORWARD = 3
local DIRECTION_BACKWARD = 4
local DIRECTION_UP = 5
local DIRECTION_DOWN = 6

local KEY_MAPPINGS = {
	[DIRECTION_LEFT] = {Enum.KeyCode.A, Enum.KeyCode.H},
	[DIRECTION_RIGHT] = {Enum.KeyCode.D, Enum.KeyCode.K},
	[DIRECTION_FORWARD] = {Enum.KeyCode.W, Enum.KeyCode.U},
	[DIRECTION_BACKWARD] = {Enum.KeyCode.S, Enum.KeyCode.J},
	[DIRECTION_UP] = {Enum.KeyCode.E, Enum.KeyCode.I},
	[DIRECTION_DOWN] = {Enum.KeyCode.Q, Enum.KeyCode.Y},
}

function CreateLetterBox()
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Position = UDim2.new(0, 0, 0, -36)
	topBar.Size = UDim2.new(1, 0, 0.128, 0)
	topBar.ZIndex = 10
	topBar.BackgroundColor3 = Color3.new(0, 0, 0)
	topBar.BorderSizePixel = 0
	topBar.Parent = script.Parent

	local bottomBar = topBar:Clone()
	bottomBar.Name = "BottomBar"
	bottomBar.Position = UDim2.new(0, 0, 1, 0)
	bottomBar.AnchorPoint = Vector2.new(0, 1)
	bottomBar.Parent = script.Parent
	return script.Parent
end

------------------------------------------------

local screenGuis = {}
local freeCamEnabled = false
--local letterBoxEnabled = true

local stateRot = Vector2.new()
local panDeltaGamepad = Vector2.new()
local panDeltaMouse = Vector2.new()

local velSpring = Spring.new(7/9, 1/3, 1, Vector3.new())
local rotSpring = Spring.new(7/9, 1/3, 1, Vector2.new())
local fovSpring = Spring.new(2,   1/3, 1, 0)

--local letterbox = CreateLetterBox()

local gp_x  = 0
local gp_z  = 0
local gp_l1 = 0
local gp_r1 = 0
local rate_fov = 0

local SpeedModifier = 1

------------------------------------------------

local function Clamp(x, min, max)
	return x < min and min or x > max and max or x
end

local function GetChar()
	local character = player.Character
	if character then
		return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
	end
end

local function InputCurve(x)
	local s = math.abs(x)
	if s > DEADZONE then
		s = 0.255000975*(2^(2.299113817*s) - 1)
		return x > 0 and (s > 1 and 1 or s) or (s > 1 and -1 or -s)
	end
	return 0
end

------------------------------------------------

local function ProcessInput(input, processed)
	local userInputType = input.UserInputType
	if userInputType == Enum.UserInputType.Gamepad1 then
		local keycode = input.KeyCode
		if keycode == Enum.KeyCode.Thumbstick2 then
			local pos = input.Position
			panDeltaGamepad = Vector2.new(InputCurve(pos.y), InputCurve(-pos.x))*7
		elseif keycode == Enum.KeyCode.Thumbstick1 then
			local pos = input.Position
			gp_x = InputCurve(pos.x)
			gp_z = InputCurve(-pos.y)
		elseif keycode == Enum.KeyCode.ButtonL2 then
			gp_l1 = input.Position.z
		elseif keycode == Enum.KeyCode.ButtonR2 then
			gp_r1 = input.Position.z
		end
	elseif userInputType == Enum.UserInputType.MouseWheel then
		rate_fov = input.Position.Z
	end
end

UIS.InputChanged:Connect(ProcessInput)
UIS.InputEnded:Connect(ProcessInput)
UIS.InputBegan:Connect(ProcessInput)

------------------------------------------------

local function IsDirectionDown(direction)
	for i = 1, #KEY_MAPPINGS[direction] do
		if UIS:IsKeyDown(KEY_MAPPINGS[direction][i]) then
			return true
		end
	end
	return false
end

local UpdateFreecam do
	local dt = 1/60
	RS.RenderStepped:Connect(function(_dt)
		dt = _dt
	end)

	function UpdateFreecam()
		local camCFrame = camera.CFrame

		local kx = (IsDirectionDown(DIRECTION_RIGHT) and 1 or 0) - (IsDirectionDown(DIRECTION_LEFT) and 1 or 0)
		local ky = (IsDirectionDown(DIRECTION_UP) and 1 or 0) - (IsDirectionDown(DIRECTION_DOWN) and 1 or 0)
		local kz = (IsDirectionDown(DIRECTION_BACKWARD) and 1 or 0) - (IsDirectionDown(DIRECTION_FORWARD) and 1 or 0)
		local km = (kx * kx) + (ky * ky) + (kz * kz)
		if km > 1e-15 then
			km = ((UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) and 1/4 or 1)/math.sqrt(km)
			kx = kx * km
			ky = ky * km
			kz = kz * km
		end

		local dx = kx + gp_x
		local dy = ky + gp_r1 - gp_l1
		local dz = kz + gp_z

		velSpring.t = Vector3.new(dx, dy, dz) * SpeedModifier
		rotSpring.t = panDeltaMouse + panDeltaGamepad
		fovSpring.t = Clamp(fovSpring.t + dt * rate_fov*FVEL_GAIN, 5, 120)

		local fov  = fovSpring:Update(dt)
		local dPos = velSpring:Update(dt) * LVEL_GAIN
		local dRot = rotSpring:Update(dt) * (RVEL_GAIN * math.tan(fov * math.pi/360) * NM_ZOOM)

		rate_fov = 0
		panDeltaMouse = Vector2.new()

		stateRot = stateRot + dRot
		stateRot = Vector2.new(Clamp(stateRot.x, -3/2, 3/2), stateRot.y)

		local c = CFrame.new(camCFrame.p) * CFrame.Angles(0, stateRot.y, 0) * CFrame.Angles(stateRot.x, 0, 0) * CFrame.new(dPos)

		camera.CFrame = c
		camera.Focus = c*FOCUS_OFFSET
		camera.FieldOfView = fov
	end
end

------------------------------------------------

local function Panned(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		panDeltaMouse = Vector2.new(-delta.y, -delta.x)
	end
end

------------------------------------------------

local function EnterFreecam()
	ToggleGui(false)
	UIS.MouseIconEnabled = false
	Maid:Mark(UIS.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local conn = UIS.InputChanged:Connect(Panned)
			repeat
				input = UIS.InputEnded:wait()
			until input.UserInputType == Enum.UserInputType.MouseButton2 or not freeCamEnabled
			panDeltaMouse = Vector2.new()
			panDeltaGamepad = Vector2.new()
			conn:Disconnect()
			if freeCamEnabled then
				UIS.MouseBehavior = Enum.MouseBehavior.Default
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			SpeedModifier = 0.5
		end
	end))

	Maid:Mark(UIS.InputEnded:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			SpeedModifier = 1
		end
	end))

	camera.CameraType = Enum.CameraType.Scriptable

	local hum, hrp = GetChar()
	if hrp then
		hrp.Anchored = true
	end
	if hum then
		hum.WalkSpeed = 0
		Maid:Mark(hum.Jumping:Connect(function(active)
			if active then
				hum.Jumping = false
			end
		end))
	end

	velSpring.t, velSpring.v, velSpring.x = Vector3.new(), Vector3.new(), Vector3.new()
	rotSpring.t, rotSpring.v, rotSpring.x = Vector2.new(), Vector2.new(), Vector2.new()
	fovSpring.t, fovSpring.v, fovSpring.x = camera.FieldOfView, 0, camera.FieldOfView

	local camCFrame = camera.CFrame
	local lookVector = camCFrame.lookVector.unit

	stateRot = Vector2.new(
		math.asin(lookVector.y),
		math.atan2(-lookVector.z, lookVector.x) - math.pi/2
	)
	panDeltaMouse = Vector2.new()

	local playerGui = player:WaitForChild("PlayerGui")
	for _, obj in next, playerGui:GetChildren() do
		if obj:IsA("ScreenGui") and obj.Enabled then
			obj.Enabled = false
			screenGuis[obj] = true
		end
	end
	--if letterBoxEnabled then
		--letterbox.Enabled = true
	--end
	RS:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, UpdateFreecam)
	freeCamEnabled = true
end

local function ExitFreecam()
	freeCamEnabled = false
	--if letterBoxEnabled then
		--letterbox.Enabled = false
	--end
	UIS.MouseIconEnabled = true
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	Maid:Sweep()
	RS:UnbindFromRenderStep("Freecam")
	local hum, hrp = GetChar()
	if hum then
		hum.WalkSpeed = 16
	end
	if hrp then
		hrp.Anchored = false
	end
	camera.FieldOfView = DEF_FOV
	camera.CameraType = Enum.CameraType.Custom
	for obj in next, screenGuis do
		obj.Enabled = true
	end
	screenGuis = {}
	ToggleGui(true)
end

------------------------------------------------

UIS.InputBegan:Connect(function(input, processed)
	if not processed then
		if input.KeyCode == Enum.KeyCode.P then
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				if freeCamEnabled then
					ExitFreecam()
				else
					EnterFreecam()
				end
			end
		elseif input.KeyCode == Enum.KeyCode.L and freeCamEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			--letterBoxEnabled = not letterBoxEnabled
			--letterbox.Enabled = letterBoxEnabled
		end
	end
end)
