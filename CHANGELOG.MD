# Changelog

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
