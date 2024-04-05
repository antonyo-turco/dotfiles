#!/bin/bash

lang=$1

if [ ! -n "${lang##+([[:space:]])}" ]; then
    echo 'Please add a programming language'
fi

langUpperCase=$(echo $lang | sed 's/./\u&/')

curl -s "https://raw.githubusercontent.com/github/gitignore/main/${langUpperCase}.gitignore" --output .gitignore
