#!/bin/bash
#------------------------------------------------------------------------------
# fetch-al2023-rpms.sh - Download AL2023 RPMs for offline repository
#------------------------------------------------------------------------------
# Pipeline phase: day-0_phase-1 (Supply Chain Preparation)
#
# Run this script on an AL2023 EC2 instance with internet access.
# Amazon's CDN (cdn.amazonlinux.com) restricts access to EC2 instances only.
#
# This script downloads the required RPM packages and their dependencies,
# generates repository metadata, and provides instructions for copying
# the files to your development machine.
#
# Usage:
#   ./tools/fetch-al2023-rpms.sh [output_dir]
#
# Examples:
#   ./tools/fetch-al2023-rpms.sh              # Uses /tmp/al2023-rpms
#   ./tools/fetch-al2023-rpms.sh /opt/rpms    # Custom output directory
#
# After running, copy the output to your dev machine:
#   scp -r ec2-user@<instance>:/tmp/al2023-rpms/* deps/rpm/al2023-minrepo/
#
# Next phase: day-0_phase-2 (./tools/0-build_release.sh)
#------------------------------------------------------------------------------
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[FETCH]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die() { error "$1"; exit 1; }

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
OUTPUT_DIR="${1:-/tmp/al2023-rpms}"

# Packages required for offline bootstrap
# python3-pip: Required for pip install on EC2
# Dependencies are resolved automatically with --resolve --alldeps
PACKAGES=(
    python3-pip
)

#------------------------------------------------------------------------------
# Validate environment
#------------------------------------------------------------------------------
log "Checking environment..."

# Must be running on Amazon Linux
if [[ ! -f /etc/os-release ]] || ! grep -q "Amazon Linux" /etc/os-release; then
    die "This script must be run on an Amazon Linux instance"
fi

# Check for dnf
if ! command -v dnf &>/dev/null; then
    die "dnf not found"
fi

# Check for createrepo_c
if ! command -v createrepo_c &>/dev/null; then
    log "Installing createrepo_c..."
    sudo dnf install -y createrepo_c || die "Failed to install createrepo_c"
fi

log "Environment verified"

#------------------------------------------------------------------------------
# Download packages
#------------------------------------------------------------------------------
log "Creating output directory: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

log "Downloading packages: ${PACKAGES[*]}"
log "This includes all dependencies (--resolve --alldeps)"

dnf download \
    --resolve \
    --alldeps \
    --downloaddir="$OUTPUT_DIR" \
    "${PACKAGES[@]}"

#------------------------------------------------------------------------------
# Generate repository metadata
#------------------------------------------------------------------------------
log "Generating repository metadata..."
createrepo_c "$OUTPUT_DIR"

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo ""
log "========================================="
log "RPM fetch complete"
log "========================================="
log "Output directory: $OUTPUT_DIR"
log ""
log "Packages downloaded:"
find "$OUTPUT_DIR" -name "*.rpm" -printf "  %f\n" | sort
echo ""
log "Total size: $(du -sh "$OUTPUT_DIR" | cut -f1)"
echo ""
log "Next steps:"
log "  1. Copy to your development machine:"
log "     scp -r $(whoami)@$(hostname -I | awk '{print $1}'):$OUTPUT_DIR/* deps/rpm/al2023-minrepo/"
log ""
log "  2. Verify on dev machine:"
log "     ls deps/rpm/al2023-minrepo/*.rpm"
log "     ls deps/rpm/al2023-minrepo/repodata/"
