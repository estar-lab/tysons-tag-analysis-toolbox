DIRECTORY="."

ZIPFILE="v1.3.0_unstable.zip"

EXCLUDE_EXTENSIONS=("*.mat" "*.asv" "*.zip" "*.gitignore" ".sh")
EXCLUDE_DIRS=(".git")

FIND_CMD="find $DIRECTORY -type f"

for EXT in "${EXCLUDE_EXTENSIONS[@]}"; do
  FIND_CMD="$FIND_CMD ! -name '$EXT'"
done

for DIR in "${EXCLUDE_DIRS[@]}"; do
  FIND_CMD="$FIND_CMD ! -path './$DIR/*'"
done

eval "$FIND_CMD" | zip $ZIPFILE -@

echo "Zipping completed. Excluded file types: ${EXCLUDE_EXTENSIONS[@]}"