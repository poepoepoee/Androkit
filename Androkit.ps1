# AndroKit v0.1 PowerShell Prototype

# Check if ADB is installed
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "ADB not found. Please install ADB and add it to PATH." -ForegroundColor Red
    exit
}

# Detect connected devices
$devices = adb devices | Select-String -Pattern "device$" | ForEach-Object { ($_ -split "`t")[0] }

if ($devices.Count -eq 0) {
    Write-Host "No devices detected. Connect your Android device with USB debugging enabled." -ForegroundColor Red
    exit
}

$device = $devices[0]
Write-Host "Connected device: $device" -ForegroundColor Green

function Show-Menu {
    Clear-Host
    Write-Host "AndroKit v0.1"
    Write-Host "[1] List settings (system/secure/global)"
    Write-Host "[2] Edit settings (non-root)"
    Write-Host "[3] Optional root access for extra tables"
    Write-Host "[4] Export settings to CSV"
    Write-Host "[0] Exit"
    $choice = Read-Host "Select an option"
    return $choice
}

function List-Settings {
    $namespaces = @("system","secure","global")
    foreach ($ns in $namespaces) {
        Write-Host "`n--- $ns settings ---`n"
        adb shell settings list $ns
    }
    Read-Host "`nPress Enter to return to menu..."
}

function Edit-Settings {
    $ns = Read-Host "Enter namespace (system/secure/global)"
    $key = Read-Host "Enter key"
    $value = Read-Host "Enter new value"
    adb shell settings put $ns $key $value
    Write-Host "Updated $key in $ns"
    Read-Host "`nPress Enter to return to menu..."
}

function Optional-Root {
    Write-Host "Checking for root..."
    $rootCheck = adb shell su -c "echo rooted"
    if ($rootCheck -match "rooted") {
        Write-Host "Root detected! You can access extra tables." -ForegroundColor Green
        # Example: list all settings tables
        adb shell su -c "sqlite3 /data/data/com.android.providers.settings/databases/settings.db 'SELECT name FROM sqlite_master WHERE type=\"table\";'"
    } else {
        Write-Host "Root not available." -ForegroundColor Yellow
    }
    Read-Host "`nPress Enter to return to menu..."
}

function Export-Settings {
    $outfile = Read-Host "Enter CSV filename (example: settings.csv)"
    $csvContent = ""
    $namespaces = @("system","secure","global")
    foreach ($ns in $namespaces) {
        $lines = adb shell settings list $ns
        foreach ($line in $lines) {
            $split = $line -split "="
            if ($split.Count -eq 2) {
                $csvContent += "$ns,$($split[0]),$($split[1])`n"
            }
        }
    }
    $csvContent | Out-File $outfile
    Write-Host "Settings exported to $outfile"
    Read-Host "`nPress Enter to return to menu..."
}

# Main loop
do {
    $choice = Show-Menu
    switch ($choice) {
        "1" { List-Settings }
        "2" { Edit-Settings }
        "3" { Optional-Root }
        "4" { Export-Settings }
        "0" { Write-Host "Exiting..." }
        default { Write-Host "Invalid choice" }
    }
} while ($choice -ne "0")
