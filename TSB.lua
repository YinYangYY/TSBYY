-- RXMHUB: INTRO + RAYFIELD (combined, runnable)
-- Locals only. Intro runs once, then Rayfield window opens.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local INTRO_TEXT = "亗 『 R X M H U B 』 🄾🄽 🅃🄾🄿 亗"
local INTRO_SOUND = "rbxassetid://86045706626808"
local INTRO_PROFILE = "rbxassetid://17297011003"
local INTRO_IMAGE_WAIT = 6

local function svc(name)
    local service = game:GetService(name)
    if cloneref then return cloneref(service) end
    return service
end

local Players = svc("Players")
local TweenService = svc("TweenService")
local UserInputService = svc("UserInputService")
local RunService = svc("RunService")
local CoreGui = svc("CoreGui")
local HttpService = svc("HttpService")
local ContentProvider = svc("ContentProvider")
local LocalPlayer = Players.LocalPlayer

local ES, ED = Enum.EasingStyle, Enum.EasingDirection
local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

pcall(function() if getgenv and getgenv().RXMHUBGUI then getgenv().RXMHUBGUI.Destroy() end end)
pcall(function()
    local old = CoreGui:FindFirstChild("RXMHUB")
    if old then old:Destroy() end
end)

local function mountGui(gui)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    local parents = {}
    if gethui then table.insert(parents, gethui) end
    table.insert(parents, function() return CoreGui end)
    table.insert(parents, function() return LocalPlayer:WaitForChild("PlayerGui") end)
    for _, getParent in ipairs(parents) do
        if pcall(function() gui.Parent = getParent() end) and gui.Parent ~= nil then
            return true
        end
    end
    return false
end

local function LoadProfileImage(maxWait, onLate)
    local id = string.match(INTRO_PROFILE, "%d+")
    if not id then return nil, false end
    local won, timedOut = false, false
    local result
    local bestGuess = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
    local probeGui = Instance.new("ScreenGui")
    probeGui.Name = "RXMHUB_ProfileProbe"
    probeGui.ResetOnSpawn = false
    probeGui.DisplayOrder = -1
    if not mountGui(probeGui) then return bestGuess, false end
    local function present() return probeGui.Parent ~= nil end
    local function resolve(url)
        if won then return end
        won = true
        result = url
        if timedOut and onLate then pcall(onLate, url) end
    end
    local function attempt(url, timeout)
        if won or not present() or type(url) ~= "string" or url == "" then return end
        task.spawn(function()
            local probe = Instance.new("ImageLabel")
            probe.Size = UDim2.fromOffset(4, 4)
            probe.BackgroundTransparency = 1
            probe.Image = url
            probe.ImageTransparency = 0.99
            probe.Parent = probeGui
            pcall(function() ContentProvider:PreloadAsync({probe}) end)
            local t0 = os.clock()
            while not won and present() and os.clock() - t0 < (timeout or 5) do
                local ok, v = pcall(function() return probe.IsLoaded end)
                if ok and v == true then resolve(url) break end
                task.wait(0.1)
            end
            pcall(function() probe:Destroy() end)
        end)
    end
    local function idFrom(text)
        if type(text) ~= "string" then return nil end
        return string.match(text, "(%d%d%d+)")
    end
    local function attemptImageId(imageId)
        if not imageId then return end
        bestGuess = "rbxassetid://" .. imageId
        attempt("rbxassetid://" .. imageId, 5)
        attempt("http://www.roblox.com/asset/?id=" .. imageId, 5)
    end
    attempt("rbxassetid://" .. id, 5)
    attempt("http://www.roblox.com/asset/?id=" .. id, 5)
    attempt("rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420", 5)
    task.spawn(function()
        local okObj, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
        if not (okObj and type(objs) == "table") then return end
        for _, obj in ipairs(objs) do
            local tex
            pcall(function()
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    tex = obj.Texture
                elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                    tex = obj.Image
                else
                    local d = obj:FindFirstChildWhichIsA("Decal", true) or obj:FindFirstChildWhichIsA("Texture", true)
                    tex = d and d.Texture
                end
            end)
            pcall(function() obj:Destroy() end)
            if tex and tex ~= "" then
                attempt(tex, 5)
                attemptImageId(idFrom(tex))
            end
        end
    end)
    local makeAsset = getcustomasset or getsynasset
    local function fetch(url)
        if not requestFunc then return nil end
        local ok, res = pcall(requestFunc, {Url = url, Method = "GET"})
        if ok and type(res) == "table" and type(res.Body) == "string" and res.Body ~= "" then
            if res.StatusCode == nil or res.StatusCode == 200 then return res.Body end
        end
        return nil
    end
    local function isImage(bytes)
        if type(bytes) ~= "string" or #bytes < 100 then return false end
        return string.sub(bytes, 2, 4) == "PNG" or (string.byte(bytes, 1) == 255 and string.byte(bytes, 2) == 216)
    end
    local function useBytes(bytes)
        if not (makeAsset and writefile and isImage(bytes)) then return end
        local file = "RXMHUB_profile" .. (string.sub(bytes, 2, 4) == "PNG" and ".png" or ".jpg")
        if not pcall(writefile, file, bytes) then return end
        local ok, asset = pcall(makeAsset, file)
        if ok and type(asset) == "string" then attempt(asset, 5) end
    end
    local function download(assetId)
        local meta = fetch("https://assetdelivery.roblox.com/v1/assetId/" .. assetId)
        if meta then
            local okJson, data = pcall(function() return HttpService:JSONDecode(meta) end)
            if okJson and type(data) == "table" and type(data.location) == "string" then
                local body = fetch(data.location)
                if body then return body end
            end
        end
        return fetch("https://assetdelivery.roblox.com/v1/asset/?id=" .. assetId)
    end
    if requestFunc then
        task.spawn(function()
            local body = download(id)
            if not body then return end
            if isImage(body) then
                useBytes(body)
            elseif string.find(body, "<roblox", 1, true) then
                local imageId = string.match(body, "<url>[^<]-id=(%d+)") or string.match(body, "rbxassetid://(%d+)")
                if imageId then
                    attemptImageId(imageId)
                    useBytes(download(imageId))
                end
            end
        end)
        task.spawn(function()
            local meta = fetch("https://thumbnails.roblox.com/v1/assets?assetIds=" .. id .. "&size=420x420&format=Png")
            if not meta then return end
            local okJson, data = pcall(function() return HttpService:JSONDecode(meta) end)
            local imageUrl = okJson and type(data) == "table" and type(data.data) == "table" and data.data[1] and data.data[1].imageUrl
            if type(imageUrl) == "string" then useBytes(fetch(imageUrl)) end
        end)
    end
    local t0 = os.clock()
    while not won and os.clock() - t0 < (maxWait or 6) do task.wait(0.05) end
    if won then
        task.delay(2, function() pcall(function() probeGui:Destroy() end) end)
        return result, true
    end
    timedOut = true
    task.delay(12, function() pcall(function() probeGui:Destroy() end) end)
    return bestGuess, false
end

-- ============================================================
-- INTRO (verbatim from provided fragments)
-- ============================================================
local function PlayScreenIntro(onComplete)
    local finished = false
    local function complete()
        if finished then return end
        finished = true
        if onComplete then task.spawn(onComplete) end
    end
    local profileHook = {}
    local okLoad, profileUrl, profileLoaded = pcall(LoadProfileImage, INTRO_IMAGE_WAIT, function(url)
        if profileHook.show then profileHook.show(url) end
    end)
    if not okLoad then profileUrl, profileLoaded = nil, false end

    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "RXMHUB_ScreenIntro"
    IntroGui.IgnoreGuiInset = true
    pcall(function() IntroGui.ScreenInsets = Enum.ScreenInsets.None end)
    IntroGui.ResetOnSpawn = false
    IntroGui.DisplayOrder = 999999
    IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if syn and syn.protect_gui then pcall(syn.protect_gui, IntroGui) end
    local mounted = false
    if gethui then
        mounted = pcall(function() IntroGui.Parent = gethui() end) and IntroGui.Parent ~= nil
    end
    if not mounted then
        mounted = pcall(function() IntroGui.Parent = CoreGui end) and IntroGui.Parent ~= nil
    end
    if not mounted then
        mounted = pcall(function() IntroGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) and IntroGui.Parent ~= nil
    end
    if not mounted then complete() return end

    local conn
    local function cleanup()
        if conn then conn:Disconnect() conn = nil end
        pcall(function() IntroGui:Destroy() end)
        complete()
    end
    task.delay(14, function() if IntroGui.Parent then cleanup() end end)

    local built = pcall(function()
        local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        local compact = UserInputService.TouchEnabled or viewport.X < 700
        local rng = Random.new()
        local RED = Color3.fromRGB(235, 235, 235)
        local DEEP = Color3.fromRGB(110, 110, 110)
        local PALE = Color3.fromRGB(200, 200, 200)
        local WHITE = Color3.new(1, 1, 1)
        local GLOW = "rbxassetid://5028857484"
        local function make(class, props, parent)
            local inst = Instance.new(class)
            for key, value in pairs(props) do inst[key] = value end
            inst.Parent = parent
            return inst
        end
        local function tw(inst, time, props, style, dir)
            local tween = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
            tween:Play()
            return tween
        end
        local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end
        local function ck(t, c) return ColorSequenceKeypoint.new(t, c) end
        local function circle(inst) make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, inst) end

        local Stage = make("CanvasGroup", {
            Name = "Stage",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            GroupTransparency = 1,
        }, IntroGui)
        local stageScale = make("UIScale", {Scale = 1}, Stage)
        tw(Stage, 0.55, {GroupTransparency = 0}, Enum.EasingStyle.Sine)

        local IntroSound = make("Sound", {SoundId = INTRO_SOUND, Volume = 2}, IntroGui)
        task.spawn(function()
            pcall(function() ContentProvider:PreloadAsync({IntroSound}) end)
            pcall(function() IntroSound:Play() end)
        end)

        local fogCfg = {
            {size = 980, color = RED, base = 0.74, sx = 0.38, sy = 0.31, ax = 0.20, ay = 0.14, ph = 0},
            {size = 760, color = DEEP, base = 0.62, sx = 0.27, sy = 0.44, ax = 0.26, ay = 0.18, ph = 2.1},
            {size = 640, color = RED, base = 0.84, sx = 0.52, sy = 0.36, ax = 0.30, ay = 0.12, ph = 4.2},
        }
        for _, cfg in ipairs(fogCfg) do
            cfg.img = make("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(cfg.size, cfg.size),
                BackgroundTransparency = 1,
                Image = GLOW,
                ImageColor3 = cfg.color,
                ImageTransparency = cfg.base,
                ZIndex = 1,
            }, Stage)
        end

        local streaks = {}
        for i = 1, compact and 4 or 6 do
            local frame = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(rng:NextInteger(2, 4), math.floor(viewport.Y * 1.7)),
                Rotation = 18,
                BackgroundColor3 = i % 2 == 0 and RED or DEEP,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, Stage)
            make("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.55), kp(1, 1)}),
            }, frame)
            streaks[i] = {frame = frame, speed = rng:NextNumber(0.05, 0.12), phase = rng:NextNumber(0, 1)}
        end

        local beamHalo = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(1, 0, 0, 130),
            BackgroundColor3 = RED,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, Stage)
        make("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.88), kp(1, 1)}),
        }, beamHalo)
        local beam = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = RED,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, Stage)
        make("UIGradient", {
            Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.2), kp(1, 1)}),
        }, beam)

        local particles = {}
        local function resetParticle(p, initial)
            p.x = rng:NextNumber(0.02, 0.98)
            p.y = initial and rng:NextNumber(0.05, 1.05) or rng:NextNumber(1.04, 1.2)
            p.vy = rng:NextNumber(0.06, 0.2)
            p.amp = rng:NextNumber(0.004, 0.022)
            p.freq = rng:NextNumber(0.8, 2.4)
            p.phase = rng:NextNumber(0, 6.28)
            p.alpha = rng:NextNumber(0.55, 0.95)
            local s = rng:NextInteger(2, 5)
            p.frame.Size = UDim2.fromOffset(s, s)
            p.frame.BackgroundColor3 = RED:Lerp(PALE, rng:NextNumber(0, 0.5))
        end
        for i = 1, compact and 28 or 46 do
            local frame = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = RED,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, Stage)
            circle(frame)
            local glow = make("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(5, 5),
                BackgroundTransparency = 1,
                Image = GLOW,
                ImageColor3 = RED,
                ImageTransparency = 1,
            }, frame)
            local p = {frame = frame, glow = glow}
            resetParticle(p, true)
            particles[i] = p
        end

        local function edge(anchor, pos, size, rot)
            local f = make("Frame", {
                AnchorPoint = anchor,
                Position = pos,
                Size = size,
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 5,
            }, Stage)
            make("UIGradient", {Rotation = rot, Transparency = NumberSequence.new({kp(0, 0), kp(1, 1)})}, f)
        end
        edge(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.3), 90)
        edge(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.3), -90)
        edge(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0.22, 1), 0)
        edge(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.22, 1), 180)

        local brackets = {}
        local function bracket(ax, ay)
            local m, len, th = 18, 34, 2
            for k = 1, 2 do
                local f = make("Frame", {
                    AnchorPoint = Vector2.new(ax, ay),
                    Position = UDim2.new(ax, ax == 0 and m or -m, ay, ay == 0 and m or -m),
                    Size = k == 1 and UDim2.fromOffset(len, th) or UDim2.fromOffset(th, len),
                    BackgroundColor3 = RED,
                    BorderSizePixel = 0,
                    ZIndex = 10,
                }, Stage)
                table.insert(brackets, f)
            end
        end
        bracket(0, 0)
        bracket(1, 0)
        bracket(0, 1)
        bracket(1, 1)

        local E = compact and 112 or 180
        local EY = 0.36
        local Emblem = make("Frame", {
            Name = "Emblem",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, EY, 0),
            Size = UDim2.fromOffset(E, E),
            BackgroundTransparency = 1,
            ZIndex = 6,
        }, Stage)
        local emblemScale = make("UIScale", {Scale = 0.3}, Emblem)
        tw(emblemScale, 0.95, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        local coreGlow = make("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(E * 2.2, E * 2.2),
            BackgroundTransparency = 1,
            Image = GLOW,
            ImageColor3 = RED,
            ImageTransparency = 0.55,
            ZIndex = 1,
        }, Emblem)

        local ticks = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(E * 1.24, E * 1.24),
            BackgroundTransparency = 1,
            ZIndex = 2,
        }, Emblem)
        for i = 0, 23 do
            local a = math.rad(i * 15)
            local major = i % 6 == 0
            make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a)),
                Size = UDim2.fromOffset(major and 3 or 2, major and 12 or 7),
                Rotation = i * 15 + 90,
                BackgroundColor3 = RED,
                BackgroundTransparency = major and 0.1 or 0.55,
                BorderSizePixel = 0,
            }, ticks)
        end

        local function ring(size, thickness, trans, colors)
            local f = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(size, size),
                BackgroundTransparency = 1,
                ZIndex = 3,
            }, Emblem)
            circle(f)
            local stroke = make("UIStroke", {
                Thickness = thickness,
                Color = WHITE,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }, f)
            local grad = make("UIGradient", {Color = colors, Transparency = trans}, stroke)
            return f, stroke, grad
        end
        local _, _, outerGrad = ring(E, 3,
            NumberSequence.new({kp(0, 1), kp(0.12, 0.1), kp(0.42, 0), kp(0.58, 1), kp(1, 1)}),
            ColorSequence.new({ck(0, RED), ck(0.5, PALE), ck(1, DEEP)}))
        local _, _, midGrad = ring(E * 0.8, 2,
            NumberSequence.new({kp(0, 1), kp(0.1, 0.15), kp(0.22, 1), kp(0.4, 1), kp(0.5, 0.15), kp(0.62, 1), kp(0.8, 1), kp(0.9, 0.25), kp(1, 1)}),
            ColorSequence.new({ck(0, DEEP), ck(0.5, RED), ck(1, DEEP)}))
        local _, innerStroke = ring(E * 0.6, 1.5,
    NumberSequence.new({kp(0, 0), kp(1, 0)}),
    ColorSequence.new({ck(0, RED), ck(1, RED)}))

local core = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(E * 0.5, E * 0.5),
    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
    BorderSizePixel = 0,
    ZIndex = 4,
}, Emblem)
circle(core)
make("UIStroke", {
    Color = RED,
    Thickness = 2,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, core)
local coreScale = make("UIScale", {Scale = 1}, core)

local profileLetter = make("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "R",
    Font = Enum.Font.GothamBlack,
    TextSize = math.floor(E * 0.26),
    TextColor3 = WHITE,
    ZIndex = 4,
}, core)
local profileImage = make("ImageLabel", {
    Name = "Profile",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = "",
    ImageTransparency = 1,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 5,
}, core)
circle(profileImage)
local function showProfile(url, instant)
    if not profileImage.Parent then return end
    profileImage.Image = url
    profileLetter.Visible = false
    if instant then
        profileImage.ImageTransparency = 0
    else
        tw(profileImage, 0.45, {ImageTransparency = 0}, Enum.EasingStyle.Sine)
    end
end
if profileUrl and profileLoaded then
    showProfile(profileUrl, true)
elseif profileUrl then
    profileImage.Image = profileUrl
    tw(profileImage, 0.45, {ImageTransparency = 0}, Enum.EasingStyle.Sine)
    profileHook.show = function(url) showProfile(url, false) end
end

local orbits = {}
for i = 1, 3 do
    local frame = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = i == 1 and WHITE or RED,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, Emblem)
    circle(frame)
    make("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(6, 6),
        BackgroundTransparency = 1,
        Image = GLOW,
        ImageColor3 = RED,
        ImageTransparency = 0.35,
    }, frame)
    orbits[i] = {frame = frame, speed = 1.3 + i * 0.55, phase = i * 2.09}
end

local function shockwave(fromSize, toSize, life, thick)
    local f = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(fromSize, fromSize),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, Emblem)
    circle(f)
    local st = make("UIStroke", {
        Color = RED,
        Thickness = thick or 3,
        Transparency = 0.15,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, f)
    tw(f, life, {Size = UDim2.fromOffset(toSize, toSize)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    tw(st, life, {Transparency = 1, Thickness = 0.5}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(life + 0.1, function() f:Destroy() end)
end

local titleOff = E / 2 + (compact and 34 or 48)
local titleHolder = make("Frame", {
    Name = "Title",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, EY, titleOff),
    Size = UDim2.new(0.94, 0, 0, 48),
    BackgroundTransparency = 1,
    ZIndex = 7,
}, Stage)

local function titleLabel(color, z)
    local label = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.GothamBlack,
        TextScaled = true,
        TextColor3 = color,
        ZIndex = z,
    }, titleHolder)
    make("UITextSizeConstraint", {MaxTextSize = compact and 18 or 26, MinTextSize = 8}, label)
    return label
end

local ghostA = titleLabel(RED, 6)
local ghostB = titleLabel(PALE, 6)
local titleMain = titleLabel(WHITE, 7)
ghostA.TextTransparency = 1
ghostB.TextTransparency = 1

make("UIStroke", {
    Color = Color3.fromRGB(10, 10, 10),
    Thickness = 2.5,
    Transparency = 0.1,
}, titleMain)

local titleGrad = make("UIGradient", {
    Color = ColorSequence.new({
        ck(0, Color3.fromRGB(200, 200, 200)),
        ck(0.5, WHITE),
        ck(1, Color3.fromRGB(120, 120, 120)),
    }),
}, titleMain)

local subtitle = make("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, EY, titleOff + (compact and 28 or 36)),
    Size = UDim2.new(0.94, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "R X M   H U B   ·   C R I M S O N   N O I R",
    Font = Enum.Font.GothamMedium,
    TextSize = compact and 9 or 11,
    TextColor3 = Color3.fromRGB(190, 190, 190),
    TextTransparency = 1,
    ZIndex = 7,
}, Stage)

local barW = math.clamp(viewport.X * 0.6, 240, 460)
local bar = make("Frame", {
    Name = "Bar",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, compact and 0.93 or 0.9, 0),
    Size = UDim2.fromOffset(barW, 44),
    BackgroundTransparency = 1,
    ZIndex = 8,
}, Stage)

local statusLabel = make("TextLabel", {
    Size = UDim2.new(0.75, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "Initializing core",
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(170, 170, 170),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8,
}, bar)

local percent = make("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0.25, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "0%",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = WHITE,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 8,
}, bar)

local track = make("Frame", {
    Position = UDim2.fromOffset(0, 24),
    Size = UDim2.new(1, 0, 0, 6),
    BackgroundColor3 = Color3.fromRGB(28, 28, 28),
    BorderSizePixel = 0,
    ZIndex = 8,
}, bar)
circle(track)
make("UIStroke", {
    Color = RED,
    Thickness = 1,
    Transparency = 0.6,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, track)

local barGlow = make("ImageLabel", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, -7, 0.5, 0),
    Size = UDim2.new(0, 14, 0, 34),
    BackgroundTransparency = 1,
    Image = GLOW,
    ImageColor3 = RED,
    ImageTransparency = 0.55,
    ZIndex = 8,
}, track)

local fill = make("Frame", {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = WHITE,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 9,
}, track)
circle(fill)
make("UIGradient", {
    Color = ColorSequence.new({
        ck(0, DEEP),
        ck(0.7, RED),
        ck(1, Color3.fromRGB(220, 220, 220)),
    }),
}, fill)

local sweep = make("Frame", {
    Size = UDim2.fromScale(0.3, 1),
    Position = UDim2.fromScale(-0.4, 0),
    BackgroundColor3 = WHITE,
    BorderSizePixel = 0,
    ZIndex = 10,
}, fill)
make("UIGradient", {
    Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.35), kp(1, 1)}),
}, sweep)

local head = make("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.fromOffset(46, 46),
    BackgroundTransparency = 1,
    Image = GLOW,
    ImageColor3 = RED,
    ImageTransparency = 0.3,
    ZIndex = 11,
}, track)

local STATUS = {
    {0, "Initializing core"},
    {0.16, "Loading modules"},
    {0.4, "Fetching tech list"},
    {0.64, "Applying Monochrome theme"},
    {0.88, "Finalizing"},
}

local flash = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(235, 235, 235),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 30,
}, Stage)

local t = 0
local BAR_START, BAR_END = 0.35, 5.0
local TYPE_START, TYPE_RATE = 0.7, 0.055
local len = utf8.len(INTRO_TEXT) or #INTRO_TEXT
local lastShown, statusIdx = -1, 0
local glitchUntil, nextGlitch, nextWave = 0, 2.6, 0.9
local subShown, exiting, faded = false, false, false
local exitAt = 0

local function step(dt)
    t = t + dt

    for _, cfg in ipairs(fogCfg) do
        cfg.img.Position = UDim2.fromScale(
            0.5 + cfg.ax * math.sin(t * cfg.sx + cfg.ph),
            0.5 + cfg.ay * math.cos(t * cfg.sy + cfg.ph)
        )
        cfg.img.ImageTransparency = cfg.base + 0.06 * math.sin(t * 1.3 + cfg.ph)
    end
    for _, s in ipairs(streaks) do
        s.frame.Position = UDim2.fromScale(((t * s.speed + s.phase) % 1) * 1.5 - 0.25, 0.5)
    end
    local by = ((t * 0.2) % 1.25) - 0.12
    beam.Position = UDim2.fromScale(0.5, by)
    beamHalo.Position = UDim2.fromScale(0.5, by)
    for _, p in ipairs(particles) do
        p.y = p.y - p.vy * dt
        if p.y < -0.06 then
            resetParticle(p, false)
        end
        p.frame.Position = UDim2.fromScale(p.x + math.sin(t * p.freq + p.phase) * p.amp, p.y)
        local vis = math.clamp(math.min((1.04 - p.y) / 0.1, (p.y + 0.02) / 0.3), 0, 1)
        p.frame.BackgroundTransparency = 1 - vis * p.alpha
        p.glow.ImageTransparency = 1 - vis * 0.5
    end
    local ba = 0.25 + 0.2 * math.sin(t * 2.4)
    for _, f in ipairs(brackets) do
        f.BackgroundTransparency = ba
    end
    outerGrad.Rotation = (t * 150) % 360
    midGrad.Rotation = 360 - (t * 95) % 360
    ticks.Rotation = (t * 14) % 360
    profileImage.Rotation = (t * 90) % 360
    local pulse = 0.5 + 0.5 * math.sin(t * 3.2)
    coreScale.Scale = 1 + 0.07 * pulse
    coreGlow.ImageTransparency = 0.55 - 0.18 * pulse
    local gs = E * (2.2 + 0.25 * pulse)
    coreGlow.Size = UDim2.fromOffset(gs, gs)
    innerStroke.Transparency = 0.45 + 0.3 * pulse
    for _, o in ipairs(orbits) do
        local a = t * o.speed + o.phase
        o.frame.Position = UDim2.new(0.5, math.cos(a) * E * 0.41, 0.5, math.sin(a) * E * 0.41)
    end
    if t >= nextWave and not exiting then
        nextWave = t + 1.5
        shockwave(E * 0.55, E * 2.6, 1.35, 3)
    end
    local shown = math.clamp(math.floor((t - TYPE_START) / TYPE_RATE), 0, len)
    if shown ~= lastShown then
        lastShown = shown
        local txt = INTRO_TEXT
        if shown < len then
            local off = utf8.offset(INTRO_TEXT, shown + 1)
            if off then
                txt = string.sub(INTRO_TEXT, 1, off - 1)
            end
        end
        titleMain.Text = txt
        ghostA.Text = txt
        ghostB.Text = txt
    end
    titleGrad.Rotation = (titleGrad.Rotation + dt * 200) % 360
    if t >= nextGlitch and shown >= len then
        glitchUntil = t + 0.16
        nextGlitch = t + rng:NextNumber(1.1, 2.4)
    end
    if t < glitchUntil then
        local j = rng:NextInteger(3, 7)
        ghostA.Position = UDim2.new(0.5, -j, 0.5, rng:NextInteger(-2, 2))
        ghostB.Position = UDim2.new(0.5, j, 0.5, rng:NextInteger(-2, 2))
        ghostA.TextTransparency = 0.3
        ghostB.TextTransparency = 0.5
        titleMain.Position = UDim2.new(0.5, rng:NextInteger(-2, 2), 0.5, 0)
    else
        ghostA.TextTransparency = 1
        ghostB.TextTransparency = 1
        titleMain.Position = UDim2.fromScale(0.5, 0.5)
    end
    if not subShown and t > 2.0 then
        subShown = true
        tw(subtitle, 0.8, {TextTransparency = 0.15}, Enum.EasingStyle.Quad)
    end
    local u = math.clamp((t - BAR_START) / (BAR_END - BAR_START), 0, 1)
    local p = u * u * (3 - 2 * u)
    fill.Size = UDim2.fromScale(p, 1)
    head.Position = UDim2.new(p, 0, 0.5, 0)
    head.ImageTransparency = 0.25 + 0.15 * math.sin(t * 11)
    barGlow.Size = UDim2.new(p, 14, 0, 34)
    sweep.Position = UDim2.fromScale((t * 0.9) % 1.6 - 0.4, 0)
    if not exiting then
        percent.Text = math.floor(p * 100 + 0.5) .. "%"
        local idx = 1
        for i, s in ipairs(STATUS) do
            if p >= s[1] then
                idx = i
            end
        end
        if idx ~= statusIdx then
            statusIdx = idx
            statusLabel.Text = STATUS[idx][2]
        end
    end
    if not exiting and u >= 1 then
        exiting, exitAt = true, t
        percent.Text = "100%"
        statusLabel.Text = "Ready"
        local f1 = tw(flash, 0.12, {BackgroundTransparency = 0.45}, Enum.EasingStyle.Quad)
        f1.Completed:Connect(function()
            tw(flash, 0.6, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
        end)
        tw(emblemScale, 0.4, {Scale = 1.2}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        shockwave(E * 0.6, E * 8, 0.95, 6)
    end
    if exiting then
        local e = t - exitAt
        if not faded and e >= 0.5 then
            faded = true
            tw(stageScale, 0.95, {Scale = 1.25}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            tw(Stage, 0.95, {GroupTransparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(IntroSound, 0.95, {Volume = 0}, Enum.EasingStyle.Linear)
            complete()
        end
        if e >= 1.55 then
            cleanup()
        end
    end
end

local fails = 0
conn = RunService.Heartbeat:Connect(function(rawDt)
    local ok = pcall(step, math.min(rawDt, 0.05))
    if not ok then
        fails = fails + 1
        if fails >= 3 then
            cleanup()
        end
    end
end)
end)
if not built then
    cleanup()
end
end

local function openMainWindow()
    local window = Rayfield:CreateWindow({
        Name = "RXMHUB",
        LoadingTitle = "RXMHUB",
        LoadingSubtitle = "Crimson Noir",
        ConfigurationSaving = {Enabled = false},
        KeySystem = false,
    })
    getgenv().RXMHUBGUI = window

    local mainTab = window:CreateTab("Main", nil)
    mainTab:CreateParagraph({
        Title = "Welcome",
        Content = "Welcome to RXMHUB. Supported game: Obby. Use Visual for ESP toggles, Obby & Fun for speed/jump sliders and utilities.",
    })

    local visualTab = window:CreateTab("Visual", nil)
    visualTab:CreateToggle({
        Name = "ESP",
        CurrentValue = false,
        Flag = "ESP",
        Callback = function(state) getgenv().RXMHUB_ESP = state end,
    })
    visualTab:CreateToggle({
        Name = "Line ESP",
        CurrentValue = false,
        Flag = "LineESP",
        Callback = function(state) getgenv().RXMHUB_LineESP = state end,
    })

    local funTab = window:CreateTab("Obby & Fun", nil)
    funTab:CreateSlider({
        Name = "Speed",
        Range = {16, 500}, Increment = 1, Suffix = "studs/s", CurrentValue = 16, Flag = "Speed",
        Callback = function(val)
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = val end
        end,
    })
    funTab:CreateSlider({
        Name = "Jump",
        Range = {50, 500}, Increment = 1, Suffix = "power", CurrentValue = 50, Flag = "Jump",
        Callback = function(val)
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true h.JumpPower = val end
        end,
    })
    funTab:CreateButton({
        Name = "Mute Anti Cheat 🤐",
        Callback = function()
            local muted = 0
            for _, remote in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local n = string.lower(remote.Name)
                    if string.find(n, "anticheat") or string.find(n, "anti_cheat")
                       or string.find(n, "detect") or string.find(n, "ban")
                       or string.find(n, "report") or string.find(n, "kick") then
                        remote.FireServer = function() end
                        muted = muted + 1
                    end
                end
            end
            Rayfield:Notify({
                Title = "Anti-Cheat",
                Content = "Muted " .. tostring(muted) .. " remote(s). Client-side only.",
                Duration = 3,
            })
        end,
    })

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        local flags = window.Flags or {}
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            if flags.Speed then h.WalkSpeed = flags.Speed end
            if flags.Jump then h.UseJumpPower = true h.JumpPower = flags.Jump end
        end
    end)
end

PlayScreenIntro(function()
    openMainWindow()
end)
