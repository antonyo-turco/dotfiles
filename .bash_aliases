# ls aliases
alias ll='ls -AohF --group-directories-first'
alias la='ls -A'
alias l='ls -CF'
alias lt='tree --filesfirst --gitignore -L 3'

# clear aliases
alias c="clear"
alias cl="clear"
alias ckear="clear"
alias clr="clear"

# history aliases
alias hgrep='history | grep -i'

# mv/cp/rm aliases
alias mk='touch'
alias mkdir='mkdir -pv'
alias mv='mv -iv'
alias mvdir='mv -iv'
alias cp='cp -i'
alias cpdir='cp -ri'
alias rm='rm -Iv'
alias rmdir='rm -rIv'

# terminal navigation aliases and shortcuts
alias back='go ..'
alias ..='go ..'
alias open='wslview'
# TODO: need to find a better way to do this 
# alias .='go .'
alias desk='go /mnt/c/Users/anton/Desktop'
alias uni='go /mnt/c/Users/anton/Desktop/Unilocale'
# Some useful shortcuts that allow for easy access 
# during this transitional period 
alias bashrc='vim ~/.bashrc'
alias bash_aliases='vim ~/.bash_aliases'
alias reload='source ~/.bashrc' 
alias vimrc='vim ~/.vimrc'
# TODO: to the folder where i will put the dotfiles 
# alias dotfiles='go NULL'

# misc
alias wisecow='fortune | cowsay -W 80'

## useful functions ##
# create new directory and cd into it
mcd() { 
    [[ "$1" ]];
    mkdir -p "$1";
    cd "$1";
}

# better movement between folders
go() {
    clear;
    cd $1;
    echo "Present Working Directory: ${PWD}"; 
    ll;
}

context() {
    local dir="${1:-$(pwd)}"  # Use provided directory or current directory if none given
    local output="full_program.txt"
    
    # Validate input
    if [ ! -d "$dir" ]; then
        echo "Error: Directory '$dir' does not exist"
        return 1
    fi

    # Clear output file
    > "$output"

    # Add directory tree structure at the beginning
    echo "Directory structure:" >> "$output"
    echo "====================" >> "$output"
    tree "$dir" -P "*.c|*.h|Makefile|makefile" --prune | sed '/^$/d' | grep -v '^[0-9]' >> "$output"
    echo >> "$output"
    echo >> "$output"

    # Process all .c, .h, and Makefiles
    find "$dir" -type f \( -name "*.c" -o -name "*.h" -o -name "Makefile" -o -name "makefile" \) | while read -r file; do
        # Get relative path
        local rel_path="${file#$dir/}"
        
        # Add file header with relative path
        echo "// $rel_path" >> "$output"
        
        # Add file content with proper escaping
        echo "\"$(sed 's/"/\\"/g' "$file" | awk '{printf "%s\\n", $0}')\"" >> "$output"
        
        # Add spacing between files
        echo >> "$output"
    done

    echo "Combined output saved to $output"
}

# open windows file explorer
explore() {

    if [ $# -eq 0 ]; then
      # If no argument is provided, open the current directory
      explorer.exe .
    else
      # Combine the arguments into a single path
      path="$*"

      # Check if the provided path is a valid directory
      if [ -d "$path" ]; then
        # If it's a valid directory, open it in the file explorer
        (cd $path; explorer.exe .;)
      else
        # If it's not a valid directory or path, print an error message
        echo "Error! Invalid path or not a directory: $path"
      fi
    fi
} 

mozilla() {
    mozilla_path='C:\"Program Files"\"Mozilla Firefox"\firefox.exe -p antonyo'
    if [ $# -eq 0 ]; then
        # If no argument is provided, open firefox normally
        powershell.exe $mozilla_path
    else
        mozilla_path+=" 'https://www.google.com/search?client=firefox-b-d&q=$*'"
        powershell.exe $mozilla_path
    fi
}


lsf() { 
    find -maxdepth 1 -type f -exec bash -c 'column <(ls -l "$@") <(file -b "$@" | cut -d, -f1)' _ {} + ; 
}


