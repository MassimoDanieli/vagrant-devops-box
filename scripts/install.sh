#!/usr/bin/env bash
# Provisions the DevOps box (Ubuntu 24.04, amd64 or arm64). Safe to re-run.
set -euo pipefail
# set -x   # uncomment to debug

export DEBIAN_FRONTEND=noninteractive
BOX_USER="${BOX_USER:-vagrant}"
KUBECTL_MINOR="${KUBECTL_MINOR:-v1.37}"
SKAFFOLD_VERSION="${SKAFFOLD_VERSION:-v2.25.0}"

case "$(dpkg --print-architecture)" in
  amd64) ARCH=amd64; AWS_ARCH=x86_64 ;;
  arm64) ARCH=arm64; AWS_ARCH=aarch64 ;;
  *) echo "unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;;
esac

apt-get update
apt-get install -y ca-certificates curl gnupg unzip git jq software-properties-common
install -m 0755 -d /etc/apt/keyrings

# --- HashiCorp (Terraform, Packer): official apt repository, any architecture
if [[ ! -f /etc/apt/keyrings/hashicorp.gpg ]]; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
fi
# shellcheck source=/dev/null
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${codename} main" \
  > /etc/apt/sources.list.d/hashicorp.list

# --- Kubernetes (kubectl): pkgs.k8s.io, pinned to one minor release
if [[ ! -f /etc/apt/keyrings/kubernetes.gpg ]]; then
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBECTL_MINOR}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
fi
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/${KUBECTL_MINOR}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y terraform packer kubectl ansible docker.io docker-compose-v2

# Docker without sudo. -aG appends: the old "usermod -G docker" replaced
# every other supplementary group of the user.
usermod -aG docker "$BOX_USER"

# --- AWS CLI v2: official installer (pip installs are blocked by PEP 668 on 24.04)
if ! command -v aws >/dev/null; then
  tmp=$(mktemp -d)
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "$tmp/awscliv2.zip"
  unzip -q "$tmp/awscliv2.zip" -d "$tmp"
  "$tmp/aws/install"
  rm -rf "$tmp"
fi

# --- Skaffold: pinned release instead of "latest"
curl -fsSL -o /tmp/skaffold "https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-${ARCH}"
install -m 0755 /tmp/skaffold /usr/local/bin/skaffold && rm /tmp/skaffold

# --- Postman: the snap is published for amd64 only
if [[ "$ARCH" == amd64 ]]; then
  if command -v snap >/dev/null; then
    snap install postman || echo "postman: snap install failed, skipping"
  else
    echo "postman: snapd not available, skipping"
  fi
fi

# --- SSH key for the box user (kept if it already exists)
home=$(getent passwd "$BOX_USER" | cut -d: -f6)
if [[ ! -f "$home/.ssh/mykey" ]]; then
  install -d -m 0700 -o "$BOX_USER" -g "$BOX_USER" "$home/.ssh"
  sudo -u "$BOX_USER" ssh-keygen -q -t ed25519 -f "$home/.ssh/mykey" -N ''
fi

apt-get clean

echo
echo "DevOps box ready:"
terraform version | head -1
packer version | head -1
kubectl version --client | head -1
ansible --version | head -1
docker --version
aws --version
skaffold version
