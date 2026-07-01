# Potatools Development Workspace

This folder holds a modular development split of the Potatools hub.

Structure:
- `main.lua` -> remote/bootstrap loader for the split files
- `modules/` -> split Lua modules
- `modules/external_scripts.lua` -> supporter/external scripts fetched on button click
- `dist/` -> generated loadstring targets
- `scripts/` -> build and extraction utilities

Build:
Run the provided PowerShell build script to create `dist/Potatools.lua`:

```powershell
powershell -File .\scripts\build_bundle.ps1
```

Loadstring setup:

```lua
-- safest single-file target while the split is being verified
loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/dist/Potatools.lua"))()

-- exact split target
getgenv().PotatoolsBaseUrl = "https://raw.githubusercontent.com/USER/REPO/main/"
loadstring(game:HttpGet(getgenv().PotatoolsBaseUrl .. "main.lua"))()
```

`dist/Potatools.lua` is copied from the current full hub so original behavior is preserved. `main.lua` fetches the exact ordered source parts from `modules/original_parts/` and executes the rebuilt original.

The earlier semantic split bootstrap is preserved as `main.modular.lua`; it is not the default because it is not a complete 1:1 game-hub split yet.

Source preservation:
- `backups/Universal-GLM-5.2-V9.lua` is the current hub used for `dist/Potatools.lua`.
- `backups/Universal-GLM-5.2-V9.lua.bak_before_compact` is the pre-compact backup.
- `modules/inlined_scripts_backup.lua.txt` preserves the extracted inlined payload backup as text, not as a runtime Lua module.
- `modules/original_manifest.lua` lists the exact split source parts and expected length/hash metadata.

Hashes:
- current hub / `dist/Potatools.lua`: `6611E3694B665781378BE3E4DB9D7AD086D99DE68921CF4942DE49CF60848FDF`
- pre-compact backup: `92D004884BF5BA4C5E23237F99D68E1A9B1596D16944B6011D3D7C223E1319CF`
