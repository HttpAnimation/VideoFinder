#!/bin/bash

find_smallest_videos() {
    count=0
    smallest_size=9999999999
    smallest_file=""
    
    while IFS= read -r file; do
        if [[ -f "$file" && $(file -b --mime-type "$file") == video/* ]]; then
            size=$(stat -c %s "$file")
            if [[ $size -lt $smallest_size ]]; then
                smallest_size=$size
                smallest_file="$file"
            fi
        fi

        ((count++))
        if [[ $count -eq 10 ]]; then
            break
        fi
    done < <(find "$1" -type f)

    if [[ -n "$smallest_file" ]]; then
        echo "Smallest video file: $smallest_file"
        echo "Size: $(du -h "$smallest_file" | cut -f 1)"
    else
        echo "No video files found."
    fi
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

if [[ ! -d "$1" ]]; then
    echo "Error: $1 is not a valid directory."
    exit 1
fi

find_smallest_videos "$1"

