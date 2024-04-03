# ls aliases
alias ll='ls -AohF'
alias la='ls -A'
alias l='ls -CF'

# mv/cp/rm aliases
alias mk='touch'
alias mv='mv -iv'
alias mvdir='mv -riv'
alias cp='cp -i'
alias cpdir='cp -ri'
alias rm='rm -Iv'
alias rmdir='rm -rIv'

# terminal navigation aliases and shortcuts
alias goback='go ..'
alias desk='go /mnt/c/Users/anton/Desktop'
alias uni='go /mnt/c/Users/anton/Desktop/Unilocale'
alias bashrc='vim ~/.bashrc'
alias bash_aliases='vim ~/.bash_aliases'
alias vimrc='vim ~/.vimrc'
# ToDo: alias dotfiles='go -> to the folder where i will put the dotfiles (set up symlinks)'

# misc
alias wisecow='fortune | cowsay -W 80 '


## useful functions ##
# create new directory and cd into it
mcd() { [[ "$1" ]] && mkdir -p "$1" && cd "$1"; }

# better movement between folders
go() { cd $1; echo "Present Working Directory: ${PWD}"; ll;}

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
        explorer.exe "$path"
      else
        # If it's not a valid directory or path, print an error message
        echo "Error: Invalid path or not a directory: $path"
      fi
    fi

} 


