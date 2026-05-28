-- ============================================================
--  Retro Rewind - Economy QoL
--  Version: 1.3
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
--
--  Changes in 1.3:
--  - Replaced NotifyOnNewObject-based gamemode tracking with
--    lazy re-acquisition via FindAllOf. The previous approach
--    had a race condition between WeatherSystem:ReceiveBeginPlay
--    (which cleared the cached reference) and the delayed
--    NotifyOnNewObject callback (which set it). On slower
--    hardware the cleanup could run *after* the acquisition,
--    leaving the cached reference permanently nil after a
--    save reload. The new pattern validates the reference at
--    each access and refreshes it on demand, eliminating the
--    timing dependency entirely.
--  - Removed WeatherSystem:ReceiveBeginPlay and End of the day
--    cleanup hooks — no longer needed with the lazy getter.
--  - Keybinds are registered immediately at mod load instead
--    of waiting for the gamemode reference; the lazy getter
--    handles the not-yet-available case gracefully.
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

-- ============================================================
-- CACHED REFERENCE: Core_Gamemode_C
--
-- The getter validates the reference before returning it;
-- if the object was garbage-collected, invalidated by a save
-- reload, or never acquired at all, a fresh lookup is performed
-- automatically. Returns nil only when the gamemode is genuinely
-- not present in the world (e.g. before the game finished loading).
--
-- This pattern is timing-independent: it does not matter in which
-- order Core_Gamemode_C and WeatherSystem_C spawn during a reload,
-- because the reference is re-acquired on demand at the moment of
-- use rather than tracked reactively via NotifyOnNewObject.
-- ============================================================
local cachedGamemode = nil

local function getGamemode()
    if not cachedGamemode or not cachedGamemode:IsValid() then
        local gms = FindAllOf("Core_Gamemode_C")
        cachedGamemode = gms and gms[1] or nil
    end
    return cachedGamemode
end

-- ============================================================
-- CORE: Log current Money, XP and Level
-- Reads live values directly from Core_Gamemode_C properties
-- (confirmed via Blueprint dump: offsets 0x348, 0x3CC, 0x3C8).
-- Called once on startup so the baseline is always visible in
-- the console — useful when players report unexpected behaviour.
-- ============================================================
local function logCurrentValues()
    local gm = getGamemode()
    if not gm then
        debug("logCurrentValues: gamemode not available")
        return
    end

    pcall(function()
        local okM, money = pcall(function() return gm["Money"] end)
        local okX, xp    = pcall(function() return gm["Experience"] end)
        local okL, level = pcall(function() return gm["Level"] end)

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
    local gm = getGamemode()
    if not gm then
        log("Gamemode not available")
        return
    end

    local hasEnough = {}
    local newMoney  = {}
    local ok, err = pcall(function()
        gm["Change Money"](amount, false, true, hasEnough, newMoney)
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
    local gm = getGamemode()
    if not gm then
        log("Gamemode not available")
        return
    end

    local newXP = {}
    local ok, err = pcall(function()
        gm["Change XP"](amount, newXP)
    end)

    if ok then
        log("Added " .. tostring(amount) .. " XP")
    else
        log("Change XP error: " .. tostring(err))
    end
end

-- ============================================================
-- KEYBINDS
-- Registered immediately at mod load. The lazy getter handles
-- the case where the player presses a key before the gamemode
-- is available, so there is no need to defer registration.
-- ============================================================
local function registerKeybinds()
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
-- INITIAL POLLING: Wait for Core_Gamemode_C to be available,
-- then log the baseline values once.
--
-- Direct access at startup fails because the Blueprint class
-- is not yet loaded when the mod initialises. The previous
-- implementation used NotifyOnNewObject for this, but coupling
-- it with the cached reference created a race condition with
-- the WeatherSystem cleanup hook. Polling decouples the initial
-- log from the runtime reference and is independent of spawn
-- ordering or hardware speed.
--
-- Up to 20 attempts at 500 ms each = 10 s timeout. The mod
-- remains fully functional even if the initial log times out;
-- the lazy getter still works the moment the gamemode appears.
-- ============================================================
local function pollForGamemode(attempt)
    attempt = attempt or 1

    if getGamemode() then
        debug("Gamemode found on attempt " .. attempt)
        logCurrentValues()
        return
    end

    if attempt >= 20 then
        debug("Initial gamemode poll timed out after " .. attempt .. " attempts")
        return
    end

    ExecuteWithDelay(500, function()
        pollForGamemode(attempt + 1)
    end)
end

-- ============================================================
registerKeybinds()
pollForGamemode()

log("Economy QoL loaded | F2 = +$" ..
    string.format("%.2f", CONFIG.moneyAmount / 100) ..
    " | F3 = +" .. CONFIG.xpAmount .. " XP")