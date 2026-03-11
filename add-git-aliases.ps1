# Function to add alias safely
function Add-GitAlias {
    param(
        [string]$Name,
        [string]$Value
    )
    
    # Escape double quotes in the value
    $escapedValue = $Value -replace '"', '\"'
    
    # Add the alias to git config
    git config --global alias.$Name $escapedValue
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Added alias: $Name" -ForegroundColor Green
    } else {
        Write-Host "Failed to add alias: $Name" -ForegroundColor Red
    }
}

# Add each alias
Add-GitAlias -Name "alias" -Value '!git config --get-regexp alias | sed -re ''s/alias\\.(\\S*)\\s(.*)$/\\1 = \\2/g'''
Add-GitAlias -Name "blog" -Value "log --graph --decorate --abbrev-commit"
Add-GitAlias -Name "bbranch" -Value "branch -vv"
Add-GitAlias -Name "reboot" -Value '!git reset --hard HEAD | git clean -f | echo "Rebooted to last commit, changes uncommitted or untracked have been lost to the sands of time."'
Add-GitAlias -Name "ignore" -Value '!"f() { echo $1 >> \"${GIT_PREFIX}.gitignore\"; }; f"'
Add-GitAlias -Name "fetch-ignore" -Value '!sh /mnt/c/Users/anton/Documents/dotfiles/scripts/fetch_ignore.sh'
Add-GitAlias -Name "sad" -Value '!"f() { git add \"$@\" && git status -s; }; f"'
Add-GitAlias -Name "last" -Value '!"f() { count=${1:-2}; git log -\"$count\" HEAD --stat; }; f"'
Add-GitAlias -Name "squash" -Value '!"f() { \
    n=$1; \
    if [ -z \"$n\" ]; then echo \"Usage: git squash <number_of_commits>\"; return 1; fi; \
    msg=$(git log --format=\"- %s%n%w(0,5,5)%b\" -n $n | sed \"/^$/d\"); \
    git reset --soft HEAD~$n && \
    git commit -m \"Squashed $n commits\" -m \"$msg\"; \
}; f"'
Add-GitAlias -Name "search" -Value "!git rev-list --all | xargs git grep -F"
Add-GitAlias -Name "unstage" -Value '!"f() { git restore --staged \"$@\"; git status -s; }; f"'
Add-GitAlias -Name "bdiff" -Value '!"f() { git diff --color \"$@\" | less -R; }; f"'
Add-GitAlias -Name "branch-rename" -Value '!"f() {\n    if [ \"$#\" -ne 2 ]; then\n        echo \"Usage: git branch-rename OLD_BRANCH NEW_BRANCH\";\n        return 1;\n    fi;\n    OLD=\"$1\";\n    NEW=\"$2\";\n    # Rename local branch\n    git branch -m \"$OLD\" \"$NEW\";\n    # Rename remote branch (if it exists)\n    if git ls-remote --exit-code --heads origin \"$OLD\" >/dev/null 2>&1; then\n        git push origin --delete \"$OLD\";\n        git push origin \"$NEW\";\n        git push origin -u \"$NEW\";\n        # Reset upstream if it was tracking the old branch\n        if [ \"$(git rev-parse --abbrev-ref \"$NEW\"@{upstream} 2>/dev/null)\" = \"origin/$OLD\" ]; then\n            git branch --unset-upstream \"$NEW\";\n            git branch --set-upstream-to=origin/\"$NEW\" \"$NEW\";\n        fi;\n    else\n        echo \"No remote branch origin/ found (only local branch was renamed)\";\n    fi;\n}; f"'
Add-GitAlias -Name "s" -Value "status -sb"

Write-Host "`nAll aliases added!" -ForegroundColor Yellow
Write-Host "To verify, run: git alias" -ForegroundColor Cyan
