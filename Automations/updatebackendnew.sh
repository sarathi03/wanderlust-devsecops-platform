#!/bin/bash

# Path to the backend .env file
file_to_find="../backend/.env.docker"

# Check whether the file exists
if [ -f "$file_to_find" ]; then
    sed -i 's|^FRONTEND_URL=.*|FRONTEND_URL="http://localhost:5173"|' "$file_to_find"
    echo "FRONTEND_URL updated to localhost."
else
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi