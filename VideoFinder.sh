#!/bin/bash

# Show a dialog for selecting a directory
directory=$(zenity --file-selection --directory --title="Select a directory")

if [[ $? -ne 0 || -z "$directory" ]]; then
    exit 0
fi

# Function to find smallest videos and display in a Zenity text info dialog
find_and_display_smallest_videos() {
    find "$1" -type f -exec file --mime-type {} + | grep "video/" | awk -F: '{ print $1 }' | xargs du -h | sort -h | head -n 10 | zenity --text-info --title="Smallest Video Files" --width=500 --height=300
}

# Function to find duplicate files based on MD5 hash
find_and_display_duplicate_videos() {
    duplicates=$(find "$1" -type f -exec md5sum {} + | sort | uniq -d -w 32)
    if [[ -z "$duplicates" ]]; then
        zenity --info --title="Duplicate Videos" --text="No duplicate videos found in '$1'."
    else
        zenity --text-info --title="Duplicate Videos" --width=500 --height=300 --text="Duplicate videos in '$1':\n$duplicates"
    fi
}

# Function to list the most common video resolutions
list_common_resolutions() {
    resolutions=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 {} + | sort | uniq -c | sort -nr | head -n 10)
    zenity --text-info --title="Common Video Resolutions" --width=500 --height=300 --text="Common video resolutions in '$1':\n$resolutions"
}

# Function to find the largest files
find_largest_files() {
    largest_files=$(find "$1" -type f -exec du -h {} + | sort -rh | head -n 10)
    zenity --text-info --title="Largest Files" --width=500 --height=300 --text="Largest files in '$1':\n$largest_files"
}

# Function to find the newest files
find_newest_files() {
    newest_files=$(find "$1" -type f -exec stat --format="%Y %n" {} + | sort -rn | head -n 10 | awk '{ print strftime("%Y-%m-%d %H:%M:%S", $1), $2 }')
    zenity --text-info --title="Newest Files" --width=500 --height=300 --text="Newest files in '$1':\n$newest_files"
}

# Function to display total duration of videos
display_total_duration() {
    total_duration=$(find "$1" -type f -exec ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 {} + | awk '{ total += $1 } END { print total }')
    zenity --info --title="Total Duration" --text="Total duration of videos in '$1': $(printf "%.2f" "$total_duration") seconds"
}

# Function to find videos by codec
find_videos_by_codec() {
    codec=$(zenity --entry --title="Find Videos by Codec" --text="Enter a video codec to search for:")
    if [[ -n "$codec" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 {} + | grep -i "$codec")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the codec '$codec'."
        else
            zenity --text-info --title="Matching Videos" --width=500 --height=300 --text="Videos with the codec '$codec' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find videos by resolution
find_videos_by_resolution() {
    resolution=$(zenity --entry --title="Find Videos by Resolution" --text="Enter a video resolution to search for (e.g., 1920x1080):")
    if [[ -n "$resolution" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 {} + | grep -i "$resolution")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the resolution '$resolution'."
        else
            zenity --text-info --title="Matching Videos" --width=500 --height=300 --text="Videos with the resolution '$resolution' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find videos by bitrate
find_videos_by_bitrate() {
    bitrate=$(zenity --entry --title="Find Videos by Bitrate" --text="Enter a video bitrate to search for (e.g., 1000k):")
    if [[ -n "$bitrate" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 {} + | grep -i "$bitrate")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the bitrate '$bitrate'."
        else
            zenity --text-info --title="Matching Videos" --width=500 --height=300 --text="Videos with the bitrate '$bitrate' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find files by extension
find_files_by_extension() {
    extension=$(zenity --entry --title="Find Files by Extension" --text="Enter a file extension to search for (e.g., mp4):")
    if [[ -n "$extension" ]]; then
        matching_files=$(find "$1" -type f -name "*.$extension")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Files" --text="No files found with the extension '$extension'."
        else
            zenity --text-info --title="Matching Files" --width=500 --height=300 --text="Files with the extension '$extension' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find files by size range
find_files_by_size_range() {
    size_range=$(zenity --entry --title="Find Files by Size Range" --text="Enter a size range in MB (e.g., 10-100):")
    if [[ -n "$size_range" ]]; then
        lower_size=$(echo "$size_range" | cut -d'-' -f1)
        upper_size=$(echo "$size_range" | cut -d'-' -f2)
        matching_files=$(find "$1" -type f -size +"$lower_size"M -a -size -"$upper_size"M)
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Files" --text="No files found within the size range '$size_range' MB."
        else
            zenity --text-info --title="Matching Files" --width=500 --height=300 --text="Files within the size range '$size_range' MB in '$1':\n$matching_files"
        fi
    fi
}

# Main menu with features
while true; do
    choice=$(zenity --list --title="Video Finder" --text="Select an option:" --column="Option" \
                    "Find Smallest Videos" \
                    "Display Total Video Count" \
                    "Display Total Video Size" \
                    "List Video Formats" \
                    "Display Oldest Videos" \
                    "Display Largest Videos" \
                    "Search by Name" \
                    "Find Largest Files" \
                    "Find Newest Files" \
                    "Display Average Video Size" \
                    "Display Total Duration" \
                    "List Unique Video Codecs" \
                    "List Video Resolutions" \
                    "List Video Bitrates" \
                    "Find Duplicate Videos" \
                    "Find Videos by Codec" \
                    "Find Videos by Resolution" \
                    "Find Videos by Bitrate" \
                    "Find Files by Extension" \
                    "Find Files by Size Range" \
                    "Exit")

    if [[ $? -ne 0 ]]; then
        exit 0
    fi

    case $choice in
        "Find Smallest Videos")
            find_and_display_smallest_videos "$directory"
            ;;
        "Display Total Video Count")
            video_count=$(find "$directory" -type f -exec file --mime-type {} + | grep "video/" | wc -l)
            zenity --info --title="Total Video Count" --text="Total video count in '$directory': $video_count"
            ;;
        "Display Total Video Size")
            total_size=$(find "$directory" -type f -exec du -cb {} + | awk '{ total += $1 } END { print total }')
            zenity --info --title="Total Video Size" --text="Total video size in '$directory': $(echo "scale=2; $total_size / 1024^2" | bc) MB"
            ;;
        "List Video Formats")
            formats=$(find "$directory" -type f -exec file --mime-type {} + | grep "video/" | awk -F: '{ print $2 }' | awk '{ print $1 }' | sort | uniq)
            zenity --text-info --title="Video Formats" --width=500 --height=300 --text="Video formats in '$directory':\n$formats"
            ;;
        "Display Oldest Videos")
            oldest_videos=$(find "$directory" -type f -exec stat --format="%Y %n" {} + | sort -n | head -n 10 | awk '{ print strftime("%Y-%m-%d %H:%M:%S", $1), $2 }')
            zenity --text-info --title="Oldest Videos" --width=500 --height=300 --text="Oldest videos in '$directory':\n$oldest_videos"
            ;;
        "Display Largest Videos")
            largest_videos=$(find "$directory" -type f -exec du -h {} + | sort -rh | head -n 10)
            zenity --text-info --title="Largest Videos" --width=500 --height=300 --text="Largest videos in '$directory':\n$largest_videos"
            ;;
        "Search by Name")
            search_name=$(zenity --entry --title="Search by Name" --text="Enter a keyword to search for:")
            if [[ -n "$search_name" ]]; then
                search_results=$(find "$directory" -type f -iname "*$search_name*" | zenity --text-info --title="Search Results" --width=500 --height=300)
                if [[ -z "$search_results" ]]; then
                    zenity --info --title="Search Results" --text="No results found for '$search_name'."
                fi
            fi
            ;;
        "Find Largest Files")
            find_largest_files "$directory"
            ;;
        "Find Newest Files")
            find_newest_files "$directory"
            ;;
        "Display Average Video Size")
            average_size=$(find "$directory" -type f -exec du -cb {} + | awk '{ total += $1; count++ } END { if (count > 0) print total/count; else print 0 }')
            zenity --info --title="Average Video Size" --text="Average video size in '$directory': $(echo "scale=2; $average_size / 1024^2" | bc) MB"
            ;;
        "Display Total Duration")
            display_total_duration "$directory"
            ;;
        "List Unique Video Codecs")
            codecs=$(find "$directory" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 {} + | sort | uniq)
            zenity --text-info --title="Unique Video Codecs" --width=500 --height=300 --text="Unique video codecs in '$directory':\n$codecs"
            ;;
        "List Video Resolutions")
            list_common_resolutions "$directory"
            ;;
        "List Video Bitrates")
            bitrates=$(find "$directory" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 {} + | sort | uniq)
            zenity --text-info --title="Video Bitrates" --width=500 --height=300 --text="Video bitrates in '$directory':\n$bitrates"
            ;;
        "Find Duplicate Videos")
            find_and_display_duplicate_videos "$directory"
            ;;
        "Find Videos by Codec")
            find_videos_by_codec "$directory"
            ;;
        "Find Videos by Resolution")
            find_videos_by_resolution "$directory"
            ;;
        "Find Videos by Bitrate")
            find_videos_by_bitrate "$directory"
            ;;
        "Find Files by Extension")
            find_files_by_extension "$directory"
            ;;
        "Find Files by Size Range")
            find_files_by_size_range "$directory"
            ;;
        "Exit")
            break
            ;;
        *)
            zenity --error --title="Error" --text="Invalid option: $choice"
            ;;
    esac
done

