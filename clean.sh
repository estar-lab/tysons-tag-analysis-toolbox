# Define the directory to search in
DIRECTORY="."
# Define the file extensions to remove
EXTENSIONS=("*.mat" "*.asv" "*.zip")  # Add any other extensions as needed
# Iterate over the file extensions and remove the matching files in the immediate folder
for EXT in "${EXTENSIONS[@]}"; do
  find "$DIRECTORY" -maxdepth 1 -type f -name "$EXT" -exec rm -f {} +
done

echo "All files with the extensions ${EXTENSIONS[@]} in the immediate folder of $DIRECTORY have been removed."

