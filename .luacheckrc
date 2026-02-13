-- Luacheck configuration for CelestialRecruiter WoW addon
std = "lua51"  -- WoW uses Lua 5.1

-- Exclude Ace3 libraries from checking
exclude_files = {
    "Libs/**/*.lua",
    ".luacheckrc",
}

-- WoW API globals that are safe to read
read_globals = {
    -- Core WoW functions
    "GetRealmName",
    "UnitName",
    "IsInInstance",
    "GetTime",
    "GetNumClasses",
    "GetClassInfo",
    "GetNumWhoResults",
    "GetWhoInfo",
    "SetWhoToUI",
    "SetWhoToUi",
    "SendWho",
    "GuildInvite",
    "InviteUnit",
    "SendChatMessage",
    "DEFAULT_CHAT_FRAME",
    "time",

    -- WoW namespaces
    "C_FriendList",
    "C_GuildInfo",
    "C_Timer",
    "Enum",

    -- Ace3 library
    "LibStub",

    -- Global tables
    "LOCALIZED_CLASS_NAMES_MALE",

    -- Slash command registration
    "SlashCmdList",
    "SLASH_CELESTIALRECRUITER1",
    "SLASH_CELESTIALRECRUITER2",
}

-- Globals that this addon creates/modifies
globals = {
    "CelestialRecruiterDB",  -- SavedVariables from TOC
}

-- Ignore some common warnings in WoW addons
ignore = {
    "212/self",  -- Unused argument 'self' (common in OOP-style methods)
    "212/_",     -- Unused argument '_' (common for addon namespace)
    "213",       -- Unused loop variable (common in iteration)
}

-- Line length limits
max_line_length = 120
max_code_line_length = 120
