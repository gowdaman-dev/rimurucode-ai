#Requires -Version 5.1

param(
  [string]$version = "",
  [string]$binary = "",
  [switch]$noModifyPath = $false
)

$ErrorActionPreference = "Stop"
$MUTED = "`e[0;2m"
$RED = "`e[0;31m"
$ORANGE = "`e[38;5;214m"
$NC = "`e[0m"

$app = "rimuru"
$installDir = "$HOME\.rimuru\bin"
$null = New-Item -ItemType Directory -Force -Path $installDir

function Write-Message {
  param([string]$level, [string]$message)
  $color = switch ($level) {
    "error" { $RED }
    "warning" { $ORANGE }
    default { $NC }
  }
  Write-Host "$color$message$NC"
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
    Write-Message "info" "${MUTED}Fetching latest release...${NC}"
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
      Write-Message "info" "${MUTED}Available releases: https://github.com/$repo/releases${NC}"
      exit 1
    }
  }
  $url = "https://github.com/$repo/releases/download/v${specificVersion}/$filename"
}

# Check if already installed
$rimuruPath = Get-Command "rimuru" -ErrorAction SilentlyContinue
if ($rimuruPath) {
  $installedVersion = & rimuru --version 2>$null
  if ($installedVersion -eq $specificVersion) {
    Write-Message "info" "${MUTED}Version ${NC}$specificVersion${MUTED} already installed${NC}"
    exit 0
  }
  Write-Message "info" "${MUTED}Installed version: ${NC}$installedVersion"
}

function Install-Binary {
  $tmpDir = Join-Path $env:TEMP "rimuru_install_$PID"
  New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
  $zipPath = Join-Path $tmpDir $filename

  Write-Message "info" "${MUTED}Installing ${NC}rimuru ${MUTED}version: ${NC}$specificVersion"

  try {
    $downloadUrl = $url
    Write-Progress -Activity "Downloading rimuru" -Status "$target" -PercentComplete 0
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -PassThru
    Write-Progress -Activity "Downloading rimuru" -Completed
  } catch {
    Write-Message "error" "Failed to download binary from GitHub Releases."
    Write-Message "info" "${MUTED}The binary for your platform ($target) may not be available yet.${NC}"
    Write-Message "info" "${MUTED}Check https://github.com/$repo/releases for available assets${NC}"
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
  Move-Item -Path $exePath -Destination "$installDir\rimuru-ai.exe" -Force
  Remove-Item -Path $tmpDir -Recurse -Force
  Write-Message "info" "${MUTED}Installed rimuru to ${NC}$installDir"
}

if (-not [string]::IsNullOrEmpty($binary)) {
  Copy-Item -Path $binary -Destination "$installDir\rimuru-ai.exe" -Force
  Write-Message "info" "${MUTED}Installed rimuru from ${NC}$binary"
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
    Write-Message "info" "${MUTED}Added rimuru to PATH (user-level)${NC}"
  }
}

# Install configs
$configDir = "$HOME\.config\rimuru"
if (-not (Test-Path "$configDir\agents") -or -not (Get-ChildItem "$configDir\agents" -ErrorAction SilentlyContinue)) {
  Write-Message "info" "${MUTED}Downloading default configs...${NC}"
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
    Write-Message "info" "${MUTED}Configs installed to ${NC}$configDir"
  } catch {
    Write-Message "warning" "Could not download default configs. Run rimuru to create defaults."
  }
}

Write-Host ""
Write-Message "info" "${MUTED}                   ${NC}             ▄     "
Write-Message "info" "${MUTED}█▀▀█ █▀▀█ █▀▀█ █▀▀▄ ${NC}█▀▀▀ █▀▀█ █▀▀█ █▀▀█"
Write-Message "info" "${MUTED}█░░█ █░░█ █▀▀▀ █░░█ ${NC}█░░░ █░░█ █░░█ █▀▀▀"
Write-Message "info" "${MUTED}▀▀▀▀ █▀▀▀ ▀▀▀▀ ▀  ▀ ${NC}▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀"
Write-Host ""
Write-Host ""
Write-Message "info" "${MUTED}Rimuru AI includes free models, to start:${NC}"
Write-Host ""
Write-Message "info" "cd <project>  ${MUTED}# Open directory${NC}"
Write-Message "info" "rimuru        ${MUTED}# Run command${NC}"
Write-Host ""
Write-Message "info" "${MUTED}For more information visit ${NC}https://rimurucode.vercel.app"
