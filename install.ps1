#Requires -Version 5.1

param(
  [string]$version = "",
  [string]$binary = "",
  [switch]$noModifyPath = $false
)

$ErrorActionPreference = "Stop"

$app = "rimuru"
$installDir = "$HOME\.rimuru\bin"
$null = New-Item -ItemType Directory -Force -Path $installDir

function Write-Message {
  param([string]$level, [string]$message)
  switch ($level) {
    "error"   { Write-Host $message -ForegroundColor Red }
    "warning" { Write-Host $message -ForegroundColor DarkYellow }
    "muted"   { Write-Host $message -ForegroundColor DarkGray }
    default   { Write-Host $message -ForegroundColor DarkGray }
  }
}

function Get-Arch {
  $arch = (Get-WmiObject Win32_Processor | Select-Object -First 1).AddressWidth
  $procArch = (Get-WmiObject Win32_Processor | Select-Object -First 1).Architecture
  $isArm = $procArch -eq 5 -or $procArch -eq 12
  if ($isArm) { return "arm64" }
  return "x64"
}

function Get-Avx2Support {
  try {
    $kernel32 = Add-Type -MemberDefinition @"
[DllImport("kernel32.dll")]
public static extern bool IsProcessorFeaturePresent(int ProcessorFeature);
"@ -Name "Kernel32" -Namespace "Win32" -PassThru
    $result = $kernel32::IsProcessorFeaturePresent(40)
    return $result
  } catch {
    return $false
  }
}

$arch = Get-Arch
$needsBaseline = -not (Get-Avx2Support)
$target = "windows-$arch"
if ($needsBaseline) {
  $target = "$target-baseline"
}
$filename = "$app-$target.zip"
$repo = "gowdaman-dev/rimurucode-ai"

if (-not [string]::IsNullOrEmpty($binary)) {
  if (-not (Test-Path $binary)) {
    Write-Message "error" "Binary not found at $binary"
    exit 1
  }
  $specificVersion = "local"
  $url = ""
} else {
  if ([string]::IsNullOrEmpty($version)) {
    $releaseUrl = "https://api.github.com/repos/$repo/releases/latest"
    Write-Message "info" "Fetching latest release..."
    try {
      $response = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
      $specificVersion = $response.tag_name -replace "^v", ""
    } catch {
      Write-Message "error" "Failed to fetch version information"
      exit 1
    }
  } else {
    $specificVersion = $version -replace "^v", ""
    $tagUrl = "https://api.github.com/repos/$repo/releases/tags/v$specificVersion"
    $httpStatus = try { (Invoke-WebRequest -Uri $tagUrl -UseBasicParsing -Method Head).StatusCode } catch { 404 }
    if ($httpStatus -eq 404) {
      Write-Message "error" "Release v${specificVersion} not found"
      Write-Message "info" "Available releases: https://github.com/$repo/releases"
      exit 1
    }
  }
  $url = "https://github.com/$repo/releases/download/v${specificVersion}/$filename"
}

# Check if already installed
$rimuruPath = Get-Command "rimuru" -ErrorAction SilentlyContinue
if (-not $rimuruPath) {
    $rimuruPath = Get-Command "rimuru.exe" -ErrorAction SilentlyContinue
}
if ($rimuruPath) {
  $installedVersion = & rimuru --version 2>$null
  if ($installedVersion -eq $specificVersion) {
    Write-Host "Version $specificVersion already installed"
    exit 0
  }
  Write-Message "info" "Installed version: $installedVersion"
}

function Install-Binary {
  $tmpDir = Join-Path $env:TEMP "rimuru_install_$PID"
  New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
  $zipPath = Join-Path $tmpDir $filename

  Write-Host "Installing rimuru version: $specificVersion"

  try {
    $downloadUrl = $url
    Write-Progress -Activity "Downloading rimuru" -Status "$target" -PercentComplete 0
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -PassThru
    Write-Progress -Activity "Downloading rimuru" -Completed
  } catch {
    Write-Message "error" "Failed to download binary from GitHub Releases."
    Write-Message "muted" "The binary for your platform ($target) may not be available yet."
    Write-Message "muted" "Check https://github.com/$repo/releases for available assets"
    exit 1
  }

  Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force
  $exePath = Join-Path $tmpDir "rimuru-ai.exe"
  if (-not (Test-Path $exePath)) {
    $exePath = Join-Path $tmpDir "rimuru-ai"
  }
  if (-not (Test-Path $exePath)) {
    $exePath = Get-ChildItem -Path $tmpDir -Recurse -Filter "rimuru*" | Select-Object -First 1 -ExpandProperty FullName
  }
  # Stop any running rimuru process to avoid file lock
  Get-Process "rimuru" -ErrorAction SilentlyContinue | Stop-Process -Force
  Copy-Item -Path $exePath -Destination "$installDir\rimuru.exe" -Force
  Remove-Item -Path $tmpDir -Recurse -Force
  Write-Host "Installed rimuru to: $installDir"
}

if (-not [string]::IsNullOrEmpty($binary)) {
  Copy-Item -Path $binary -Destination "$installDir\rimuru.exe" -Force
  Write-Host "Installed rimuru from: $binary"
} else {
  Install-Binary
}

# Add to PATH
if (-not $noModifyPath) {
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  if ($userPath -notlike "*$installDir*") {
    $newPath = "$installDir;$userPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$installDir;$env:PATH"
    Write-Message "muted" "Added rimuru to PATH (user-level)"
    Write-Message "warning" "Restart your terminal or run:"
    Write-Host "  `$env:PATH = `"$installDir;`$env:PATH`""
  }
}

# Install configs
$configDir = "$HOME\.config\rimuru"
if (-not (Test-Path "$configDir\agents") -or -not (Get-ChildItem "$configDir\agents" -ErrorAction SilentlyContinue)) {
  Write-Host "Downloading default configs..."
  $configUrl = "https://raw.githubusercontent.com/$repo/main/rimuru-configs.tar.gz"
  $tmpDir = Join-Path $env:TEMP "rimuru_config_$PID"
  New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
  $tarPath = Join-Path $tmpDir "rimuru-configs.tar.gz"
  try {
    Invoke-WebRequest -Uri $configUrl -OutFile $tarPath -UseBasicParsing
    if (Get-Command "tar" -ErrorAction SilentlyContinue) {
      tar -xzf $tarPath -C $tmpDir 2>$null
      if (Test-Path "$tmpDir\.rimuru") {
        Copy-Item -Path "$tmpDir\.rimuru\*" -Destination $configDir -Recurse -Force
      }
    }
    Remove-Item -Path $tmpDir -Recurse -Force
    Write-Host "Configs installed to: $configDir"
  } catch {
    Write-Message "warning" "Could not download default configs. Run rimuru to create defaults."
  }
}

Write-Host ""
Write-Host "  ██████╗ ██╗███╗   ███╗██╗   ██╗██████╗ ██╗   ██╗" -ForegroundColor DarkGray
Write-Host "  ██╔══██╗██║████╗ ████║██║   ██║██╔══██╗██║   ██║" -ForegroundColor DarkGray
Write-Host "  ██████╔╝██║██╔████╔██║██║   ██║██████╔╝██║   ██║" -ForegroundColor DarkGray
Write-Host "  ██╔══██╗██║██║╚██╔╝██║██║   ██║██╔══██╗██║   ██║" -ForegroundColor DarkGray
Write-Host "  ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██║  ██║╚██████╔╝" -ForegroundColor DarkGray
Write-Host "  ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ " -ForegroundColor DarkGray
Write-Host ""
Write-Host "Rimuru AI includes free models, to start:" -ForegroundColor DarkGray
Write-Host ""
Write-Host "cd <project>  # Open directory"
Write-Host "rimuru        # Run command"
Write-Host ""
Write-Host "For more information visit https://rimurucode.vercel.app" -ForegroundColor DarkGray
