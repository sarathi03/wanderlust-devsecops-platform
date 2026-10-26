#!/usr/bin/env bash
# Updates the image references in the Kubernetes manifests.
# Called by the CD pipeline (GitOps/Jenkinsfile). You can also run it locally to test.
#
# Usage:   scripts/update-image-tags.sh <dockerhub-username> <image-tag> [manifest-dir]
# Example: scripts/update-image-tags.sh myuser 12-a1b2c3d
#
# Turns:   image: <anything>/wanderlust-backend:<anything>
# Into:    image: myuser/wanderlust-backend:12-a1b2c3d
# (and the same for wanderlust-frontend)
set -euo pipefail

DOCKERHUB_USER="${1:?Usage: $0 <dockerhub-username> <image-tag> [manifest-dir]}"
IMAGE_TAG="${2:?Usage: $0 <dockerhub-username> <image-tag> [manifest-dir]}"
MANIFEST_DIR="${3:-kubernetes}"

# Reject values that are not valid in a Docker image reference.
[[ "$DOCKERHUB_USER" =~ ^[a-z0-9]+([._-][a-z0-9]+)*$ ]] \
  || { echo "ERROR: invalid Docker Hub username: '$DOCKERHUB_USER' (must be lowercase)"; exit 1; }
[[ "$IMAGE_TAG" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]] \
  || { echo "ERROR: invalid image tag: '$IMAGE_TAG'"; exit 1; }

update_image() {
  local file="$1" image="$2"
  [[ -f "$file" ]] || { echo "ERROR: $file not found"; exit 1; }

  sed -i -E "s#^([[:space:]]*image:[[:space:]]*)[^[:space:]]+/${image}:[^[:space:]]+#\1${DOCKERHUB_USER}/${image}:${IMAGE_TAG}#" "$file"

  # Verify the change really happened; fail loudly instead of silently deploying nothing.
  if ! grep -Eq "^[[:space:]]*image:[[:space:]]*${DOCKERHUB_USER}/${image}:${IMAGE_TAG}$" "$file"; then
    echo "ERROR: could not set ${image} in ${file}"
    exit 1
  fi
  echo "OK: ${file} -> ${DOCKERHUB_USER}/${image}:${IMAGE_TAG}"
}

update_image "${MANIFEST_DIR}/backend.yaml"  wanderlust-backend
update_image "${MANIFEST_DIR}/frontend.yaml" wanderlust-frontend
