#!/bin/bash

# Loop through all files in the current directory
for file in *; do
  # Check if the file is a regular file (not a directory)
  if [[ -f "$file" ]]; then
  
      # Get the encoding of the file
    encoding=$(file -i "$file" | awk -F'charset=' '{print $2}')

	new_file="original/${file%.*}.uc2"
    # Check if the encoding is UTF-16 (either UTF-16LE or UTF-16BE)
    if [[ "$encoding" == "utf-16le" || "$encoding" == "utf-16be" ]]; then
	
		# Define the new filename by appending "uc2" before the file extension
		# If there's no extension, just append "uc2"
		# Convert the file from UTF-16 to UTF-8
		iconv -f UTF-16 -t UTF-8 "$file" > "$new_file"
		
		# Print a message indicating the conversion
		echo "Converted $file to $new_file"
    else
      echo "Skipping $file: not UTF-16 encoded ($encoding)"
	  cat "$file" > "$new_file"
    fi
  fi
done