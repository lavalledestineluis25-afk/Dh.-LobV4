--[[
    DH UI Library  v4.0  -  LOGIC FILE
    Host this file (GitHub raw etc.) and load it from the usage file with loadstring.

    local Window = Library:CreateWindow({
        Title = "DH", Tag = "v4.0", LogoText = "DH",
        Theme = "Crimson" | "Black" | "Violet",
        Width = 680, Height = 460, ToggleKey = Enum.KeyCode.RightShift,
        ToggleText = "DH", ToggleSize = 46, TogglePosition = Vector2.new(16, 76),
        ConfigFolder = "DHUI",
        Loader = true, LoadingTitle, LoadingTime = 2.8, LoadingStatus = {...}, LoadingTips = {...},
        Snow = false | {Enabled = true, Count = 90, Wind = 0},       -- snow inside the window
        ScreenSnow = true,                                           -- snow over the whole screen
        Blur = true, BlurSize = 20, Dim = 0.45,                      -- backdrop while the GUI is open
        MaxNotifications = 5, OnClose = function() end,
    })

    local Tab = Window:CreateTab("Name")
    local Section = Tab:CreateSection({Name = "Title", Side = "Left" | "Right", Collapsed = false})
        Section:CreateLabel(text)               Section:CreateParagraph({Title, Content})
        Section:CreateButton({Name, Description, Tooltip, Callback})
        Section:CreateToggle({Name, Description, Tooltip, Default, Flag, Callback})
        Section:CreateSlider({Name, Range = {min, max}, Increment, Suffix, Default, Flag, Callback})
        Section:CreateStepper({Name, Range, Increment, Default, Flag, Callback})
        Section:CreateDropdown({Name, Options, Default, Multi, Search, Flag, Callback})
        Section:CreateTextbox({Name, Placeholder, Default, Flag, Callback})
        Section:CreateKeybind({Name, Default, Flag, Callback, Changed})
        Section:CreateColorPicker({Name, Default, Flag, Callback})
        Section:CreateProgress({Name, Default})
        Section:CreateDivider()
        Section:SetCollapsed(bool)   Section:Toggle()   Section:SetTitle(text)
    Tab:CreateLeftSection(o)  Tab:CreateRightSection(o)  Tab:Select()

    Window:Notify({Title, Content, Type, Duration, Progress, Actions = {{Text, Callback}}})  -> handle
        handle:Dismiss()   handle:Update({Title, Content})   handle:SetProgress(0..1)
    Window:SetTheme(name)  Window:SetSnow(bool)  Window:SetSnowCount(n)  Window:SetScreenSnow(bool)
    Window:SetBlur(bool)   Window:SetBlurSize(n)  Window:SetDim(alpha)
    Window:SetVisible(bool)  Window:Toggle()  Window:Minimize()  Window:SetToggleKey(key)
    Window:SetTitle(text)  Window:SaveConfig(name)  Window:LoadConfig(name)  Window:Destroy()
    Library:GetThemes()  Library.Flags
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local Library = {Flags = {}, Version = "4.0"}

---------------------------------------------------------------------
-- Themes (Black / Crimson / Violet)
---------------------------------------------------------------------

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Base = {
    Success = rgb(96, 236, 150),
    Warning = rgb(255, 194, 76),
    Error = rgb(255, 86, 102),
}

local function makeTheme(t)
    for k, v in pairs(Base) do
        if t[k] == nil then
            t[k] = v
        end
    end
    return t
end

local Themes = {
    Black = makeTheme({
        Background = rgb(7, 7, 9), Background2 = rgb(18, 18, 23),
        Topbar = rgb(12, 12, 15), Section = rgb(14, 14, 18),
        Element = rgb(22, 22, 28), ElementHover = rgb(34, 34, 42), Stroke = rgb(48, 48, 58),
        Accent = rgb(238, 238, 245), Accent2 = rgb(132, 150, 196), OnAccent = rgb(10, 10, 12),
        Text = rgb(242, 242, 248), SubText = rgb(142, 142, 158),
        Glow = rgb(120, 130, 175), Glow2 = rgb(70, 82, 120),
        Snow = rgb(240, 245, 255), Dim = rgb(0, 0, 0),
    }),
    Crimson = makeTheme({
        Background = rgb(11, 5, 7), Background2 = rgb(32, 9, 16),
        Topbar = rgb(18, 9, 12), Section = rgb(21, 10, 14),
        Element = rgb(31, 15, 20), ElementHover = rgb(47, 22, 30), Stroke = rgb(82, 34, 46),
        Accent = rgb(232, 28, 66), Accent2 = rgb(255, 112, 86), OnAccent = rgb(255, 255, 255),
        Text = rgb(248, 238, 240), SubText = rgb(172, 132, 142),
        Glow = rgb(222, 30, 72), Glow2 = rgb(255, 110, 60),
        Snow = rgb(255, 234, 238), Dim = rgb(22, 0, 5),
    }),
    Violet = makeTheme({
        Background = rgb(8, 5, 17), Background2 = rgb(26, 12, 50),
        Topbar = rgb(15, 9, 28), Section = rgb(18, 11, 33),
        Element = rgb(27, 17, 47), ElementHover = rgb(41, 26, 72), Stroke = rgb(74, 50, 124),
        Accent = rgb(154, 94, 255), Accent2 = rgb(216, 128, 255), OnAccent = rgb(255, 255, 255),
        Text = rgb(244, 239, 253), SubText = rgb(152, 138, 188),
        Glow = rgb(140, 80, 255), Glow2 = rgb(222, 110, 255),
        Snow = rgb(240, 232, 255), Dim = rgb(8, 0, 22),
    }),
}
Library.Themes = Themes

local Theme = {}
local function applyTheme(name)
    local src = Themes[name]
    if not src then
        return false
    end
    for k, v in pairs(src) do
        Theme[k] = v
    end
    return true
end
applyTheme("Crimson")

function Library:GetThemes()
    return {"Black", "Crimson", "Violet"}
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local WHITE = Color3.new(1, 1, 1)

local function create(className, props, children)
    local inst = Instance.new(className)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function tween(obj, props, time, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function corner(r)
    return create("UICorner", {CornerRadius = UDim.new(0, r or 8)})
end

local function round()
    return create("UICorner", {CornerRadius = UDim.new(1, 0)})
end

local function safeCall(cb, ...)
    if type(cb) == "function" then
        local ok, err = pcall(cb, ...)
        if not ok then
            warn("[DH UI] " .. tostring(err))
        end
    end
end

local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end
    local ok = pcall(function() return CoreGui.Name end)
    if ok then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function pointer(input)
    return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function textWidth(text, size, font)
    return TextService:GetTextSize(text, size, font or Enum.Font.GothamMedium, Vector2.new(1000, 100)).X
end

local function textHeight(text, size, font, width)
    if text == nil or text == "" then
        return 0
    end
    return TextService:GetTextSize(text, size, font or Enum.Font.Gotham, Vector2.new(width, 2000)).Y
end

local function ser(v)
    local t = typeof(v)
    if t == "Color3" then
        return {__t = "c", r = v.R, g = v.G, b = v.B}
    elseif t == "EnumItem" then
        return {__t = "e", n = v.Name}
    end
    return v
end

local function deser(v)
    if type(v) == "table" and v.__t == "c" then
        return Color3.new(v.r, v.g, v.b)
    elseif type(v) == "table" and v.__t == "e" then
        return Enum.KeyCode[v.n]
    end
    return v
end

local function decimalsOf(inc)
    local d = tostring(inc):match("%.(%d+)")
    return d and math.min(#d, 4) or 0
end

---------------------------------------------------------------------
-- Snow field factory (used by the window, the whole screen, the round
-- toggle button and the loader)
---------------------------------------------------------------------

local function newSnowField(parent, w, h, layers)
    local field = {w = w, h = h, flakes = {}, wind = 0}
    for _, L in ipairs(layers) do
        for _ = 1, L.count do
            local size = L.minS + math.random() * (L.maxS - L.minS)
            local depth = (size - L.minS) / (L.maxS - L.minS + 0.001)
            local fr = create("Frame", {
                Size = UDim2.fromOffset(size, size),
                BackgroundColor3 = Theme.Snow,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = parent,
            }, {round()})
            field.flakes[#field.flakes + 1] = {
                f = fr, on = true,
                x = math.random() * w, y = math.random() * h, size = size,
                base = L.minT + math.random() * (L.maxT - L.minT),
                depth = 0.35 + depth * 0.65,
                speed = (L.speed or 30) * (0.7 + size * 0.1) * (0.85 + math.random() * 0.3),
                drift = (math.random() - 0.5) * 8,
                amp = 5 + math.random() * 14,
                freq = 0.6 + math.random() * 1.4,
                ph = math.random() * 6.28,
                twinkle = math.random() < 0.25,
            }
        end
    end
    return field
end

local function stepSnowField(field, dt, t, windTarget, mx, my, fade)
    field.wind = field.wind + (windTarget - field.wind) * (1 - math.exp(-dt * 3))
    local w, h, wind = field.w, field.h, field.wind
    for _, s in ipairs(field.flakes) do
        if s.on then
            local x = s.x + (s.drift + wind * s.depth + math.sin(t * s.freq + s.ph) * s.amp) * dt
            local y = s.y + s.speed * dt
            if mx then
                local dx, dy = x - mx, y - my
                local d2 = dx * dx + dy * dy
                if d2 < 8100 and d2 > 1 then
                    local d = math.sqrt(d2)
                    local push = (90 - d) / 90 * 90 * dt
                    x = x + dx / d * push
                    y = y + dy / d * push
                end
            end
            if y > h + 10 then
                y = -10
                x = math.random() * w
            end
            if x > w + 12 then
                x = -12
            elseif x < -12 then
                x = w + 12
            end
            s.x, s.y = x, y
            s.f.Position = UDim2.fromOffset(x, y)
            local tr = s.base
            if s.twinkle then
                tr = tr + math.sin(t * 2.2 + s.ph) * 0.12
            end
            s.f.BackgroundTransparency = math.clamp(1 - (1 - tr) * fade, 0, 1)
        end
    end
end

---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local startTheme = Themes[cfg.Theme or ""] and cfg.Theme or "Crimson"
    applyTheme(startTheme)

    local useLoader = cfg.Loader ~= false
    local Window = {
        Tabs = {}, Conns = {}, Hooks = {}, Updaters = {}, Setters = {},
        Minimized = false, Visible = not useLoader, Loading = useLoader,
        Active = nil, Destroyed = false, ThemeName = startTheme,
    }
    local updaters = Window.Updaters

    local W, H = cfg.Width or 680, cfg.Height or 460
    local TOP, FOOT = 48, 46
    local title = cfg.Title or "DH"
    local logoText = cfg.LogoText or string.upper(string.sub(title, 1, 2))
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    local folder = cfg.ConfigFolder or "DHUI"
    local ON_COLOR, OFF_COLOR = rgb(126, 240, 160), rgb(220, 20, 60)

    local function connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(Window.Conns, c)
        return c
    end

    -- theme binding -------------------------------------------------
    local function themed(fn)
        fn(false)
        table.insert(Window.Hooks, fn)
    end

    local function bind(inst, prop, key)
        themed(function(animate)
            if animate then
                tween(inst, {[prop] = Theme[key]}, 0.4)
            else
                inst[prop] = Theme[key]
            end
        end)
    end

    local function bgSeq()
        return ColorSequence.new(Theme.Background, Theme.Background2)
    end

    local function accentSeq()
        return ColorSequence.new(Theme.Accent, Theme.Accent2)
    end

    local function borderSeq()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(0.5, Theme.Accent2),
            ColorSequenceKeypoint.new(1, Theme.Accent),
        })
    end

    local function accentGrad(parent, rotation)
        local g = create("UIGradient", {Color = accentSeq(), Rotation = rotation or 0, Parent = parent})
        themed(function()
            g.Color = accentSeq()
        end)
        return g
    end

    local function label(parent, text, props, key)
        local l = create("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme[key or "Text"],
            Parent = parent,
        })
        for k, v in pairs(props or {}) do
            l[k] = v
        end
        bind(l, "TextColor3", key or "Text")
        return l
    end

    local function snowField(parent, w, h, layers)
        local fld = newSnowField(parent, w, h, layers)
        themed(function()
            for _, s in ipairs(fld.flakes) do
                s.f.BackgroundColor3 = Theme.Snow
            end
        end)
        return fld
    end

    -- screen / state --------------------------------------------------
    local gui = create("ScreenGui", {
        Name = cfg.Name or "DHUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    gui.Parent = getGuiParent()

    local function screenSize()
        local s = gui.AbsoluteSize
        if s.X < 100 or s.Y < 100 then
            local cam = workspace.CurrentCamera
            return cam and cam.ViewportSize or Vector2.new(1280, 720)
        end
        return s
    end

    local scr = screenSize()
    local posX, posY = (scr.X - W) / 2, (scr.Y - H) / 2
    local tgtX, tgtY = posX, posY
    local slide, slideTarget = 36, 0

    local function clampTarget(x, y)
        local s = screenSize()
        return math.clamp(x, 90 - W, s.X - 90), math.clamp(y, 0, s.Y - 60)
    end

    ---------------------------------------------------------------------
    -- Backdrop: dim + blur + screen-wide snow (only while the GUI is open)
    ---------------------------------------------------------------------
    local backdrop, backdropTarget = 0, useLoader and 0 or 1
    local dimAlpha = cfg.Dim or 0.45
    local blurSize = cfg.BlurSize or 20
    local blurOn = cfg.Blur ~= false
    local screenSnowOn = cfg.ScreenSnow ~= false

    local dim = create("Frame", {
        Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Dim,
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = gui,
    })
    bind(dim, "BackgroundColor3", "Dim")

    local screenHolder = create("Frame", {
        Name = "ScreenSnow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Visible = false, ZIndex = 2, Parent = gui,
    })
    local sf = cfg.ScreenSnowCount or 1
    local screenField = snowField(screenHolder, scr.X, scr.Y, {
        {count = math.floor(55 * sf), minS = 1.5, maxS = 3, minT = 0.55, maxT = 0.85, speed = 26},
        {count = math.floor(45 * sf), minS = 2.5, maxS = 5, minT = 0.4, maxT = 0.75, speed = 46},
        {count = math.floor(18 * sf), minS = 6, maxS = 12, minT = 0.8, maxT = 0.93, speed = 90},
    })

    local blur = Instance.new("BlurEffect")
    blur.Name = "DH_Blur"
    blur.Size = 0
    blur.Enabled = false
    pcall(function()
        blur.Parent = Lighting
    end)

    -- root / main -----------------------------------------------------
    local root = create("Frame", {
        Name = "Root",
        Size = UDim2.fromOffset(W, H),
        Position = UDim2.fromOffset(posX, posY + slide),
        BackgroundTransparency = 1,
        Visible = not useLoader,
        ZIndex = 3,
        Parent = gui,
    })

    local shadow = create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.35,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 80, 1, 80),
        Position = UDim2.new(0, -40, 0, -30),
        Parent = root,
    })

    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    }, {corner(12)})
    local bgGrad = create("UIGradient", {Color = bgSeq(), Rotation = 62, Parent = main})
    themed(function()
        bgGrad.Color = bgSeq()
    end)

    local borderStroke = create("UIStroke", {
        Color = WHITE, Thickness = 1.5, Transparency = 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main,
    })
    local borderGrad = create("UIGradient", {Color = borderSeq(), Parent = borderStroke})
    themed(function()
        borderGrad.Color = borderSeq()
    end)

    -- slow drifting aurora orbs behind everything
    local orbs = {}
    local orbSpecs = {
        {size = 280, x = 0.12, y = 0.22, sx = 0.35, sy = 0.27, key = "Glow"},
        {size = 240, x = 0.86, y = 0.78, sx = 0.28, sy = 0.33, key = "Glow2"},
        {size = 190, x = 0.55, y = 0.08, sx = 0.41, sy = 0.23, key = "Glow"},
    }
    for i, spec in ipairs(orbSpecs) do
        local orb = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(spec.x, spec.y),
            Size = UDim2.fromOffset(spec.size, spec.size), BackgroundColor3 = WHITE,
            BorderSizePixel = 0, ZIndex = 1, Parent = main,
        }, {round()})
        local og = create("UIGradient", {
            Rotation = 45 + i * 40,
            Color = ColorSequence.new(Theme[spec.key], Theme.Accent2),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.84),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = orb,
        })
        themed(function()
            og.Color = ColorSequence.new(Theme[spec.key], Theme.Accent2)
        end)
        orbs[i] = {f = orb, spec = spec}
    end

    -- fade cover used for show / hide
    local cover = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false, ZIndex = 100, Parent = main,
    }, {corner(12)})
    bind(cover, "BackgroundColor3", "Background")

    ---------------------------------------------------------------------
    -- Snow inside the window (back = big and soft, front = small and crisp)
    ---------------------------------------------------------------------
    local snowCfg = type(cfg.Snow) == "table" and cfg.Snow or {}
    local snowBuilt = cfg.Snow ~= false
    local snowOn = snowBuilt and snowCfg.Enabled ~= false
    local snowFields, snowHolders = {}, {}
    local toggleSnowHolder

    if snowBuilt then
        local total = snowCfg.Count or 90
        local backHolder = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
            ZIndex = 1, Visible = snowOn, Parent = main,
        })
        local frontHolder = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
            ZIndex = 15, Visible = snowOn, Parent = main,
        })
        snowHolders = {backHolder, frontHolder}
        snowFields[1] = snowField(backHolder, W, H, {
            {count = math.floor(total * 0.45), minS = 3, maxS = 7, minT = 0.6, maxT = 0.88, speed = 24},
        })
        snowFields[2] = snowField(frontHolder, W, H, {
            {count = math.ceil(total * 0.55), minS = 1.6, maxS = 4, minT = 0.3, maxT = 0.7, speed = 34},
        })
    end

    function Window:SetSnow(on)
        if snowBuilt then
            snowOn = on and true or false
            for _, h in ipairs(snowHolders) do
                h.Visible = snowOn
            end
            if toggleSnowHolder then
                toggleSnowHolder.Visible = snowOn
            end
        end
    end

    function Window:SetSnowCount(n)
        local i = 0
        for _, fld in ipairs(snowFields) do
            for _, s in ipairs(fld.flakes) do
                i = i + 1
                s.on = i <= n
                s.f.Visible = s.on
            end
        end
    end

    function Window:SetScreenSnow(on)
        screenSnowOn = on and true or false
    end

    function Window:SetBlur(on)
        blurOn = on and true or false
    end

    function Window:SetBlurSize(n)
        blurSize = math.clamp(n, 0, 56)
    end

    function Window:SetDim(alpha)
        dimAlpha = math.clamp(alpha, 0, 1)
    end

    ---------------------------------------------------------------------
    -- Topbar: logo, title, tag, tab button, minimize, close
    ---------------------------------------------------------------------
    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, TOP),
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = main,
    }, {corner(12)})
    bind(topbar, "BackgroundColor3", "Topbar")

    local topFiller = create("Frame", {
        Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, Parent = topbar,
    })
    bind(topFiller, "BackgroundColor3", "Topbar")

    -- logo: ring with a rotating gradient, gradient monogram, orbiting dot
    local logo = create("Frame", {
        Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(12, 7),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = topbar,
    }, {round()})
    bind(logo, "BackgroundColor3", "Background")
    local logoStroke = create("UIStroke", {
        Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = logo,
    })
    local logoRing = create("UIGradient", {Color = borderSeq(), Parent = logoStroke})
    themed(function()
        logoRing.Color = borderSeq()
    end)
    local logoInner = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(26, 26), BackgroundColor3 = WHITE, BackgroundTransparency = 0.78,
        BorderSizePixel = 0, Parent = logo,
    }, {round()})
    accentGrad(logoInner, 45)
    local logoTxt = create("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = logoText,
        Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = WHITE, Parent = logo,
    })
    accentGrad(logoTxt, 90)
    local logoDot = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.fromOffset(5, 5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Parent = logo,
    }, {round()})

    -- title: heavy font with a shimmering gradient
    local titleLbl = create("TextLabel", {
        Position = UDim2.fromOffset(56, 0), Size = UDim2.new(0, 60, 1, 0),
        BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBlack, TextSize = 18,
        TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Parent = topbar,
    })
    local function titleSeq()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Text),
            ColorSequenceKeypoint.new(0.5, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.Accent2),
        })
    end
    local titleGrad = create("UIGradient", {Color = titleSeq(), Parent = titleLbl})
    themed(function()
        titleGrad.Color = titleSeq()
    end)

    -- tag: glowing pill with a pulsing status dot
    local tagPill, tagDot
    if cfg.Tag ~= false and cfg.Subtitle ~= false then
        local tagText = cfg.Tag or cfg.Subtitle or ("v" .. Library.Version)
        local tgw = textWidth(tagText, 10, Enum.Font.GothamBold) + 30
        tagPill = create("Frame", {
            Size = UDim2.fromOffset(tgw, 20), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.86,
            BorderSizePixel = 0, Parent = topbar,
        }, {round()})
        bind(tagPill, "BackgroundColor3", "Accent")
        local tagStroke = create("UIStroke", {
            Color = WHITE, Thickness = 1, Transparency = 0.3,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tagPill,
        })
        accentGrad(tagStroke, 0)
        tagDot = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0),
            Size = UDim2.fromOffset(5, 5), BackgroundColor3 = Theme.Accent2, BorderSizePixel = 0, Parent = tagPill,
        }, {round()})
        bind(tagDot, "BackgroundColor3", "Accent2")
        label(tagPill, tagText, {
            Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -24, 1, 0),
            Font = Enum.Font.GothamBold, TextSize = 10,
        }, "Accent")
    end

    local function layoutTop()
        local tw = math.min(130, textWidth(titleLbl.Text, 18, Enum.Font.GothamBlack))
        titleLbl.Size = UDim2.new(0, tw + 4, 1, 0)
        if tagPill then
            tagPill.Position = UDim2.fromOffset(56 + tw + 12, 14)
        end
    end
    layoutTop()

    -- center tab button ------------------------------------------------
    local tabBtn = create("TextButton", {
        Name = "TabButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(196, 32),
        BackgroundColor3 = Theme.Element,
        Text = "", AutoButtonColor = false, Parent = topbar,
    }, {corner(8)})
    bind(tabBtn, "BackgroundColor3", "Element")
    local tabBtnStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.15, Parent = tabBtn})
    bind(tabBtnStroke, "Color", "Stroke")
    for i = 0, 2 do
        local bar = create("Frame", {
            Position = UDim2.fromOffset(13, 11 + i * 4), Size = UDim2.fromOffset(i == 1 and 9 or 13, 2),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = tabBtn,
        }, {round()})
        bind(bar, "BackgroundColor3", "Accent")
    end
    local tabBtnLbl = label(tabBtn, "Tabs", {
        Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -66, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local chevron = label(tabBtn, ">", {
        Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(18, 32),
        TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Rotation = 90,
    }, "Accent")

    -- minimize / close ---------------------------------------------------
    local function topBtn(xOff, hoverColor)
        local b = create("TextButton", {
            Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0.5, -14),
            BackgroundColor3 = Theme.Element, Text = "", AutoButtonColor = false, Parent = topbar,
        }, {corner(8)})
        bind(b, "BackgroundColor3", "Element")
        connect(b.MouseEnter, function()
            tween(b, {BackgroundColor3 = Theme[hoverColor]}, 0.15)
        end)
        connect(b.MouseLeave, function()
            tween(b, {BackgroundColor3 = Theme.Element}, 0.2)
        end)
        return b
    end

    local closeBtn = topBtn(-40, "Error")
    local minBtn = topBtn(-74, "Warning")

    for _, rot in ipairs({45, -45}) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 2), Rotation = rot,
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = closeBtn,
        }, {round()})
    end
    local minLine = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(11, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = minBtn,
    }, {round()})
    local minBox = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Visible = false, Parent = minBtn,
    }, {corner(2), create("UIStroke", {Color = WHITE, Thickness = 2})})

    -- animated accent line under the topbar
    local line = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, TOP),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = main,
    })
    local lineGrad = accentGrad(line, 0)

    -- smooth window dragging (target position, eased every frame)
    do
        local dragging, grabX, grabY = false, 0, 0
        connect(topbar.InputBegan, function(input)
            if isPress(input) then
                dragging = true
                local p = pointer(input)
                grabX, grabY = p.X - tgtX, p.Y - tgtY
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and isMove(input) then
                local p = pointer(input)
                tgtX, tgtY = clampTarget(p.X - grabX, p.Y - grabY)
            end
        end)
    end

    ---------------------------------------------------------------------
    -- Body, footer (profile card, bottom left) and tab menu
    ---------------------------------------------------------------------
    local body = create("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(0, TOP + 1),
        Size = UDim2.new(1, 0, 1, -(TOP + 1)),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = main,
    })
    local pageArea = create("Frame", {
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 1, -(FOOT + 20)),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = body,
    })

    local footer = create("Frame", {
        Name = "Footer",
        Position = UDim2.new(0, 0, 1, -FOOT),
        Size = UDim2.new(1, 0, 0, FOOT),
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = main,
    }, {corner(12)})
    bind(footer, "BackgroundColor3", "Topbar")
    local footerFiller = create("Frame", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, Parent = footer,
    })
    bind(footerFiller, "BackgroundColor3", "Topbar")
    local footerLine = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.35,
        BorderSizePixel = 0, Parent = footer,
    })
    bind(footerLine, "BackgroundColor3", "Stroke")

    local lp = Players.LocalPlayer
    local dispName = lp and lp.DisplayName or "Player"
    local userName = "@" .. (lp and lp.Name or "unknown")
    local profW = 3 + 28 + 9 + math.max(textWidth(dispName, 12, Enum.Font.GothamBold), textWidth(userName, 10, Enum.Font.Code)) + 18
    local profile = create("Frame", {
        Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(profW, 34),
        BackgroundColor3 = Theme.Element, BorderSizePixel = 0, Parent = footer,
    }, {round()})
    bind(profile, "BackgroundColor3", "Element")
    local profStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.35, Parent = profile})
    bind(profStroke, "Color", "Stroke")

    local avatar = create("ImageLabel", {
        Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Image = "", Parent = profile,
    }, {round()})
    bind(avatar, "BackgroundColor3", "Stroke")
    local avRing = create("UIStroke", {
        Color = WHITE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = avatar,
    })
    accentGrad(avRing, 45)
    local onlineDot = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(28, 28), Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = ON_COLOR, BorderSizePixel = 0, ZIndex = 2, Parent = profile,
    }, {round()})
    local onlineStroke = create("UIStroke", {Color = Theme.Element, Thickness = 2, Parent = onlineDot})
    bind(onlineStroke, "Color", "Element")
    label(profile, dispName, {
        Position = UDim2.fromOffset(40, 3), Size = UDim2.new(1, -46, 0, 16),
        Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    label(profile, userName, {
        Position = UDim2.fromOffset(40, 18), Size = UDim2.new(1, -46, 0, 12),
        Font = Enum.Font.Code, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd,
    }, "SubText")
    if lp then
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            if ok and img and avatar.Parent then
                avatar.Image = img
                avatar.ImageTransparency = 1
                tween(avatar, {ImageTransparency = 0}, 0.5)
            end
        end)
    end

    local hintLbl = label(footer, "", {
        Position = UDim2.new(1, -250, 0, 0), Size = UDim2.new(0, 238, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 11,
    }, "SubText")
    local fpsShown = 0
    local function updateHint()
        hintLbl.Text = string.format("%d FPS   |   %s to toggle", fpsShown, toggleKey.Name)
    end
    updateHint()
    do
        local frames, acc = 0, 0
        table.insert(updaters, function(dt)
            frames = frames + 1
            acc = acc + dt
            if acc >= 0.5 then
                fpsShown = math.floor(frames / acc + 0.5)
                frames, acc = 0, 0
                updateHint()
            end
        end)
    end

    -- tab menu (popup under the center button) --------------------------
    local menuW = math.min(W - 40, 440)
    local menuHeight = 54
    local menuOpen = false

    local backdropBtn = create("TextButton", {
        Position = UDim2.fromOffset(0, TOP + 1), Size = UDim2.new(1, 0, 1, -(TOP + 1)),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 39, Parent = main,
    })

    local menu = create("CanvasGroup", {
        Name = "TabMenu",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, TOP + 8),
        Size = UDim2.fromOffset(menuW, 0),
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 40,
        Parent = main,
    }, {corner(10)})
    bind(menu, "BackgroundColor3", "Topbar")
    local menuStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.1, Parent = menu})
    bind(menuStroke, "Color", "Stroke")

    local function setMenu(open)
        menuOpen = open and true or false
        if menuOpen then
            menu.Visible = true
            backdropBtn.Visible = true
            tween(menu, {Size = UDim2.fromOffset(menuW, menuHeight), GroupTransparency = 0}, 0.34)
            tween(chevron, {Rotation = -90}, 0.32, Enum.EasingStyle.Back)
            tween(tabBtnStroke, {Color = Theme.Accent}, 0.2)
        else
            backdropBtn.Visible = false
            local t = tween(menu, {Size = UDim2.fromOffset(menuW, 0), GroupTransparency = 1}, 0.22)
            tween(chevron, {Rotation = 90}, 0.25)
            tween(tabBtnStroke, {Color = Theme.Stroke}, 0.25)
            t.Completed:Connect(function()
                if not menuOpen then
                    menu.Visible = false
                end
            end)
        end
    end
    connect(tabBtn.MouseButton1Click, function()
        setMenu(not menuOpen)
    end)
    connect(backdropBtn.MouseButton1Click, function()
        setMenu(false)
    end)
    connect(tabBtn.MouseEnter, function()
        tween(tabBtn, {BackgroundColor3 = Theme.ElementHover}, 0.15)
    end)
    connect(tabBtn.MouseLeave, function()
        tween(tabBtn, {BackgroundColor3 = Theme.Element}, 0.2)
    end)

    -- flow layout: chips fill the row, the next one wraps to a new row
    local function reflowTabs()
        local padX, padY, gap, rowH = 10, 10, 6, 30
        local inner = menuW - padX * 2
        local x, y = 0, 0
        for _, t in ipairs(Window.Tabs) do
            if x + t.ChipWidth > inner and x > 0 then
                x = 0
                y = y + rowH + gap
            end
            tween(t.Chip, {Position = UDim2.fromOffset(padX + x, padY + y)}, 0.32)
            x = x + t.ChipWidth + gap
        end
        menuHeight = padY * 2 + y + rowH
        if menuOpen then
            tween(menu, {Size = UDim2.fromOffset(menuW, menuHeight)}, 0.3)
        end
    end

    ---------------------------------------------------------------------
    -- Tooltips (any element with a Tooltip field)
    ---------------------------------------------------------------------
    local tipState = {text = nil, since = 0, shown = false}
    local tipFrame = create("Frame", {
        Size = UDim2.fromOffset(100, 24), BackgroundColor3 = Theme.Topbar, BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false, ZIndex = 60, Parent = main,
    }, {corner(6)})
    bind(tipFrame, "BackgroundColor3", "Topbar")
    local tipStroke = create("UIStroke", {Color = Theme.Accent, Transparency = 0.4, Parent = tipFrame})
    bind(tipStroke, "Color", "Accent")
    local tipLbl = label(tipFrame, "", {
        Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 11, TextTransparency = 1,
    })

    local function tipEnter(text)
        tipState.text = text
        tipState.since = os.clock()
    end
    local function tipLeave(text)
        if tipState.text == text then
            tipState.text = nil
        end
    end

    table.insert(updaters, function()
        if tipState.text and Window.Visible and os.clock() - tipState.since > 0.45 then
            if tipLbl.Text ~= tipState.text then
                tipLbl.Text = tipState.text
                tipFrame.Size = UDim2.fromOffset(textWidth(tipState.text, 11, Enum.Font.GothamMedium) + 22, 24)
            end
            local mp = UserInputService:GetMouseLocation()
            local org = main.AbsolutePosition
            local x = math.clamp(mp.X - org.X + 14, 6, W - tipFrame.Size.X.Offset - 6)
            local y = math.clamp(mp.Y - org.Y + 22, 6, H - 34)
            tipFrame.Position = UDim2.fromOffset(x, y)
            if not tipState.shown then
                tipState.shown = true
                tipFrame.Visible = true
                tween(tipFrame, {BackgroundTransparency = 0.05}, 0.18)
                tween(tipLbl, {TextTransparency = 0}, 0.18)
            end
        elseif tipState.shown then
            tipState.shown = false
            local t = tween(tipFrame, {BackgroundTransparency = 1}, 0.12)
            tween(tipLbl, {TextTransparency = 1}, 0.12)
            t.Completed:Connect(function()
                if not tipState.shown then
                    tipFrame.Visible = false
                end
            end)
        end
    end)

    ---------------------------------------------------------------------
    -- Minimize / close / visibility
    ---------------------------------------------------------------------
    local function setMinimized(state)
        Window.Minimized = state
        setMenu(false)
        minLine.Visible = not state
        minBox.Visible = state
        topFiller.Visible = not state
        footer.Visible = not state
        if state then
            local t = tween(root, {Size = UDim2.fromOffset(W, TOP + 2)}, 0.32, Enum.EasingStyle.Quint)
            t.Completed:Connect(function()
                if Window.Minimized then
                    body.Visible = false
                end
            end)
        else
            body.Visible = true
            tween(root, {Size = UDim2.fromOffset(W, H)}, 0.4, Enum.EasingStyle.Back)
        end
    end
    function Window:Minimize()
        setMinimized(not Window.Minimized)
    end
    connect(minBtn.MouseButton1Click, function()
        Window:Minimize()
    end)

    function Window:SetVisible(state)
        state = state and true or false
        if Window.Loading or Window.Destroyed or Window.Visible == state then
            return
        end
        Window.Visible = state
        backdropTarget = state and 1 or 0
        Window.PaintToggle(true)
        if state then
            root.Visible = true
            slide, slideTarget = 36, 0
            cover.Visible = true
            cover.BackgroundTransparency = 0
            tween(shadow, {ImageTransparency = 0.35}, 0.4)
            local t = tween(cover, {BackgroundTransparency = 1}, 0.4)
            t.Completed:Connect(function()
                if Window.Visible then
                    cover.Visible = false
                end
            end)
        else
            setMenu(false)
            slideTarget = 36
            cover.Visible = true
            cover.BackgroundTransparency = 1
            tween(shadow, {ImageTransparency = 1}, 0.25)
            local t = tween(cover, {BackgroundTransparency = 0}, 0.26)
            t.Completed:Connect(function()
                if not Window.Visible then
                    root.Visible = false
                end
            end)
        end
    end

    function Window:Toggle()
        Window:SetVisible(not Window.Visible)
    end

    function Window:Destroy()
        if Window.Destroyed then
            return
        end
        Window.Destroyed = true
        safeCall(cfg.OnClose)
        for _, c in ipairs(Window.Conns) do
            c:Disconnect()
        end
        Window.Conns = {}
        pcall(function()
            blur:Destroy()
        end)
        cover.Visible = true
        tween(cover, {BackgroundTransparency = 0}, 0.25)
        tween(shadow, {ImageTransparency = 1}, 0.25)
        tween(dim, {BackgroundTransparency = 1}, 0.25)
        tween(root, {Position = UDim2.fromOffset(root.Position.X.Offset, root.Position.Y.Offset + 40)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.32, function()
            gui:Destroy()
        end)
    end
    connect(closeBtn.MouseButton1Click, function()
        Window:Destroy()
    end)

    connect(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == toggleKey and not Window.Loading then
            Window:Toggle()
        end
    end)

    ---------------------------------------------------------------------
    -- Round toggle button: themed like the GUI, with its own snow
    ---------------------------------------------------------------------
    local tbText = cfg.ToggleText or "DH"
    local TB = cfg.ToggleSize or 46
    local tbStart = typeof(cfg.TogglePosition) == "Vector2" and cfg.TogglePosition or Vector2.new(16, 76)
    local btnPos, btnTgt = tbStart, tbStart

    local toggleBtn = create("Frame", {
        Name = "ToggleButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(TB, TB),
        Position = UDim2.fromOffset(tbStart.X + TB / 2, tbStart.Y + TB / 2),
        BackgroundTransparency = 1,
        Visible = not useLoader,
        ZIndex = 6,
        Parent = gui,
    })
    local tbScale = create("UIScale", {Scale = 1, Parent = toggleBtn})

    local halo = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(TB + 18, TB + 18), BackgroundColor3 = WHITE, BackgroundTransparency = 0.82,
        BorderSizePixel = 0, Parent = toggleBtn,
    }, {round()})
    accentGrad(halo, 45)

    local disc = create("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = toggleBtn,
    }, {round()})
    local discGrad = create("UIGradient", {Color = bgSeq(), Rotation = 62, Parent = disc})
    themed(function()
        discGrad.Color = bgSeq()
    end)
    local tbGlow = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = disc,
    })
    local tbGlowGrad = create("UIGradient", {
        Rotation = 38, Color = accentSeq(),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(0.65, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = tbGlow,
    })
    themed(function()
        tbGlowGrad.Color = accentSeq()
    end)
    local tbLbl = create("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tbText,
        Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = WHITE, Parent = disc,
    })
    accentGrad(tbLbl, 90)

    toggleSnowHolder = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = snowOn, Parent = disc,
    })
    local tbField
    if snowBuilt then
        tbField = snowField(toggleSnowHolder, TB, TB, {
            {count = 16, minS = 1.4, maxS = 3.4, minT = 0.3, maxT = 0.75, speed = 14},
        })
    end

    local ring = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = toggleBtn,
    }, {round()})
    local ringStroke = create("UIStroke", {
        Color = WHITE, Thickness = 2, Transparency = 0.1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ring,
    })
    local tbRing = create("UIGradient", {Color = borderSeq(), Parent = ringStroke})
    themed(function()
        tbRing.Color = borderSeq()
    end)

    local tbDot = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.85, 0.85), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = ON_COLOR, BorderSizePixel = 0, Parent = toggleBtn,
    }, {round()})
    local tbDotStroke = create("UIStroke", {Color = Theme.Background, Thickness = 2, Parent = tbDot})
    bind(tbDotStroke, "Color", "Background")

    local tbHit = create("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 10, Parent = toggleBtn,
    })

    function Window.PaintToggle(animate)
        local on = Window.Visible
        local dotColor = on and ON_COLOR or OFF_COLOR
        local ringT = on and 0.1 or 0.5
        local grp = on and 0 or 0.35
        local haloT = on and 0.82 or 0.95
        if animate then
            tween(tbDot, {BackgroundColor3 = dotColor}, 0.3)
            tween(ringStroke, {Transparency = ringT}, 0.3)
            tween(disc, {GroupTransparency = grp}, 0.3)
            tween(halo, {BackgroundTransparency = haloT}, 0.3)
        else
            tbDot.BackgroundColor3 = dotColor
            ringStroke.Transparency = ringT
            disc.GroupTransparency = grp
            halo.BackgroundTransparency = haloT
        end
    end
    Window.PaintToggle(false)

    do
        local dragging, moved, hovering = false, false, false
        local startP, grab = Vector2.new(), Vector2.new()
        connect(tbHit.MouseEnter, function()
            hovering = true
            tween(tbScale, {Scale = 1.1}, 0.2, Enum.EasingStyle.Back)
            tween(ringStroke, {Thickness = 3}, 0.15)
        end)
        connect(tbHit.MouseLeave, function()
            hovering = false
            tween(tbScale, {Scale = 1}, 0.2)
            tween(ringStroke, {Thickness = 2}, 0.2)
        end)
        connect(tbHit.InputBegan, function(input)
            if isPress(input) then
                dragging, moved = true, false
                startP = pointer(input)
                grab = startP - btnTgt
                tween(tbScale, {Scale = 0.9}, 0.12)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        tween(tbScale, {Scale = hovering and 1.1 or 1}, 0.25, Enum.EasingStyle.Back)
                        if not moved and not Window.Loading then
                            Window:Toggle()
                        end
                    end
                end)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and isMove(input) then
                local p = pointer(input)
                if (p - startP).Magnitude > 6 then
                    moved = true
                end
                if moved then
                    local s = screenSize()
                    local t = p - grab
                    btnTgt = Vector2.new(math.clamp(t.X, 0, s.X - TB), math.clamp(t.Y, 0, s.Y - TB))
                end
            end
        end)
    end

    ---------------------------------------------------------------------
    -- Window methods
    ---------------------------------------------------------------------
    function Window:SetToggleKey(key)
        toggleKey = key
        updateHint()
    end

    function Window:SetTitle(text)
        titleLbl.Text = text
        layoutTop()
    end

    function Window:SetTheme(name)
        if Themes[name] and applyTheme(name) then
            Window.ThemeName = name
            for _, hook in ipairs(Window.Hooks) do
                pcall(hook, true)
            end
        end
    end

    ---------------------------------------------------------------------
    -- Notifications (stacked bottom right, hover to pause, click to dismiss)
    ---------------------------------------------------------------------
    local NW = 336
    local notifs = {}
    local MAXN = cfg.MaxNotifications or 5
    local notifHolder = create("Frame", {
        Name = "Notifications", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8, Parent = gui,
    })

    local function contrastOn(c)
        local lum = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
        return lum > 0.55 and rgb(10, 10, 12) or WHITE
    end

    local function notifRelayout()
        local y = 0
        for i = #notifs, 1, -1 do
            local n = notifs[i]
            n.y = y
            tween(n.wrap, {Position = UDim2.new(1, -18, 1, -(18 + y))}, 0.45, Enum.EasingStyle.Quint)
            y = y + n.h + 10
        end
    end

    local function dismissNotif(n)
        if n.closing then
            return
        end
        n.closing = true
        for i, v in ipairs(notifs) do
            if v == n then
                table.remove(notifs, i)
                break
            end
        end
        notifRelayout()
        local t = tween(n.card, {Position = UDim2.new(1.25, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(n.shadow, {ImageTransparency = 1}, 0.3)
        t.Completed:Connect(function()
            n.wrap:Destroy()
        end)
    end

    local function notifGlyph(parent, kind, color)
        local function bar(x, y, w, rot)
            create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(w, 2.5), Rotation = rot, BackgroundColor3 = color,
                BorderSizePixel = 0, Parent = parent,
            }, {round()})
        end
        if kind == "Success" then
            bar(11.5, 16.5, 7, 45)
            bar(17.5, 14.5, 13, -50)
        elseif kind == "Error" then
            bar(15, 15, 13, 45)
            bar(15, 15, 13, -45)
        else
            create("TextLabel", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                Text = kind == "Warning" and "!" or "i", Font = Enum.Font.GothamBlack,
                TextSize = 16, TextColor3 = color, Parent = parent,
            })
        end
    end

    function Window:Notify(o)
        o = o or {}
        local kind = o.Type or "Info"
        local colors = {Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error}
        local color = colors[kind] or Theme.Accent
        local titleText, bodyText = o.Title or kind, o.Content or ""
        local textW = NW - 54 - 34
        local textH = textHeight(bodyText, 12, Enum.Font.Gotham, textW)
        local actions = type(o.Actions) == "table" and o.Actions or {}
        local h = math.max(68, 14 + 18 + 4 + textH + 16 + (#actions > 0 and 34 or 0))

        while #notifs >= MAXN do
            dismissNotif(notifs[1])
        end

        local n = {
            h = h, y = 0, t = 0, dur = o.Duration or 4, closing = false,
            manual = o.Progress ~= nil, progress = o.Progress or 0, shownP = o.Progress or 0,
        }
        n.persistent = o.Persistent == true or o.Duration == 0 or (n.manual and o.Duration == nil)

        n.wrap = create("Frame", {
            AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(NW, h),
            Position = UDim2.new(1, -18, 1, -18), BackgroundTransparency = 1, Parent = notifHolder,
        })
        n.shadow = create("ImageLabel", {
            BackgroundTransparency = 1, Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.45, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
            Size = UDim2.new(1, 44, 1, 44), Position = UDim2.fromOffset(-22, -14), Parent = n.wrap,
        })
        n.card = create("Frame", {
            Size = UDim2.fromScale(1, 1), Position = UDim2.new(1.25, 0, 0, 0),
            BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, ClipsDescendants = true, Parent = n.wrap,
        }, {corner(12), create("UIStroke", {Color = color, Transparency = 0.55, Thickness = 1})})
        local card = n.card
        create("UIGradient", {Color = ColorSequence.new(WHITE, rgb(214, 214, 226)), Rotation = 90, Parent = card})

        local wash = create("Frame", {
            Size = UDim2.new(0, 170, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card,
        })
        create("UIGradient", {Transparency = NumberSequence.new(0.8, 1), Parent = wash})
        create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card})

        local hit = create("TextButton", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = card,
        })
        connect(hit.MouseButton1Click, function()
            if o.Sticky ~= true then
                dismissNotif(n)
            end
        end)

        local icon = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(31, 29), Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = card,
        }, {round(), create("UIStroke", {Color = color, Transparency = 0.4, Thickness = 1})})
        local iconScale = create("UIScale", {Scale = 0.3, Parent = icon})
        notifGlyph(icon, kind, color)

        local titleLbl2 = create("TextLabel", {
            Position = UDim2.fromOffset(54, 11), Size = UDim2.fromOffset(textW, 18), BackgroundTransparency = 1,
            Text = titleText, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
        })
        local bodyLbl = create("TextLabel", {
            Position = UDim2.fromOffset(54, 31), Size = UDim2.fromOffset(textW, math.max(textH, 14)), BackgroundTransparency = 1,
            Text = bodyText, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, Parent = card,
        })

        -- close button
        local closeN = create("TextButton", {
            Position = UDim2.new(1, -28, 0, 8), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, Parent = card,
        })
        local xBars = {}
        for _, rot in ipairs({45, -45}) do
            xBars[#xBars + 1] = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 2),
                Rotation = rot, BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = closeN,
            }, {round()})
        end
        connect(closeN.MouseEnter, function()
            for _, b in ipairs(xBars) do
                tween(b, {BackgroundColor3 = Theme.Text}, 0.12)
            end
        end)
        connect(closeN.MouseLeave, function()
            for _, b in ipairs(xBars) do
                tween(b, {BackgroundColor3 = Theme.SubText}, 0.15)
            end
        end)
        connect(closeN.MouseButton1Click, function()
            dismissNotif(n)
        end)

        -- action buttons
        local ax = 54
        for _, act in ipairs(actions) do
            local aw = textWidth(act.Text or "OK", 12, Enum.Font.GothamBold) + 26
            local base = act.Primary and color or Theme.Element
            local ab = create("TextButton", {
                Position = UDim2.fromOffset(ax, 31 + textH + 8), Size = UDim2.fromOffset(aw, 24),
                BackgroundColor3 = base, Text = act.Text or "OK", Font = Enum.Font.GothamBold, TextSize = 12,
                TextColor3 = act.Primary and contrastOn(color) or Theme.Text, AutoButtonColor = false, Parent = card,
            }, {corner(6)})
            connect(ab.MouseEnter, function()
                tween(ab, {BackgroundColor3 = act.Primary and color:Lerp(WHITE, 0.2) or Theme.ElementHover}, 0.12)
            end)
            connect(ab.MouseLeave, function()
                tween(ab, {BackgroundColor3 = base}, 0.15)
            end)
            connect(ab.MouseButton1Click, function()
                safeCall(act.Callback)
                if act.Keep ~= true then
                    dismissNotif(n)
                end
            end)
            ax = ax + aw + 8
        end

        n.bar = create("Frame", {
            Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(n.manual and n.shownP or 1, 0, 0, 3),
            BackgroundColor3 = color, BorderSizePixel = 0, Parent = card,
        })

        table.insert(notifs, n)
        notifRelayout()
        tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.6, Enum.EasingStyle.Back)
        tween(iconScale, {Scale = 1}, 0.55, Enum.EasingStyle.Back)

        local handle = {}
        function handle:Dismiss()
            dismissNotif(n)
        end
        function handle:Update(u)
            u = u or {}
            if u.Title then
                titleLbl2.Text = u.Title
            end
            if u.Content then
                bodyLbl.Text = u.Content
            end
        end
        function handle:SetProgress(p)
            n.manual = true
            n.progress = math.clamp(p, 0, 1)
        end
        return handle
    end

    table.insert(updaters, function(dt)
        if #notifs == 0 then
            return
        end
        local mp = UserInputService:GetMouseLocation()
        for i = #notifs, 1, -1 do
            local n = notifs[i]
            if n and not n.closing then
                local p, s = n.wrap.AbsolutePosition, n.wrap.AbsoluteSize
                local inside = mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
                if n.manual then
                    n.shownP = n.shownP + (n.progress - n.shownP) * (1 - math.exp(-dt * 10))
                    n.bar.Size = UDim2.new(n.shownP, 0, 0, 3)
                    if n.progress >= 1 then
                        n.doneT = (n.doneT or 0) + dt
                        if n.doneT > 1.2 then
                            dismissNotif(n)
                        end
                    end
                elseif not n.persistent then
                    if not inside then
                        n.t = n.t + dt
                    end
                    n.bar.Size = UDim2.new(math.clamp(1 - n.t / n.dur, 0, 1), 0, 0, 3)
                    if n.t >= n.dur then
                        dismissNotif(n)
                    end
                end
            end
        end
    end)

    ---------------------------------------------------------------------
    -- Config save / load
    ---------------------------------------------------------------------
    function Window:SaveConfig(name)
        local data = {}
        for flag, val in pairs(Library.Flags) do
            data[flag] = ser(val)
        end
        local ok = pcall(function()
            if makefolder and isfolder and not isfolder(folder) then
                makefolder(folder)
            end
            writefile(folder .. "/" .. (name or "default") .. ".json", HttpService:JSONEncode(data))
        end)
        return ok
    end

    function Window:LoadConfig(name)
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(folder .. "/" .. (name or "default") .. ".json"))
        end)
        if not ok or type(data) ~= "table" then
            return false
        end
        for flag, val in pairs(data) do
            local setter = Window.Setters[flag]
            if setter then
                pcall(setter, deser(val))
            end
        end
        return true
    end

    ---------------------------------------------------------------------
    -- Loader: logo ring with orbiting dots, typewriter title, status
    -- messages, shining progress bar, rotating tips, snow
    ---------------------------------------------------------------------
    local loader

    local function startLoader()
        local LW, LH = 440, 276
        local D = cfg.LoadingTime or 2.8
        local statuses = cfg.LoadingStatus or {
            "Initializing core", "Loading themes", "Building interface", "Warming up the snow", "Finishing touches",
        }
        local tips = cfg.LoadingTips or {
            "Drag the title bar to move the window",
            "Click a section title to collapse it",
            "Drag the round button anywhere you like",
            "Press the toggle key to hide or show the GUI",
        }
        local fullTitle = cfg.LoadingTitle or title

        backdropTarget = 1

        local panel = create("CanvasGroup", {
            Name = "Loader", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(LW - 60, LH - 50), BackgroundColor3 = WHITE, BorderSizePixel = 0,
            GroupTransparency = 1, ZIndex = 20, Parent = gui,
        }, {corner(16)})
        local panelGrad = create("UIGradient", {Color = bgSeq(), Rotation = 62, Parent = panel})
        themed(function()
            panelGrad.Color = bgSeq()
        end)

        local glowOrb = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromOffset(320, 320),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1, Parent = panel,
        }, {round()})
        local glowOrbGrad = create("UIGradient", {
            Rotation = 90, Color = accentSeq(),
            Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1)}),
            Parent = glowOrb,
        })
        themed(function()
            glowOrbGrad.Color = accentSeq()
        end)

        local snowHolderL = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = panel,
        })
        local lfield = snowField(snowHolderL, LW, LH, {
            {count = 34, minS = 1.5, maxS = 4.2, minT = 0.35, maxT = 0.8, speed = 28},
        })

        -- logo ring + orbiting dots
        local ringHolder = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.fromOffset(76, 76),
            BackgroundTransparency = 1, ZIndex = 3, Parent = panel,
        })
        local ringScale = create("UIScale", {Parent = ringHolder})
        local rdisc = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = ringHolder,
        }, {round()})
        bind(rdisc, "BackgroundColor3", "Background")
        local rstroke = create("UIStroke", {
            Color = WHITE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = rdisc,
        })
        local rgrad = create("UIGradient", {Color = borderSeq(), Parent = rstroke})
        themed(function()
            rgrad.Color = borderSeq()
        end)
        local rinner = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0, Parent = rdisc,
        }, {round()})
        accentGrad(rinner, 45)
        local rmono = create("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = logoText,
            Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = WHITE, Parent = rdisc,
        })
        accentGrad(rmono, 90)
        local orbitDots = {}
        for i = 1, 3 do
            local sz = 9 - i * 2
            orbitDots[i] = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = WHITE,
                BackgroundTransparency = (i - 1) * 0.25, BorderSizePixel = 0, Parent = ringHolder,
            }, {round()})
        end

        -- title (typewriter + shimmer)
        local ltitle = create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 124), Size = UDim2.fromOffset(LW, 30),
            BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBlack, TextSize = 24,
            TextColor3 = WHITE, ZIndex = 3, Parent = panel,
        })
        local ltGrad = create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Text),
                ColorSequenceKeypoint.new(0.5, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.Accent2),
            }),
            Parent = ltitle,
        })
        themed(function()
            ltGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Text),
                ColorSequenceKeypoint.new(0.5, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.Accent2),
            })
        end)

        local statusLbl = label(panel, "", {
            Position = UDim2.fromOffset(44, 166), Size = UDim2.fromOffset(280, 18), ZIndex = 3,
            Font = Enum.Font.GothamMedium, TextSize = 12,
        }, "SubText")
        local pctLbl = label(panel, "0%", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(LW - 44, 166), Size = UDim2.fromOffset(80, 18),
            TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 12, ZIndex = 3,
        }, "Accent")

        local track = create("Frame", {
            Position = UDim2.fromOffset(44, 190), Size = UDim2.fromOffset(LW - 88, 8),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3, Parent = panel,
        }, {round()})
        bind(track, "BackgroundColor3", "Stroke")
        local fill = create("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track,
        }, {round()})
        accentGrad(fill, 0)
        local shine = create("Frame", {
            Size = UDim2.new(0, 64, 1, 0), Position = UDim2.fromScale(-0.3, 0), BackgroundColor3 = WHITE,
            BorderSizePixel = 0, ZIndex = 4, Parent = track,
        })
        create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = shine,
        })

        local tipLbl2 = label(panel, "", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 218), Size = UDim2.fromOffset(LW - 60, 18),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Gotham, TextSize = 11, ZIndex = 3,
        }, "SubText")
        local verLbl = label(panel, "DH UI v" .. Library.Version, {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 246), Size = UDim2.fromOffset(LW - 60, 14),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Code, TextSize = 10, ZIndex = 3,
            TextTransparency = 0.45,
        }, "SubText")

        tween(panel, {Size = UDim2.fromOffset(LW, LH), GroupTransparency = 0}, 0.55, Enum.EasingStyle.Back)

        local phase, phaseT, statusIdx, tipIdx, lastTip = "in", 0, 0, 0, -10
        local finished = false

        loader = {panel = panel}
        function loader.step(dt, clk)
            phaseT = phaseT + dt
            rgrad.Rotation = (clk * 140) % 360
            ringScale.Scale = 1 + math.sin(clk * 3) * 0.035
            for i, d in ipairs(orbitDots) do
                local a = clk * 2.6 - i * 0.42
                d.Position = UDim2.fromOffset(38 + math.cos(a) * 52, 38 + math.sin(a) * 52)
            end
            ltGrad.Offset = Vector2.new(math.sin(clk * 1.4) * 0.45, 0)
            stepSnowField(lfield, dt, clk, math.sin(clk * 0.8) * 20, nil, nil, 1)

            if phase == "in" then
                if phaseT >= 0.5 then
                    phase, phaseT = "run", 0
                end
            elseif phase == "run" then
                local x = math.clamp(phaseT / D, 0, 1)
                local p = x * x * (3 - 2 * x)
                fill.Size = UDim2.fromScale(p, 1)
                pctLbl.Text = string.format("%d%%", math.floor(p * 100 + 0.5))
                local chars = math.floor(math.clamp(phaseT / 0.7, 0, 1) * #fullTitle + 0.5)
                ltitle.Text = string.sub(fullTitle, 1, chars)
                local idx = math.min(#statuses, math.floor(x * #statuses) + 1)
                if idx ~= statusIdx then
                    statusIdx = idx
                    statusLbl.TextTransparency = 1
                    tween(statusLbl, {TextTransparency = 0}, 0.25)
                end
                statusLbl.Text = statuses[idx] .. string.rep(".", math.floor(clk * 3) % 4)
                if #tips > 0 and clk - lastTip > 1.3 then
                    lastTip = clk
                    tipIdx = tipIdx % #tips + 1
                    tipLbl2.Text = tips[tipIdx]
                    tipLbl2.TextTransparency = 1
                    tween(tipLbl2, {TextTransparency = 0}, 0.35)
                end
                shine.Position = UDim2.new(((clk * 0.9) % 1.5) - 0.3, 0, 0, 0)
                if x >= 1 then
                    phase, phaseT = "hold", 0
                    ltitle.Text = fullTitle
                    statusLbl.Text = "Ready"
                    pctLbl.Text = "100%"
                end
            elseif phase == "hold" then
                if phaseT >= 0.45 then
                    phase, phaseT = "out", 0
                    tween(panel, {GroupTransparency = 1, Size = UDim2.fromOffset(LW + 50, LH + 36)}, 0.5)
                end
            elseif phase == "out" then
                if phaseT >= 0.5 and not finished then
                    finished = true
                    panel:Destroy()
                    loader = nil
                    Window.Loading = false
                    toggleBtn.Visible = true
                    tbScale.Scale = 0.3
                    tween(tbScale, {Scale = 1}, 0.55, Enum.EasingStyle.Back)
                    Window:SetVisible(true)
                end
            end
        end
    end

    ---------------------------------------------------------------------
    -- Element toolkit
    ---------------------------------------------------------------------

    local function newElement(parent, height)
        local f = create("Frame", {
            Size = UDim2.new(1, 0, 0, height or 38),
            BackgroundColor3 = Theme.Element,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = parent,
        }, {corner(7)})
        bind(f, "BackgroundColor3", "Element")
        local st = create("UIStroke", {
            Color = Theme.Stroke, Transparency = 0.45, Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f,
        })
        bind(st, "Color", "Stroke")
        create("UIGradient", {
            Color = ColorSequence.new(WHITE, rgb(206, 206, 218)),
            Rotation = 90, Parent = f,
        })
        return f, st
    end

    local function hoverFx(btn, frame, stroke, extra)
        connect(btn.MouseEnter, function()
            tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.2)
            tween(stroke, {Color = Theme.Accent, Transparency = 0.2}, 0.2)
            if extra then
                extra(true)
            end
        end)
        connect(btn.MouseLeave, function()
            tween(frame, {BackgroundColor3 = Theme.Element}, 0.25)
            tween(stroke, {Color = Theme.Stroke, Transparency = 0.45}, 0.25)
            if extra then
                extra(false)
            end
        end)
    end

    local function ripple(frame, input)
        local p = pointer(input)
        local x = p.X - frame.AbsolutePosition.X
        local y = p.Y - frame.AbsolutePosition.Y
        local size = math.max(frame.AbsoluteSize.X, frame.AbsoluteSize.Y) * 2.4
        local c = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Parent = frame,
        }, {round()})
        tween(c, {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1}, 0.6)
        task.delay(0.65, function()
            c:Destroy()
        end)
    end

    local function overlay(f, st, extra, o)
        local b = create("TextButton", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, ZIndex = 10, Parent = f,
        })
        hoverFx(b, f, st, extra)
        local tipText = o and o.Tooltip
        if tipText then
            connect(b.MouseEnter, function()
                tipEnter(tipText)
            end)
            connect(b.MouseLeave, function()
                tipLeave(tipText)
            end)
        end
        connect(b.InputBegan, function(input)
            if isPress(input) then
                ripple(f, input)
            end
        end)
        return b
    end

    local function commit(o, value, silent)
        if o.Flag then
            Library.Flags[o.Flag] = value
        end
        if not silent then
            safeCall(o.Callback, value)
        end
    end

    local function register(o, setter)
        if o.Flag then
            Window.Setters[o.Flag] = setter
        end
    end

    -- name + optional description laid out inside an element
    local function nameBlock(f, o, defaultName, rightPad)
        local hasDesc = o.Description ~= nil and o.Description ~= ""
        label(f, o.Name or defaultName, {
            Position = UDim2.fromOffset(12, hasDesc and 7 or 0),
            Size = UDim2.new(1, -(rightPad or 60), 0, hasDesc and 18 or 38),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        if hasDesc then
            label(f, o.Description, {
                Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -(rightPad or 60), 0, 16),
                TextSize = 11, Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd,
            }, "SubText")
        end
        return hasDesc and 52 or 38
    end

    local E = {}

    -- Label ---------------------------------------------------------------
    function E.Label(parent, o)
        if type(o) == "string" then
            o = {Text = o}
        end
        local f = newElement(parent, 32)
        local l = label(f, o.Text or o.Name or "Label", {
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0),
            TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
        }, "SubText")
        local obj = {}
        function obj:Set(t)
            l.Text = t
        end
        return obj
    end

    -- Paragraph -----------------------------------------------------------
    function E.Paragraph(parent, o)
        local f = newElement(parent, 40)
        f.AutomaticSize = Enum.AutomaticSize.Y
        f.Size = UDim2.new(1, 0, 0, 0)
        create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f})
        create("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = f,
        })
        local t = label(f, o.Title or "Paragraph", {Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, LayoutOrder = 1})
        local c = label(f, o.Content or "", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top, TextSize = 12, Font = Enum.Font.Gotham, LayoutOrder = 2,
        }, "SubText")
        local obj = {}
        function obj:Set(title, content)
            t.Text = title or t.Text
            c.Text = content or c.Text
        end
        return obj
    end

    -- Divider -------------------------------------------------------------
    function E.Divider(parent)
        local d = create("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = parent})
        bind(d, "BackgroundColor3", "Stroke")
        return {}
    end

    -- Button --------------------------------------------------------------
    function E.Button(parent, o)
        local f, st = newElement(parent, 38)
        local height = nameBlock(f, o, "Button", 56)
        f.Size = UDim2.new(1, 0, 0, height)
        local glyph = label(f, ">", {
            Size = UDim2.fromOffset(20, height), Position = UDim2.new(1, -30, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold,
        }, "SubText")
        local b = overlay(f, st, function(on)
            tween(glyph, {
                Position = on and UDim2.new(1, -24, 0, 0) or UDim2.new(1, -30, 0, 0),
                TextColor3 = on and Theme.Accent or Theme.SubText,
            }, 0.2)
        end, o)
        connect(b.MouseButton1Click, function()
            safeCall(o.Callback)
        end)
        return {}
    end

    -- Toggle --------------------------------------------------------------
    function E.Toggle(parent, o)
        local state = o.Default == true
        local f, st = newElement(parent, 38)
        local height = nameBlock(f, o, "Toggle", 72)
        f.Size = UDim2.new(1, 0, 0, height)
        local track = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -52, 0.5, 0),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
        }, {round()})
        bind(track, "BackgroundColor3", "Stroke")
        local fill = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
            BorderSizePixel = 0, Parent = track,
        }, {round()})
        accentGrad(fill, 0)
        local knob = create("Frame", {
            Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = track,
        }, {round()})

        local function render(anim)
            local pos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            local kc = state and Theme.OnAccent or Theme.SubText
            if anim then
                knob.Size = UDim2.fromOffset(21, 14)
                tween(knob, {Size = UDim2.fromOffset(14, 14), Position = pos, BackgroundColor3 = kc}, 0.38, Enum.EasingStyle.Back)
                tween(fill, {BackgroundTransparency = state and 0 or 1}, 0.25)
            else
                knob.Position = pos
                knob.BackgroundColor3 = kc
                fill.BackgroundTransparency = state and 0 or 1
            end
        end

        local obj = {}
        function obj:Set(v, silent)
            state = v and true or false
            render(true)
            commit(o, state, silent)
        end
        function obj:Get()
            return state
        end

        local b = overlay(f, st, nil, o)
        connect(b.MouseButton1Click, function()
            obj:Set(not state)
        end)
        themed(function()
            render(false)
        end)
        register(o, function(v)
            obj:Set(v)
        end)
        -- fires the callback once at creation only when it starts enabled
        commit(o, state, (not state) or o.Silent)
        return obj
    end

    -- Slider: eased knob, hover growth, value bubble while dragging, ticks, typeable value ----
    function E.Slider(parent, o)
        local min = (o.Range and o.Range[1]) or 0
        local max = (o.Range and o.Range[2]) or 100
        local inc = o.Increment or 1
        local suffix = o.Suffix or ""
        local fmt = "%." .. decimalsOf(inc) .. "f"
        local value = math.clamp(o.Default or min, min, max)
        local BAR_Y = 44

        local function alphaOf(v)
            return (max == min) and 0 or (v - min) / (max - min)
        end
        local shownA = alphaOf(value)
        local dragging, hovered = false, false

        local f, st = newElement(parent, 68)
        label(f, o.Name or "Slider", {
            Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -112, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd,
        })

        local pill = create("Frame", {
            Position = UDim2.new(1, -92, 0, 6), Size = UDim2.fromOffset(80, 22), BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 20, Parent = f,
        }, {corner(6)})
        bind(pill, "BackgroundColor3", "Accent")
        local pillStroke = create("UIStroke", {Color = Theme.Accent, Transparency = 0.7, Parent = pill})
        bind(pillStroke, "Color", "Accent")
        local valBox = create("TextBox", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = Theme.Accent, ClearTextOnFocus = true, ZIndex = 21, Parent = pill,
        })
        bind(valBox, "TextColor3", "Accent")

        local bar = create("Frame", {
            Position = UDim2.new(0, 14, 0, BAR_Y), Size = UDim2.new(1, -28, 0, 6),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
        }, {round()})
        bind(bar, "BackgroundColor3", "Stroke")
        for i = 0, 4 do
            local tick = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(i / 4, 0, 1, 5), Size = UDim2.fromOffset(1, 4),
                BackgroundColor3 = Theme.SubText, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = bar,
            })
            bind(tick, "BackgroundColor3", "SubText")
        end
        local fill = create("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar,
        }, {round()})
        accentGrad(fill, 0)
        local glow = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = bar,
        }, {round()})
        accentGrad(glow, 45)
        local knob = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar,
        }, {round()})
        local knobStroke = create("UIStroke", {Color = Theme.Accent, Thickness = 2, Parent = knob})
        bind(knobStroke, "Color", "Accent")
        local knobDot = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = knob,
        }, {round()})
        bind(knobDot, "BackgroundColor3", "Accent")
        local knobScale = create("UIScale", {Parent = knob})

        local bubble = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(52, 22), BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 15, Parent = f,
        }, {corner(6)})
        bind(bubble, "BackgroundColor3", "Accent")
        local bubbleScale = create("UIScale", {Scale = 0.4, Parent = bubble})
        local bubbleLbl = label(bubble, "", {
            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.Code, TextSize = 11, TextTransparency = 1,
        }, "OnAccent")
        local bubblePtr = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(8, 8),
            Rotation = 45, BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = bubble,
        })
        bind(bubblePtr, "BackgroundColor3", "Accent")

        local function applyVisual(a)
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.fromScale(a, 0.5)
            glow.Position = UDim2.fromScale(a, 0.5)
            local half = bubble.Size.X.Offset / 2
            local x = 14 + a * bar.AbsoluteSize.X
            if f.AbsoluteSize.X > 0 then
                x = math.clamp(x, half + 2, f.AbsoluteSize.X - half - 2)
            end
            bubble.Position = UDim2.new(0, x, 0, BAR_Y - 8)
        end

        local obj = {}
        function obj:Set(v, silent)
            v = math.clamp(v, min, max)
            v = min + math.floor((v - min) / inc + 0.5) * inc
            v = math.clamp(tonumber(string.format(fmt, v)), min, max)
            value = v
            local txt = string.format(fmt, v) .. suffix
            valBox.Text = txt
            bubbleLbl.Text = txt
            bubble.Size = UDim2.fromOffset(math.max(44, textWidth(txt, 11, Enum.Font.Code) + 18), 22)
            commit(o, v, silent)
        end
        function obj:Get()
            return value
        end

        local function setDrag(on)
            dragging = on
            tween(knobScale, {Scale = on and 1.5 or (hovered and 1.18 or 1)}, 0.22, Enum.EasingStyle.Back)
            tween(glow, {BackgroundTransparency = on and 0.68 or 0.88, Size = on and UDim2.fromOffset(40, 40) or UDim2.fromOffset(28, 28)}, 0.22)
            if on then
                bubble.Visible = true
                tween(bubbleScale, {Scale = 1}, 0.24, Enum.EasingStyle.Back)
                tween(bubble, {BackgroundTransparency = 0}, 0.15)
                tween(bubblePtr, {BackgroundTransparency = 0}, 0.15)
                tween(bubbleLbl, {TextTransparency = 0}, 0.15)
            else
                local t = tween(bubbleScale, {Scale = 0.4}, 0.16)
                tween(bubble, {BackgroundTransparency = 1}, 0.14)
                tween(bubblePtr, {BackgroundTransparency = 1}, 0.14)
                tween(bubbleLbl, {TextTransparency = 1}, 0.14)
                t.Completed:Connect(function()
                    if not dragging then
                        bubble.Visible = false
                    end
                end)
            end
        end

        local function update(input)
            local a = math.clamp((pointer(input).X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            obj:Set(min + (max - min) * a)
        end

        local b = overlay(f, st, function(on)
            hovered = on
            tween(bar, {
                Size = UDim2.new(1, -28, 0, on and 8 or 6),
                Position = UDim2.new(0, 14, 0, on and BAR_Y - 1 or BAR_Y),
            }, 0.15)
            if not dragging then
                tween(knobScale, {Scale = on and 1.18 or 1}, 0.18, Enum.EasingStyle.Back)
            end
        end, o)
        connect(b.InputBegan, function(input)
            if isPress(input) and pointer(input).Y - f.AbsolutePosition.Y > 30 then
                setDrag(true)
                update(input)
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if dragging and isPress(input) then
                setDrag(false)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and isMove(input) then
                update(input)
            end
        end)

        connect(valBox.Focused, function()
            tween(pillStroke, {Transparency = 0, Thickness = 1.5}, 0.15)
        end)
        connect(valBox.FocusLost, function()
            tween(pillStroke, {Transparency = 0.7, Thickness = 1}, 0.2)
            local n = tonumber((valBox.Text:gsub("[^%d%.%-]", "")))
            if n then
                obj:Set(n)
            else
                valBox.Text = string.format(fmt, value) .. suffix
            end
        end)

        -- eased knob: it glides toward the real value instead of snapping
        table.insert(updaters, function(dt)
            local target = alphaOf(value)
            if math.abs(target - shownA) > 0.0002 then
                shownA = shownA + (target - shownA) * (1 - math.exp(-dt * 20))
                applyVisual(shownA)
            elseif shownA ~= target then
                shownA = target
                applyVisual(shownA)
            end
        end)

        local startTxt = string.format(fmt, value) .. suffix
        valBox.Text = startTxt
        bubbleLbl.Text = startTxt
        bubble.Size = UDim2.fromOffset(math.max(44, textWidth(startTxt, 11, Enum.Font.Code) + 18), 22)
        applyVisual(shownA)
        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, value, true)
        return obj
    end

    -- Stepper (press and hold to repeat) ------------------------------------
    function E.Stepper(parent, o)
        local min = (o.Range and o.Range[1]) or 0
        local max = (o.Range and o.Range[2]) or 100
        local inc = o.Increment or 1
        local fmt = "%." .. decimalsOf(inc) .. "f"
        local value = math.clamp(o.Default or min, min, max)
        local holdToken

        local f = newElement(parent, 38)
        label(f, o.Name or "Stepper", {
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -150, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local valueLbl = label(f, string.format(fmt, value), {
            Position = UDim2.new(1, -98, 0, 0), Size = UDim2.fromOffset(60, 38),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.Code, TextSize = 13,
        }, "Accent")

        local obj = {}
        function obj:Set(v, silent)
            v = math.clamp(v, min, max)
            v = min + math.floor((v - min) / inc + 0.5) * inc
            v = math.clamp(tonumber(string.format(fmt, v)), min, max)
            if v ~= value then
                valueLbl.TextColor3 = Theme.Text
                tween(valueLbl, {TextColor3 = Theme.Accent}, 0.3)
            end
            value = v
            valueLbl.Text = string.format(fmt, v)
            commit(o, v, silent)
        end
        function obj:Get()
            return value
        end

        local function stepButton(text, xOff, dir)
            local b = create("TextButton", {
                Position = UDim2.new(1, xOff, 0.5, -12), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Background,
                Text = text, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.Accent,
                AutoButtonColor = false, Parent = f,
            }, {corner(6)})
            bind(b, "BackgroundColor3", "Background")
            bind(b, "TextColor3", "Accent")
            local bs = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = b})
            bind(bs, "Color", "Stroke")
            connect(b.MouseEnter, function()
                tween(bs, {Color = Theme.Accent}, 0.15)
            end)
            connect(b.MouseLeave, function()
                tween(bs, {Color = Theme.Stroke}, 0.2)
            end)
            connect(b.InputBegan, function(input)
                if isPress(input) then
                    local token = {}
                    holdToken = token
                    obj:Set(value + dir * inc)
                    task.spawn(function()
                        task.wait(0.4)
                        while holdToken == token and not Window.Destroyed do
                            obj:Set(value + dir * inc)
                            task.wait(0.07)
                        end
                    end)
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End and holdToken == token then
                            holdToken = nil
                        end
                    end)
                end
            end)
        end
        stepButton("-", -128, -1)
        stepButton("+", -36, 1)

        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, value, true)
        return obj
    end

    -- Progress bar --------------------------------------------------------------
    function E.Progress(parent, o)
        local value = math.clamp(o.Default or 0, 0, 1)
        local shown = value
        local f = newElement(parent, 46)
        label(f, o.Name or "Progress", {
            Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -90, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local pct = label(f, "0%", {
            Position = UDim2.new(1, -72, 0, 5), Size = UDim2.fromOffset(60, 20),
            TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 12,
        }, "Accent")
        local track = create("Frame", {
            Position = UDim2.new(0, 12, 0, 31), Size = UDim2.new(1, -24, 0, 8),
            BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
        }, {round()})
        bind(track, "BackgroundColor3", "Stroke")
        local fill = create("Frame", {
            Size = UDim2.fromScale(value, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0,
            ClipsDescendants = true, Parent = track,
        }, {round()})
        accentGrad(fill, 0)
        local shine = create("Frame", {
            Size = UDim2.new(0, 46, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = fill,
        })
        create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = shine,
        })

        table.insert(updaters, function(dt, t)
            if math.abs(value - shown) > 0.0005 then
                shown = shown + (value - shown) * (1 - math.exp(-dt * 8))
                fill.Size = UDim2.fromScale(shown, 1)
            end
            pct.Text = string.format("%d%%", math.floor(shown * 100 + 0.5))
            shine.Position = UDim2.new(((t * 0.7) % 1.6) - 0.3, 0, 0, 0)
        end)

        local obj = {}
        function obj:Set(p)
            value = math.clamp(p, 0, 1)
        end
        function obj:Get()
            return value
        end
        return obj
    end

    -- Dropdown (smooth open / close, multi select, optional search) --------------
    function E.Dropdown(parent, o)
        local multi = o.Multi == true
        local options = o.Options or {}
        local search = o.Search == true or (o.Search == nil and #options > 8)
        local IH, MAXV = 28, 6
        local selected
        if multi then
            selected = {}
            if type(o.Default) == "table" then
                for _, v in ipairs(o.Default) do
                    selected[v] = true
                end
            end
        else
            selected = o.Default or options[1]
        end
        local open = false
        local visibleCount = #options

        local f, st = newElement(parent, 38)
        label(f, o.Name or "Dropdown", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.42, -12, 0, 38)})
        local valLbl = label(f, "", {
            Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, -38, 0, 38),
            TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
            TextSize = 12, Font = Enum.Font.Code,
        }, "SubText")
        local arrow = label(f, ">", {
            Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(18, 38),
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Rotation = 90,
        }, "Accent")

        local listTop = 42
        local searchBox
        if search then
            local sw = create("Frame", {
                Position = UDim2.fromOffset(6, 42), Size = UDim2.new(1, -12, 0, 26),
                BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = f,
            }, {corner(6)})
            bind(sw, "BackgroundColor3", "Background")
            local sws = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = sw})
            bind(sws, "Color", "Stroke")
            searchBox = create("TextBox", {
                Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 1, 0), BackgroundTransparency = 1,
                Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text,
                Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = sw,
            })
            bind(searchBox, "TextColor3", "Text")
            bind(searchBox, "PlaceholderColor3", "SubText")
            connect(searchBox.Focused, function()
                tween(sws, {Color = Theme.Accent}, 0.15)
            end)
            connect(searchBox.FocusLost, function()
                tween(sws, {Color = Theme.Stroke}, 0.2)
            end)
            listTop = 72
        end

        local listWrap = create("ScrollingFrame", {
            Position = UDim2.fromOffset(6, listTop), Size = UDim2.new(1, -12, 0, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f,
        }, {create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})})
        bind(listWrap, "ScrollBarImageColor3", "Accent")

        local items = {}
        local function isSel(v)
            if multi then
                return selected[v] == true
            end
            return selected == v
        end
        local function getValue()
            if multi then
                local t = {}
                for _, v in ipairs(options) do
                    if selected[v] then
                        t[#t + 1] = v
                    end
                end
                return t
            end
            return selected
        end
        local function display()
            if multi then
                local names = {}
                for _, v in ipairs(getValue()) do
                    names[#names + 1] = tostring(v)
                end
                valLbl.Text = #names > 0 and table.concat(names, ", ") or "None"
            else
                valLbl.Text = tostring(selected or "None")
            end
        end
        local function paintItems()
            for v, it in pairs(items) do
                local on = isSel(v)
                tween(it.lbl, {TextColor3 = on and Theme.Accent or Theme.SubText}, 0.15)
                tween(it.mark, {BackgroundTransparency = on and 0 or 1}, 0.15)
                tween(it.btn, {BackgroundTransparency = on and 0.88 or 1}, 0.15)
            end
        end
        local function listHeight()
            return math.min(visibleCount, MAXV) * (IH + 2)
        end
        local function openHeight()
            return listTop + listHeight() + 6
        end
        local function resize()
            tween(f, {Size = UDim2.new(1, 0, 0, open and openHeight() or 38)}, open and 0.36 or 0.26)
            tween(arrow, {Rotation = open and -90 or 90}, 0.32, Enum.EasingStyle.Back)
        end
        local function staggerIn()
            local i = 0
            for _, opt in ipairs(options) do
                local it = items[opt]
                if it and it.btn.Visible then
                    it.lbl.TextTransparency = 1
                    task.delay(i * 0.022, function()
                        if open and it.lbl.Parent then
                            tween(it.lbl, {TextTransparency = 0}, 0.2)
                        end
                    end)
                    i = i + 1
                end
            end
        end
        local function applyFilter()
            local q = searchBox and string.lower(searchBox.Text) or ""
            local c = 0
            for _, opt in ipairs(options) do
                local it = items[opt]
                if it then
                    local show = q == "" or string.find(string.lower(tostring(opt)), q, 1, true) ~= nil
                    it.btn.Visible = show
                    if show then
                        c = c + 1
                    end
                end
            end
            visibleCount = c
            listWrap.Size = UDim2.new(1, -12, 0, listHeight())
            if open then
                tween(f, {Size = UDim2.new(1, 0, 0, openHeight())}, 0.22)
            end
        end

        local function build()
            for _, it in pairs(items) do
                it.btn:Destroy()
            end
            items = {}
            for _, opt in ipairs(options) do
                local ib = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, IH), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                    Text = "", AutoButtonColor = false, Parent = listWrap,
                }, {corner(5)})
                local mark = create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
                    Size = UDim2.fromOffset(3, 14), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                    BorderSizePixel = 0, Parent = ib,
                }, {round()})
                local il = create("TextLabel", {
                    Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
                    Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.SubText,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = ib,
                })
                items[opt] = {btn = ib, lbl = il, mark = mark}
                connect(ib.MouseEnter, function()
                    if not isSel(opt) then
                        tween(il, {TextColor3 = Theme.Text}, 0.12)
                    end
                end)
                connect(ib.MouseLeave, function()
                    if not isSel(opt) then
                        tween(il, {TextColor3 = Theme.SubText}, 0.15)
                    end
                end)
                connect(ib.MouseButton1Click, function()
                    if multi then
                        selected[opt] = (not selected[opt]) or nil
                    else
                        selected = opt
                        open = false
                        resize()
                    end
                    display()
                    paintItems()
                    commit(o, getValue())
                end)
            end
            visibleCount = #options
            listWrap.Size = UDim2.new(1, -12, 0, listHeight())
            display()
            paintItems()
            if searchBox then
                applyFilter()
            end
        end
        if searchBox then
            connect(searchBox:GetPropertyChangedSignal("Text"), applyFilter)
        end

        local obj = {}
        function obj:Set(v, silent)
            if multi then
                selected = {}
                for _, x in ipairs(type(v) == "table" and v or {}) do
                    selected[x] = true
                end
            else
                selected = v
            end
            display()
            paintItems()
            commit(o, getValue(), silent)
        end
        function obj:Get()
            return getValue()
        end
        function obj:Refresh(newOptions)
            options = newOptions or {}
            build()
            if open then
                resize()
            end
        end

        local b = overlay(f, st, nil, o)
        b.Size = UDim2.new(1, 0, 0, 38)
        connect(b.MouseButton1Click, function()
            open = not open
            resize()
            if open then
                staggerIn()
            end
        end)

        build()
        themed(function()
            paintItems()
        end)
        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, getValue(), true)
        return obj
    end

    -- Textbox ---------------------------------------------------------------------
    function E.Textbox(parent, o)
        local f = newElement(parent, 38)
        label(f, o.Name or "Textbox", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.42, -12, 1, 0)})
        local wrapBox = create("Frame", {
            Position = UDim2.new(0.42, 0, 0.5, -14), Size = UDim2.new(0.58, -10, 0, 28),
            BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = f,
        }, {corner(6)})
        bind(wrapBox, "BackgroundColor3", "Background")
        local ws = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = wrapBox})
        bind(ws, "Color", "Stroke")
        local box = create("TextBox", {
            Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 1, 0), BackgroundTransparency = 1,
            Text = o.Default or "", PlaceholderText = o.Placeholder or "Type here...",
            PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text, Font = Enum.Font.Code,
            TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = wrapBox,
        })
        bind(box, "TextColor3", "Text")
        bind(box, "PlaceholderColor3", "SubText")
        connect(box.Focused, function()
            tween(ws, {Color = Theme.Accent, Transparency = 0, Thickness = 1.5}, 0.2)
        end)
        connect(box.FocusLost, function()
            tween(ws, {Color = Theme.Stroke, Transparency = 0.2, Thickness = 1}, 0.25)
            commit(o, box.Text)
        end)
        local obj = {}
        function obj:Set(t, silent)
            box.Text = t
            commit(o, t, silent)
        end
        function obj:Get()
            return box.Text
        end
        register(o, function(v)
            obj:Set(v)
        end)
        commit(o, box.Text, true)
        return obj
    end

    -- Keybind ----------------------------------------------------------------------
    function E.Keybind(parent, o)
        local key = o.Default or Enum.KeyCode.F
        local listening = false
        local f = newElement(parent, 38)
        label(f, o.Name or "Keybind", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -110, 1, 0)})
        local kb = create("TextButton", {
            Position = UDim2.new(1, -94, 0.5, -13), Size = UDim2.fromOffset(82, 26),
            BackgroundColor3 = Theme.Background, Text = key.Name, Font = Enum.Font.Code,
            TextSize = 12, TextColor3 = Theme.Accent, AutoButtonColor = false, Parent = f,
        }, {corner(6)})
        bind(kb, "BackgroundColor3", "Background")
        bind(kb, "TextColor3", "Accent")
        local ks = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.2, Parent = kb})
        bind(ks, "Color", "Stroke")

        connect(kb.MouseButton1Click, function()
            listening = true
            kb.Text = "..."
            tween(ks, {Color = Theme.Accent, Transparency = 0}, 0.2)
        end)
        connect(UserInputService.InputBegan, function(input, processed)
            if listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    if input.KeyCode ~= Enum.KeyCode.Escape then
                        key = input.KeyCode
                        if o.Flag then
                            Library.Flags[o.Flag] = key
                        end
                        safeCall(o.Changed, key)
                    end
                    kb.Text = key.Name
                    tween(ks, {Color = Theme.Stroke, Transparency = 0.2}, 0.25)
                end
            elseif not processed and input.KeyCode == key then
                safeCall(o.Callback, key)
            end
        end)
        local obj = {}
        function obj:Set(k)
            key = k
            kb.Text = k.Name
            if o.Flag then
                Library.Flags[o.Flag] = k
            end
            safeCall(o.Changed, k)
        end
        function obj:Get()
            return key
        end
        register(o, function(v)
            if v then
                obj:Set(v)
            end
        end)
        if o.Flag then
            Library.Flags[o.Flag] = key
        end
        return obj
    end

    -- Color picker ------------------------------------------------------------------
    function E.ColorPicker(parent, o)
        local color = o.Default or rgb(255, 255, 255)
        local h, s, v = color:ToHSV()
        local open = false

        local f, st = newElement(parent, 38)
        label(f, o.Name or "Color", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -140, 0, 38)})
        local hexLbl = label(f, "", {
            Position = UDim2.new(1, -134, 0, 0), Size = UDim2.fromOffset(70, 38),
            TextXAlignment = Enum.TextXAlignment.Right, TextSize = 11, Font = Enum.Font.Code,
        }, "SubText")
        local swatch = create("Frame", {
            Position = UDim2.new(1, -52, 0, 8), Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = color, BorderSizePixel = 0, Parent = f,
        }, {corner(5), create("UIStroke", {Color = WHITE, Transparency = 0.7})})

        local svBox = create("Frame", {
            Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -58, 0, 104),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, Parent = f,
        }, {corner(5)})
        local whiteOv = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = svBox}, {corner(5)})
        create("UIGradient", {Transparency = NumberSequence.new(0, 1), Parent = whiteOv})
        local blackOv = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = svBox}, {corner(5)})
        create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = blackOv})
        local svCursor = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1, Parent = svBox,
        }, {round(), create("UIStroke", {Color = WHITE, Thickness = 2})})

        local hueBar = create("Frame", {
            Position = UDim2.new(1, -32, 0, 48), Size = UDim2.fromOffset(20, 104),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f,
        }, {corner(5)})
        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, rgb(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, rgb(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, rgb(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, rgb(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, rgb(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, rgb(255, 0, 255)),
                ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
            }),
            Parent = hueBar,
        })
        local hueCursor = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 6, 0, 5),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = hueBar,
        }, {corner(3), create("UIStroke", {Color = Color3.new(0, 0, 0), Transparency = 0.5})})

        local obj = {}
        local function apply(silent)
            h = math.clamp(h, 0, 0.999)
            color = Color3.fromHSV(h, s, v)
            swatch.BackgroundColor3 = color
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svCursor.Position = UDim2.fromScale(s, 1 - v)
            hueCursor.Position = UDim2.fromScale(0.5, h)
            hexLbl.Text = "#" .. string.upper(color:ToHex())
            commit(o, color, silent)
        end
        function obj:Set(c, silent)
            h, s, v = c:ToHSV()
            apply(silent)
        end
        function obj:Get()
            return color
        end

        local drag
        local function update(input)
            local p = pointer(input)
            if drag == "sv" then
                s = math.clamp((p.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
            elseif drag == "hue" then
                h = math.clamp((p.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
            end
            apply()
        end
        connect(svBox.InputBegan, function(input)
            if isPress(input) then
                drag = "sv"
                update(input)
            end
        end)
        connect(hueBar.InputBegan, function(input)
            if isPress(input) then
                drag = "hue"
                update(input)
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if isPress(input) then
                drag = nil
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if drag and isMove(input) then
                update(input)
            end
        end)

        local b = overlay(f, st, nil, o)
        b.Size = UDim2.new(1, 0, 0, 38)
        connect(b.MouseButton1Click, function()
            open = not open
            tween(f, {Size = UDim2.new(1, 0, 0, open and 164 or 38)}, open and 0.36 or 0.26)
        end)

        apply(true)
        register(o, function(c)
            obj:Set(c)
        end)
        return obj
    end

    ---------------------------------------------------------------------
    -- Tabs + collapsible sections
    ---------------------------------------------------------------------

    local ELEMENT_NAMES = {
        "Label", "Paragraph", "Button", "Toggle", "Slider", "Stepper", "Progress",
        "Dropdown", "Textbox", "Keybind", "ColorPicker", "Divider",
    }

    local function paintChips(animate)
        for _, t in ipairs(Window.Tabs) do
            local on = Window.Active == t
            local bgColor = on and Theme.Accent or Theme.Element
            local bgTrans = on and 0.82 or 0
            local strokeColor = on and Theme.Accent or Theme.Stroke
            local textColor = on and Theme.Text or Theme.SubText
            if animate then
                tween(t.Chip, {BackgroundColor3 = bgColor, BackgroundTransparency = bgTrans}, 0.2)
                tween(t.ChipStroke, {Color = strokeColor}, 0.2)
                tween(t.ChipLbl, {TextColor3 = textColor}, 0.2)
            else
                t.Chip.BackgroundColor3 = bgColor
                t.Chip.BackgroundTransparency = bgTrans
                t.ChipStroke.Color = strokeColor
                t.ChipLbl.TextColor3 = textColor
            end
        end
    end
    themed(function(animate)
        paintChips(animate)
    end)

    function Window:CreateTab(name)
        name = name or "Tab"
        local Tab = {Name = name, Sections = {}, NextSide = "Left"}

        -- chip inside the top-center tab menu
        local chipW = textWidth(name, 12, Enum.Font.GothamMedium) + 30
        local chip = create("TextButton", {
            Size = UDim2.fromOffset(chipW, 30), Position = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Theme.Element, Text = "", AutoButtonColor = false, Parent = menu,
        }, {corner(6)})
        local chipStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.25, Parent = chip})
        local chipLbl = create("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = name,
            Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.SubText, Parent = chip,
        })
        Tab.Chip, Tab.ChipWidth, Tab.ChipLbl, Tab.ChipStroke = chip, chipW, chipLbl, chipStroke

        connect(chip.MouseEnter, function()
            if Window.Active ~= Tab then
                tween(chip, {BackgroundColor3 = Theme.ElementHover}, 0.15)
                tween(chipLbl, {TextColor3 = Theme.Text}, 0.15)
            end
        end)
        connect(chip.MouseLeave, function()
            if Window.Active ~= Tab then
                tween(chip, {BackgroundColor3 = Theme.Element}, 0.2)
                tween(chipLbl, {TextColor3 = Theme.SubText}, 0.2)
            end
        end)

        -- page: fading CanvasGroup with two columns
        local holder = create("CanvasGroup", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            GroupTransparency = 1, Visible = false, Parent = pageArea,
        })
        local scroll = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(), Parent = holder,
        })
        bind(scroll, "ScrollBarImageColor3", "Accent")
        Tab.Holder = holder

        local function makeColumn(xScale, xOff)
            local col = create("Frame", {
                Position = UDim2.new(xScale, xOff, 0, 0), Size = UDim2.new(0.5, -8, 0, 0),
                BackgroundTransparency = 1, Parent = scroll,
            })
            local lay = create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col})
            return col, lay
        end
        local leftCol, leftLay = makeColumn(0, 0)
        local rightCol, rightLay = makeColumn(0.5, 2)

        local function updateCanvas()
            local h = math.max(leftLay.AbsoluteContentSize.Y, rightLay.AbsoluteContentSize.Y)
            scroll.CanvasSize = UDim2.fromOffset(0, h + 12)
        end
        connect(leftLay:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
        connect(rightLay:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)

        function Tab:Select()
            if Window.Active == Tab then
                setMenu(false)
                return
            end
            local prev = Window.Active
            Window.Active = Tab
            if prev then
                local ph = prev.Holder
                local t = tween(ph, {GroupTransparency = 1}, 0.15)
                t.Completed:Connect(function()
                    if Window.Active ~= prev then
                        ph.Visible = false
                    end
                end)
            end
            holder.Position = UDim2.fromOffset(0, 16)
            holder.GroupTransparency = 1
            holder.Visible = true
            tween(holder, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.42)
            tabBtnLbl.Text = name
            tabBtnLbl.TextTransparency = 1
            tween(tabBtnLbl, {TextTransparency = 0}, 0.3)
            paintChips(true)
            setMenu(false)
        end
        connect(chip.MouseButton1Click, function()
            Tab:Select()
        end)

        -- sections ---------------------------------------------------------
        function Tab:CreateSection(o)
            if type(o) == "string" then
                o = {Name = o}
            end
            o = o or {}
            local side = o.Side
            if side ~= "Left" and side ~= "Right" then
                side = Tab.NextSide
                Tab.NextSide = (Tab.NextSide == "Left") and "Right" or "Left"
            end
            local col = (side == "Left") and leftCol or rightCol

            local Section = {Count = 0, Collapsed = o.Collapsed == true, Side = side}
            local HEADER = 36
            local collapsed = Section.Collapsed
            local animating, animToken = false, 0

            local frame = create("Frame", {
                Size = UDim2.new(1, 0, 0, HEADER), BackgroundColor3 = Theme.Section, BackgroundTransparency = 0.12,
                BorderSizePixel = 0, ClipsDescendants = true, Parent = col,
            }, {corner(8)})
            bind(frame, "BackgroundColor3", "Section")
            local frameStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 0.3, Parent = frame})
            bind(frameStroke, "Color", "Stroke")

            local hdr = create("TextButton", {
                Size = UDim2.new(1, 0, 0, HEADER), BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = frame,
            }, {corner(8)})
            connect(hdr.MouseEnter, function()
                tween(hdr, {BackgroundTransparency = 0.55}, 0.15)
            end)
            connect(hdr.MouseLeave, function()
                tween(hdr, {BackgroundTransparency = 1}, 0.2)
            end)
            connect(hdr.InputBegan, function(input)
                if isPress(input) then
                    ripple(hdr, input)
                end
            end)

            local accentBar = create("Frame", {
                Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(3, 14),
                BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = hdr,
            }, {round()})
            accentGrad(accentBar, 90)
            local secTitle = label(hdr, o.Name or "Section", {
                Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -90, 1, 0),
                Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
            })
            local countBox = create("Frame", {
                Position = UDim2.new(1, -58, 0.5, -8), Size = UDim2.fromOffset(24, 16),
                BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = hdr,
            }, {corner(4)})
            bind(countBox, "BackgroundColor3", "Accent")
            local countLbl = label(countBox, "0", {
                Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
                Font = Enum.Font.Code, TextSize = 11,
            }, "Accent")
            local chev = label(hdr, ">", {
                Position = UDim2.new(1, -28, 0, 0), Size = UDim2.fromOffset(18, HEADER),
                TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold,
                Rotation = collapsed and 0 or 90,
            }, "Accent")

            local body = create("Frame", {
                Position = UDim2.fromOffset(0, HEADER), Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1, Visible = not collapsed, Parent = frame,
            })
            local lay = create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body})
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), Parent = body,
            })

            local function targetHeight()
                if collapsed then
                    return HEADER
                end
                return HEADER + lay.AbsoluteContentSize.Y + 12
            end
            local function refresh()
                if not animating then
                    frame.Size = UDim2.new(1, 0, 0, targetHeight())
                end
            end
            connect(lay:GetPropertyChangedSignal("AbsoluteContentSize"), refresh)

            function Section:SetCollapsed(state)
                state = state and true or false
                if state == collapsed then
                    return
                end
                collapsed = state
                Section.Collapsed = state
                animToken = animToken + 1
                local mine = animToken
                animating = true
                if not state then
                    body.Visible = true
                end
                tween(chev, {Rotation = state and 0 or 90}, 0.3, Enum.EasingStyle.Back)
                local t = tween(frame, {Size = UDim2.new(1, 0, 0, targetHeight())}, 0.34)
                t.Completed:Connect(function()
                    if mine ~= animToken then
                        return
                    end
                    animating = false
                    if collapsed then
                        body.Visible = false
                    end
                    refresh()
                end)
            end
            function Section:Toggle()
                Section:SetCollapsed(not collapsed)
            end
            function Section:SetTitle(text)
                secTitle.Text = text
            end
            connect(hdr.MouseButton1Click, function()
                Section:Toggle()
            end)

            for _, elementName in ipairs(ELEMENT_NAMES) do
                Section["Create" .. elementName] = function(_, opts)
                    Section.Count = Section.Count + 1
                    countLbl.Text = tostring(Section.Count)
                    return E[elementName](body, opts or {})
                end
            end

            refresh()
            table.insert(Tab.Sections, Section)
            return Section
        end

        function Tab:CreateLeftSection(o)
            if type(o) == "string" then
                o = {Name = o}
            end
            o = o or {}
            o.Side = "Left"
            return Tab:CreateSection(o)
        end

        function Tab:CreateRightSection(o)
            if type(o) == "string" then
                o = {Name = o}
            end
            o = o or {}
            o.Side = "Right"
            return Tab:CreateSection(o)
        end

        table.insert(Window.Tabs, Tab)
        reflowTabs()
        paintChips(false)
        if #Window.Tabs == 1 then
            Tab:Select()
        end
        return Tab
    end

    ---------------------------------------------------------------------
    -- Render loop: smooth dragging, backdrop (dim / blur / screen snow),
    -- toggle button, orbs, logo / title / tag animation, element updaters
    ---------------------------------------------------------------------
    local clock = 0
    local lastX = posX
    local lastBX = btnPos.X
    local lastScr = 0
    local winVX = 0

    connect(RunService.RenderStepped, function(dt)
        dt = math.min(dt, 0.1)
        clock = clock + dt
        local a = 1 - math.exp(-dt * 16)

        -- round toggle button eases toward its target and carries its own snow
        btnPos = btnPos:Lerp(btnTgt, a)
        toggleBtn.Position = UDim2.fromOffset(math.floor(btnPos.X + TB / 2 + 0.5), math.floor(btnPos.Y + TB / 2 + 0.5))
        local bvx = (btnPos.X - lastBX) / math.max(dt, 0.001)
        lastBX = btnPos.X
        tbRing.Rotation = (clock * 60) % 360
        local pulse = TB + 16 + math.sin(clock * 2) * 3
        halo.Size = UDim2.fromOffset(pulse, pulse)
        if snowOn and tbField then
            stepSnowField(tbField, dt, clock, math.clamp(-bvx * 0.15, -60, 60) + 6, nil, nil, 1)
        end

        -- backdrop: dim, blur and screen-wide snow fade in only while the GUI is open
        backdrop = backdrop + (backdropTarget - backdrop) * (1 - math.exp(-dt * 5))
        if math.abs(backdropTarget - backdrop) < 0.003 then
            backdrop = backdropTarget
        end
        dim.Visible = backdrop > 0.004
        dim.BackgroundTransparency = 1 - dimAlpha * backdrop
        blur.Enabled = blurOn and backdrop > 0.01
        blur.Size = blurSize * backdrop
        local showScreen = screenSnowOn and backdrop > 0.01
        screenHolder.Visible = showScreen
        if showScreen then
            if clock - lastScr > 0.5 then
                lastScr = clock
                local s = screenSize()
                screenField.w, screenField.h = s.X, s.Y
            end
            local mp = UserInputService:GetMouseLocation()
            local windT = math.sin(clock * 0.4) * 14 + math.clamp(-winVX * 0.1, -80, 80)
            stepSnowField(screenField, dt, clock, windT, mp.X, mp.Y, backdrop)
        end

        -- element + notification + footer updaters
        for _, fn in ipairs(updaters) do
            local ok, err = pcall(fn, dt, clock)
            if not ok then
                warn("[DH UI] updater error: " .. tostring(err))
            end
        end

        -- loader
        if loader then
            local ok, err = pcall(loader.step, dt, clock)
            if not ok then
                warn("[DH UI] loader error: " .. tostring(err))
                pcall(function()
                    loader.panel:Destroy()
                end)
                loader = nil
                Window.Loading = false
                toggleBtn.Visible = true
                Window:SetVisible(true)
            end
        end

        if not root.Visible then
            return
        end

        -- window eases toward its target (smooth dragging) + show / hide slide
        posX = posX + (tgtX - posX) * a
        posY = posY + (tgtY - posY) * a
        slide = slide + (slideTarget - slide) * (1 - math.exp(-dt * 11))
        root.Position = UDim2.fromOffset(math.floor(posX + 0.5), math.floor(posY + slide + 0.5))
        winVX = (posX - lastX) / math.max(dt, 0.001)
        lastX = posX

        -- ambient animation
        for i, ob in ipairs(orbs) do
            local sp = ob.spec
            ob.f.Position = UDim2.fromScale(
                sp.x + math.sin(clock * sp.sx + i) * 0.07,
                sp.y + math.cos(clock * sp.sy + i * 1.7) * 0.07
            )
        end
        borderGrad.Rotation = (clock * 45) % 360
        lineGrad.Offset = Vector2.new(math.sin(clock * 1.3) * 0.4, 0)
        logoRing.Rotation = (clock * 80) % 360
        local oa = clock * 2.2
        logoDot.Position = UDim2.fromScale(0.5 + 0.5 * math.cos(oa), 0.5 + 0.5 * math.sin(oa))
        titleGrad.Offset = Vector2.new(math.sin(clock * 1.2) * 0.45, 0)
        if tagDot then
            tagDot.BackgroundTransparency = 0.05 + (math.sin(clock * 3) + 1) / 2 * 0.55
        end

        -- snow inside the window
        if snowOn and not Window.Minimized then
            local mp = UserInputService:GetMouseLocation()
            local org = main.AbsolutePosition
            local windT = math.clamp(-winVX * 0.3, -150, 150) + math.sin(clock * 0.35) * 10 + (snowCfg.Wind or 0)
            for _, fld in ipairs(snowFields) do
                stepSnowField(fld, dt, clock, windT, mp.X - org.X, mp.Y - org.Y, 1)
            end
        end
    end)

    if useLoader then
        startLoader()
    end

    return Window
end

return Library
