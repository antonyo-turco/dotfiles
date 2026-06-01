# tmpOrder.ps1
# Organizes files in the user's Documents\tmp directory into date-based archive folders.
# - Moves files older than today into archive-YYYY-MM-DD/ folders (preserving subfolder structure)
# - Compresses daily archives older than 7 days into weekly zips (ISO week, Mon-Sun)
# - Compresses weekly zips older than 30 days into monthly zips
# Idempotent: safe to run multiple times without side effects.
#
# Usage:
#   .\tmpOrder.ps1                          Run the organizer immediately
#   .\tmpOrder.ps1 -Register                Register a daily scheduled task (default 02:00)
#   .\tmpOrder.ps1 -Register -TriggerTime "06:30"   Register at a custom time
#   .\tmpOrder.ps1 -Unregister              Remove the scheduled task

param(
    [switch]$Register,
    [switch]$Unregister,
    [switch]$Run,
    [string]$TriggerTime = "02:00"
)

$TaskName = "tmpOrder-Daily"

# ------------------------------------------------------------------
# Scheduled Task: Register
# ------------------------------------------------------------------
if ($Register) {
    $scriptPath = $MyInvocation.MyCommand.Definition

    # Determine the PowerShell executable (prefer pwsh, fall back to powershell)
    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh).Source
    } else {
        (Get-Command powershell).Source
    }

    $action  = New-ScheduledTaskAction -Execute $psExe `
        -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""

    $trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 1)

    # Idempotent: remove existing task before re-registering
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "[INFO] Removed existing scheduled task '$TaskName'."
    }

    Register-ScheduledTask -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Runs tmpOrder.ps1 daily to organize Documents\tmp." `
        -RunLevel Limited | Out-Null

    Write-Host "[OK] Scheduled task '$TaskName' registered to run daily at $TriggerTime."
    Write-Host "     Script: $scriptPath"
    return
}

# ------------------------------------------------------------------
# Scheduled Task: Unregister
# ------------------------------------------------------------------
if ($Unregister) {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "[OK] Scheduled task '$TaskName' removed."
    } else {
        Write-Host "[INFO] Scheduled task '$TaskName' does not exist — nothing to remove."
    }
    return
}

# ==================================================================
# Main function (unchanged)
# ==================================================================

function Invoke-TmpOrder {
    [CmdletBinding()]
    param()

    $tmpDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "tmp"

    if (-not (Test-Path $tmpDir)) {
        Write-Host "[INFO] tmp directory does not exist: $tmpDir — nothing to do."
        return
    }

    Write-Host "=========================================="
    Write-Host " tmpOrder — Organizing $tmpDir"
    Write-Host "=========================================="

    $today = (Get-Date).Date

    # ------------------------------------------------------------------
    # Helper: Get ISO 8601 week number (Monday-Sunday) for a given date
    # ------------------------------------------------------------------
    function Get-ISOWeekInfo {
        param([Parameter(Mandatory)][datetime]$Date)

        $culture = [System.Globalization.CultureInfo]::new("en-US")
        $calendar = $culture.Calendar
        $calendarWeekRule = [System.Globalization.CalendarWeekRule]::FirstFourDayWeek
        $dayOfWeekStart = [System.DayOfWeek]::Monday
        $weekNumber = $calendar.GetWeekOfYear($Date, $calendarWeekRule, $dayOfWeekStart)

        $isoYear = $Date.Year
        if ($weekNumber -ge 52 -and $Date.Month -eq 1) { $isoYear = $Date.Year - 1 }
        elseif ($weekNumber -eq 1 -and $Date.Month -eq 12) { $isoYear = $Date.Year + 1 }

        return [PSCustomObject]@{
            Year       = $isoYear
            WeekNumber = $weekNumber
            WeekLabel  = "W{0:D2}" -f $weekNumber
        }
    }

    # ------------------------------------------------------------------
    # Helper: Get the Monday (start) of the ISO week for a given date
    # ------------------------------------------------------------------
    function Get-ISOWeekMonday {
        param([Parameter(Mandatory)][datetime]$Date)
        $dayOfWeek = [int]$Date.DayOfWeek
        $daysFromMonday = ($dayOfWeek + 6) % 7
        return $Date.Date.AddDays(-$daysFromMonday)
    }

    # ==================================================================
    # PHASE 1: Daily Archiving
    # ==================================================================
    Write-Host ""
    Write-Host "[PHASE 1] Daily archiving — moving old files into date-based folders..."

    $topLevelItems = Get-ChildItem -Path $tmpDir -Force | Where-Object {
        $_.Name -notmatch "^archive-"
    }

    $filesToProcess = @()
    foreach ($item in $topLevelItems) {
        if ($item.PSIsContainer) {
            $filesInSubfolder = Get-ChildItem -Path $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
            foreach ($file in $filesInSubfolder) { $filesToProcess += $file }
        } else {
            $filesToProcess += $item
        }
    }

    $movedCount = 0
    foreach ($file in $filesToProcess) {
        $lastWrite = $file.LastWriteTime.Date
        if ($lastWrite -ge $today) { continue }

        $archiveFolderName = "archive-{0:yyyy-MM-dd}" -f $lastWrite
        $archiveFolderPath = Join-Path $tmpDir $archiveFolderName
        $relativePath      = $file.FullName.Substring($tmpDir.Length).TrimStart('\', '/')
        $destinationPath   = Join-Path $archiveFolderPath $relativePath
        $destinationDir    = Split-Path $destinationPath -Parent

        if (-not (Test-Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        }
        if (Test-Path $destinationPath) {
            Write-Host "  [SKIP] Already archived: $relativePath"
            continue
        }
        try {
            Move-Item -Path $file.FullName -Destination $destinationPath -Force -ErrorAction Stop
            Write-Host "  [MOVE] $relativePath -> $archiveFolderName/$relativePath"
            $movedCount++
        } catch {
            Write-Host "  [ERROR] Failed to move $($file.FullName): $_" -ForegroundColor Red
        }
    }

    # Clean up empty subfolders
    $nonArchiveDirs = Get-ChildItem -Path $tmpDir -Directory -Force | Where-Object {
        $_.Name -notmatch "^archive-"
    }
    foreach ($dir in $nonArchiveDirs) {
        $subDirs = Get-ChildItem -Path $dir.FullName -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending
        foreach ($subDir in $subDirs) {
            $remaining = Get-ChildItem -Path $subDir.FullName -Force -ErrorAction SilentlyContinue
            if ($null -eq $remaining -or $remaining.Count -eq 0) {
                Remove-Item -Path $subDir.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  [CLEANUP] Removed empty subfolder: $($subDir.FullName.Substring($tmpDir.Length))"
            }
        }
        $remaining = Get-ChildItem -Path $dir.FullName -Force -ErrorAction SilentlyContinue
        if ($null -eq $remaining -or $remaining.Count -eq 0) {
            Remove-Item -Path $dir.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "  [CLEANUP] Removed empty folder: $($dir.Name)"
        }
    }

    Write-Host "[PHASE 1] Complete. Moved $movedCount file(s)."

    # ==================================================================
    # PHASE 2: Weekly Compression
    # ==================================================================
    Write-Host ""
    Write-Host "[PHASE 2] Weekly compression — zipping daily archives older than 7 days..."

    $cutoffWeekly = $today.AddDays(-7)
    $weeklyCompressedCount = 0

    $dailyArchives = Get-ChildItem -Path $tmpDir -Directory -Force | Where-Object {
        $_.Name -match "^archive-(\d{4}-\d{2}-\d{2})$"
    }

    $eligibleDailyArchives = @()
    foreach ($archive in $dailyArchives) {
        if ($archive.Name -match "^archive-(\d{4}-\d{2}-\d{2})$") {
            $archiveDate = [datetime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)
            if ($archiveDate -lt $cutoffWeekly) {
                $weekInfo = Get-ISOWeekInfo -Date $archiveDate
                $eligibleDailyArchives += [PSCustomObject]@{
                    Folder     = $archive
                    Date       = $archiveDate
                    ISOYear    = $weekInfo.Year
                    WeekNumber = $weekInfo.WeekNumber
                    WeekLabel  = $weekInfo.WeekLabel
                    GroupKey   = "{0}-{1}" -f $weekInfo.Year, $weekInfo.WeekLabel
                }
            }
        }
    }

    $weeklyGroups = $eligibleDailyArchives | Group-Object -Property GroupKey

    foreach ($group in $weeklyGroups) {
        $weekKey = $group.Name
        $zipName = "archive-week-$weekKey.zip"
        $zipPath = Join-Path $tmpDir $zipName
        $foldersInGroup = $group.Group | ForEach-Object { $_.Folder }

        if (Test-Path $zipPath) {
            foreach ($folderObj in $foldersInGroup) {
                if (Test-Path $folderObj.FullName) {
                    Write-Host "  [CLEANUP] Removing leftover daily folder $($folderObj.Name) (zip exists: $zipName)"
                    Remove-Item -Path $folderObj.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            Write-Host "  [SKIP] Weekly zip already exists: $zipName"
            continue
        }

        Write-Host "  [ZIP] Creating $zipName from $($foldersInGroup.Count) daily archive(s)..."
        $stagingDir = Join-Path $tmpDir "_staging_$weekKey"
        if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force }
        New-Item -Path $stagingDir -ItemType Directory -Force | Out-Null

        try {
            foreach ($folderObj in $foldersInGroup) {
                $destInStaging = Join-Path $stagingDir $folderObj.Name
                Copy-Item -Path $folderObj.FullName -Destination $destInStaging -Recurse -Force
                Write-Host "    [ADD] $($folderObj.Name)"
            }
            Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $zipPath -Force -ErrorAction Stop
            Write-Host "  [OK] Created $zipName"
            foreach ($folderObj in $foldersInGroup) {
                Remove-Item -Path $folderObj.FullName -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "    [DEL] Removed $($folderObj.Name)"
            }
            $weeklyCompressedCount++
        } catch {
            Write-Host "  [ERROR] Failed to create $zipName : $_" -ForegroundColor Red
        } finally {
            if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Write-Host "[PHASE 2] Complete. Created $weeklyCompressedCount weekly zip(s)."

    # ==================================================================
    # PHASE 3: Monthly Compression
    # ==================================================================
    Write-Host ""
    Write-Host "[PHASE 3] Monthly compression — zipping weekly archives older than 30 days..."

    $cutoffMonthly = $today.AddDays(-30)
    $monthlyCompressedCount = 0

    $weeklyZips = Get-ChildItem -Path $tmpDir -File -Force | Where-Object {
        $_.Name -match "^archive-week-(\d{4})-W(\d{2})\.zip$"
    }

    $eligibleWeeklyZips = @()
    foreach ($zip in $weeklyZips) {
        if ($zip.Name -match "^archive-week-(\d{4})-W(\d{2})\.zip$") {
            $isoYear = [int]$Matches[1]
            $isoWeek = [int]$Matches[2]
            $jan4 = [datetime]::new($isoYear, 1, 4)
            $jan4Monday = Get-ISOWeekMonday -Date $jan4
            $weekMonday = $jan4Monday.AddDays(($isoWeek - 1) * 7)

            if ($weekMonday -lt $cutoffMonthly) {
                $monthKey = "{0:yyyy-MM}" -f $weekMonday
                $eligibleWeeklyZips += [PSCustomObject]@{
                    File       = $zip
                    WeekMonday = $weekMonday
                    ISOYear    = $isoYear
                    ISOWeek    = $isoWeek
                    MonthKey   = $monthKey
                }
            }
        }
    }

    $monthlyGroups = $eligibleWeeklyZips | Group-Object -Property MonthKey

    foreach ($group in $monthlyGroups) {
        $monthKey     = $group.Name
        $monthZipName = "archive-month-$monthKey.zip"
        $monthZipPath = Join-Path $tmpDir $monthZipName
        $zipsInGroup  = $group.Group | ForEach-Object { $_.File }

        if (Test-Path $monthZipPath) {
            foreach ($zipFile in $zipsInGroup) {
                if (Test-Path $zipFile.FullName) {
                    Write-Host "  [CLEANUP] Removing leftover weekly zip $($zipFile.Name) (monthly zip exists: $monthZipName)"
                    Remove-Item -Path $zipFile.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            Write-Host "  [SKIP] Monthly zip already exists: $monthZipName"
            continue
        }

        Write-Host "  [ZIP] Creating $monthZipName from $($zipsInGroup.Count) weekly zip(s)..."
        $stagingDir = Join-Path $tmpDir "_staging_month_$monthKey"
        if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force }
        New-Item -Path $stagingDir -ItemType Directory -Force | Out-Null

        try {
            foreach ($zipFile in $zipsInGroup) {
                $destInStaging = Join-Path $stagingDir $zipFile.Name
                Copy-Item -Path $zipFile.FullName -Destination $destInStaging -Force
                Write-Host "    [ADD] $($zipFile.Name)"
            }
            Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $monthZipPath -Force -ErrorAction Stop
            Write-Host "  [OK] Created $monthZipName"
            foreach ($zipFile in $zipsInGroup) {
                Remove-Item -Path $zipFile.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "    [DEL] Removed $($zipFile.Name)"
            }
            $monthlyCompressedCount++
        } catch {
            Write-Host "  [ERROR] Failed to create $monthZipName : $_" -ForegroundColor Red
        } finally {
            if (Test-Path $stagingDir) { Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Write-Host "[PHASE 3] Complete. Created $monthlyCompressedCount monthly zip(s)."

    Write-Host ""
    Write-Host "=========================================="
    Write-Host " tmpOrder complete!"
    Write-Host "=========================================="
}

# ------------------------------------------------------------------
# Entry point: invoke the main function only when -Run is specified
# ------------------------------------------------------------------
if ($Run) {
    Invoke-TmpOrder
}