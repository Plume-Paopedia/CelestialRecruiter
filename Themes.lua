local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- CelestialRecruiter  —  Theme System
-- Beautiful preset themes and custom color picker
-- ═══════════════════════════════════════════════════════════════════

ns.Themes = ns.Themes or {}
local Themes = ns.Themes

-- Built-in theme presets
Themes.presets = {
    dark = {
        name = "Dark (Default)",
        colors = {
            bg        = {0.05, 0.06, 0.11, 0.97},
            panel     = {0.08, 0.09, 0.16, 0.90},
            row1      = {0.10, 0.12, 0.21, 0.50},
            row2      = {0.07, 0.08, 0.15, 0.30},
            hover     = {0.16, 0.22, 0.38, 0.65},
            border    = {0.20, 0.26, 0.46, 0.60},
            accent    = {0.00, 0.68, 1.00},
            accentDark= {0.00, 0.35, 0.55},
            gold      = {1.00, 0.84, 0.00},
            purple    = {0.58, 0.40, 1.00},
            text      = {0.92, 0.93, 0.96},
            dim       = {0.55, 0.58, 0.66},
            muted     = {0.36, 0.38, 0.46},
            green     = {0.20, 0.88, 0.48},
            orange    = {1.00, 0.70, 0.28},
            red       = {1.00, 0.40, 0.40},
        },
    },

    light = {
        name = "Light",
        colors = {
            bg        = {0.95, 0.96, 0.98, 0.97},
            panel     = {0.98, 0.98, 0.99, 0.95},
            row1      = {0.94, 0.95, 0.97, 0.80},
            row2      = {0.97, 0.98, 0.99, 0.60},
            hover     = {0.85, 0.90, 0.95, 0.85},
            border    = {0.70, 0.75, 0.85, 0.80},
            accent    = {0.20, 0.55, 0.85},
            accentDark= {0.10, 0.35, 0.65},
            gold      = {0.85, 0.65, 0.10},
            purple    = {0.50, 0.30, 0.85},
            text      = {0.10, 0.12, 0.15},
            dim       = {0.40, 0.45, 0.50},
            muted     = {0.55, 0.60, 0.65},
            green     = {0.15, 0.70, 0.35},
            orange    = {0.90, 0.55, 0.15},
            red       = {0.85, 0.25, 0.25},
        },
    },

    purple = {
        name = "Purple Dream",
        colors = {
            bg        = {0.08, 0.05, 0.12, 0.97},
            panel     = {0.10, 0.07, 0.16, 0.90},
            row1      = {0.14, 0.10, 0.22, 0.50},
            row2      = {0.10, 0.07, 0.16, 0.30},
            hover     = {0.22, 0.16, 0.35, 0.65},
            border    = {0.35, 0.25, 0.50, 0.60},
            accent    = {0.75, 0.35, 1.00},
            accentDark= {0.45, 0.20, 0.65},
            gold      = {1.00, 0.84, 0.00},
            purple    = {0.85, 0.50, 1.00},
            text      = {0.95, 0.92, 0.98},
            dim       = {0.65, 0.58, 0.72},
            muted     = {0.50, 0.42, 0.58},
            green     = {0.40, 0.90, 0.60},
            orange    = {1.00, 0.70, 0.28},
            red       = {1.00, 0.40, 0.50},
        },
    },

    green = {
        name = "Forest",
        colors = {
            bg        = {0.05, 0.10, 0.08, 0.97},
            panel     = {0.07, 0.12, 0.10, 0.90},
            row1      = {0.10, 0.16, 0.14, 0.50},
            row2      = {0.07, 0.12, 0.10, 0.30},
            hover     = {0.15, 0.25, 0.20, 0.65},
            border    = {0.25, 0.40, 0.32, 0.60},
            accent    = {0.30, 0.90, 0.50},
            accentDark= {0.18, 0.55, 0.30},
            gold      = {1.00, 0.84, 0.00},
            purple    = {0.60, 0.80, 0.70},
            text      = {0.92, 0.96, 0.94},
            dim       = {0.58, 0.70, 0.64},
            muted     = {0.38, 0.48, 0.42},
            green     = {0.35, 1.00, 0.60},
            orange    = {1.00, 0.75, 0.30},
            red       = {1.00, 0.45, 0.45},
        },
    },

    blue = {
        name = "Ocean",
        colors = {
            bg        = {0.04, 0.08, 0.14, 0.97},
            panel     = {0.06, 0.10, 0.18, 0.90},
            row1      = {0.08, 0.14, 0.24, 0.50},
            row2      = {0.05, 0.10, 0.18, 0.30},
            hover     = {0.12, 0.20, 0.32, 0.65},
            border    = {0.18, 0.30, 0.48, 0.60},
            accent    = {0.15, 0.70, 0.95},
            accentDark= {0.08, 0.40, 0.60},
            gold      = {1.00, 0.84, 0.00},
            purple    = {0.60, 0.70, 0.95},
            text      = {0.92, 0.94, 0.98},
            dim       = {0.58, 0.64, 0.74},
            muted     = {0.38, 0.44, 0.54},
            green     = {0.30, 0.88, 0.70},
            orange    = {1.00, 0.72, 0.35},
            red       = {1.00, 0.45, 0.50},
        },
    },

    amber = {
        name = "Amber",
        colors = {
            bg        = {0.10, 0.08, 0.05, 0.97},
            panel     = {0.14, 0.11, 0.07, 0.90},
            row1      = {0.18, 0.14, 0.10, 0.50},
            row2      = {0.14, 0.11, 0.07, 0.30},
            hover     = {0.26, 0.20, 0.14, 0.65},
            border    = {0.40, 0.32, 0.22, 0.60},
            accent    = {1.00, 0.70, 0.20},
            accentDark= {0.65, 0.45, 0.12},
            gold      = {1.00, 0.84, 0.00},
            purple    = {0.85, 0.70, 0.50},
            text      = {0.96, 0.94, 0.90},
            dim       = {0.72, 0.66, 0.58},
            muted     = {0.54, 0.48, 0.40},
            green     = {0.60, 0.90, 0.40},
            orange    = {1.00, 0.75, 0.30},
            red       = {1.00, 0.45, 0.30},
        },
    },
}

-- Current active theme
Themes.current = "dark"

function Themes:Init()
    -- Load saved theme
    if ns.db and ns.db.profile and ns.db.profile.theme then
        self.current = ns.db.profile.theme
    end

    -- Load custom theme if exists
    if ns.db and ns.db.profile and ns.db.profile.customTheme then
        self.presets.custom = {
            name = "Custom",
            colors = ns.db.profile.customTheme,
        }
    end

    -- Apply the loaded theme
    self:Apply(self.current)
end

function Themes:GetCurrent()
    return self.presets[self.current] or self.presets.dark
end

function Themes:GetColors()
    local theme = self:GetCurrent()
    return theme.colors
end

function Themes:Apply(themeId)
    if not self.presets[themeId] then
        themeId = "dark"
    end

    self.current = themeId

    -- Save to DB
    if ns.db and ns.db.profile then
        ns.db.profile.theme = themeId
    end

    -- Apply colors to UIWidgets color palette
    if ns.UIWidgets and ns.UIWidgets.C then
        local colors = self.presets[themeId].colors
        for k, v in pairs(colors) do
            ns.UIWidgets.C[k] = v
        end
    end

    -- Trigger UI refresh to update all colors
    if ns.UI_Refresh then
        -- Full UI reload needed for theme changes
        if ns.Notifications_Info then
            ns.Notifications_Info("Thème appliqué", self.presets[themeId].name .. " - Recharge /reload pour l'effet complet")
        else
            ns.Util_Print("Thème " .. self.presets[themeId].name .. " appliqué. /reload pour effet complet.")
        end
    end
end

function Themes:GetPresetList()
    local list = {}
    for id, theme in pairs(self.presets) do
        table.insert(list, {
            id = id,
            name = theme.name,
            colors = theme.colors,
        })
    end

    -- Sort: custom first, then alphabetically
    table.sort(list, function(a, b)
        if a.id == "custom" then return true end
        if b.id == "custom" then return false end
        return a.name < b.name
    end)

    return list
end

function Themes:SaveCustom(colors)
    self.presets.custom = {
        name = "Custom",
        colors = colors,
    }

    if ns.db and ns.db.profile then
        ns.db.profile.customTheme = colors
    end

    self:Apply("custom")
end

function Themes:GetColorHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function Themes:ParseColorHex(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        return r, g, b
    end
    return nil
end

-- Generate a complementary color scheme from a base color
function Themes:GenerateFromBase(baseR, baseG, baseB)
    -- Simple algorithm to generate harmonious colors
    local colors = {}

    -- Background (darker version)
    colors.bg = {baseR * 0.2, baseG * 0.2, baseB * 0.2, 0.97}
    colors.panel = {baseR * 0.3, baseG * 0.3, baseB * 0.3, 0.90}

    -- Rows (slightly lighter)
    colors.row1 = {baseR * 0.4, baseG * 0.4, baseB * 0.4, 0.50}
    colors.row2 = {baseR * 0.3, baseG * 0.3, baseB * 0.3, 0.30}

    -- Hover (medium)
    colors.hover = {baseR * 0.5, baseG * 0.5, baseB * 0.5, 0.65}

    -- Border (medium-light)
    colors.border = {baseR * 0.6, baseG * 0.6, baseB * 0.6, 0.60}

    -- Accent (brightest, saturated)
    colors.accent = {
        math.min(1, baseR * 1.5),
        math.min(1, baseG * 1.5),
        math.min(1, baseB * 1.5)
    }
    colors.accentDark = {baseR * 0.8, baseG * 0.8, baseB * 0.8}

    -- Fixed colors
    colors.gold = {1.00, 0.84, 0.00}
    colors.purple = {0.58, 0.40, 1.00}
    colors.text = {0.92, 0.93, 0.96}
    colors.dim = {0.55, 0.58, 0.66}
    colors.muted = {0.36, 0.38, 0.46}
    colors.green = {0.20, 0.88, 0.48}
    colors.orange = {1.00, 0.70, 0.28}
    colors.red = {1.00, 0.40, 0.40}

    return colors
end
