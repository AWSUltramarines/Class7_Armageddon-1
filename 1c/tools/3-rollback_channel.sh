#!/bin/bash
#------------------------------------------------------------------------------
# 3-rollback_channel.sh - Rollback a channel to a previous release
#------------------------------------------------------------------------------
# Pipeline phase: day-2+ (Rollback Operations)
#
# Points channel pointers back to a previous release. Functionally identical
# to 2-promote_channel.sh; this wrapper provides semantic clarity.
#
# Usage:
#   ./tools/3-rollback_channel.sh <channel> <release_id> <bucket_name>
#   ./tools/3-rollback_channel.sh prod 2026-01-28T1200Z my-bucket-abc123
#
# Release ID format:
#   Use ISO 8601 timestamps (e.g., 2026-01-28T1200Z) for chronological ordering
#   and immutability.
#
# Prerequisites:
#   - Target release must exist in S3 (old releases are preserved)
#   - AWS credentials configured
#
# System packages:
#   - aws-cli (v2 recommended)
#
# Environment variables:
#   ARCH         - Architecture (default: x86_64)
#   PYTHON_VER   - Python version (default: py39)
#
# This script delegates to 2-promote_channel.sh, which performs all
# validation (manifest, signature, artifacts) before updating pointers.
#------------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

die() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <channel> <release_id> <bucket_name>"
    echo ""
    echo "Rollback promotes a previous release to the specified channel."
    echo ""
    echo "Arguments:"
    echo "  channel      Deployment channel: dev, stage, or prod"
    echo "  release_id   ISO 8601 timestamp to rollback to (e.g., 2026-01-28T1200Z)"
    echo "  bucket_name  S3 bucket name"
    echo ""
    echo "Example:"
    echo "  $0 prod 2026-01-28T1200Z my-bucket-abc123"
    exit 1
fi

CHANNEL="$1"

# Validate channel before delegating
case "$CHANNEL" in
    dev|stage|prod) ;;
    *) die "Invalid channel '$CHANNEL'. Must be: dev, stage, or prod" ;;
esac

echo -e "${YELLOW}[ROLLBACK]${NC} Rolling back $CHANNEL channel..."
echo ""

# Delegate to 2-promote_channel.sh
exec "$SCRIPT_DIR/2-promote_channel.sh" "$@"
