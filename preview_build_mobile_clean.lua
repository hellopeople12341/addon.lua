local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local FALLBACK_FOLDER_NAME = "__SS_FileStore_clean_v1"
local function isFunction(f) return type(f) == "function" end
local fileApis = {
    isfile = pcall(function() return isFunction(isfile) end) and isFunction(isfile),
    readfile = pcall(function() return isFunction(readfile) end) and isFunction(readfile),
    writefile = pcall(function() return isFunction(writefile) end) and isFunction(writefile),
    delfile = pcall(function() return isFunction(delfile) end) and isFunction(delfile),
}
local function getFallbackFolder()
    local lp = Players.LocalPlayer
    if not lp then return nil end
    local pg = lp:FindFirstChild("PlayerGui") or (lp.FindFirstChildWhichIsA and lp:FindFirstChildWhichIsA("PlayerGui"))
    if not pg then return nil end
    local folder = pg:FindFirstChild(FALLBACK_FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = FALLBACK_FOLDER_NAME
        folder.Parent = pg
    end
    return folder
end
local function sanitize(path) return tostring(path):gsub("[/\\:%%%.%s]", "_") end
local function fallback_write(path, content)
    local folder = getFallbackFolder()
    if not folder then return false end
    local key = sanitize(path)
    local sv = folder:FindFirstChild(key)
    if not sv then
        sv = Instance.new("StringValue")
        sv.Name = key
        sv.Parent = folder
    end
    sv.Value = content or ""
    return true
end
local function fallback_read(path)
    local folder = getFallbackFolder()
    if not folder then return false, "no" end
    local sv = folder:FindFirstChild(sanitize(path))
    if not sv then return false, "no" end
    return true, sv.Value
end
local function fallback_isfile(path)
    local folder = getFallbackFolder()
    if not folder then return false end
    return folder:FindFirstChild(sanitize(path)) ~= nil
end
local function fallback_delfile(path)
    local folder = getFallbackFolder()
    if not folder then return false end
    local sv = folder:FindFirstChild(sanitize(path))
    if sv then sv:Destroy(); return true end
    return false
end
local function safe_write(path, content)
    if fileApis.writefile then local ok = pcall(function() writefile(path, content or "") end) if ok then return true end end
    return fallback_write(path, content)
end
local function safe_read(path)
    if fileApis.readfile then local ok, res = pcall(function() return readfile(path) end) if ok then return true, res end end
    return fallback_read(path)
end
local function safe_isfile(path)
    if fileApis.isfile then local ok, ret = pcall(function() return isfile(path) end) if ok then return ret end end
    return fallback_isfile(path)
end
local function safe_delete(path)
    if fileApis.delfile then local ok = pcall(function() delfile(path) end) if ok then return true end end
    return fallback_delfile(path)
end
_G.safe_write = safe_write
_G.safe_read = safe_read
_G.safe_isfile = safe_isfile
_G.safe_delete = safe_delete
local function CreateUnifiedMouse()
    local unified = { X = 0, Y = 0 }
    local realMouse = nil
    pcall(function() realMouse = Players.LocalPlayer and Players.LocalPlayer:GetMouse() end)
    local function update(pos)
        if typeof(pos) == "Vector2" then unified.X = pos.X; unified.Y = pos.Y end
    end
    pcall(function()
        UIS.InputChanged:Connect(function(input)
            if input and input.Position and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                update(input.Position)
            end
        end)
    end)
    pcall(function()
        UIS.InputBegan:Connect(function(input)
            if input and input.Position and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
                update(input.Position)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input and input.Position and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
                update(input.Position)
            end
        end)
    end)
    if realMouse then
        pcall(function()
            if realMouse.Move then
                realMouse.Move:Connect(function() unified.X = realMouse.X or unified.X; unified.Y = realMouse.Y or unified.Y end)
            else
                unified.X = realMouse.X or unified.X; unified.Y = realMouse.Y or unified.Y
            end
        end)
    end
    setmetatable(unified, { __index = function(t,k) if realMouse and realMouse[k] ~= nil then return realMouse[k] end; return nil end })
    return unified
end
local __UNIFIED_MOUSE = CreateUnifiedMouse()
pcall(function() if Players and Players.LocalPlayer and Players.LocalPlayer.GetMouse then Players.LocalPlayer.GetMouse = function() return __UNIFIED_MOUSE end end end)
local function getSSPanel()
    local names = {"SSPanel","SS Panel","sspanel","ss panel","SS_Panel"}
    local parents = {}
    if script and script.Parent then table.insert(parents, script.Parent) end
    table.insert(parents, workspace)
    pcall(function() table.insert(parents, game:GetService("CoreGui")) end)
    if Players.LocalPlayer then local suc, pg = pcall(function() return Players.LocalPlayer:FindFirstChild("PlayerGui") end) if suc and pg then table.insert(parents, pg) end end
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
local ss = getSSPanel()
local function pick(parent, opts)
    if not parent then return nil end
    for _,n in ipairs(opts) do local v = parent:FindFirstChild(n, true) or parent:FindFirstChild(n) if v then return v end end
    return nil
end
local ExecBtn = pick(ss, {"Exec","Execute","ExecButton","btnExec"})
local ExecConsoleBtn = pick(ss, {"ExecConsole","Exec & Console","ExecConsoleButton"})
local ClearBtn = pick(ss, {"Clear","ClearButton","btnClear","btn_Clear"})
local CodeBox = pick(ss, {"CodeBox","CodeTextBox","ScriptBox","TextBox","CodeEditor","Input"})
local ConsoleBox = pick(ss, {"Console","ConsoleBox","Output","Log","LogBox","ConsoleOutput"})
local function appendConsole(msg)
    if not ConsoleBox then return end
    pcall(function()
        if ConsoleBox.Text and ConsoleBox.Text ~= "" then ConsoleBox.Text = ConsoleBox.Text .. "\n" .. tostring(msg) else ConsoleBox.Text = tostring(msg) end
    end)
end
local function get_loader()
    if type(loadstring) == "function" then return loadstring end
    if type(load) == "function" then return function(src) return load(src, "user_code", "t") end end
    return nil
end
local safe_loader = get_loader()
local function executeCode()
    local code = ""
    if CodeBox then pcall(function() code = CodeBox.Text or "" end) end
    if code == "" then appendConsole("No code to execute.") return end
    if not safe_loader then appendConsole("Execution unavailable.") return end
    local ok, fn = pcall(function() return safe_loader(code) end)
    if not ok or type(fn) ~= "function" then appendConsole("Load failed.") return end
    local ok2, res = pcall(function() return fn() end)
    if not ok2 then appendConsole(tostring(res)) else appendConsole("Executed.") end
end
local function bindButton(btn, fn)
    if not btn then return end
    pcall(function()
        if btn.Activated then btn.Activated:Connect(fn) end
        if btn.MouseButton1Click then btn.MouseButton1Click:Connect(fn) end
        if btn:IsA and btn:IsA("GuiObject") and btn.InputEnded then
            btn.InputEnded:Connect(function(input) if input and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then fn() end end)
        end
    end)
end
bindButton(ExecBtn, executeCode)
bindButton(ExecConsoleBtn, executeCode)
bindButton(ClearBtn, function()
    if CodeBox then pcall(function() CodeBox.Text = "" end) end
    if ConsoleBox then pcall(function() ConsoleBox.Text = "" end) end
end)
