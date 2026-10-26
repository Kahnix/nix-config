# winvm prepare: install Rust toolchain/JS deps/cargo deps and hydrate vector-crates LFS objects.
# Mirrors .github/actions/hydrate-cargo-lfs. Re-run after a lockfile or vector-crates rev change.
param(
    [Parameter(Mandatory = $true)][string]$Root
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
    $env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'
    Set-Location -Path $Root

    # 1-2. Rust toolchain from rust-toolchain.toml, plus the x64 MSVC target
    Invoke-Native rustup toolchain install
    Invoke-Native rustup target add x86_64-pc-windows-msvc

    # 3. JS dependencies
    Invoke-Native pnpm install --frozen-lockfile

    # 4. Cargo git dependencies
    Invoke-Native cargo fetch --manifest-path apps/vector-client/src-tauri/Cargo.toml --locked

    # 5. Hydrate LFS objects in the vector-crates checkouts
    $cargoHome = $env:CARGO_HOME
    if (-not $cargoHome) { $cargoHome = Join-Path $env:USERPROFILE '.cargo' }
    $checkoutRoot = Join-Path $cargoHome 'git\checkouts'
    if (-not (Test-Path $checkoutRoot)) {
        throw "Cargo git checkout directory does not exist: $checkoutRoot"
    }

    $lfsRepo = 'https://github.com/vector-org/vector-crates.git'
    $requiredFile = 'discord-social-sdk\vendor\lib\release\discord_partner_sdk.lib'
    $pointerPrefix = [Text.Encoding]::ASCII.GetBytes('version https://git-lfs.github.com/spec')

    $found = 0
    $checkouts = @(Get-ChildItem -Path $checkoutRoot -Directory -Filter 'vector-crates-*' |
        ForEach-Object { Get-ChildItem -Path $_.FullName -Directory })
    foreach ($checkout in $checkouts) {
        $found++
        $dir = $checkout.FullName
        Write-Host "Hydrating LFS files in $dir"

        $remotes = @(& git -C $dir remote)
        if ($LASTEXITCODE -ne 0) { throw "git remote failed in $dir" }
        if ($remotes -contains 'cargo-lfs') {
            Invoke-Native git -C $dir remote set-url cargo-lfs $lfsRepo
        } else {
            Invoke-Native git -C $dir remote add cargo-lfs $lfsRepo
        }
        Invoke-Native git -C $dir lfs install --local
        Invoke-Native git -C $dir lfs pull cargo-lfs

        $lib = Join-Path $dir $requiredFile
        if (-not (Test-Path $lib) -or (Get-Item $lib).Length -le 0) {
            throw "Required Cargo dependency file is missing or empty: $lib"
        }
        $buf = New-Object byte[] $pointerPrefix.Length
        $fs = [IO.File]::OpenRead($lib)
        try { $n = $fs.Read($buf, 0, $buf.Length) } finally { $fs.Dispose() }
        $isPointer = ($n -eq $pointerPrefix.Length)
        if ($isPointer) {
            for ($i = 0; $i -lt $n; $i++) {
                if ($buf[$i] -ne $pointerPrefix[$i]) { $isPointer = $false; break }
            }
        }
        if ($isPointer) {
            throw "Required Cargo dependency file is still an LFS pointer: $lib"
        }
    }
    if ($found -eq 0) {
        throw "No Cargo git checkout matched vector-crates-* under $checkoutRoot"
    }

    Write-Host 'prepare complete'
    $exitCode = 0
} catch {
    [Console]::Error.WriteLine("prepare failed: " + $_.Exception.Message)
    $exitCode = 1
}
exit $exitCode
