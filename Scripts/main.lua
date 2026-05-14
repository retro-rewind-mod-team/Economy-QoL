-- ============================================================
--  Retro Rewind - Economy QoL
--  Version: 1.1
--
--  Keybinds to add money and XP on demand.
--  Does NOT set the game's internal Cheat flag —
--  achievements are unaffected.
--
--  F2 = Add money (default: $1000)
--  F3 = Add XP    (default: 50)
--
--  Edit config.lua to change the amounts.
--
--  HOW IT WORKS:
--  Both Change Money and Change XP are native functions on
--  Core_Gamemode_C — the same functions the game itself uses
--  for all money and XP transactions. Calling them directly
--  ensures all UI counters and SaveGame state update correctly.
-- ============================================================

local CONFIG = require("config")

-- ============================================================
-- INTERNAL
-- ============================================================
local P = "[Economy-QoL] "

local function log(msg)
    print(P .. msg .. "\n")
end

local function debug(msg)
    if CONFIG.Debug then
        log(msg)
    end
end

local function safe(label, fn, ...)
    local results = {pcall(fn, ...)}
    if not results[1] then
        log(label .. " FAILED: " .. tostring(results[2]))
        return nil
    end
    return table.unpack(results, 2)
end

local gamemodeRef = nil

-- ============================================================
-- CORE: Log current Money, XP and Level
-- Reads live values directly from Core_Gamemode_C properties
-- (confirmed via Blueprint dump: offsets 0x348, 0x3CC, 0x3C8).
-- Called on startup so the baseline is always visible in the
-- console — useful when players report unexpected behaviour.
-- ============================================================
local function logCurrentValues()
    pcall(function()
        local okM, money = pcall(function() return gamemodeRef["Money"] end)
        local okX, xp    = pcall(function() return gamemodeRef["Experience"] end)
        local okL, level = pcall(function() return gamemodeRef["Level"] end)

        log("Money: " .. (okM and ("$" .. string.format("%.2f", money / 100)) or "ERR"))
        log("XP:    " .. (okX and tostring(xp) or "ERR"))
        log("Level: " .. (okL and tostring(level) or "ERR"))
    end)
end

-- ============================================================
-- CORE: Add money via native Change Money function
--
-- Parameter breakdown (confirmed via Blueprint dump):
--   1. Money modification  - delta in cents (positive = add)
--   2. Only valid Fund     - false = allow any amount
--   3. Allow Dept          - true  = allow going below zero
--   4. Have enough money   - Out-param (Bool), ignored
--   5. New Current Money   - Out-param (Int),  ignored
-- ============================================================
local function addMoney(amount)
    if not gamemodeRef or not gamemodeRef:IsValid() then
        log("Gamemode not available")
        return
    end

    local hasEnough = {}
    local newMoney  = {}
    local ok, err = pcall(function()
        gamemodeRef["Change Money"](amount, false, true, hasEnough, newMoney)
    end)

    if ok then
        log("Added $" .. string.format("%.2f", amount / 100))
    else
        log("Change Money error: " .. tostring(err))
    end
end

-- ============================================================
-- CORE: Add XP via native Change XP function
--
-- Parameter breakdown (confirmed via Blueprint dump):
--   1. XP Modification  - the delta (our input)
--   2. New Current XP   - Out-param (Int), ignored
--   (Local Xp modification at offset 8 is internally computed
--    and is not a callable parameter)
-- ============================================================
local function addXP(amount)
    if not gamemodeRef or not gamemodeRef:IsValid() then
        log("Gamemode not available")
        return
    end

    local newXP = {}
    local ok, err = pcall(function()
        gamemodeRef["Change XP"](amount, newXP)
    end)

    if ok then
        log("Added " .. tostring(amount) .. " XP")
    else
        log("Change XP error: " .. tostring(err))
    end
end

-- ============================================================
-- KEYBINDS
-- ============================================================
local keybindsRegistered = false

local function registerKeybinds()
    if keybindsRegistered then return end
    keybindsRegistered = true

    -- F2: Add money
    RegisterKeyBind(Key.F2, function()
        addMoney(CONFIG.moneyAmount)
    end)

    -- F3: Add XP
    RegisterKeyBind(Key.F3, function()
        addXP(CONFIG.xpAmount)
    end)

    log("Keybinds active | F2 = +$" .. string.format("%.2f", CONFIG.moneyAmount / 100) ..
        " | F3 = +" .. CONFIG.xpAmount .. " XP")
end

-- ============================================================
-- Wait for Core_Gamemode_C to be available, then store a
-- reference and register keybinds.
-- Direct access at startup fails because the Blueprint class
-- is not yet loaded when the mod initialises.
--
-- hookRegistered removed: NotifyOnNewObject fires on every
-- new spawn, so gamemodeRef is always kept up to date after
-- a save reload. keybindsRegistered guards the one-time setup.
-- ============================================================
NotifyOnNewObject(
    "/Game/VideoStore/core/gamemode/Core_Gamemode.Core_Gamemode_C",
    function(obj)
        ExecuteWithDelay(500, function()
            gamemodeRef = obj
            debug("Gamemode reference acquired")
            logCurrentValues()
            registerKeybinds()
        end)
    end
)

-- ============================================================
-- Clear gamemodeRef on save reload or end of day so the next
-- NotifyOnNewObject callback always receives a fresh object.
-- ============================================================
ExecuteWithDelay(3000, function()
    safe("WeatherSystem hook", function()
        RegisterHook(
            "/Game/VideoStore/asset/outside/WeatherSystem.WeatherSystem_C:ReceiveBeginPlay",
            function()
                gamemodeRef = nil
                debug("Save reloaded - gamemode reference cleared")
            end
        )
    end)

    safe("EndOfDay hook", function()
        RegisterHook(
            "/Game/VideoStore/core/gamemode/Core_Gamemode.Core_Gamemode_C:End of the day",
            function()
                gamemodeRef = nil
                debug("Day ended - gamemode reference cleared")
            end
        )
    end)

    debug("Reset hooks active")
end)

-- ============================================================
log("Economy QoL loaded | F2 = +$" ..
    string.format("%.2f", CONFIG.moneyAmount / 100) ..
    " | F3 = +" .. CONFIG.xpAmount .. " XP")
