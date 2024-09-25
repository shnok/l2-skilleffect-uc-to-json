for file in original/*; do

  if [[ -f "$file" ]]; then
	filename_only="${input_file##*/}"
	if [[ $filename_only == *"br_"* ]]; then
	  echo "Skipping useless skill..."
	else
		#echo "Converting $file to json."
		source ./skill_uc_to_json.sh "$file"
	fi
  fi
done