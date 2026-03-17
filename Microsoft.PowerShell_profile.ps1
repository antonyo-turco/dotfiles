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

function createContext {
 param(
  [string]$Path = ".",
  [string[]]$Include = @(
   # Java / JVM
   "java", "kt", "kts", "groovy", "gradle", "scala", "clj",
   # .NET
   "cs", "fs", "vb", "csx", "csproj", "fsproj", "vbproj", "sln", "razor", "cshtml",
   # Web
   "html", "htm", "css", "scss", "sass", "less", "js", "jsx", "ts", "tsx",
   "vue", "svelte", "astro", "ejs", "hbs", "pug", "jade",
   # Python
   "py", "pyw", "pyi", "pyx", "ipynb",
   # Ruby
   "rb", "erb", "rake", "gemspec",
   # PHP
   "php", "blade.php", "twig",
   # Go / Rust / C / C++
   "go", "rs", "c", "h", "cpp", "hpp", "cc", "cxx", "hxx",
   # Swift / Objective-C
   "swift", "m", "mm",
   # Shell / Scripting
   "sh", "bash", "zsh", "fish", "ps1", "psm1", "psd1", "bat", "cmd",
   # Config / Data
   "json", "jsonc", "json5", "xml", "yaml", "yml", "toml", "ini", "cfg",
   "conf", "env", "properties", "plist",
   # Markup / Docs
   "md", "mdx", "txt", "rst", "adoc", "tex", "latex", "org",
   # SQL / DB
   "sql", "ddl", "dml", "plsql", "hql",
   # DevOps / IaC
   "tf", "tfvars", "hcl", "dockerfile", "dockerignore",
   "vagrantfile", "jenkinsfile", "pipeline",
   # CI/CD
   "github", "gitlab-ci", "circleci", "travis",
   # Build / Package
   "makefile", "cmake", "gradle", "sbt", "pom", "build",
   "package", "lock", "gemfile", "rakefile",
   # Misc Config
   "editorconfig", "gitignore", "gitattributes", "gitmodules",
   "htaccess", "nginx", "prettierrc", "eslintrc", "babelrc",
   "stylelintrc", "tsconfig", "browserslistrc",
   # Data / Log
   "csv", "tsv", "log", "diff", "patch",
   # R / MATLAB / Julia
   "r", "rmd", "m", "jl",
   # Perl / Lua / Elixir / Erlang
   "pl", "pm", "lua", "ex", "exs", "erl", "hrl",
   # Haskell / OCaml / Lisp
   "hs", "lhs", "ml", "mli", "el", "lisp", "scm", "rkt",
   # Dart / Flutter
   "dart",
   # Zig / Nim / V
   "zig", "nim", "v",
   # Protobuf / GraphQL / Thrift
   "proto", "graphql", "gql", "thrift",
   # Terraform / Ansible
   "tf", "tfstate", "ansible",
   # Misc
   "vim", "emacs", "nix", "dhall"
  ),
  [string]$Output
 )

 $resolvedPath = Resolve-Path $Path
 $dirName = Split-Path -Leaf $resolvedPath

 if (-not $Output) {
  $tmpDir = Join-Path "$env:USERPROFILE\Documents\tmp"
  if (-not (Test-Path $tmpDir)) { New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null }
  $Output = Join-Path $tmpDir "context_$dirName.txt"
 }

 $patterns = $Include | ForEach-Object { "*.$_" }

 Get-ChildItem -Path "$resolvedPath\*" -Recurse -Include $patterns |
  ForEach-Object { "--- $($_.FullName) ---"; Get-Content $_ } |
  Out-File -Path $Output -Encoding UTF8

 Write-Host "Context written to $Output" -ForegroundColor Green
}


function ll { Get-ChildItem -Force -LiteralPath . | Format-List }
Set-Alias -Name ll -Value ll
