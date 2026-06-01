function Transcribe-Video
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputFile,

        [int]$Threads = 10
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    # 1. Setup Paths
    $BaseDir = "C:\USERS\ANT.TURCO\DOCUMENTS\TOOLS\WHISPER-BIN-X64\RELEASE"
    $ModelsDir = "$BaseDir\models"

    if (-not (Test-Path $InputFile)) { Write-Error "Input file not found!"; return }

    $InputFilePath = (Resolve-Path $InputFile).Path
    $InputFolder = Split-Path $InputFilePath
    $FileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($InputFilePath)
    $TempWav = Join-Path $InputFolder "$($FileNameNoExt)_temp.wav"

    # 2. Get Video Duration
    Write-Host "Analyzing video duration..." -ForegroundColor Gray
    $DurationRaw = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$InputFilePath"
    $TotalSeconds = [double]$DurationRaw
    if ($TotalSeconds -le 0) { Write-Error "Could not determine video length."; return }

    # 3. Model Selection
    $ModelFiles = Get-ChildItem -Path $ModelsDir -Filter "*.bin" -Recurse | Where-Object {
        $_.Name -notlike "*encoder*" -and $_.Name -notlike "*openvino*"
    }

    Write-Host "`n--- Available Models ---" -ForegroundColor Cyan
    for ($i = 0; $i -lt $ModelFiles.Count; $i++) {
        $RelativePath = $ModelFiles[$i].FullName.Replace($ModelsDir + "\", "")
        Write-Host "[$i] $RelativePath"
    }

    $choice = Read-Host "`nSelect model index"
    $SelectedModel = $ModelFiles[[int]$choice].FullName

    # 4. Extract Audio
    Write-Host "`n[1/2] Extracting Audio..." -ForegroundColor Cyan
    ffmpeg -i "$InputFilePath" -ar 16000 -ac 1 -c:a pcm_s16le "$TempWav" -y -loglevel error

    # 5. Transcribe with Live Progress
    Write-Host "[2/2] Transcribing (Italian)..." -ForegroundColor Green

    $EncoderXML = $SelectedModel.Replace(".bin", "-encoder-openvino.xml")
    $WhisperArgs = @("-m", "$SelectedModel", "-f", "$TempWav", "-t", "$Threads", "-l", "it", "-otxt", "-of", "$($InputFolder)\$($FileNameNoExt)_transcript")

    if (Test-Path $EncoderXML) {
        Write-Host "OpenVINO GPU acceleration active." -ForegroundColor Cyan
        $WhisperArgs += @("-oved", "GPU")
    }

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Execute Whisper and catch BOTH standard output and errors
    & "$BaseDir\whisper-cli.exe" @WhisperArgs 2>&1 | ForEach-Object {
        $line = $_.ToString()

        # Display the line so you can see the text and any errors
        Write-Host $line

        # Look for timestamps like [00:00:10.000 --> 00:00:15.000]
        if ($line -match '(\d{2}:\d{2}:\d{2})') {
            $CurrentTimeStr = $Matches[1]
            try {
                $CurrentSeconds = ([timespan]$CurrentTimeStr).TotalSeconds
                $Percent = [math]::Min(100, [math]::Round(($CurrentSeconds / $TotalSeconds) * 100))
                $Elapsed = $Stopwatch.Elapsed

                if ($Percent -gt 0) {
                    $TotalEst = ($Elapsed.TotalSeconds / $Percent) * 100
                    $Remaining = [timespan]::FromSeconds($TotalEst - $Elapsed.TotalSeconds)

                    Write-Progress -Activity "Transcribing: $FileNameNoExt" `
                        -Status "Progress: $Percent% | Remaining: $($Remaining.ToString('hh\:mm\:ss'))" `
                        -PercentComplete $Percent
                }
            } catch { }
        }
    }

    $Stopwatch.Stop()

    # 6. Cleanup
    if (Test-Path $TempWav) { Remove-Item "$TempWav" }

    Write-Host "`nTranscription Finished." -ForegroundColor Yellow
    Write-Host "Total Time: $($Stopwatch.Elapsed.ToString('mm\:ss'))"
}
