#!/usr/bin/env bash

# Function to check if a dotfile is already symlinked in the home directory
dotfile_exists() {
    local dotfile="$1"
    [ -e "$HOME/$dotfile" ] && [ -L "$HOME/$dotfile" ]
}

# Array of dotfiles
dotfiles=($(find /mnt/c/Users/anton/Documents/dotfiles -maxdepth 1 -type f | grep '/\.'))
echo $dotfiles
# Function to create symbolic link for a dotfile
create_dotfile_link() {
    local dotfile="$1"
    ln -s "$(pwd)/$dotfile" "$HOME/$dotfile"
    echo "Created symbolic link for $dotfile in $HOME directory."
}

# Check if no arguments are provided, then recreate dotfile links if necessary
if [ "$#" -eq 0 ]; then
    for dotfile in "${dotfiles[@]}"; do
        if ! dotfile_exists "$dotfile"; then
            create_dotfile_link "$dotfile"
        else
            echo "dotfile $dotfile already in \$HOME" 
        fi
    done
    exit 0
fi

# If arguments are provided, create symbolic links for them
for file in "$@"; do
    if [ -e "$file" ]; then
        filename=$(basename "$file")
        ln -s "$(pwd)/$filename" "$HOME/$filename"
        echo "Created symbolic link for $filename in $HOME directory."
    else
        echo "File '$file' not found."
    fi
done

