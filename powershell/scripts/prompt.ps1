function prompt {
  # 1. Check if running as Administrator for the "PS" color
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  $promptColor = if ($isAdmin) { "Red" } else { "Blue" }

  # 2. Get the truncated path (last 3 folders)
  $pathItems = $pwd.Path.Split([System.IO.Path]::DirectorySeparatorChar)
  $displayPath = ($pathItems | Select-Object -Last 3) -join '\'

  # 3. Get the Git branch name if inside a Git repository
  $gitBranchInfo = ""
  try {
    # This command gets the current branch name. '2>$null' suppresses errors.
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $branch) {
      $gitBranchInfo = " ($branch)"
    }
  }
  catch {
    # Handles cases where 'git' might not be installed.
  }

  # --- Assemble the prompt ---

  # Write the "PS" prefix
  Write-Host "PS " -NoNewline -ForegroundColor $promptColor

  # Write the truncated path
  Write-Host "$displayPath" -NoNewline

  # Write the Git branch info (if it exists) in orange
  if ($gitBranchInfo) {
    Write-Host $gitBranchInfo -NoNewline -ForegroundColor DarkYellow
  }

  # Write the final ">" symbol in white
  Write-Host "> " -NoNewline -ForegroundColor White

  # Return a single space to position the cursor correctly
  " "
}
