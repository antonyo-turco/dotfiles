#!/usr/bin/env bash

REPO_DIR="/mnt/c/Users/anton/Documents/dotfiles"
LINUX_DIR="$REPO_DIR/linux"

dotfile_exists() {
    local name="$1"
    [ -e "$HOME/$name" ] && [ -L "$HOME/$name" ]
}

create_dotfile_link() {
    local src="$1"
    local name="$(basename "$src")"
    ln -s "$src" "$HOME/$name"
    echo "Created symbolic link for $name in $HOME directory."
}

mapfile -t dotfiles < <(find "$LINUX_DIR" -maxdepth 1 -type f -name '.*')

if [ "$#" -eq 0 ]; then
    for dotfile in "${dotfiles[@]}"; do
        name="$(basename "$dotfile")"
        if ! dotfile_exists "$name"; then
            create_dotfile_link "$dotfile"
        else
            echo "dotfile $name already in \$HOME"
        fi
    done
    exit 0
fi

for file in "$@"; do
    if [ -e "$file" ]; then
        create_dotfile_link "$(realpath "$file")"
    else
        echo "File '$file' not found."
    fi
done
