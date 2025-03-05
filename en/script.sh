#!/bin/bash

CONFIG_FILE="config.txt"

# Check if fswatch is installed on macOS
if ! command -v fswatch &> /dev/null; then
    echo "fswatch is not installed. Installing it now..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Please install it manually from https://brew.sh/"
        exit 1
    fi
    
    # Install fswatch using Homebrew
    brew install fswatch
else
    echo "fswatch is already installed."
fi

# Check if the configuration file exists; if not, create it with the correct format
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "The configuration file does not exist. Creating it with a sample format..."
    cat <<EOL > "$CONFIG_FILE"
#  DOWNLOAD ORGANIZER CONFIGURATION RULES
#  FORMAT FOR ASSIGNING FILES TO FOLDERS:
# extension=destination_folder

pdf=~/Documents/freelance/pdf_downloads_Monday
jpg=~/Pictures/Image_Folder
mp4=~/Videos/Video_Folder

#  If you want to change folder paths, add them here:
# old_path=new_path
~/Documents/freelance/pdf_downloads_Monday=~/Documents/projects/organized_pdfs
EOL
    echo "Configuration file created. Edit '$CONFIG_FILE' to customize the rules."
    exit 0
fi

# Function to read the configuration and move files
move_files() {
    local file="$1"
    local extension="${file##*.}"

    # Read the destination folder from the configuration file, ignoring commented lines
    destination_folder=$(grep "^$extension=" "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r')

    if [[ -n "$destination_folder" ]]; then
        # Expand tilde (~) in paths
        destination_folder=$(eval echo "$destination_folder")

        # Replace old paths if they exist in the configuration
        while IFS="=" read -r old_path new_path; do
            if [[ "$destination_folder" == "$old_path" ]]; then
                destination_folder="$new_path"
            fi
        done < <(grep -v "^#" "$CONFIG_FILE" | awk -F= 'NF==2 && $1 ~ /^\//')

        mkdir -p "$destination_folder"
        mv "$file" "$destination_folder"
        echo "📂 Moved: $(basename "$file") → $destination_folder"
    fi
}

# Monitor the Downloads folder and move files in real time
echo " Monitoring ~/Downloads according to the rules in $CONFIG_FILE..."
nohup fswatch -0 ~/Downloads | while read -d "" file; do 
    move_files "$file"
done &>/dev/null &

