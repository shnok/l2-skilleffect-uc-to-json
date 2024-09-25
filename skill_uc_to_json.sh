#!/bin/bash

# Define input file and output JSON file
input_file=$1  # Replace with your input file name
filename_only="${input_file##*/}"

SPLITS=(${filename_only//_/ })

output_file=converted/${SPLITS[1]%.*}.json

if [ -e "$output_file" ]
then
	echo "Skill ${SPLITS[1]%} already converted."
    return 
fi

# Print the contents of the input file for debugging
#echo "Debugging: Contents of input file:" >&2
#cat "$input_file" >&2
#echo "Debugging: End of input file contents" >&2

# Initialize JSON structure
json_output="{\n"
json_output+="\"SkillId\": $(grep -oP 'SkillID=\K\d+' "$input_file"),\n"

# Function to extract action details based on matching reference lines
extract_action_details() {
    local array_name="$1"
    local action_pattern="$2"
    local json_array=()
    local capturing=false
    local action_details=()
    local key_value_pairs=()
    local block_name=""

    #echo "Debugging: Extracting $array_name" >&2
   # echo "Debugging: Using pattern: $action_pattern" >&2

    # Extract the action lines matching the given pattern (case-insensitive)
    mapfile -t action_lines < <(grep -ioP $action_pattern "$input_file")
    
   # echo "Debugging: Matched action lines:" >&2
   # if [ ${#action_lines[@]} -eq 0 ]; then
     #   echo "  No matches found" >&2
   # else
   #     printf '%s\n' "${action_lines[@]}" >&2
   # fi

    # Read input file line by line
    while IFS= read -r line; do
        # Start capturing if the line matches a Begin Object line for relevant blocks
        if [[ $line =~ Begin\ Object\ Class=L2EffectEmitter\ Name=L2EffectEmitter([0-9]+) ]]; then
            block_name="L2EffectEmitter${BASH_REMATCH[1]}"
            capturing=false
            # Check if the current block matches any of the extracted action lines
            for action_line in "${action_lines[@]}"; do
                if [[ $action_line =~ $block_name ]]; then
                    capturing=true
                    key_value_pairs=()
                 #   echo "Debugging: Started capturing for $block_name" >&2
                    break
                fi
            done
        elif [[ $capturing == true ]]; then
            # Stop capturing when the End Object is reached
            if [[ $line =~ End\ Object ]]; then
                capturing=false
                action_details="{\"Name\": \"$block_name\", "
                # Join key-value pairs without trailing commas
                action_details+=$(IFS=,; echo "${key_value_pairs[*]}")
                action_details+="}"
                json_array+=("$action_details")
               # echo "Debugging: Finished capturing for $block_name" >&2
            else
                # Extract key-value pairs inside the block
                if [[ $line =~ ^[[:space:]]*([^=]+)=(.+)$ ]]; then
                    key=$(echo "${BASH_REMATCH[1]}" | xargs)
                    value=$(echo "${BASH_REMATCH[2]}" | xargs)
                    value="${value//\'/\"}"
                    key_value_pairs+=("\"$key\": \"$value\"")
                  #  echo "Debugging: Captured key-value pair: $key = $value" >&2
                fi
            fi
        fi
    done < "$input_file"

  #  echo "Debugging: Number of items in json_array: ${#json_array[@]}" >&2

    # Format JSON array items without trailing commas
    json_output+="\"$array_name\": ["
    printf -v joined '%s,' "${json_array[@]}"
    json_output+="${joined%,}"
    json_output+="]"
}

# Extract CastingActions based on their reference lines (case-insensitive)
extract_action_details "CastingActions" "CastingAction\([0-9]+\)=L2EffectEmitter'LineageSkillEffect\.[^']+\.L2EffectEmitter[0-9]+'"

# Add comma between CastingActions and ShotActions
json_output+=",\n"

# Extract ShotActions based on their reference lines (case-insensitive)
extract_action_details "ShotActions" "ShotAction\([0-9]+\)=L2EffectEmitter'LineageSkillEffect\.[^']+\.L2EffectEmitter[0-9]+'"

# Close JSON structure
json_output+=$'\n}'

# Write JSON to output file
echo -e "$json_output" > "$output_file"

# Print success message
echo "===> Skill successfully converted at path \"$output_file\"."

