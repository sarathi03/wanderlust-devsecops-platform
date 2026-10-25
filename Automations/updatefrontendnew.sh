#!/bin/bash

# Path to the frontend .env file
file_to_find="../frontend/.env.docker"

# Check whether the file exists
if [ -f "$file_to_find" ]; then
    sed -i 's|^VITE_API_PATH=.*|VITE_API_PATH="http://localhost:31100"|' "$file_to_find"
    echo "VITE_API_PATH updated to localhost."
else
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi