#!/bin/bash
set -euo pipefail

file_to_find="../backend/.env.docker"

if [[ ! -f "$file_to_find" ]]; then
  echo "ERROR: File not found: $file_to_find"
  exit 1
fi

if grep -q '^FRONTEND_URL=' "$file_to_find"; then
  sed -i 's|^FRONTEND_URL=.*|FRONTEND_URL="http://localhost:5173"|' "$file_to_find"
else
  printf '\nFRONTEND_URL="http://localhost:5173"\n' >> "$file_to_find"
fi

echo "FRONTEND_URL set to localhost for local CI."
