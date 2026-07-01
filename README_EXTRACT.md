Extraction helper

Use `scripts/extract_windows.ps1` to generate candidate window modules from the hub for manual review.

Usage (PowerShell):

```powershell
cd C:\Users\oofer\Downloads\Potatools-dev\scripts
.
Extract_Windows.ps1 -HubPath "C:\Users\oofer\Downloads\Universal-GLM-5.2-V9.lua" -OutDir "C:\Users\oofer\Downloads\Potatools-dev\modules\windows\candidates"
```

After running, review `modules/windows/candidates` and move verified files into `modules/windows/`, then register them in `modules/ui.lua`.