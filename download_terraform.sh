#!/bin/bash

LOG_FILE="/tmp/terraform_install.log"
: > $LOG_FILE
exec > >(tee -i $LOG_FILE)
exec 2>&1

log() {
    echo "$1"
    echo "$1" >> $LOG_FILE
}

log "Detecting platform and architecture..."
PLATFORM=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        log "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
log "Platform: $PLATFORM"
log "Architecture: $ARCH"

log "Fetching latest Terraform version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name)
if [ -z "$LATEST_VERSION" ]; then
  log "Failed to fetch the latest Terraform version."
  exit 1
fi
log "Latest Terraform version: $LATEST_VERSION"

# Remove the 'v' prefix from the version
VERSION=${LATEST_VERSION#v}
log "Version without prefix: $VERSION"

DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_${PLATFORM}_${ARCH}.zip"
log "Download URL: $DOWNLOAD_URL"

log "Downloading Terraform..."
if ! curl -LO $DOWNLOAD_URL; then
  log "Failed to download Terraform."
  exit 1
fi

log "Verifying the downloaded file..."
if ! file terraform_${VERSION}_${PLATFORM}_${ARCH}.zip | grep -q "Zip archive data"; then
  log "The downloaded file is not a valid ZIP archive."
  exit 1
fi

log "Unzipping Terraform..."
if ! unzip terraform_${VERSION}_${PLATFORM}_${ARCH}.zip; then
  log "Failed to unzip Terraform."
  exit 1
fi

log "Moving Terraform binary to /usr/local/bin..."
if ! sudo mv terraform /usr/local/bin/; then
  log "Failed to move Terraform binary."
  exit 1
fi

log "Setting execute permissions for Terraform binary..."
if ! sudo chmod +x /usr/local/bin/terraform; then
  log "Failed to set execute permissions for Terraform binary."
  exit 1
fi

log "Terraform installation completed successfully"
