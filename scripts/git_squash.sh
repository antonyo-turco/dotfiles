#!/bin/bash

# Check if a valid number is provided
origCount=$1
if ! [[ "$origCount" =~ ^[0-9]+$ ]] || [[ "$origCount" -lt 1 ]]; then
    echo "Error: Argument must be a number greater than 0"
    exit 1
fi

# Get commit hashes in chronological order
readarray -t commitHashes < <(git log -n "$origCount" --reverse --pretty=format:"%H")

totalCount=0
result=""
tab=$'\t'

# Process each commit
for hash in "${commitHashes[@]}"; do
    subject=$(git log -1 --pretty=format:"%s" "$hash")
    body=$(git log -1 --pretty=format:"%b" "$hash")

    if [[ "$subject" =~ ^Squashed[[:space:]]+([0-9]+)[[:space:]]+commits ]]; then
        # Parse squashed commit's body
        while IFS= read -r line; do
            if [[ "$line" =~ ^[0-9]+\)[[:space:]]+(.*) ]]; then
                # New entry
                totalCount=$((totalCount + 1))
                result+="${totalCount}) ${BASH_REMATCH[1]}\n"
            elif [[ "$line" =~ ^${tab}(.*) ]]; then
                # Body line
                result+="${tab}${BASH_REMATCH[1]}\n"
            fi
        done <<< "$body"
    else
        # Regular commit
        totalCount=$((totalCount + 1))
        result+="${totalCount}) ${subject}\n"
        if [[ -n "$body" ]]; then
            while IFS= read -r line; do
                result+="${tab}${line}\n"
            done <<< "$body"
        fi
    fi
done

# Create commit message
finalMessage="Squashed ${totalCount} commits\n\n${result}"
msgFile=$(mktemp)
echo -e "$finalMessage" > "$msgFile"

# Perform squash
git reset --soft HEAD~"$origCount" && git commit --edit --file "$msgFile"
rm "$msgFile"
