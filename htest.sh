#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $(basename "$0") ModuleName file1 [file2 ...]"
  exit 1
fi

# === Configuration ===
GROUP_ID="com.github.fadingafterglow"
ARTIFACT_ID="htest-runner"
VERSION="1.0.0"
REPO_OWNER="fadingafterglow"
REPO_NAME="htest"
DOWNLOAD_TOKEN="P75NLIjsbl8emsfYYlB6jIgQzg4aL61p0lEr"

# === Derive runner path ===
BASE_URL="https://maven.pkg.github.com/${REPO_OWNER}/${REPO_NAME}"
GROUP_PATH="${GROUP_ID//\.//}"
JAR_FILE="${ARTIFACT_ID}-${VERSION}.jar"
SCRIPT_DIR="$(dirname "$0")"
JAR_FILE_PATH="${SCRIPT_DIR}/${JAR_FILE}"
DOWNLOAD_URL="${BASE_URL}/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${JAR_FILE}"

# === Download runner if missing ===
if [[ ! -f "$JAR_FILE_PATH" ]]; then
  find "$SCRIPT_DIR" -maxdepth 1 -name "${ARTIFACT_ID}-*.jar" -type f |
  while IFS= read -r file; do
    echo "Removing old runner version: $file"
    rm -f "$file"
  done

  echo "Downloading ${JAR_FILE} from:"
  echo "${DOWNLOAD_URL}"
  if ! curl -sL -H "Authorization: Bearer ghp_${DOWNLOAD_TOKEN}" -o "$JAR_FILE_PATH" "$DOWNLOAD_URL"; then
    echo "Failed to download runner."
    exit 1
  fi
fi

# === Prepare arguments ===
MODULE_NAME="$1"
shift
TEST_FILES=()

# === Expand paths ===
for arg in "$@"; do
  for f in $arg; do
    TEST_FILES+=("$(realpath "$f")")
  done
done

# === Invoke runner ===
java -jar "$JAR_FILE_PATH" "$MODULE_NAME" "${TEST_FILES[@]}"