# Changelog

## 1.3
- Replaced NotifyOnNewObject-based gamemode tracking with lazy re-acquisition via FindAllOf. The previous approach had a race condition between WeatherSystem:ReceiveBeginPlay (which cleared the cached reference) and the delayed NotifyOnNewObject callback (which set it). On slower hardware the cleanup could run *after* the acquisition, leaving the cached reference permanently nil after a save reload. The new pattern validates the reference at each access and refreshes it on demand, eliminating the timing dependency entirely.
- Removed WeatherSystem:ReceiveBeginPlay and End of the day cleanup hooks — no longer needed with the lazy getter.
- Keybinds are registered immediately at mod load instead of waiting for the gamemode reference; the lazy getter handles the not-yet-available case gracefully.

## 1.2
- Fixed `moneyAmount` default in YAML (was 10000, should be 100000)
- Added unit hint to `moneyAmount` description (cents)
- Corrected mod name and version in YAML to match main.lua

## 1.1
- Added `debug()` helper gated behind `CONFIG.Debug`
- Removed `hookRegistered` flag — `NotifyOnNewObject` now keeps `gamemodeRef` up to date after save reloads; `keybindsRegistered` guards the one-time keybind setup
- Added reset hooks (`WeatherSystem_C:ReceiveBeginPlay`, `End of the day`) to clear `gamemodeRef` between sessions

## 1.0
- Initial release
- F2 adds configurable money amount via native `Change Money` function
- F3 adds configurable XP amount via native `Change XP` function
- Does not set the game's Cheat flag — achievements are unaffected
