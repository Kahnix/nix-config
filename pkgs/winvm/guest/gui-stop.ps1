# winvm gui-stop: kill the whole gui process tree (cmd -> powershell -> pnpm/node -> cargo -> app)
# and stop the winvm-gui task. Always exits 0.
$ErrorActionPreference = 'Continue'

$guiDir = 'C:\winvm\gui'
$pidFile = Join-Path $guiDir 'pid.txt'
$exitFile = Join-Path $guiDir 'exit.txt'

$guiPid = ''
if (Test-Path $pidFile) {
    $guiPid = ([string](Get-Content -Raw -Path $pidFile)).Trim()
    if ($guiPid -match '^\d+$') {
        & taskkill.exe /PID $guiPid /T /F 2>&1 | Out-Null
        # Give gui-run.ps1 a moment to record the exit code so a concurrent gui-tail terminates.
        for ($i = 0; $i -lt 20 -and -not (Test-Path $exitFile); $i++) {
            Start-Sleep -Milliseconds 150
        }
    }
}

Stop-ScheduledTask -TaskName 'winvm-gui' -ErrorAction SilentlyContinue

if ($guiPid -and -not (Test-Path $exitFile)) {
    [IO.File]::WriteAllText($exitFile, '1')
}
exit 0
