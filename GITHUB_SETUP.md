# GitHub Setup

Upload the whole `Potatools-dev` folder contents to a GitHub repository. The important runtime paths are:

- `main.lua`
- `modules/original_manifest.lua`
- `modules/original_parts/part_*.lua`
- `dist/Potatools.lua`

## Fastest Exact Test

This runs the single-file copy of the current full hub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/dist/Potatools.lua"))()
```

Replace `USER` and `REPO` with your GitHub username and repository name.

## Exact Split Test

This runs `main.lua`, which downloads all ordered source parts from `modules/original_parts/`, joins them, checks the expected source length, then executes the rebuilt original script:

```lua
getgenv().PotatoolsBaseUrl = "https://raw.githubusercontent.com/USER/REPO/main/"
loadstring(game:HttpGet(getgenv().PotatoolsBaseUrl .. "main.lua"))()
```

You can also edit the default `baseUrl` inside `main.lua` after upload, then use:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/main.lua"))()
```

## Upload With GitHub Website

1. Create a new public GitHub repository.
2. Click `Add file` -> `Upload files`.
3. Drag the contents of `C:\Users\oofer\Downloads\Potatools-dev` into the upload page.
4. Commit the upload.
5. Open `https://raw.githubusercontent.com/USER/REPO/main/main.lua` in your browser. If it shows Lua text, the raw path is working.
6. Test one of the loadstring snippets above.

## Upload With Git Commands

Run these from `C:\Users\oofer\Downloads\Potatools-dev` after installing Git:

```powershell
git init
git add .
git commit -m "Initial Potatools exact split"
git branch -M main
git remote add origin https://github.com/USER/REPO.git
git push -u origin main
```

## What Is Exact

`modules/original_parts/` is an exact ordered split of `Universal-GLM-5.2-V9.lua`. It is not a semantic per-game refactor; it is the verified no-code-missing split used for runnable testing.

`main.modular.lua` and `modules/windows/` are the partial semantic split workspace. Keep using those for future per-game cleanup, but use `main.lua` or `dist/Potatools.lua` when you need the full original behavior.
