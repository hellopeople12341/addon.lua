local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local function CreateUnifiedMouse()
    local unified = { X = 0, Y = 0 }
    local realMouse = Players.LocalPlayer and Players.LocalPlayer:GetMouse() or nil
    local function update(pos)
        if typeof(pos) == "Vector2" then unified.X = pos.X; unified.Y = pos.Y end
    end
    UIS.InputChanged:Connect(function(input)
        if input.Position and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then update(input.Position) end
    end)
    UIS.InputBegan:Connect(function(input)
        if input.Position and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then update(input.Position) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.Position and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then update(input.Position) end
    end)
    if realMouse and realMouse.Move then realMouse.Move:Connect(function() unified.X = realMouse.X; unified.Y = realMouse.Y end) end
    setmetatable(unified, { __index = function(t,k) if realMouse then return realMouse[k] end; return nil end })
    return unified
end

local __UNIFIED_MOUSE = CreateUnifiedMouse()
if Players.LocalPlayer then Players.LocalPlayer.GetMouse = function() return __UNIFIED_MOUSE end end

local function findPanel()
    local names = {"SSPanel","SS Panel","sspanel","ss panel","SS_Panel"}
    local parents = {}
    if script and script.Parent then table.insert(parents, script.Parent) end
    table.insert(parents, workspace)
    table.insert(parents, game:GetService("CoreGui"))
    if Players.LocalPlayer then table.insert(parents, Players.LocalPlayer:FindFirstChild("PlayerGui")) end
    for _,p in ipairs(parents) do
        if p then
            for _,n in ipairs(names) do
                local ok = p:FindFirstChild(n, true)
                if ok then return ok end
            end
        end
    end
    for _,n in ipairs(names) do local ok = game:FindFirstChild(n, true) if ok then return ok end end
    return nil
end

local ss = findPanel()

local function pick(parent, opts)
    if not parent then return nil end
    for _,n in ipairs(opts) do local v = parent:FindFirstChild(n, true) or parent:FindFirstChild(n) if v then return v end end
    return nil
end

local ExecBtn = pick(ss, {"Exec","Execute","ExecButton","btnExec","ButtonExec"})
local ExecConsoleBtn = pick(ss, {"ExecConsole","Exec & Console","ExecConsoleButton","ExecAndConsole"})
local ClearBtn = pick(ss, {"Clear","ClearButton","btnClear","btn_Clear"})
local CodeBox = pick(ss, {"CodeBox","CodeTextBox","ScriptBox","TextBox","CodeEditor","Input","Editor"})
local ConsoleBox = pick(ss, {"Console","ConsoleBox","Output","Log","LogBox","ConsoleOutput"})

local function appendConsole(msg)
    if not ConsoleBox then return end
    if ConsoleBox.Text and ConsoleBox.Text ~= "" then ConsoleBox.Text = ConsoleBox.Text .. "\n" .. tostring(msg) else ConsoleBox.Text = tostring(msg) end
end

local function try_compile(code)
    if type(loadstring) == "function" then
        local fn, err = loadstring(code)
        if type(fn) == "function" then return fn end
    end
    if type(load) == "function" then
        local fn, err = load(code, "user_code", "t")
        if type(fn) == "function" then return fn end
        local fn2, err2 = load("return "..code, "user_code", "t")
        if type(fn2) == "function" then return fn2 end
    end
    local wrapped = "return ("..code..")"
    local fn3 = load(wrapped, "user_code", "t")
    if type(fn3) == "function" then return fn3 end
    return nil
end

local function executeCode()
    local code = ""
    if CodeBox then code = CodeBox.Text or "" end
    if code == "" then return end
    local fn = try_compile(code)
    if not fn then appendConsole("LF") return end
    local ok, res = pcall(fn)
    if not ok then appendConsole("RE") else appendConsole("OK") end
end

local function bind(btn, fn)
    if not btn then return end
    if btn.Activated then btn.Activated:Connect(fn) end
    if btn.MouseButton1Click then btn.MouseButton1Click:Connect(fn) end
    if btn:IsA and btn:IsA("GuiObject") then
        btn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then fn() end end)
    end
end

bind(ExecBtn, executeCode)
bind(ExecConsoleBtn, executeCode)
bind(ClearBtn, function() if CodeBox then CodeBox.Text = "" end if ConsoleBox then ConsoleBox.Text = "" end end)