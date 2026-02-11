function prompt {
  # Number of folders to display from the end of the path
  $folderCount = 3

  # Split the path and select the last 3 parts
  $pathItems = $pwd.Path.Split([System.IO.Path]::DirectorySeparatorChar)
  $displayPath = ($pathItems | Select-Object -Last $folderCount) -join '\'

  # Write the "PS" part of the prompt in blue
  Write-Host "PS " -NoNewline -ForegroundColor Blue

  # Return the path and the closing ">"
  "$($displayPath)> "
}
