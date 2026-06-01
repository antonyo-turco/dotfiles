function Fetch-Ignore {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Language
    )

    $lang = $Language.Substring(0, 1).ToUpper() + $Language.Substring(1)
    $url  = "https://raw.githubusercontent.com/github/gitignore/main/$lang.gitignore"

    try {
        $content = Invoke-RestMethod -Uri $url -ErrorAction Stop
    } catch {
        Write-Error "No gitignore template found for '$lang' — check https://github.com/github/gitignore for valid names"
        return
    }

    $header = "`n# ==============================`n# $lang`n# =============================="
    $header | Add-Content .gitignore -Encoding UTF8
    $content | Add-Content .gitignore -Encoding UTF8
    Write-Host "Added $lang rules to .gitignore" -ForegroundColor Green
}
