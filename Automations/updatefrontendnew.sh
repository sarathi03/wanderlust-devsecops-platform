#!/bin/bash
set -euo pipefail

file_to_find="../frontend/.env.docker"

if [[ ! -f "$file_to_find" ]]; then
  echo "ERROR: File not found: $file_to_find"
  exit 1
fi

if grep -q '^VITE_API_PATH=' "$file_to_find"; then
  sed -i 's|^VITE_API_PATH=.*|VITE_API_PATH="http://localhost:31100"|' "$file_to_find"
else
  printf '\nVITE_API_PATH="http://localhost:31100"\n' >> "$file_to_find"
fi

echo "VITE_API_PATH set to localhost for local CI."
