function Get-TokenCount {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    $absPath = (Resolve-Path $FilePath).Path
    $escapedPath = $absPath.Replace('\', '\\')

    python -c @"
import sys
try:
    import tiktoken
except ImportError:
    print('ERROR: tiktoken not installed. Run: pip install tiktoken')
    sys.exit(1)

enc = tiktoken.get_encoding('cl100k_base')
with open('$escapedPath', encoding='utf-8') as f:
    text = f.read()
tokens = enc.encode(text)
print(f'File: $escapedPath')
print(f'Tokens: {len(tokens)}')
print(f'Words (approx): {len(text.split())}')
print(f'Characters: {len(text)}')
"@
}