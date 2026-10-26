# winvm gui-run: executed by the winvm-gui scheduled task in the interactive session.
# Runs C:\winvm\gui\cmd.txt in cwd.txt, output to out.log, exit code to exit.txt.
$ErrorActionPreference = 'Stop'

$guiDir = 'C:\winvm\gui'
$outLog = Join-Path $guiDir 'out.log'
$exitFile = Join-Path $guiDir 'exit.txt'
$pidFile = Join-Path $guiDir 'pid.txt'

try {
    $cmd = [IO.File]::ReadAllText((Join-Path $guiDir 'cmd.txt'), [Text.Encoding]::UTF8)
    $cwd = [IO.File]::ReadAllText((Join-Path $guiDir 'cwd.txt'), [Text.Encoding]::UTF8)
    $cwdQuoted = $cwd.Replace("'", "''")

    # Same exit rule as the host's exec: last native exit code, else 1 if the last statement failed.
    $exitRule = '$ok = $?; if ($LASTEXITCODE) { exit $LASTEXITCODE }; if (-not $ok) { exit 1 }; exit 0'
    $inner = "`$ProgressPreference = 'SilentlyContinue'; [Console]::OutputEncoding=[Text.Encoding]::UTF8; Set-Location '" + $cwdQuoted + "'; " + $cmd + "; " + $exitRule
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))

    $argLine = "/d /s /c `"powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc > $outLog 2>&1`""
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList $argLine -PassThru -WindowStyle Minimized
    $null = $p.Handle
    [IO.File]::WriteAllText($pidFile, [string]$p.Id)
    $p.WaitForExit()
    [IO.File]::WriteAllText($exitFile, [string]$p.ExitCode)
} catch {
    $msg = "gui-run failed: " + $_.Exception.Message + "`r`n"
    [IO.File]::AppendAllText($outLog, $msg)
    [IO.File]::WriteAllText($exitFile, '1')
    exit 1
}
