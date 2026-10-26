# winvm provision: idempotent toolchain + Syncthing + GUI task setup.
# Synced folders (C:\src\<name>, .stfolder, .stignore) are managed by the host.
# Exit codes: 0 ok, 1 failure, 3 not elevated, 10 reboot required.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [Console]::Error.WriteLine('provision.ps1 must run elevated')
    exit 3
}

New-Item C:\winvm -ItemType Directory -Force | Out-Null
Start-Transcript -Path C:\winvm\provision.log -Append | Out-Null

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machine + ';' + $user
}

function Add-PathEntry {
    param([string]$Scope, [string]$Dir)
    if ($Scope -eq 'Machine') {
        $hive = [Microsoft.Win32.Registry]::LocalMachine
        $subKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    } else {
        $hive = [Microsoft.Win32.Registry]::CurrentUser
        $subKey = 'Environment'
    }
    $key = $hive.OpenSubKey($subKey, $true)
    try {
        $cur = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $entries = @($cur.Split(';') | Where-Object { $_ })
        $want = $Dir.TrimEnd('\')
        foreach ($e in $entries) {
            if ([Environment]::ExpandEnvironmentVariables($e).TrimEnd('\') -ieq $want) { return }
        }
        $new = (($entries + $Dir) -join ';')
        $key.SetValue('Path', $new, [Microsoft.Win32.RegistryValueKind]::ExpandString)
        Write-Host "Added to $Scope PATH: $Dir"
    } finally {
        $key.Dispose()
    }
}

function Write-TextNoBom {
    param([string]$Path, [string]$Text)
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}

function Invoke-Native {
    $file = $args[0]
    $rest = @()
    if ($args.Count -gt 1) { $rest = $args[1..($args.Count - 1)] }
    $global:LASTEXITCODE = 0
    & $file @rest
    if ($LASTEXITCODE -ne 0) {
        throw "$file $($rest -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Invoke-WithRetry {
    param([scriptblock]$Action, [int]$Attempts = 3, [int]$DelaySeconds = 60)
    $attempt = 0
    while ($true) {
        $attempt++
        try {
            & $Action
            return
        } catch {
            Write-Warning "attempt $attempt failed: $($_.Exception.Message)"
            if ($attempt -ge $Attempts) { throw }
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

$rebootNeeded = $false

try {
    # ---- 2. System settings -------------------------------------------------
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
        -Name LongPathsEnabled -Value 1 -Type DWord

    # Separate script: with these calls inline, AMSI blocks this whole file as
    # Trojan:PowerShell/Killav (exclusions next to downloads and installers).
    try {
        & (Join-Path $PSScriptRoot 'defender.ps1')
    } catch {
        Write-Warning "Defender exclusions not applied: $($_.Exception.Message)"
    }

    $vbs = Get-WindowsCapability -Online -Name 'VBSCRIPT*' | Select-Object -First 1
    if ($vbs -and $vbs.State -ne 'Installed') {
        Write-Host "Installing capability $($vbs.Name)"
        $vbsName = $vbs.Name
        Invoke-WithRetry { Add-WindowsCapability -Online -Name $vbsName | Out-Null }
    } elseif (-not $vbs) {
        throw 'VBSCRIPT Windows capability not found'
    }

    foreach ($pc in @(
            @('-h', 'off'),
            @('/change', 'standby-timeout-ac', '0'),
            @('/change', 'monitor-timeout-ac', '0'))) {
        & powercfg.exe @pc
        if ($LASTEXITCODE -ne 0) { Write-Warning "powercfg $($pc -join ' ') exited with $LASTEXITCODE" }
    }

    $wuAu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    New-Item -Path $wuAu -Force | Out-Null
    Set-ItemProperty -Path $wuAu -Name AUOptions -Value 3 -Type DWord
    Set-ItemProperty -Path $wuAu -Name NoAutoRebootWithLoggedOnUsers -Value 1 -Type DWord

    # QEMU's RTC runs in UTC but Windows reads it as local time unless told otherwise
    # (guest clock off by the UTC offset). Applies from the next boot, so ask for one
    # the first time; NTP below corrects the running clock meanwhile.
    $tzKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
    if ((Get-ItemProperty -Path $tzKey -Name RealTimeIsUniversal -ErrorAction SilentlyContinue).RealTimeIsUniversal -ne 1) {
        Set-ItemProperty -Path $tzKey -Name RealTimeIsUniversal -Value 1 -Type DWord
        $rebootNeeded = $true
    }
    Set-Service -Name w32time -StartupType Automatic
    Start-Service -Name w32time
    Invoke-Native w32tm /config '/manualpeerlist:time.windows.com,0x9' /syncfromflags:manual /update
    & w32tm /resync /force | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Warning "w32tm /resync exited with $LASTEXITCODE (the service retries)" }
    $global:LASTEXITCODE = 0

    # ---- 3. Tools from tools.json ------------------------------------------
    $toolsFile = 'C:\winvm\tools.json'
    if (-not (Test-Path $toolsFile)) { throw "$toolsFile is missing" }
    $tools = Get-Content -Raw -Path $toolsFile | ConvertFrom-Json

    $dlDir = 'C:\winvm\dl'
    $markerDir = 'C:\winvm\installed'
    $toolsDir = 'C:\winvm\tools'
    foreach ($d in @($dlDir, $markerDir, $toolsDir)) {
        New-Item $d -ItemType Directory -Force | Out-Null
    }

    foreach ($t in $tools) {
        $marker = Join-Path $markerDir ("{0}-{1}" -f $t.name, $t.version)
        if (Test-Path $marker) {
            Write-Host "skip $($t.name) $($t.version) (installed)"
            continue
        }
        Write-Host "=== $($t.name) $($t.version) ($($t.type)) ==="

        $toolArgs = @()
        if ($t.PSObject.Properties['args'] -and $null -ne $t.args) { $toolArgs = @($t.args) }
        $okCodes = @(0)
        if ($t.PSObject.Properties['okExitCodes'] -and $null -ne $t.okExitCodes) { $okCodes = @($t.okExitCodes | ForEach-Object { [int]$_ }) }

        $fileName = [IO.Path]::GetFileName(([Uri]$t.url).AbsolutePath)
        # Keep the upstream file name: rustup-init dispatches on its own exe name.
        $toolDl = Join-Path $dlDir $t.name
        New-Item $toolDl -ItemType Directory -Force | Out-Null
        $dl = Join-Path $toolDl $fileName
        $want = ([string]$t.sha256).ToUpper()

        $have = $false
        if (Test-Path $dl) {
            $have = ((Get-FileHash -Algorithm SHA256 -Path $dl).Hash -eq $want)
        }
        if (-not $have) {
            Invoke-Native curl.exe -fL --retry 5 -o $dl $t.url
            $got = (Get-FileHash -Algorithm SHA256 -Path $dl).Hash
            if ($got -ne $want) {
                Remove-Item $dl -Force
                throw "SHA256 mismatch for $($t.name): expected $want, got $got"
            }
        }

        # rustup must see CARGO_HOME/RUSTUP_HOME (tauri-cli only reads $CARGO_HOME/config.toml when set)
        if ($t.name -eq 'rustup') {
            $cargoHome = Join-Path $env:USERPROFILE '.cargo'
            $rustupHome = Join-Path $env:USERPROFILE '.rustup'
            [Environment]::SetEnvironmentVariable('CARGO_HOME', $cargoHome, 'User')
            [Environment]::SetEnvironmentVariable('RUSTUP_HOME', $rustupHome, 'User')
            $env:CARGO_HOME = $cargoHome
            $env:RUSTUP_HOME = $rustupHome
        }

        $code = 0
        switch ($t.type) {
            'msi' {
                $msiArgs = @('/i', ('"{0}"' -f $dl), '/qn', '/norestart') + $toolArgs
                $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList ($msiArgs -join ' ') -Wait -PassThru
                $code = $p.ExitCode
                $okCodes = @($okCodes + 0 + 3010)
            }
            'exe' {
                $spArgs = @{ FilePath = $dl; Wait = $true; PassThru = $true }
                if ($toolArgs.Count -gt 0) { $spArgs['ArgumentList'] = ($toolArgs -join ' ') }
                $p = Start-Process @spArgs
                $code = $p.ExitCode
            }
            'zip' {
                $dest = Join-Path $toolsDir $t.name
                Expand-Archive -Path $dl -DestinationPath $dest -Force
                if ($t.PSObject.Properties['addPath'] -and $t.addPath) {
                    Add-PathEntry -Scope Machine -Dir (Join-Path $dest $t.addPath)
                }
                $code = 0
            }
            'bin' {
                $dest = Join-Path $toolsDir $t.name
                New-Item $dest -ItemType Directory -Force | Out-Null
                Copy-Item -Path $dl -Destination (Join-Path $dest $t.bin) -Force
                Add-PathEntry -Scope Machine -Dir $dest
                $code = 0
            }
            default { throw "unknown tool type '$($t.type)' for $($t.name)" }
        }

        if ($okCodes -notcontains $code) {
            throw "$($t.name) installer failed with exit code $code (see $dl)"
        }
        if ($code -eq 3010) { $rebootNeeded = $true }
        New-Item -Path $marker -ItemType File -Force | Out-Null
        Update-SessionPath
    }

    Update-SessionPath

    # ---- 4. Post-install configuration -------------------------------------
    [Environment]::SetEnvironmentVariable('LIBCLANG_PATH', 'C:\Program Files\LLVM\bin', 'User')
    $env:LIBCLANG_PATH = 'C:\Program Files\LLVM\bin'

    $nasmDir = $null
    foreach ($cand in @('C:\Program Files\NASM', 'C:\Program Files (x86)\NASM')) {
        if (Test-Path (Join-Path $cand 'nasm.exe')) { $nasmDir = $cand; break }
    }
    if (-not $nasmDir) { throw 'nasm.exe not found under C:\Program Files\NASM or C:\Program Files (x86)\NASM' }
    Add-PathEntry -Scope Machine -Dir $nasmDir
    Add-PathEntry -Scope User -Dir (Join-Path $env:APPDATA 'npm')
    Update-SessionPath

    # Dev servers (next dev, vite) listen on all interfaces; without a rule Windows
    # pops an "allow Node.js" dialog over the desktop. Loopback is never filtered.
    if (-not (Get-NetFirewallRule -Name 'winvm-node-inbound' -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name 'winvm-node-inbound' -DisplayName 'winvm: Node.js inbound (blocked)' `
            -Direction Inbound -Program 'C:\Program Files\nodejs\node.exe' -Action Block -Profile Any | Out-Null
    }

    # ---- 5. arm64: default cargo build target is x86_64 --------------------
    $osArch = [string][Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    if ($osArch -eq 'Arm64') {
        $cargoDir = Join-Path $env:USERPROFILE '.cargo'
        New-Item $cargoDir -ItemType Directory -Force | Out-Null
        $cfg = "# managed by winvm`n[build]`ntarget = `"x86_64-pc-windows-msvc`"`n"
        Write-TextNoBom -Path (Join-Path $cargoDir 'config.toml') -Text $cfg
        Write-Host 'wrote .cargo\config.toml (build.target = x86_64-pc-windows-msvc)'
    }

    # Default toolchain for repos without rust-toolchain.toml (Silentsuite, kage-ss,
    # vector-sdk, vector-crates); CI there uses latest stable.
    $toolchains = @(& rustup toolchain list)
    if ($LASTEXITCODE -ne 0) { throw "rustup toolchain list failed with exit code $LASTEXITCODE" }
    # rustup prints "(default)" or "(active, default)" next to the default toolchain.
    if (-not ($toolchains -match '\(([a-z]+, )?default\)')) {
        Invoke-Native rustup toolchain install stable --profile minimal
        Invoke-Native rustup default stable
    }
    if ($osArch -eq 'Arm64') {
        Invoke-Native rustup target add x86_64-pc-windows-msvc --toolchain stable
    }

    # ---- 6. pnpm (standalone pnpm.exe from tools.json) -----------------------
    # build.ts spawns "pnpm" without a shell, so it must resolve to an .exe. Run
    # outside any repo so packageManager does not switch versions.
    $pnpmCmd = Get-Command pnpm -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $pnpmCmd -or $pnpmCmd.Source -notlike '*.exe') {
        throw "pnpm does not resolve to pnpm.exe (got: $($pnpmCmd.Source))"
    }
    Push-Location C:\
    $global:LASTEXITCODE = 0
    $pnpmVersion = ([string](& $pnpmCmd.Source --version)).Trim()
    Pop-Location
    if ($pnpmVersion -ne '10.30.1') { throw "pnpm.exe reports version '$pnpmVersion', expected 10.30.1" }

    # ---- 7. Git configuration ----------------------------------------------
    Invoke-Native git config --system core.longpaths true
    Invoke-Native git config --global core.autocrlf false
    Invoke-Native git config --global --replace-all url.https://github.com/.insteadOf ssh://git@github.com/
    $global:LASTEXITCODE = 0
    $rewrites = @(& git config --global --get-all url.https://github.com/.insteadOf)
    $global:LASTEXITCODE = 0
    if ($rewrites -notcontains 'git@github.com:') {
        Invoke-Native git config --global --add url.https://github.com/.insteadOf git@github.com:
    }

    # ---- 8. gh token -------------------------------------------------------
    $ghToken = 'C:\winvm\gh-token'
    if (Test-Path $ghToken) {
        try {
            $token = (Get-Content -Raw -Path $ghToken).Trim()
            $global:LASTEXITCODE = 0
            $token | & gh auth login --with-token --insecure-storage
            if ($LASTEXITCODE -ne 0) { throw "gh auth login failed with exit code $LASTEXITCODE" }
            Invoke-Native gh auth setup-git
        } finally {
            Remove-Item $ghToken -Force -ErrorAction SilentlyContinue
        }
    }

    # ---- 9. Guest Syncthing -------------------------------------------------
    $stExe = Get-ChildItem -Path (Join-Path $toolsDir 'syncthing') -Recurse -Filter 'syncthing.exe' -File |
        Select-Object -First 1
    if (-not $stExe) { throw 'syncthing.exe not found under C:\winvm\tools\syncthing' }

    if (-not (Get-NetFirewallRule -Name 'winvm-syncthing' -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name 'winvm-syncthing' -DisplayName 'winvm-syncthing' `
            -Direction Inbound -Protocol TCP -LocalPort 22000 -Action Allow -Profile Any | Out-Null
    }

    # Stop a running instance so it picks up the freshly copied config.
    Stop-ScheduledTask -TaskName 'winvm-syncthing' -ErrorAction SilentlyContinue
    Get-Process -Name syncthing -ErrorAction SilentlyContinue | Stop-Process -Force

    $stArgs = 'serve --home "C:\winvm\syncthing-home" --no-browser --no-restart --no-upgrade --no-console'
    $stAction = New-ScheduledTaskAction -Execute $stExe.FullName -Argument $stArgs
    $stTrigger = New-ScheduledTaskTrigger -AtStartup
    $stPrincipal = New-ScheduledTaskPrincipal -UserId 'dev' -LogonType S4U
    $stSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName 'winvm-syncthing' -Action $stAction -Trigger $stTrigger `
        -Principal $stPrincipal -Settings $stSettings -Force | Out-Null
    Start-ScheduledTask -TaskName 'winvm-syncthing'

    # ---- 10. GUI task (runs in the interactive desktop session) -------------
    $guiAction = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\winvm\gui-run.ps1'
    $guiPrincipal = New-ScheduledTaskPrincipal -UserId 'dev' -LogonType Interactive -RunLevel Highest
    $guiSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName 'winvm-gui' -Action $guiAction `
        -Principal $guiPrincipal -Settings $guiSettings -Force | Out-Null

    # ---- 11. Done -----------------------------------------------------------
    New-Item C:\winvm\provisioned -ItemType File -Force | Out-Null
    if ($rebootNeeded) {
        Write-Host 'provision complete; reboot required'
        $exitCode = 10
    } else {
        Write-Host 'provision complete'
        $exitCode = 0
    }
} catch {
    Write-Host ("PROVISION FAILED: " + $_.Exception.Message)
    Write-Host $_.ScriptStackTrace
    $exitCode = 1
} finally {
    Stop-Transcript | Out-Null
}
exit $exitCode
