# Retro Rewind - Economy QoL
**Version 1.0**

Adds keybinds to give yourself money and XP on demand.
Does not set the game's internal Cheat flag — achievements are unaffected.

---

## KEYBINDS

| Key | Action |
|-----|--------|
| F2  | Add money (default: $1,000) |
| F3  | Add XP (default: 500) |

---

## HOW IT WORKS

Both `Change Money` and `Change XP` are native functions on `Core_Gamemode_C` — the same functions the game itself uses for all money and XP transactions. Calling them directly ensures all UI counters and SaveGame state update correctly, exactly as they would from normal gameplay.

---

## INSTALLATION

1. Extract the `Economy QoL` folder into your UE4SS Mods directory:
   ```
   RetroRewind\Binaries\Win64\ue4ss\Mods\
   ```
2. Make sure `Economy QoL` is listed and enabled in `mods.txt`
3. Load your save — the mod is active immediately

---

## CONFIGURATION

Edit `config.lua` to change the amounts per keypress:

```lua
return {
    moneyAmount = 100000,   -- $1000.00 per press  (in cents)
    xpAmount    = 500,      -- 500 XP per press
}
```

A few examples:

| moneyAmount | Result per F2 press |
|-------------|---------------------|
| 100000      | $1,000.00           |
| 500000      | $5,000.00           |
| 1000000     | $10,000.00          |

---

## NOTES

- **Cheat flag:** The mod calls the same native functions the game uses internally. The game's Cheat flag (which disables achievements when using the in-game debug computer) is **not** set by this mod.
- **SaveGame:** Changes take effect immediately and are included in the next normal save via the time clock. No additional steps required.
- **Console output:** On load, the mod logs your current Money, XP and Level to the UE4SS console. This is intentional — it gives a baseline for diagnosing any unexpected behaviour.

---

## COMPATIBILITY

- Tested on game build 1994+
- No known conflicts with other mods
- Safe to add or remove mid-playthrough

---

## License
Shield: [![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]

This work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][cc-by-nc-sa].

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
