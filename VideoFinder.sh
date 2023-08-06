#!/bin/bash

# Show a dialog for selecting a directory
directory=$(zenity --file-selection --directory --title="Select a directory")

if [[ -z "$directory" ]]; then
    exit 1
fi

# Function to find smallest videos and display in a Zenity text info dialog
find_and_display_smallest_videos() {
    find "$1" -type f -exec file --mime-type {} + | grep "video/" | awk -F: '{ print $1 }' | xargs du -h | sort -h | head -n 10 | zenity --text-info --title="Smallest Video Files" --width=500 --height=300
}

# Main menu with features
while true; do
    choice=$(zenity --list --title="Video Finder" --text="Select an option:" --column="Option" "Find Smallest Videos" "Display Total Video Count" "Display Total Video Size" "List Video Formats" "Display Oldest Videos" "Display Largest Videos" "Search by Name" "Find Largest Files" "Find Newest Files" "Exit")

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
            zenity --info --title="Total Video Size" --text="Total video size in '$directory': $(numfmt --to=iec-i --suffix=B "$total_size")"
            ;;
        "List Video Formats")
            formats=$(find "$directory" -type f -exec file --mime-type {} + | grep "video/" | awk -F: '{ print $2 }' | sort | uniq)
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
            largest_files=$(find "$directory" -type f -exec du -h {} + | sort -rh | head -n 10)
            zenity --text-info --title="Largest Files" --width=500 --height=300 --text="Largest files in '$directory':\n$largest_files"
            ;;
        "Find Newest Files")
            newest_files=$(find "$directory" -type f -exec stat --format="%Y %n" {} + | sort -rn | head -n 10 | awk '{ print strftime("%Y-%m-%d %H:%M:%S", $1), $2 }')
            zenity --text-info --title="Newest Files" --width=500 --height=300 --text="Newest files in '$directory':\n$newest_files"
            ;;
        "Exit")
            break
            ;;
        *)
            zenity --error --title="Error" --text="Invalid option: $choice"
            ;;
    esac
done

