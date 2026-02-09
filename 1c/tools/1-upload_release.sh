#!/bin/bash
#------------------------------------------------------------------------------
# 1-upload_release.sh - Upload a signed release to S3
#------------------------------------------------------------------------------
# Pipeline phase: day-1_phase-2 (Upload Release)
#
# Uploads release artifacts to S3 without Terraform tracking. Using aws s3
# sync (without --delete) preserves old releases for rollback.
#
# Usage:
#   ./tools/1-upload_release.sh <release_id> <bucket_name>
#   ./tools/1-upload_release.sh 2026-01-29T1800Z my-bucket-abc123
#
# Release ID format:
#   Use ISO 8601 timestamps (e.g., 2026-01-29T1800Z) for chronological ordering
#   and immutability.
#
# Prerequisites:
#   - day-0_phase-2 complete: ./tools/0-build_release.sh <release_id>
#   - day-1_phase-1 complete: terraform apply (with fingerprints in terraform.tfvars)
#   - AWS credentials configured
#
# System packages:
#   - aws-cli (v2 recommended)
#
# Network:
#   Internet access required (AWS S3 endpoints)
#
# Previous phase: day-1_phase-1 (terraform apply)
# Next phase: day-1_phase-3 (./tools/2-promote_channel.sh)
#------------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[UPLOAD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
die() { error "$1"; exit 1; }

#------------------------------------------------------------------------------
# Argument parsing
#------------------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <release_id> <bucket_name>"
    echo ""
    echo "Arguments:"
    echo "  release_id   ISO 8601 timestamp (e.g., 2026-01-29T1800Z)"
    echo "  bucket_name  S3 bucket name (from terraform output)"
    echo ""
    echo "Example:"
    echo "  $0 2026-01-29T1800Z lab1c-test-deps-abc123"
    echo ""
    echo "Get bucket name from Terraform:"
    echo "  terraform output deps_bucket_name"
    exit 1
fi

RELEASE_ID="$1"
BUCKET="$2"

# Validate release_id format.
# Expected: ISO 8601 timestamp (e.g., 2026-01-29T1800Z) for path safety.
if [[ ! "$RELEASE_ID" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    die "Invalid release_id format. Expected ISO 8601 timestamp (e.g., 2026-01-29T1800Z). Use only alphanumeric characters, dots, underscores, and hyphens."
fi

#------------------------------------------------------------------------------
# Verify build output exists
#------------------------------------------------------------------------------
OUT_DIR="$PROJECT_DIR/out"

if [[ ! -d "$OUT_DIR" ]]; then
    die "Build output not found. Run: ./tools/0-build_release.sh $RELEASE_ID"
fi

MANIFEST_FILE="$OUT_DIR/manifests/$RELEASE_ID.json"
if [[ ! -f "$MANIFEST_FILE" ]]; then
    die "Manifest not found: $MANIFEST_FILE"
fi

#------------------------------------------------------------------------------
# Verify signature exists
#------------------------------------------------------------------------------
SIG_FILE="$OUT_DIR/manifests/$RELEASE_ID.json.sig"
if [[ ! -f "$SIG_FILE" ]]; then
    die "Signature not found. Release must be signed. Run: ./tools/0-build_release.sh $RELEASE_ID"
fi

# Verify signature is not a placeholder (sanity check for corrupted builds)
if grep -q "^UNSIGNED" "$SIG_FILE" 2>/dev/null; then
    die "Release is unsigned. Rebuild with: ./tools/0-build_release.sh $RELEASE_ID"
fi

log "Signature verified: $(basename "$SIG_FILE")"

log "Uploading release: $RELEASE_ID"
log "Target bucket: s3://$BUCKET"
log "Source: $OUT_DIR"

#------------------------------------------------------------------------------
# Verify bucket exists
#------------------------------------------------------------------------------
log "Verifying bucket..."
if ! aws s3 ls "s3://$BUCKET" &>/dev/null; then
    die "Bucket not accessible: $BUCKET. Run: terraform apply"
fi

#------------------------------------------------------------------------------
# Upload release artifacts
#------------------------------------------------------------------------------
log "Uploading release artifacts..."

# Upload RPM repository
RPM_SOURCE="$OUT_DIR/repo/rpm/releases/$RELEASE_ID"
if [[ -d "$RPM_SOURCE" ]]; then
    log "Uploading RPM packages..."
    aws s3 sync "$RPM_SOURCE" "s3://$BUCKET/repo/rpm/releases/$RELEASE_ID/" \
        --no-progress
    RPM_COUNT=$(find "$RPM_SOURCE" -name "*.rpm" | wc -l)
    log "Uploaded $RPM_COUNT RPM packages"
else
    warn "RPM source not found: $RPM_SOURCE"
fi

# Upload pip wheelhouse
PIP_SOURCE="$OUT_DIR/repo/pip/releases/$RELEASE_ID"
if [[ -d "$PIP_SOURCE" ]]; then
    log "Uploading pip wheels..."
    aws s3 sync "$PIP_SOURCE" "s3://$BUCKET/repo/pip/releases/$RELEASE_ID/" \
        --no-progress
    WHEEL_COUNT=$(find "$PIP_SOURCE" -name "*.whl" | wc -l)
    log "Uploaded $WHEEL_COUNT wheel packages"
else
    warn "Pip source not found: $PIP_SOURCE"
fi

# Upload CloudWatch agent
CW_SOURCE="$OUT_DIR/repo/cw-agent/releases/$RELEASE_ID"
if [[ -d "$CW_SOURCE" ]]; then
    log "Uploading CloudWatch agent..."
    aws s3 sync "$CW_SOURCE" "s3://$BUCKET/repo/cw-agent/releases/$RELEASE_ID/" \
        --no-progress
    log "Uploaded CloudWatch agent"
else
    warn "CW agent source not found: $CW_SOURCE"
fi

# Upload manifest and signature
MANIFEST_SOURCE="$OUT_DIR/manifests"
if [[ -d "$MANIFEST_SOURCE" ]]; then
    log "Uploading manifest and signature..."
    for file in "$MANIFEST_SOURCE/$RELEASE_ID".json*; do
        if [[ -f "$file" ]]; then
            aws s3 cp "$file" "s3://$BUCKET/manifests/" --no-progress
        fi
    done
    log "Uploaded manifest files"
else
    warn "Manifest source not found: $MANIFEST_SOURCE"
fi

# Upload GPG public keys (3-key model)
KEYS_SOURCE="$PROJECT_DIR/keys"
REQUIRED_KEYS=("release-signing-public.gpg" "repo-metadata-signing-public.gpg" "rpm-packages-signing-public.gpg")
for keyfile in "${REQUIRED_KEYS[@]}"; do
    if [[ ! -f "$KEYS_SOURCE/$keyfile" ]]; then
        die "GPG public key not found: $KEYS_SOURCE/$keyfile"
    fi
done
log "Uploading GPG public keys (3-key model)..."
aws s3 sync "$KEYS_SOURCE" "s3://$BUCKET/keys/" --no-progress
log "Uploaded ${#REQUIRED_KEYS[@]} GPG public keys"

#------------------------------------------------------------------------------
# Verify upload
#------------------------------------------------------------------------------
log "Verifying upload..."

verify_prefix() {
    local prefix="$1"
    local desc="$2"
    if aws s3 ls "s3://$BUCKET/$prefix" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $desc"
        return 0
    else
        echo -e "  ${RED}✗${NC} $desc"
        return 1
    fi
}

ERRORS=0
verify_prefix "manifests/$RELEASE_ID.json" "Manifest" || ((ERRORS++))
verify_prefix "manifests/$RELEASE_ID.json.sig" "Signature" || ((ERRORS++))
verify_prefix "repo/rpm/releases/$RELEASE_ID/" "RPM repo" || ((ERRORS++))
verify_prefix "repo/pip/releases/$RELEASE_ID/" "Pip wheelhouse" || ((ERRORS++))
verify_prefix "repo/cw-agent/releases/$RELEASE_ID/" "CW agent" || ((ERRORS++))
verify_prefix "keys/release-signing-public.gpg" "Release signing key" || ((ERRORS++))
verify_prefix "keys/repo-metadata-signing-public.gpg" "Repo metadata signing key" || ((ERRORS++))
verify_prefix "keys/rpm-packages-signing-public.gpg" "RPM packages signing key" || ((ERRORS++))

if [[ $ERRORS -gt 0 ]]; then
    die "Upload verification failed"
fi

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo ""
log "========================================="
log "Upload complete"
log "========================================="
log "Release:  $RELEASE_ID"
log "Bucket:   $BUCKET"
echo ""
log "Next (day-1_phase-3): ./tools/2-promote_channel.sh dev $RELEASE_ID $BUCKET"
