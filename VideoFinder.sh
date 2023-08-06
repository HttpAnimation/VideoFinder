#!/bin/bash

# Show a dialog for selecting a directory
directory=$(zenity --file-selection --directory --title="Select a directory")

if [[ $? -ne 0 || -z "$directory" ]]; then
    exit 0
fi

# Function to find smallest videos and display in a Zenity text info dialog
find_and_display_smallest_videos() {
    smallest_videos=$(find "$1" -type f -exec du -h --block-size=1M {} + | sort -n -k1 | head -n 10)
    zenity --text-info --title="Smallest Video Files" --width=800 --height=600 --text="Smallest video files in '$1':\n$smallest_videos"
}

# Function to find and display largest videos
find_and_display_largest_videos() {
    largest_videos=$(find "$1" -type f -exec du -h --block-size=1M {} + | sort -rh -k1 | head -n 10)
    zenity --text-info --title="Largest Video Files" --width=800 --height=600 --text="Largest video files in '$1':\n$largest_videos"
}

# Function to find and display oldest videos
find_and_display_oldest_videos() {
    oldest_videos=$(find "$1" -type f -exec stat --format="%Y %n" {} + | sort -n | head -n 10 | awk '{ print strftime("%Y-%m-%d %H:%M:%S", $1), $2 }')
    zenity --text-info --title="Oldest Video Files" --width=800 --height=600 --text="Oldest video files in '$1':\n$oldest_videos"
}

# Function to find and display newest videos
find_and_display_newest_videos() {
    newest_videos=$(find "$1" -type f -exec stat --format="%Y %n" {} + | sort -nr | head -n 10 | awk '{ print strftime("%Y-%m-%d %H:%M:%S", $1), $2 }')
    zenity --text-info --title="Newest Video Files" --width=800 --height=600 --text="Newest video files in '$1':\n$newest_videos"
}

# Function to find and display total video count
find_and_display_total_video_count() {
    video_count=$(find "$1" -type f -exec file --mime-type {} + | grep "video/" | wc -l)
    zenity --info --title="Total Video Count" --text="Total video count in '$1': $video_count"
}

# Function to find and display total video size
find_and_display_total_video_size() {
    total_size=$(find "$1" -type f -exec du -cb {} + | awk '{ total += $1 } END { print total }')
    zenity --info --title="Total Video Size" --text="Total video size in '$1': $(echo "scale=2; $total_size / 1024^2" | bc) MB"
}

# Function to list video formats
list_video_formats() {
    formats=$(find "$1" -type f -exec file --mime-type {} + | grep "video/" | awk -F: '{ print $2 }' | awk '{ print $1 }' | sort | uniq)
    zenity --text-info --title="Video Formats" --width=800 --height=600 --text="Video formats in '$1':\n$formats"
}

# Function to display average video size
display_average_video_size() {
    average_size=$(find "$1" -type f -exec du -cb {} + | awk '{ total += $1; count++ } END { if (count > 0) print total/count; else print 0 }')
    zenity --info --title="Average Video Size" --text="Average video size in '$1': $(echo "scale=2; $average_size / 1024^2" | bc) MB"
}

# Function to find and display total duration of videos
find_and_display_total_duration() {
    total_duration=$(find "$1" -type f -exec ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 {} + | awk '{ total += $1 } END { print total }')
    zenity --info --title="Total Duration" --text="Total duration of videos in '$1': $(printf "%.2f" "$total_duration") seconds"
}

# Function to list unique video codecs
list_unique_video_codecs() {
    codecs=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 {} + | sort | uniq)
    zenity --text-info --title="Unique Video Codecs" --width=800 --height=600 --text="Unique video codecs in '$1':\n$codecs"
}

# Function to list common video resolutions
list_common_video_resolutions() {
    resolutions=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 {} + | sort | uniq -c | sort -nr | head -n 10)
    zenity --text-info --title="Common Video Resolutions" --width=800 --height=600 --text="Common video resolutions in '$1':\n$resolutions"
}

# Function to list video bitrates
list_video_bitrates() {
    bitrates=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 {} + | sort | uniq)
    zenity --text-info --title="Video Bitrates" --width=800 --height=600 --text="Video bitrates in '$1':\n$bitrates"
}

# Function to find and display duplicate videos
find_and_display_duplicate_videos() {
    duplicates=$(find "$1" -type f -exec md5sum {} + | sort | uniq -d -w 32)
    if [[ -z "$duplicates" ]]; then
        zenity --info --title="Duplicate Videos" --text="No duplicate videos found in '$1'."
    else
        zenity --text-info --title="Duplicate Videos" --width=800 --height=600 --text="Duplicate videos in '$1':\n$duplicates"
    fi
}

# Function to find videos by codec
find_videos_by_codec() {
    codec=$(zenity --entry --title="Find Videos by Codec" --text="Enter a video codec to search for:")
    if [[ -n "$codec" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 {} + | grep -i "$codec")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the codec '$codec'."
        else
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the codec '$codec' in '$1':\n$matching_files"
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
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the resolution '$resolution' in '$1':\n$matching_files"
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
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the bitrate '$bitrate' in '$1':\n$matching_files"
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
            zenity --text-info --title="Matching Files" --width=800 --height=600 --text="Files with the extension '$extension' in '$1':\n$matching_files"
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
            zenity --text-info --title="Matching Files" --width=800 --height=600 --text="Files within the size range '$size_range' MB in '$1':\n$matching_files"
        fi
    fi
}

# Function to find files by modification date
find_files_by_modification_date() {
    mod_date_range=$(zenity --entry --title="Find Files by Modification Date" --text="Enter a date range in the format YYYY-MM-DD (e.g., 2023-01-01-2023-12-31):")
    if [[ -n "$mod_date_range" ]]; then
        start_date=$(echo "$mod_date_range" | cut -d'-' -f1)
        end_date=$(echo "$mod_date_range" | cut -d'-' -f2)
        matching_files=$(find "$1" -type f -newermt "$start_date" ! -newermt "$end_date")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Files" --text="No files found within the modification date range '$mod_date_range'."
        else
            zenity --text-info --title="Matching Files" --width=800 --height=600 --text="Files within the modification date range '$mod_date_range' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find videos by framerate
find_videos_by_framerate() {
    framerate=$(zenity --entry --title="Find Videos by Framerate" --text="Enter a video framerate to search for (e.g., 24):")
    if [[ -n "$framerate" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 {} + | grep -i "$framerate")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the framerate '$framerate'."
        else
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the framerate '$framerate' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find videos by language
find_videos_by_language() {
    language=$(zenity --entry --title="Find Videos by Language" --text="Enter a video language to search for (e.g., eng):")
    if [[ -n "$language" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams a:0 -show_entries stream=tags:language -of default=noprint_wrappers=1:nokey=1 {} + | grep -i "$language")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the language code '$language'."
        else
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the language code '$language' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find videos by aspect ratio
find_videos_by_aspect_ratio() {
    aspect_ratio=$(zenity --entry --title="Find Videos by Aspect Ratio" --text="Enter an aspect ratio to search for (e.g., 16:9):")
    if [[ -n "$aspect_ratio" ]]; then
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 {} + | grep -i "$aspect_ratio")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the aspect ratio '$aspect_ratio'."
        else
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the aspect ratio '$aspect_ratio' in '$1':\n$matching_files"
        fi
    fi
}

# Function to find videos by resolution and framerate
find_videos_by_resolution_and_framerate() {
    resolution=$(zenity --entry --title="Find Videos by Resolution and Framerate" --text="Enter a video resolution (e.g., 1920x1080) and framerate (e.g., 24) separated by a space:")
    if [[ -n "$resolution" ]]; then
        res=$(echo "$resolution" | cut -d' ' -f1)
        fps=$(echo "$resolution" | cut -d' ' -f2)
        matching_files=$(find "$1" -type f -exec ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=s=x:p=0:nk=0 {} + | grep -i "$res" | grep -i "$fps")
        if [[ -z "$matching_files" ]]; then
            zenity --info --title="Matching Videos" --text="No videos found with the resolution '$res' and framerate '$fps'."
        else
            zenity --text-info --title="Matching Videos" --width=800 --height=600 --text="Videos with the resolution '$res' and framerate '$fps' in '$1':\n$matching_files"
        fi
    fi
}

# Main menu with features
while true; do
    choice=$(zenity --list --title="Video Finder" --text="Select an option:" --column="Option" \
                    "Find Smallest Videos" \
                    "Find Largest Videos" \
                    "Find Oldest Videos" \
                    "Find Newest Videos" \
                    "Display Total Video Count" \
                    "Display Total Video Size" \
                    "List Video Formats" \
                    "Display Average Video Size" \
                    "Display Total Duration" \
                    "List Unique Video Codecs" \
                    "List Common Video Resolutions" \
                    "List Video Bitrates" \
                    "Find Duplicate Videos" \
                    "Find Videos by Codec" \
                    "Find Videos by Resolution" \
                    "Find Videos by Bitrate" \
                    "Find Files by Extension" \
                    "Find Files by Size Range" \
                    "Find Files by Modification Date" \
                    "Find Videos by Framerate" \
                    "Find Videos by Language" \
                    "Find Videos by Aspect Ratio" \
                    "Find Videos by Resolution and Framerate" \
                    "Exit")

    if [[ $? -ne 0 ]]; then
        exit 0
    fi

    case $choice in
        "Find Smallest Videos")
            find_and_display_smallest_videos "$directory"
            ;;
        "Find Largest Videos")
            find_and_display_largest_videos "$directory"
            ;;
        "Find Oldest Videos")
            find_and_display_oldest_videos "$directory"
            ;;
        "Find Newest Videos")
            find_and_display_newest_videos "$directory"
            ;;
        "Display Total Video Count")
            find_and_display_total_video_count "$directory"
            ;;
        "Display Total Video Size")
            find_and_display_total_video_size "$directory"
            ;;
        "List Video Formats")
            list_video_formats "$directory"
            ;;
        "Display Average Video Size")
            display_average_video_size "$directory"
            ;;
        "Display Total Duration")
            find_and_display_total_duration "$directory"
            ;;
        "List Unique Video Codecs")
            list_unique_video_codecs "$directory"
            ;;
        "List Common Video Resolutions")
            list_common_video_resolutions "$directory"
            ;;
        "List Video Bitrates")
            list_video_bitrates "$directory"
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
        "Find Files by Modification Date")
            find_files_by_modification_date "$directory"
            ;;
        "Find Videos by Framerate")
            find_videos_by_framerate "$directory"
            ;;
        "Find Videos by Language")
            find_videos_by_language "$directory"
            ;;
        "Find Videos by Aspect Ratio")
            find_videos_by_aspect_ratio "$directory"
            ;;
        "Find Videos by Resolution and Framerate")
            find_videos_by_resolution_and_framerate "$directory"
            ;;
        "Exit")
            break
            ;;
        *)
            zenity --error --title="Error" --text="Invalid option: $choice"
            ;;
    esac
done

