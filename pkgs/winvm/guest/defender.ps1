# winvm: Defender exclusions for the synced source tree and the Rust/Node toolchain.
# Called by provision.ps1; kept in its own file so AMSI does not flag provision.ps1.
$ErrorActionPreference = 'Stop'
Add-MpPreference -ExclusionPath 'C:\src', 'C:\winvm', "$env:USERPROFILE\.cargo", "$env:USERPROFILE\.rustup", "$env:LOCALAPPDATA\pnpm"
Add-MpPreference -ExclusionProcess 'cargo.exe', 'rustc.exe', 'link.exe', 'node.exe'
