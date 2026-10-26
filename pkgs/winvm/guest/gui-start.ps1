# winvm gui-start: queue a command to run on the interactive desktop via the winvm-gui task.
# Exit 2 if a gui command is already running.
param(
    [Parameter(Mandatory = $true)][string]$CommandBase64,
    [Parameter(Mandatory = $true)][string]$Cwd
)

$ErrorActionPreference = 'Stop'

$task = Get-ScheduledTask -TaskName 'winvm-gui'
if ($task.State -eq 'Running') {
    [Console]::Error.WriteLine('a gui command is already running')
    exit 2
}

$guiDir = 'C:\winvm\gui'
New-Item $guiDir -ItemType Directory -Force | Out-Null

$utf8 = New-Object Text.UTF8Encoding($false)
$command = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($CommandBase64))
[IO.File]::WriteAllText((Join-Path $guiDir 'cmd.txt'), $command, $utf8)
[IO.File]::WriteAllText((Join-Path $guiDir 'cwd.txt'), $Cwd, $utf8)

foreach ($f in @('out.log', 'exit.txt', 'pid.txt')) {
    Remove-Item -Path (Join-Path $guiDir $f) -Force -ErrorAction SilentlyContinue
}

Start-ScheduledTask -TaskName 'winvm-gui'
exit 0
