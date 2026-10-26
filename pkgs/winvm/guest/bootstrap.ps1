# winvm bootstrap: runs elevated at first logon from the setup CD
# (<cd>\winvm\bootstrap.ps1, drivers in <cd>\drivers, key in <cd>\winvm\authorized_keys).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

New-Item C:\winvm -ItemType Directory -Force | Out-Null
Start-Transcript -Path C:\winvm\bootstrap.log -Append | Out-Null

try {
    # 2. Guest drivers (NetKVM etc.). pnputil returns non-zero when some INFs do not apply; log only.
    $driverGlob = Join-Path $PSScriptRoot '..\drivers\*.inf'
    Write-Host "Installing drivers: $driverGlob"
    & pnputil.exe /add-driver $driverGlob /subdirs /install
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "pnputil exited with $LASTEXITCODE (continuing)"
    }

    # 3. Execution policy and non-expiring password. This script runs with
    # -ExecutionPolicy Bypass, so Set-ExecutionPolicy saves the LocalMachine value
    # but then throws "overridden by a policy defined at a more specific scope".
    try {
        Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
    } catch {
        if ((Get-ExecutionPolicy -Scope LocalMachine) -ne 'RemoteSigned') { throw }
    }
    Set-LocalUser -Name dev -PasswordNeverExpires $true

    # 4. Make autologon permanent
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' `
        -Name AutoLogonCount -ErrorAction SilentlyContinue

    # 5. Wait for network, then mark profiles Private
    $deadline = (Get-Date).AddMinutes(10)
    $online = $false
    while ((Get-Date) -lt $deadline) {
        try {
            Resolve-DnsName github.com -ErrorAction Stop | Out-Null
            $online = $true
            break
        } catch {
            Start-Sleep -Seconds 5
        }
    }
    if (-not $online) {
        throw 'Network did not come up within 10 minutes (github.com does not resolve).'
    }
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

    # 6. Remote Desktop
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' `
        -Name fDenyTSConnections -Value 0 -Type DWord
    Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'

    # 7. OpenSSH Server
    if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
        $attempt = 0
        while ($true) {
            $attempt++
            try {
                Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Null
                break
            } catch {
                Write-Warning "Add-WindowsCapability OpenSSH.Server attempt $attempt failed: $($_.Exception.Message)"
                if ($attempt -ge 3) { throw }
                Start-Sleep -Seconds 60
            }
        }
    }
    Set-Service -Name sshd -StartupType Automatic
    Start-Service -Name sshd

    if (-not (Test-Path 'HKLM:\SOFTWARE\OpenSSH')) {
        New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
    }
    New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
        -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' `
        -PropertyType String -Force | Out-Null

    $sshDir = 'C:\ProgramData\ssh'
    New-Item $sshDir -ItemType Directory -Force | Out-Null
    $akeys = Join-Path $sshDir 'administrators_authorized_keys'
    Copy-Item -Path (Join-Path $PSScriptRoot 'authorized_keys') -Destination $akeys -Force
    & icacls.exe $akeys /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'
    if ($LASTEXITCODE -ne 0) { throw "icacls failed with exit code $LASTEXITCODE" }

    if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
            -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow | Out-Null
    }
    Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Enabled True -Profile Any

    # 8. Done marker (host polls for it over ssh)
    New-Item C:\winvm\bootstrap.done -ItemType File -Force | Out-Null
    Write-Host 'bootstrap complete'
} catch {
    Write-Host ("BOOTSTRAP FAILED: " + $_.Exception.Message)
    Write-Host $_.ScriptStackTrace
    exit 1
} finally {
    Stop-Transcript | Out-Null
}
