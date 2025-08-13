# === Config ===
$requiredUnityVersion = "6000.0.44f1"
# Optional: manual override for Unity Editor path
$UNITY_PATH_OVERRIDE = "C:\Program Files\Unity\Hub\Editor\6000.0.44f1\Editor\Unity.exe"

# Get project root (Unity project root)
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Backend directory
$backendDir = Join-Path $projectRoot "InterviewAPI"

# === Determine Unity Editor Path ===
if ($UNITY_PATH_OVERRIDE -and (Test-Path $UNITY_PATH_OVERRIDE)) {
    $unityExe = $UNITY_PATH_OVERRIDE
    Write-Host "Using manual Unity path: $unityExe"
} else {
    $possiblePaths = @(
        "$env:APPDATA\UnityHub\editors.json",
        "$env:LOCALAPPDATA\UnityHub\editors.json",
        "$env:ProgramData\UnityHub\editors.json",
        "$env:UserProfile\AppData\Roaming\UnityHub\editors.json"
    )

    $hubConfig = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $hubConfig) {
        Write-Error "Unity Hub editors.json not found in any known location. Please install Unity Hub and the required Unity version, or set \$UNITY_PATH_OVERRIDE."
        exit 1
    }

    $editors = Get-Content $hubConfig | ConvertFrom-Json

    if (-not $editors.PSObject.Properties.Name.Contains($requiredUnityVersion)) {
        Write-Error "Required Unity version $requiredUnityVersion is not installed via Unity Hub."
        exit 1
    }

    $unityInstallPath = $editors.$requiredUnityVersion
    $unityExe = Join-Path $unityInstallPath "Editor\Unity.exe"

    if (-not (Test-Path $unityExe)) {
        Write-Error "Unity.exe not found for version $requiredUnityVersion at $unityExe"
        exit 1
    }

    Write-Host "Found Unity version $requiredUnityVersion at $unityExe"
}

# === Build Backend ===
Write-Host "=== Building Backend API ==="
cd $backendDir
dotnet build

# === Run Backend in new terminal ===
Write-Host "=== Starting Backend API ==="
Start-Process powershell -ArgumentList "cd `"$backendDir`"; dotnet run"

# Wait for backend to start
Start-Sleep -Seconds 5

# === Start Unity Editor ===
Write-Host "=== Starting Unity Editor v$requiredUnityVersion ==="
Start-Process $unityExe -ArgumentList "-projectPath `"$projectRoot`""
