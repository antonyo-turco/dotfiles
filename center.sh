#!/bin/bash

linelist=()
while IFS= read -r line; do
    linelist+=("$line")
done

biggest_line_size=0
for line in "${linelist[@]}"; do
    line_length=${#line}
    if ((line_length > biggest_line_size)); then
        biggest_line_size=$line_length
    fi
done

columns=$(tput cols)
((offset = biggest_line_size / 2))
((perfect_center = columns / 2))
((padsize = perfect_center - offset))
spacing=$(printf "%*s" $padsize "")

for line in "${linelist[@]}"; do
    echo "$spacing$line"
done

printf "$spacing"
for ((i = 0; i < biggest_line_size; i++)); do
    printf ─  # unicode 0x2500
done
echo

