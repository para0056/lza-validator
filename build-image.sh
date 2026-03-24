#!/bin/bash
set -euo pipefail

# Full ECR registry URI: <account-id>.dkr.ecr.<region>.amazonaws.com
# Can be overridden by setting ECR_REGISTRY in the environment.
ECR_REGISTRY="${ECR_REGISTRY:-123456789012.dkr.ecr.us-east-1.amazonaws.com}"
ECR_REGION="${ECR_REGION:-us-east-1}"

usage() {
  echo "Usage: $0 <lza-version>"
  echo "  Example: $0 v1.9.2"
  exit 1
}

[[ $# -lt 1 ]] && usage

VERSION="$1"
IMAGE="${ECR_REGISTRY}/lza-validator:${VERSION}"
LZA_DIR="$(dirname "$0")/landing-zone-accelerator-on-aws"

echo "==> Cloning LZA source at ${VERSION}"
if [[ -d "$LZA_DIR" ]]; then
  git -C "$LZA_DIR" fetch --tags
  git -C "$LZA_DIR" -c advice.detachedHead=false checkout "${VERSION}"
else
  git clone --branch "${VERSION}" --depth 1 \
    https://github.com/awslabs/landing-zone-accelerator-on-aws.git \
    "$LZA_DIR"
fi

echo "==> Authenticating to ECR"
aws ecr get-login-password --region "${ECR_REGION}" \
  | podman login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "==> Building image ${IMAGE}"
podman build \
  --tag "${IMAGE}" \
  "$(dirname "$0")"

echo "==> Pushing image ${IMAGE}"
podman push "${IMAGE}"

echo "==> Done: ${IMAGE}"
