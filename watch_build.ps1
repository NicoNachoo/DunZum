$path = Get-Location
$filter = "*.lua"
$watcher = New-Object IO.FileSystemWatcher $path, $filter -Property @{
    IncludeSubdirectories = $true
    EnableRaisingEvents = $true
}

Write-Host "Watching for changes in $path... (Press Ctrl+C to stop)" -ForegroundColor Cyan

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    # Simple debounce to avoid multiple builds for one save
    $recent = Get-Variable -Name "LastBuildTime" -ErrorAction SilentlyContinue
    if ($recent -and (New-TimeSpan -Start $recent.Value -End (Get-Date)).TotalSeconds -lt 2) {
        return
    }
    Set-Variable -Name "LastBuildTime" -Value (Get-Date) -Scope Global

    Write-Host "[$timestamp] $changeType detected in $path. Rebuilding..." -ForegroundColor Yellow
    pwsh -ExecutionPolicy Bypass -File package.ps1
}

$handlers = . {
    Register-ObjectEvent $watcher "Changed" -Action $action
    Register-ObjectEvent $watcher "Created" -Action $action
    Register-ObjectEvent $watcher "Deleted" -Action $action
    Register-ObjectEvent $watcher "Renamed" -Action $action
}

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "Stopping watcher..." -ForegroundColor Red
    $handlers | Unregister-Event
    $watcher.Dispose()
}
