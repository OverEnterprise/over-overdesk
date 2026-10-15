[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$UiOnly
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$ServerKey = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'server_key.pub')
if ([string]::IsNullOrWhiteSpace($ServerKey)) {
    throw 'Preencha res/overdesk/server_key.pub com a chave publica do RustDesk Server.'
}
$ServerKey = $ServerKey.Trim()
try {
    $decodedKey = [Convert]::FromBase64String($ServerKey)
} catch {
    throw 'A chave publica do RustDesk deve estar em Base64. Nao use a chave privada nem uma senha.'
}
if ($decodedKey.Length -ne 32) {
    throw 'A chave publica do RustDesk deve conter 32 bytes apos decodificar o Base64. Confira /root/id_ed25519.pub no hbbs.'
}
if ($Check) {
    Write-Host 'Configuracao OverDesk valida: rustdesk.overenterprise.com.br, servidor OSS, sem API de contas.'
    return
}
if ($env:OS -ne 'Windows_NT' -or [Environment]::Is64BitProcess -eq $false -or
    $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Este comando compila apenas Windows x64. Use um terminal PowerShell de 64 bits.'
}

Push-Location -LiteralPath $repoRoot
try {
    foreach ($command in @('cargo', 'flutter', 'python')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Instale $command e adicione ao PATH. Consulte docs/OVERDESK.md."
        }
    }
    foreach ($file in @('src/bridge_generated.rs', 'src/bridge_generated.io.rs',
        'flutter/lib/generated_bridge.dart', 'flutter/lib/generated_bridge.freezed.dart')) {
        if (-not (Test-Path -LiteralPath $file)) {
            throw "Falta $file. Extraia bridge-artifact gerado pelo CI na raiz do repositorio; nao execute codegen localmente."
        }
    }
    if (-not (Test-Path -LiteralPath 'libs/hbb_common/Cargo.toml')) {
        throw 'Inicialize os submodulos: git submodule update --init --recursive'
    }
    if (-not $env:VCPKG_ROOT) {
        throw 'Configure VCPKG_ROOT conforme docs/OVERDESK.md.'
    }
    & python -c 'import brotli'
    if ($LASTEXITCODE -ne 0) {
        throw 'Instale a dependencia do empacotador: python -m pip install -r libs/portable/requirements.txt'
    }
    foreach ($asset in @('logo.png', 'icon.png', 'icon.ico')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $asset) -Destination (Join-Path 'flutter/assets' $asset) -Force
    }

    if ($UiOnly) {
        if (-not (Test-Path -LiteralPath 'target/release/librustdesk.dll')) {
            throw 'Execute primeiro o build completo do OverDesk, sem -UiOnly.'
        }
        Push-Location flutter
        try {
            & flutter build windows --release
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar a interface Flutter.' }
        } finally {
            Pop-Location
        }
    } else {
        & cargo build --locked --features flutter,hwcodec,vram,overdesk --lib --release
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar o Rust do OverDesk.' }
        & python build.py --flutter --hwcodec --vram --skip-cargo --skip-portable-pack
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar o aplicativo Windows.' }
    }

    $bundle = Join-Path $repoRoot 'flutter/build/windows/x64/runner/Release'
    Copy-Item -LiteralPath (Join-Path $bundle 'rustdesk.exe') -Destination (Join-Path $bundle 'OverDesk.exe') -Force
    Copy-Item -LiteralPath 'LICENCE' -Destination (Join-Path $bundle 'LICENSE-RustDesk.txt') -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'NOTICE.txt') -Destination $bundle -Force
    & python res/overdesk/package.py
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao comprimir o pacote portatil.' }
    & cargo build --locked --release -p rustdesk-portable-packer --features overdesk --target-dir target/overdesk-portable
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar o executavel portatil.' }
    Copy-Item -LiteralPath 'target/overdesk-portable/release/rustdesk-portable-packer.exe' -Destination 'target/OverDesk.exe' -Force
    Write-Host "OverDesk: $repoRoot\target\OverDesk.exe"
    Write-Host 'Distribua apenas esse EXE. Os arquivos internos sao extraidos automaticamente ao executar.'
} finally {
    Pop-Location
}
