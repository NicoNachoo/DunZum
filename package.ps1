$lovePath = "C:\Program Files\LOVE"
$buildDir = "build"
$projectName = "DUNZUM"

# Create build directory
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir
}
else {
    Remove-Item -Path "$buildDir\*" -Recurse -Force
}

# Create game.love (zip)
# We include src, lib, main.lua, conf.lua
$zipSource = @("src", "lib", "fonts", "imgs", "main.lua", "conf.lua")
Compress-Archive -Path $zipSource -DestinationPath "$buildDir\game.zip" -Force
Rename-Item -Path "$buildDir\game.zip" -NewName "game.love"

# Fuse love.exe and game.love
$loveExe = Join-Path $lovePath "love.exe"
$outputExe = Join-Path $buildDir "$projectName.exe"

# Use cmd /c for the copy /b command which is a reliable way to fuse files on Windows
cmd /c "copy /b `"$loveExe`" + `"$buildDir\game.love`" `"$outputExe`""

# Copy DLLs
$dlls = Get-ChildItem -Path $lovePath -Filter "*.dll"
foreach ($dll in $dlls) {
    Copy-Item -Path $dll.FullName -Destination $buildDir
}

# Clean up game.love
Remove-Item -Path "$buildDir\game.love"

Write-Host "Build complete! Check the '$buildDir' directory." -ForegroundColor Green
