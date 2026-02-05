---
description: Build the game executable
---

To build the game into a standalone executable:

// turbo
1. Run the packaging script:
```powershell
pwsh -ExecutionPolicy Bypass -File package.ps1
```

This will create a `build` directory containing `game.exe` and `game.love`.
