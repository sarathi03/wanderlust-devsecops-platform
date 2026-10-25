#!/bin/bash
# AWS version retained separately. Set INSTANCE_ID and AWS credentials/region for your own account.
set -euo pipefail
INSTANCE_ID="${INSTANCE_ID:?Set INSTANCE_ID to your own EC2 instance ID}"
file_to_find="../frontend/.env.docker"
ipv4_address="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"
[[ -f "$file_to_find" ]] || { echo "ERROR: File not found: $file_to_find"; exit 1; }
[[ -n "$ipv4_address" && "$ipv4_address" != "None" ]] || { echo "ERROR: Could not retrieve EC2 public IP"; exit 1; }
sed -i "s|^VITE_API_PATH=.*|VITE_API_PATH=\"http://${ipv4_address}:31100\"|" "$file_to_find"
