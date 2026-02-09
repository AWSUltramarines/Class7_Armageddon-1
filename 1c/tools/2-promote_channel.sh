#!/bin/bash
#------------------------------------------------------------------------------
# 2-promote_channel.sh - Promote a release to a deployment channel
#------------------------------------------------------------------------------
# Pipeline phase: day-1_phase-3 (Promote Channel)
#
# Updates channel pointer objects in S3 to point to a specific release.
# EC2 instances read these pointers to determine which release to install.
#
# Usage:
#   ./tools/2-promote_channel.sh <channel> <release_id> <bucket_name>
#   ./tools/2-promote_channel.sh prod 2026-01-29T1800Z my-bucket-abc123
#
# Release ID format:
#   Use ISO 8601 timestamps (e.g., 2026-01-29T1800Z) for chronological ordering
#   and immutability.
#
# Prerequisites:
#   - day-1_phase-2 complete: ./tools/1-upload_release.sh <release_id> <bucket>
#   - AWS credentials configured
#
# System packages:
#   - aws-cli (v2 recommended)
#
# Channels: dev, stage, prod
#
# Updates the following S3 objects (channel pointers):
#   repo/rpm/channels/<channel>
#   repo/pip/channels/<channel>
#   repo/cw-agent/channels/<channel>
#
# Each pointer contains the S3 prefix path to the release artifacts.
#
# Environment variables:
#   ARCH         - Architecture (default: x86_64)
#   PYTHON_VER   - Python version (default: py39)
#
# Previous phase: day-1_phase-2 (./tools/1-upload_release.sh)
# Next phase: day-1_phase-4 (terraform apply with enable_ec2=true in tfvars)
#------------------------------------------------------------------------------
set -euo pipefail

# Configuration (overridable via environment)
ARCH="${ARCH:-x86_64}"
PYTHON_VER="${PYTHON_VER:-py39}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[PROMOTE]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
die() { error "$1"; exit 1; }

#------------------------------------------------------------------------------
# Argument parsing
#------------------------------------------------------------------------------
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <channel> <release_id> <bucket_name>"
    echo ""
    echo "Arguments:"
    echo "  channel      Deployment channel: dev, stage, or prod"
    echo "  release_id   ISO 8601 timestamp (e.g., 2026-01-29T1800Z)"
    echo "  bucket_name  S3 bucket name"
    echo ""
    echo "Examples:"
    echo "  $0 dev 2026-01-29T1800Z my-bucket-abc123"
    echo "  $0 prod 2026-01-28T1200Z my-bucket-abc123"
    exit 1
fi

CHANNEL="$1"
RELEASE_ID="$2"
BUCKET="$3"

# Validate channel
case "$CHANNEL" in
    dev|stage|prod) ;;
    *) die "Invalid channel '$CHANNEL'. Must be: dev, stage, or prod" ;;
esac

# Validate release_id format.
# Expected: ISO 8601 timestamp (e.g., 2026-01-29T1800Z) for path safety.
if [[ ! "$RELEASE_ID" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    die "Invalid release_id format. Expected ISO 8601 timestamp (e.g., 2026-01-29T1800Z). Use only alphanumeric characters, dots, underscores, and hyphens."
fi

#------------------------------------------------------------------------------
# Verify release exists in S3
#------------------------------------------------------------------------------
log "Verifying release $RELEASE_ID in s3://$BUCKET..."

# Check manifest exists
MANIFEST_KEY="manifests/${RELEASE_ID}.json"
if ! aws s3 ls "s3://$BUCKET/$MANIFEST_KEY" &>/dev/null; then
    die "Manifest not found: s3://$BUCKET/$MANIFEST_KEY"
fi
log "Found manifest"

# Verify signature exists
SIG_KEY="manifests/${RELEASE_ID}.json.sig"
if ! aws s3 ls "s3://$BUCKET/$SIG_KEY" &>/dev/null; then
    die "Signature not found. Release must be uploaded first."
fi

# Verify signature is valid (sanity check)
SIG_CONTENT=$(aws s3 cp "s3://$BUCKET/$SIG_KEY" - 2>/dev/null | head -1)
if [[ "$SIG_CONTENT" == UNSIGNED* ]]; then
    die "Release is unsigned. Rebuild and re-upload the release."
fi
log "Signature verified"

# Build artifact prefixes
RPM_PREFIX="repo/rpm/releases/${RELEASE_ID}/${ARCH}/"
PIP_PREFIX="repo/pip/releases/${RELEASE_ID}/${PYTHON_VER}/"
CW_PREFIX="repo/cw-agent/releases/${RELEASE_ID}/"

# Check RPM release
if ! aws s3 ls "s3://$BUCKET/$RPM_PREFIX" &>/dev/null; then
    die "RPM release not found: s3://$BUCKET/$RPM_PREFIX"
fi
if ! aws s3 ls "s3://$BUCKET/${RPM_PREFIX}repodata/" &>/dev/null; then
    die "RPM repodata not found: s3://$BUCKET/${RPM_PREFIX}repodata/"
fi
log "Found RPM release"

# Check pip release
if ! aws s3 ls "s3://$BUCKET/$PIP_PREFIX" &>/dev/null; then
    die "Pip release not found: s3://$BUCKET/$PIP_PREFIX"
fi
if ! aws s3 ls "s3://$BUCKET/${PIP_PREFIX}requirements.lock" &>/dev/null; then
    die "requirements.lock not found: s3://$BUCKET/${PIP_PREFIX}requirements.lock"
fi
log "Found pip release"

# Check CW agent release
if ! aws s3 ls "s3://$BUCKET/${CW_PREFIX}amazon-cloudwatch-agent.rpm" &>/dev/null; then
    die "CW agent not found: s3://$BUCKET/${CW_PREFIX}amazon-cloudwatch-agent.rpm"
fi
log "Found CW agent release"

#------------------------------------------------------------------------------
# Get current channel pointers (for reference)
#------------------------------------------------------------------------------
info "Current channel pointers:"

get_current_pointer() {
    local key="$1"
    aws s3 cp "s3://$BUCKET/$key" - 2>/dev/null || echo "(not set)"
}

CURRENT_RPM=$(get_current_pointer "repo/rpm/channels/$CHANNEL")
CURRENT_PIP=$(get_current_pointer "repo/pip/channels/$CHANNEL")
CURRENT_CW=$(get_current_pointer "repo/cw-agent/channels/$CHANNEL")

echo "  RPM:      $CURRENT_RPM"
echo "  Pip:      $CURRENT_PIP"
echo "  CW Agent: $CURRENT_CW"

#------------------------------------------------------------------------------
# Update channel pointers
#------------------------------------------------------------------------------
log "Promoting release $RELEASE_ID to $CHANNEL channel..."

# RPM channel pointer
echo -n "${RPM_PREFIX}" | aws s3 cp - "s3://$BUCKET/repo/rpm/channels/$CHANNEL" \
    --content-type "text/plain" \
    --metadata "release-id=$RELEASE_ID,promoted-at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Updated: repo/rpm/channels/$CHANNEL"

# Pip channel pointer
echo -n "${PIP_PREFIX}" | aws s3 cp - "s3://$BUCKET/repo/pip/channels/$CHANNEL" \
    --content-type "text/plain" \
    --metadata "release-id=$RELEASE_ID,promoted-at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Updated: repo/pip/channels/$CHANNEL"

# CW Agent channel pointer
echo -n "${CW_PREFIX}" | aws s3 cp - "s3://$BUCKET/repo/cw-agent/channels/$CHANNEL" \
    --content-type "text/plain" \
    --metadata "release-id=$RELEASE_ID,promoted-at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Updated: repo/cw-agent/channels/$CHANNEL"

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo ""
log "========================================="
log "Promotion complete"
log "========================================="
log "Channel:    $CHANNEL"
log "Release:    $RELEASE_ID"
log "Bucket:     $BUCKET"
echo ""
log "Next (day-1_phase-4): Set enable_ec2=true in terraform.tfvars, then: terraform apply"
log "Rollback (day-2+):    ./tools/3-rollback_channel.sh $CHANNEL <release_id> $BUCKET"
