# installs zoo on windows, building from source when run from a checkout with cargo.
$ErrorActionPreference = 'Stop'

$Repo = if ($env:ZOO_REPO) { $env:ZOO_REPO } else { 'MateusAMP2119/zoo' }
$BinDir = Join-Path $HOME '.local\bin'

function Say($msg) { Write-Host "zoo: $msg" }

# 1. claude code, through its official installer, which also uses ~\.local\bin.
if ((Get-Command claude -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $BinDir 'claude.exe'))) {
    Say 'claude code already installed'
} else {
    Say 'installing claude code'
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
}

# 2. the zoo binary, built from this checkout or downloaded from the latest release.
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$Target = Join-Path $BinDir 'zoo.exe'
$SrcDir = if ($PSScriptRoot) { $PSScriptRoot } else { $null }
if ($SrcDir -and (Select-String -Quiet -Pattern '^name = "zoo"' -Path (Join-Path $SrcDir 'Cargo.toml') -ErrorAction SilentlyContinue) -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Say "building zoo from $SrcDir"
    cargo build --release --quiet --manifest-path (Join-Path $SrcDir 'Cargo.toml')
    if ($LASTEXITCODE -ne 0) { throw 'zoo: cargo build failed' }
    Copy-Item -Force (Join-Path $SrcDir 'target\release\zoo.exe') $Target
} else {
    $Arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { 'aarch64' } else { 'x86_64' }
    $Url = "https://github.com/$Repo/releases/latest/download/zoo-$Arch-pc-windows-msvc.zip"
    Say "downloading $Url"
    $Tmp = Join-Path ([IO.Path]::GetTempPath()) ("zoo-" + [Guid]::NewGuid())
    New-Item -ItemType Directory -Path $Tmp | Out-Null
    try {
        Invoke-WebRequest -UseBasicParsing $Url -OutFile (Join-Path $Tmp 'zoo.zip')
        Expand-Archive -Force (Join-Path $Tmp 'zoo.zip') $Tmp
        Copy-Item -Force (Join-Path $Tmp 'zoo.exe') $Target
    } finally {
        Remove-Item -Recurse -Force $Tmp
    }
}
Say "installed $Target"

# 3. ~\.local\bin on the user path, for terminals opened from now on.
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not (($UserPath -split ';') -contains $BinDir)) {
    [Environment]::SetEnvironmentVariable('Path', (@($UserPath, $BinDir) | Where-Object { $_ }) -join ';', 'User')
    Say "added $BinDir to your PATH"
    Say 'done, open a new terminal and type: zoo'
} else {
    Say 'done, type: zoo'
}
