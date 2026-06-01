

# Context File Generator - PowerShell Script
# Generates a context file containing a directory tree and file contents.
# Optimized for speed and safety. Supports gitignore rules and extensive file type filtering.

function createContext {
    <#
    .SYNOPSIS
        Generates a context file with a tree and file contents. Optimized for speed and safety.
    #>
    param(
        [string]$Path = ".",
        [string[]]$Include = @(
            "java", "kt", "kts", "groovy", "gradle", "scala", "clj",
            "cs", "fs", "vb", "csx", "csproj", "fsproj", "vbproj", "sln", "razor", "cshtml",
            "html", "htm", "css", "scss", "sass", "less", "js", "jsx", "ts", "tsx",
            "vue", "svelte", "astro", "ejs", "hbs", "pug", "jade",
            "py", "pyw", "pyi", "pyx", "ipynb",
            "rb", "erb", "rake", "gemspec",
            "php", "blade.php", "twig",
            "go", "rs", "c", "h", "cpp", "hpp", "cc", "cxx", "hxx",
            "swift", "m", "mm",
            "sh", "bash", "zsh", "fish", "ps1", "psm1", "psd1", "bat", "cmd",
            "json", "jsonc", "json5", "xml", "yaml", "yml", "toml", "ini", "cfg",
            "conf", "env", "properties", "plist",
            "md", "mdx", "txt", "rst", "adoc", "tex", "latex", "org",
            "sql", "ddl", "dml", "plsql", "hql",
            "tf", "tfvars", "hcl", "dockerfile", "dockerignore",
            "vagrantfile", "jenkinsfile", "pipeline",
            "github", "gitlab-ci", "circleci", "travis",
            "makefile", "cmake", "gradle", "sbt", "pom", "build",
            "package", "lock", "gemfile", "rakefile",
            "editorconfig", "gitignore", "gitattributes", "gitmodules",
            "htaccess", "nginx", "prettierrc", "eslintrc", "babelrc",
            "stylelintrc", "tsconfig", "browserslistrc",
            "csv", "tsv", "log", "diff", "patch",
            "r", "rmd", "m", "jl",
            "pl", "pm", "lua", "ex", "exs", "erl", "hrl",
            "hs", "lhs", "ml", "mli", "el", "lisp", "scm", "rkt",
            "dart", "zig", "nim", "v",
            "proto", "graphql", "gql", "thrift",
            "tfstate", "ansible", "vim", "emacs", "nix", "dhall"
        ),
        [string]$Output,
        [ValidateSet("Quiet", "Verbose", "VeryVerbose")]
        [string]$Verbosity = "Quiet",
        [bool]$RespectGitIgnore = $true
    )

    # --- Setup ---
    $resolvedPath = (Resolve-Path $Path).Path
    $dirName = Split-Path -Leaf $resolvedPath
    if (-not $Output) {
        $tmpDir = Join-Path $env:USERPROFILE "Documents\tmp"
        if (-not (Test-Path $tmpDir)) { New-Item $tmpDir -ItemType Directory -Force | Out-Null }
        $Output = Join-Path $tmpDir "context_$dirName.txt"
    }

    $isVerbose = $Verbosity -match "Verbose"
    $includeSet = New-Object System.Collections.Generic.HashSet[string] ([string[]]($Include | ForEach-Object { ".$($_.TrimStart('.'))" }), [System.StringComparer]::OrdinalIgnoreCase)
    $ignoreRules = New-Object System.Collections.Generic.List[object]

    # --- Helper: Convert Pattern ---
    function Convert-GitignoreToRegex {
        param([string]$Pattern, [string]$BasePath)
        
        $isNegation = $Pattern.StartsWith("!")
        if ($isNegation) { $Pattern = $Pattern.Substring(1) }
        
        $isDirOnly = $Pattern.EndsWith("/")
        if ($isDirOnly) { $Pattern = $Pattern.TrimEnd("/") }

        $isAnchored = ($Pattern.StartsWith("/") -or $Pattern.Contains("/"))
        if ($Pattern.StartsWith("/")) { $Pattern = $Pattern.Substring(1) }

        $escaped = [regex]::Escape($Pattern).Replace('\\\*', '.*').Replace('\\\?', '.')
        $prefix = ""
        if ($BasePath) { $prefix = [regex]::Escape($BasePath.Replace("\", "/")) + "/" }
        
        $regexStr = ""
        if ($isAnchored) { 
            $regexStr = "^" + $prefix + $escaped + "(/.*)?$" 
        } else { 
            $regexStr = "^" + $prefix + "(.+/)??" + $escaped + "(/.*)?$" 
        }

        return @{ Regex = $regexStr; Negate = $isNegation; DirOnly = $isDirOnly }
    }

    # --- Parse Gitignores ---
    if ($RespectGitIgnore) {
        $giFiles = [System.IO.Directory]::GetFiles($resolvedPath, ".gitignore", [System.IO.SearchOption]::AllDirectories)
        foreach ($gi in $giFiles) {
            $relBase = $gi.Replace($resolvedPath, "").TrimStart('\').Replace("\", "/")
            $relBase = Split-Path $relBase -Parent
            if ($relBase -eq ".") { $relBase = "" }

            $content = Get-Content $gi
            foreach ($line in $content) {
                $trimmed = $line.Trim()
                if ($trimmed -and -not $trimmed.StartsWith("#")) {
                    $res = Convert-GitignoreToRegex -Pattern $trimmed -BasePath $relBase
                    $opt = [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                    $ignoreRules.Add([PSCustomObject]@{
                        Regex = New-Object System.Text.RegularExpressions.Regex($res.Regex, $opt)
                        Negate = $res.Negate
                        DirOnly = $res.DirOnly
                    })
                }
            }
        }
    }

    # --- Tree & Content Collector ---
    $treeBuilder = New-Object System.Text.StringBuilder
    $fileList = New-Object System.Collections.Generic.List[string]
    [void]$treeBuilder.AppendLine("================== DIRECTORY TREE ==================")
    [void]$treeBuilder.AppendLine($dirName)

    function Walk-Dir {
        param($CurrPath, $Prefix, $RelPath)
        
        $items = Get-ChildItem -Path $CurrPath -Force | Sort-Object { -not $_.PSIsContainer }, Name
        
        foreach ($item in $items) {
            $itemRel = $item.Name
            if ($RelPath) { $itemRel = "$RelPath/$($item.Name)" }
            
            if ($item.Name -eq ".git") { continue }
            
            $ignored = $false
            foreach ($rule in $ignoreRules) {
                if ($rule.DirOnly -and -not $item.PSIsContainer) { continue }
                if ($itemRel -match $rule.Regex) { $ignored = -not $rule.Negate }
            }
            if ($RespectGitIgnore -and $ignored) { continue }

            $isLast = ($item -eq $items[-1])
            $connector = "├── "
            if ($isLast) { $connector = "└── " }
            
            [void]$treeBuilder.AppendLine("$Prefix$connector$($item.Name)")

            if ($item.PSIsContainer) {
                $indent = "│   "
                if ($isLast) { $indent = "    " }
                $newPrefix = $Prefix + $indent
                Walk-Dir -CurrPath $item.FullName -Prefix $newPrefix -RelPath $itemRel
            } elseif ($includeSet.Contains($item.Extension)) {
                $fileList.Add($item.FullName)
            }
        }
    }

    Write-Progress -Activity "Building context" -Status "Scanning directory tree..." -PercentComplete 0
    Walk-Dir -CurrPath $resolvedPath -Prefix "" -RelPath ""
    [void]$treeBuilder.AppendLine("====================================================")
    
    # --- Final Output ---
    Write-Progress -Activity "Building context" -Status "Writing tree..." -PercentComplete 5
    $treeBuilder.ToString() | Out-File $Output -Encoding UTF8

    $total = $fileList.Count
    for ($i = 0; $i -lt $total; $i++) {
        $f = $fileList[$i]
        $pct = [math]::Round(5 + (($i + 1) / $total) * 95)
        $shortName = Split-Path -Leaf $f

        Write-Progress -Activity "Building context" -Status "[$($i+1)/$total] $shortName" -PercentComplete $pct

        if ($isVerbose) { Write-Host "Adding: $f" -ForegroundColor Cyan }

        "`n--- $f ---" | Out-File $Output -Encoding UTF8 -Append
        Get-Content $f | Out-File $Output -Encoding UTF8 -Append
    }

    Write-Progress -Activity "Building context" -Completed
    Write-Host "Context written to $Output (Files: $($fileList.Count))" -ForegroundColor Green
}