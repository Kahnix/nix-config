# winvm build: build the vector-client Windows bundles (x86_64-pc-windows-msvc).
# Mirrors .github/workflows/jobs-build.yml.
param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][ValidateSet('local', 'dev', 'test', 'prod')][string]$Stage
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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

function Update-SessionEnv {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    foreach ($name in @('CARGO_HOME', 'RUSTUP_HOME', 'LIBCLANG_PATH')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($value) { Set-Item -Path "Env:$name" -Value $value }
    }
}

try {
    Update-SessionEnv

    # 1. Build environment (scripts/build.ts requires these)
    $env:STAGE = $Stage
    $env:OPERATING_SYSTEM = 'windows'
    $env:ARCHITECTURE = 'x86_64'
    $env:SIGNING_ENABLED = 'false'
    $env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'

    # 2. Work in the app dir
    Set-Location -Path (Join-Path $Root 'apps\vector-client')

    # 3. Same steps as CI
    Invoke-Native pnpm --filter '@vector/supabase' build
    Invoke-Native pnpm build
    Invoke-Native pnpm tauri:build:local

    # 4. Report installers
    $targetDir = Join-Path (Get-Location).Path 'src-tauri\target\x86_64-pc-windows-msvc'
    $bundles = @(Get-ChildItem -Path $targetDir -Recurse -File -Include '*.msi', '*-setup.exe' -ErrorAction SilentlyContinue)
    if ($bundles.Count -eq 0) {
        throw "build finished but no .msi or -setup.exe found under $targetDir"
    }
    Write-Host 'Bundles:'
    foreach ($b in $bundles) {
        Write-Host ("  {0}  ({1:N1} MiB)" -f $b.FullName, ($b.Length / 1MB))
    }
    $exitCode = 0
} catch {
    [Console]::Error.WriteLine("build failed: " + $_.Exception.Message)
    $exitCode = 1
}
exit $exitCode
