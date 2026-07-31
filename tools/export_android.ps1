# Export Android APK for Mini TD
# Usage: powershell -ExecutionPolicy Bypass -File tools\export_android.ps1

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

$Godot = "C:\Users\WIN10\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64_console.exe"
$Jdk = Join-Path $Root "tools\jdk-17"
$Sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$TplDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.1.stable"
$Tpz = Join-Path $Root "tools\Godot_v4.7.1-stable_export_templates.tpz"
$OutDir = Join-Path $Root "build"
$Apk = Join-Path $OutDir "MiniTD.apk"

$env:JAVA_HOME = "$Jdk"
$env:ANDROID_HOME = "$Sdk"
$env:ANDROID_SDK_ROOT = "$Sdk"
$env:Path = "$Jdk\bin;$Sdk\platform-tools;" + $env:Path

Write-Host "== Check environment =="
if (-not (Test-Path $Godot)) { throw "Godot not found: $Godot" }
if (-not (Test-Path "$Jdk\bin\java.exe")) { throw "JDK not found: $Jdk" }
if (-not (Test-Path "$Sdk\platform-tools\adb.exe")) { throw "Android SDK not found: $Sdk" }

$needTpl = -not (Test-Path (Join-Path $TplDir "android_debug.apk"))
if ($needTpl) {
  if (-not (Test-Path $Tpz)) {
    Write-Host "Missing export templates tpz:"
    Write-Host "  $Tpz"
    Write-Host "Download:"
    Write-Host "  https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz"
    exit 2
  }
  $size = (Get-Item $Tpz).Length
  if ($size -lt 1000000000) {
    throw "Template file incomplete ($size bytes), need ~1.28GB"
  }
  Write-Host "Extracting export templates..."
  New-Item -ItemType Directory -Force -Path $TplDir | Out-Null
  $extract = Join-Path $env:TEMP "godot_tpl_4_7_1"
  if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $extract | Out-Null
  Copy-Item $Tpz (Join-Path $extract "templates.zip") -Force
  Expand-Archive (Join-Path $extract "templates.zip") -DestinationPath $extract -Force
  $src = Join-Path $extract "templates"
  if (-not (Test-Path (Join-Path $src "android_debug.apk"))) {
    $hit = Get-ChildItem $extract -Recurse -Filter "android_debug.apk" | Select-Object -First 1
    if (-not $hit) { throw "android_debug.apk not found after extract" }
    $src = $hit.Directory.FullName
  }
  Copy-Item (Join-Path $src "*") $TplDir -Force
  Set-Content (Join-Path $TplDir "version.txt") "4.7.1.stable"
  Write-Host "Templates installed: $TplDir"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "== Exporting APK =="
& $Godot --headless --path "$Root" --export-debug "Android" "$Apk"
if ($LASTEXITCODE -ne 0) {
  Write-Host "Export failed, exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}
if (Test-Path $Apk) {
  Write-Host ""
  Write-Host "SUCCESS APK:"
  Write-Host "  $Apk"
  Write-Host ("Size: {0:N1} MB" -f ((Get-Item $Apk).Length / 1MB))
} else {
  Write-Host "APK file not found."
  exit 1
}
