#!/bin/bash
#------------------------------------------------------------------------------
# 0-build_release.sh - Build a signed release for the offline repository
#------------------------------------------------------------------------------
# Pipeline phase: day-0_phase-2 (Build Signed Release)
#
# Creates a complete, signed release in out/ ready for upload to S3.
#
# Output structure:
#   out/repo/rpm/releases/<release_id>/x86_64/  - RPMs + repodata
#   out/repo/pip/releases/<release_id>/py39/    - Wheels + requirements.lock
#   out/repo/cw-agent/releases/<release_id>/    - CloudWatch agent RPM
#   out/manifests/<release_id>.json             - Release manifest
#   out/manifests/<release_id>.json.sig         - GPG signature
#   out/manifests/<release_id>.json.sha256      - SHA256 checksum
#
# Usage:
#   ./tools/0-build_release.sh <release_id>
#   ./tools/0-build_release.sh 2026-01-29T1800Z
#
# Release ID format:
#   Use ISO 8601 timestamps (e.g., 2026-01-29T1800Z) for chronological ordering,
#   immutability, and filesystem safety. Only alphanumeric, dots, underscores,
#   and hyphens are permitted.
#
# Signing model (3 role-specific keys):
#   RELEASE_GPG_KEY_ID  - Signs the release manifest (.json.sig)
#   REPO_GPG_KEY_ID     - Signs repodata/repomd.xml (.xml.asc)
#   RPM_GPG_KEY_ID      - Signs individual RPM packages (rpmsign)
#
#   If only one GPG secret key exists, all three default to it.
#   If multiple keys exist and an env var is unset, the build fails with
#   instructions.
#
# Non-interactive signing:
#   Set GPG_PASSPHRASE_FILE or GPG_PASSPHRASE to enable loopback pinentry.
#   All GPG and rpmsign operations are wrapped with a timeout safety net
#   (default 30s, override with SIGN_TIMEOUT).
#
# Self-contained signing (does NOT modify ~/.gnupg):
#   All signing operations use a temporary GNUPGHOME with COPIES of mutable
#   keyring files (pubring.kbx, trustdb.gpg) and a symlink only for the
#   private key directory (private-keys-v1.d). The temp dir gets its own
#   gpg-agent.conf (with allow-loopback-pinentry) and .rpmmacros for
#   rpmsign. A post-build mtime assertion verifies the real keyring was
#   not modified. Everything is cleaned up on exit.
#
# Prerequisites:
#   GPG signing key(s) must be configured. Generate with:
#     gpg --full-generate-key
#
# System packages:
#   - createrepo_c (or createrepo)          Generate RPM repository metadata
#   - python3 (3.9+)                        Required for pip operations
#   - python3-pip                           Download wheel packages
#   - curl or wget                          Download CloudWatch agent
#   - gpg                                   Sign release manifests
#   - rpmsign (rpm-sign)                    Sign RPM packages
#
# Install on Debian/Ubuntu:
#   sudo apt install createrepo-c python3 python3-pip curl gnupg rpm
#
# Note: AL2023 CDN (cdn.amazonlinux.com) restricts access to EC2 instances.
# RPMs are sourced from deps/rpm/al2023-minrepo/ which must be pre-populated.
#
# Network:
#   Internet access required (PyPI, Amazon Linux repos, AWS S3)
#
# Environment variables:
#   ARCH                  - Architecture (default: x86_64)
#   PYTHON_VER            - Python version (default: py39)
#   RELEASE_GPG_KEY_ID    - GPG key ID for manifest signing
#   REPO_GPG_KEY_ID       - GPG key ID for repomd.xml signing
#   RPM_GPG_KEY_ID        - GPG key ID for RPM package signing
#   GPG_PASSPHRASE_FILE   - Path to file containing GPG passphrase (preferred)
#   GPG_PASSPHRASE        - GPG passphrase string (written to temp file)
#   SIGN_TIMEOUT          - Timeout for each signing operation (default: 30)
#
# Next phase: day-1_phase-1 (terraform apply with fingerprints in tfvars), then day-1_phase-2
#------------------------------------------------------------------------------
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCH="${ARCH:-x86_64}"
PYTHON_VER="${PYTHON_VER:-py39}"

# 3-key model: role-specific GPG key IDs
RELEASE_GPG_KEY_ID="${RELEASE_GPG_KEY_ID:-}"
REPO_GPG_KEY_ID="${REPO_GPG_KEY_ID:-}"
RPM_GPG_KEY_ID="${RPM_GPG_KEY_ID:-}"

# Non-interactive signing
GPG_PASSPHRASE_FILE="${GPG_PASSPHRASE_FILE:-}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
SIGN_TIMEOUT="${SIGN_TIMEOUT:-30}"

# CloudWatch agent URL (latest version for AL2023/x86_64)
CW_AGENT_URL="https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
die() { error "$1"; exit 1; }

#------------------------------------------------------------------------------
# Argument parsing
#------------------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <release_id>"
    echo ""
    echo "Arguments:"
    echo "  release_id   ISO 8601 timestamp (e.g., 2026-01-29T1800Z)"
    echo ""
    echo "Example:"
    echo "  $0 2026-01-29T1800Z"
    echo ""
    echo "Environment variables:"
    echo "  ARCH                  Architecture (default: x86_64)"
    echo "  PYTHON_VER            Python version (default: py39)"
    echo "  RELEASE_GPG_KEY_ID    GPG key for manifest signing"
    echo "  REPO_GPG_KEY_ID       GPG key for repomd.xml signing"
    echo "  RPM_GPG_KEY_ID        GPG key for RPM package signing"
    echo "  GPG_PASSPHRASE_FILE   Path to passphrase file (for non-interactive signing)"
    echo "  GPG_PASSPHRASE        Passphrase string (fallback; prefer file)"
    echo "  SIGN_TIMEOUT          Signing timeout in seconds (default: 30)"
    exit 1
fi

RELEASE_ID="$1"

# Validate release_id format.
# Expected: ISO 8601 timestamp (e.g., 2026-01-29T1800Z) for chronological ordering
# and immutability. Regex ensures path safety across filesystems and S3.
if [[ ! "$RELEASE_ID" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    die "Invalid release_id format. Expected ISO 8601 timestamp (e.g., 2026-01-29T1800Z). Use only alphanumeric characters, dots, underscores, and hyphens."
fi

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Resolve a GPG key ID: use explicit env var, or auto-detect if exactly 1 key exists
resolve_key_id() {
    local env_val="$1"
    local label="$2"

    if [[ -n "$env_val" ]]; then
        # Verify the key exists
        if ! gpg --list-secret-keys "$env_val" &>/dev/null; then
            die "$label='$env_val' not found in keyring"
        fi
        echo "$env_val"
        return
    fi

    local count
    count=$(gpg --list-secret-keys --with-colons 2>/dev/null | grep -c '^sec:' || true)

    case "$count" in
        0) die "No GPG secret keys found. Generate with: gpg --full-generate-key" ;;
        1) gpg --list-secret-keys --with-colons 2>/dev/null \
               | awk -F: '/^sec:/{print $5; exit}' ;;
        *) die "Multiple GPG keys found; set $label explicitly.
Available keys:
$(gpg --list-secret-keys --keyid-format long 2>/dev/null)" ;;
    esac
}

# Extract 40-char fingerprint for a key ID
get_key_fingerprint() {
    local key_id="$1"
    local fpr
    fpr=$(gpg --fingerprint --with-colons "$key_id" 2>/dev/null \
        | awk -F: '/^fpr:/{print $10; exit}')
    [[ -n "$fpr" ]] || die "Cannot extract fingerprint for key: $key_id"
    echo "$fpr"
}

# Sign a file with GPG (detached, armored). Uses loopback pinentry + timeout.
gpg_sign_file() {
    local key_id="$1"
    local input_file="$2"
    local output_file="$3"

    local gpg_opts=(--batch --yes --armor --detach-sign
                    --local-user "$key_id"
                    --output "$output_file")

    if [[ -n "${PASSPHRASE_FILE:-}" ]]; then
        gpg_opts+=(--pinentry-mode loopback --passphrase-file "$PASSPHRASE_FILE")
    fi

    if ! timeout "${SIGN_TIMEOUT}s" gpg "${gpg_opts[@]}" "$input_file"; then
        die "GPG signing failed or timed out (${SIGN_TIMEOUT}s): $(basename "$input_file")"
    fi
}

# Sign an RPM with rpmsign using a temp .rpmmacros file.
# Instead of the fragile inline %__gpg_sign_cmd --define override, we write
# stable macros to $SIGN_TMPDIR/.rpmmacros and override HOME for the rpmsign
# call so it reads our temp file (not ~/.rpmmacros).
# GNUPGHOME (exported) still points to SIGN_GNUPGHOME for key access.
rpmsign_rpm() {
    local key_id="$1"
    local rpm_file="$2"

    # Write temp rpmmacros file in the signing workspace.
    # rpmsign reads $HOME/.rpmmacros; we override HOME to SIGN_TMPDIR
    # so the user's real ~/.rpmmacros is never read or written.
    local macros_file="$SIGN_TMPDIR/.rpmmacros"
    cat > "$macros_file" << MACROS_EOF
%_signature gpg
%_gpg_name $key_id
%_gpgbin /usr/bin/gpg
%__gpg /usr/bin/gpg
MACROS_EOF

    if [[ -n "${PASSPHRASE_FILE:-}" ]]; then
        cat >> "$macros_file" << MACROS_EOF
%__gpg_sign_cmd %{__gpg} --batch --yes --pinentry-mode loopback --passphrase-file $PASSPHRASE_FILE -u "%{_gpg_name}" -sbo %{__signature_filename} -- %{__plaintext_filename}
MACROS_EOF
    fi

    # Override HOME so rpmsign reads our temp .rpmmacros, not ~/.rpmmacros.
    HOME="$SIGN_TMPDIR" timeout "${SIGN_TIMEOUT}s" rpmsign --addsign "$rpm_file" \
        || die "RPM signing failed or timed out (${SIGN_TIMEOUT}s): $(basename "$rpm_file")"
}

#------------------------------------------------------------------------------
# Validate required tools
#------------------------------------------------------------------------------
log "Checking required tools..."

missing_tools=()

# Check for createrepo
if ! command -v createrepo_c &>/dev/null && ! command -v createrepo &>/dev/null; then
    missing_tools+=("createrepo_c (or createrepo)")
fi

# Check for python3 and pip
if ! command -v python3 &>/dev/null; then
    missing_tools+=("python3")
elif ! python3 -m pip --version &>/dev/null; then
    missing_tools+=("python3-pip")
fi

# Check for GPG
if ! command -v gpg &>/dev/null; then
    missing_tools+=("gpg")
fi

# Check for rpmsign (RPM package signing)
if ! command -v rpmsign &>/dev/null; then
    missing_tools+=("rpmsign (rpm-sign package)")
fi

# Check for timeout (coreutils)
if ! command -v timeout &>/dev/null; then
    missing_tools+=("timeout (coreutils)")
fi

# Check for sha256sum (coreutils) — used for keyring isolation assertion
if ! command -v sha256sum &>/dev/null; then
    missing_tools+=("sha256sum (coreutils)")
fi

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    die "Missing required tools: ${missing_tools[*]}"
fi

log "Required tools verified (createrepo, python3, pip, gpg, rpmsign, timeout, sha256sum)"

#------------------------------------------------------------------------------
# Resolve GPG Keys (3-key model)
#------------------------------------------------------------------------------
# Key resolution uses the real GNUPGHOME (read-only: --list-secret-keys,
# --fingerprint). This runs BEFORE we create the temp signing environment.
log "Resolving GPG signing keys..."

RELEASE_KEY=$(resolve_key_id "$RELEASE_GPG_KEY_ID" "RELEASE_GPG_KEY_ID")
REPO_KEY=$(resolve_key_id "$REPO_GPG_KEY_ID" "REPO_GPG_KEY_ID")
RPM_KEY=$(resolve_key_id "$RPM_GPG_KEY_ID" "RPM_GPG_KEY_ID")

RELEASE_FPR=$(get_key_fingerprint "$RELEASE_KEY")
REPO_FPR=$(get_key_fingerprint "$REPO_KEY")
RPM_FPR=$(get_key_fingerprint "$RPM_KEY")

log "Release manifest key: $RELEASE_KEY (fpr: $RELEASE_FPR)"
log "Repo metadata key:    $REPO_KEY (fpr: $REPO_FPR)"
log "RPM packages key:     $RPM_KEY (fpr: $RPM_FPR)"

#------------------------------------------------------------------------------
# Setup Non-Interactive Signing (passphrase + self-contained GNUPGHOME)
#------------------------------------------------------------------------------
# Approach: create a temporary GNUPGHOME with COPIES of mutable keyring
# files and a SYMLINK only for the private key directory.
#
# Why copy pubring.kbx/trustdb.gpg instead of symlink:
#   GPG writes through symlinks. Operations like --import, --export, and
#   even --verify can trigger trustdb updates or keyring auto-migration.
#   Symlinking these files would silently mutate the real ~/.gnupg,
#   violating our "never modify the user's keyring" guarantee.
#
# Why symlink private-keys-v1.d:
#   GnuPG 2.2+ stores private keys in private-keys-v1.d/ managed by
#   gpg-agent. Exporting secret keys via --export-secret-keys may itself
#   require passphrase confirmation through the agent (chicken-and-egg
#   with loopback pinentry). The agent only reads key files during signing;
#   it does not write new files into this directory during normal operations.
#   A symlink here is safe and avoids the export problem.
#
# Lock/socket isolation:
#   With a separate GNUPGHOME, GPG places .lock files, agent sockets, and
#   any other transient state inside the temp dir — not in ~/.gnupg.
#
# Safety assertion:
#   We record mtimes of the real pubring.kbx and trustdb.gpg before signing
#   and verify they are unchanged afterward. If they changed, the build fails.
#------------------------------------------------------------------------------
PASSPHRASE_FILE=""
PASSPHRASE_TMPFILE=""
SIGN_TMPDIR=""

# Global registry of temp files to remove on exit. Sections that create temp
# files via mktemp should append to this array instead of relying on cleanup()
# knowing their variable names. This stays correct even if sections are later
# refactored into functions where local variables would be invisible to cleanup().
CLEANUP_TMPFILES=()

cleanup() {
    # Capture the build exit code FIRST — cleanup must never change it.
    local build_rc=$?
    # Disable errexit so cleanup errors don't override build_rc.
    set +e
    # Kill gpg-agent for temp GNUPGHOME (if running)
    if [[ -n "${SIGN_GNUPGHOME:-}" && -d "${SIGN_GNUPGHOME:-}" ]]; then
        GNUPGHOME="$SIGN_GNUPGHOME" gpgconf --kill gpg-agent >/dev/null 2>&1 || true
    fi
    # Remove temp signing workspace (copies + symlink, not real key data)
    if [[ -n "${SIGN_TMPDIR:-}" && -d "${SIGN_TMPDIR:-}" ]]; then
        rm -rf "$SIGN_TMPDIR" 2>/dev/null || true
    fi
    # Shred passphrase temp file
    if [[ -n "${PASSPHRASE_TMPFILE:-}" && -f "${PASSPHRASE_TMPFILE:-}" ]]; then
        shred -u "$PASSPHRASE_TMPFILE" 2>/dev/null || rm -f "$PASSPHRASE_TMPFILE" 2>/dev/null || true
    fi
    # Remove any registered temp files
    local _f
    for _f in "${CLEANUP_TMPFILES[@]+"${CLEANUP_TMPFILES[@]}"}"; do
        rm -f "$_f" 2>/dev/null || true
    done
    # Log cleanup outcome without changing build exit code
    if [[ $build_rc -ne 0 ]]; then
        echo -e "${YELLOW:-}[WARN]${NC:-} Build failed (exit $build_rc). Cleanup completed." >&2
    fi
    exit "$build_rc"
}
trap cleanup EXIT

# --- Passphrase handling ---
if [[ -n "$GPG_PASSPHRASE_FILE" ]]; then
    [[ -f "$GPG_PASSPHRASE_FILE" ]] || die "GPG_PASSPHRASE_FILE not found: $GPG_PASSPHRASE_FILE"
    PASSPHRASE_FILE="$GPG_PASSPHRASE_FILE"
    log "Non-interactive signing: passphrase from file"
elif [[ -n "$GPG_PASSPHRASE" ]]; then
    PASSPHRASE_TMPFILE=$(mktemp)
    chmod 600 "$PASSPHRASE_TMPFILE"
    printf '%s' "$GPG_PASSPHRASE" > "$PASSPHRASE_TMPFILE"
    PASSPHRASE_FILE="$PASSPHRASE_TMPFILE"
    log "Non-interactive signing: passphrase from environment"
else
    warn "No passphrase configured; GPG may prompt interactively (timeout: ${SIGN_TIMEOUT}s)"
fi

# --- Self-contained signing environment ---
# Discover the real GNUPGHOME before we override it.
REAL_GNUPGHOME="$(gpgconf --list-dirs homedir 2>/dev/null || echo "$HOME/.gnupg")"

SIGN_TMPDIR="$(mktemp -d)"
chmod 700 "$SIGN_TMPDIR"

SIGN_GNUPGHOME="$SIGN_TMPDIR/.gnupg"
mkdir -p "$SIGN_GNUPGHOME"
chmod 700 "$SIGN_GNUPGHOME"

# COPY mutable keyring files so GPG writes hit the temp copies, not originals.
# cp -a preserves permissions/timestamps; || true handles missing files.
cp -a "$REAL_GNUPGHOME/pubring.kbx" "$SIGN_GNUPGHOME/" 2>/dev/null || true
cp -a "$REAL_GNUPGHOME/pubring.gpg" "$SIGN_GNUPGHOME/" 2>/dev/null || true
cp -a "$REAL_GNUPGHOME/trustdb.gpg" "$SIGN_GNUPGHOME/" 2>/dev/null || true

# SYMLINK private key directory only — gpg-agent reads (not writes) these
# files during signing. This avoids the export-requires-passphrase problem.
if [[ -d "$REAL_GNUPGHOME/private-keys-v1.d" ]]; then
    ln -s "$REAL_GNUPGHOME/private-keys-v1.d" "$SIGN_GNUPGHOME/private-keys-v1.d"
fi
# openpgp-revocs.d is read-only reference material (revocation certs)
if [[ -d "$REAL_GNUPGHOME/openpgp-revocs.d" ]]; then
    ln -s "$REAL_GNUPGHOME/openpgp-revocs.d" "$SIGN_GNUPGHOME/openpgp-revocs.d"
fi

# Copy gpg.conf if it exists (user preferences — not modified by us)
if [[ -f "$REAL_GNUPGHOME/gpg.conf" ]]; then
    cp "$REAL_GNUPGHOME/gpg.conf" "$SIGN_GNUPGHOME/gpg.conf" 2>/dev/null || true
fi

# Write gpg-agent.conf in temp dir ONLY (never touches real ~/.gnupg).
if [[ -n "$PASSPHRASE_FILE" ]]; then
    echo "allow-loopback-pinentry" > "$SIGN_GNUPGHOME/gpg-agent.conf"
    log "Temp gpg-agent.conf: allow-loopback-pinentry enabled"
fi

# Record mtimes + SHA256 of real keyring files BEFORE signing for safety assertion.
# - mtime:  always enforced (fast signal)
# - SHA256: enforced when successfully captured (authoritative)
# - empty hash → warning logged + mtime-only fallback (build continues)
MTIME_PUBRING_BEFORE=""
MTIME_TRUSTDB_BEFORE=""
SHA256_PUBRING_BEFORE=""
SHA256_TRUSTDB_BEFORE=""
if [[ -f "$REAL_GNUPGHOME/pubring.kbx" ]]; then
    MTIME_PUBRING_BEFORE=$(stat -c%Y "$REAL_GNUPGHOME/pubring.kbx" 2>/dev/null \
        || stat -f%m "$REAL_GNUPGHOME/pubring.kbx" 2>/dev/null || echo "")
    SHA256_PUBRING_BEFORE=$(sha256sum "$REAL_GNUPGHOME/pubring.kbx" 2>/dev/null | awk '{print $1}' || true)
    if [[ -z "$SHA256_PUBRING_BEFORE" ]]; then
        warn "Could not compute SHA256 for $REAL_GNUPGHOME/pubring.kbx; falling back to mtime-only check"
    fi
fi
if [[ -f "$REAL_GNUPGHOME/trustdb.gpg" ]]; then
    MTIME_TRUSTDB_BEFORE=$(stat -c%Y "$REAL_GNUPGHOME/trustdb.gpg" 2>/dev/null \
        || stat -f%m "$REAL_GNUPGHOME/trustdb.gpg" 2>/dev/null || echo "")
    SHA256_TRUSTDB_BEFORE=$(sha256sum "$REAL_GNUPGHOME/trustdb.gpg" 2>/dev/null | awk '{print $1}' || true)
    if [[ -z "$SHA256_TRUSTDB_BEFORE" ]]; then
        warn "Could not compute SHA256 for $REAL_GNUPGHOME/trustdb.gpg; falling back to mtime-only check"
    fi
fi

# Switch to temp GNUPGHOME for all subsequent GPG operations.
# The first gpg call will auto-start an agent that reads our temp config.
export GNUPGHOME="$SIGN_GNUPGHOME"
gpgconf --reload gpg-agent 2>/dev/null || true

log "Self-contained signing environment ready: $SIGN_TMPDIR"
log "  Temp GNUPGHOME: $SIGN_GNUPGHOME (copies + private-keys-v1.d symlink)"
log "  Real ~/.gnupg:  $REAL_GNUPGHOME (must remain untouched)"

#------------------------------------------------------------------------------
# Setup directories
#------------------------------------------------------------------------------
OUT_DIR="$PROJECT_DIR/out"
RPM_DIR="$OUT_DIR/repo/rpm/releases/$RELEASE_ID/$ARCH"
PIP_DIR="$OUT_DIR/repo/pip/releases/$RELEASE_ID/$PYTHON_VER"
CW_DIR="$OUT_DIR/repo/cw-agent/releases/$RELEASE_ID"
MANIFEST_DIR="$OUT_DIR/manifests"
WHEELS_DIR="$PIP_DIR/wheels"

log "Building release: $RELEASE_ID"
log "Output directory: $OUT_DIR"

# Clean and create directories
rm -rf "$OUT_DIR"
mkdir -p "$RPM_DIR" "$WHEELS_DIR" "$CW_DIR" "$MANIFEST_DIR"

#------------------------------------------------------------------------------
# Build RPM Repository
#------------------------------------------------------------------------------
log "Building RPM repository..."

# RPM source: deps/rpm/al2023-minrepo/
# This directory must be pre-populated with AL2023 RPMs before running this script.
# AL2023 CDN (cdn.amazonlinux.com) restricts access to EC2 instances only, so these
# packages cannot be fetched from a local workstation. Use tools/fetch-al2023-rpms.sh
# on an AL2023 EC2 instance to refresh the cache.
RPM_SOURCE="$PROJECT_DIR/deps/rpm/al2023-minrepo"

if [[ ! -d "$RPM_SOURCE" ]]; then
    die "RPM source directory not found: $RPM_SOURCE
This directory must be pre-populated with AL2023 RPMs.
Amazon Linux 2023 packages can only be downloaded from EC2 instances (CDN restriction).
Refresh the RPM cache: ./tools/fetch-al2023-rpms.sh (run on an AL2023 EC2 instance)"
fi

log "Copying RPM packages from $RPM_SOURCE"

# Copy pre-populated RPMs to release directory (flat).
# RPMs are inputs (from deps/), not fetched by this script.
# Fail-closed: abort on duplicate basenames to prevent silent overwrites.

# Phase 1: detect duplicate basenames across all subdirs (NUL-delimited).
declare -A _rpm_seen=()   # basename -> first full path (or "DUP" after collision)
_rpm_dupes=0

while IFS= read -r -d '' _rpm_path; do
    _rpm_base="${_rpm_path##*/}"
    if [[ -n "${_rpm_seen[$_rpm_base]+x}" ]]; then
        # First collision for this basename: log both the original and the dup
        if [[ "${_rpm_seen[$_rpm_base]}" != "DUP" ]]; then
            error "Duplicate RPM basename '$_rpm_base':"
            error "  1) ${_rpm_seen[$_rpm_base]}"
            _rpm_seen[$_rpm_base]="DUP"
        fi
        # Subsequent collisions: log each additional path
        error "  *) $_rpm_path"
        _rpm_dupes=1
    else
        _rpm_seen[$_rpm_base]="$_rpm_path"
    fi
done < <(find "$RPM_SOURCE" -type f -name "*.rpm" -print0)

# Phase 2: abort if any duplicates were found (nothing copied yet).
if (( _rpm_dupes )); then
    die "Duplicate RPM basenames detected — aborting (no files copied)"
fi

# Phase 3: no duplicates — batch-copy all RPMs into flat dir.
# -exec {} + is safe for special chars and is a no-op on zero matches
# (letting downstream RPM_COUNT handle the empty-source case).
find "$RPM_SOURCE" -type f -name "*.rpm" -exec cp -t "$RPM_DIR/" {} +
unset _rpm_seen _rpm_dupes _rpm_base _rpm_path

# Fail-fast: verify RPMs were copied from the pre-populated source.
RPM_COUNT=$(find "$RPM_DIR" -name "*.rpm" 2>/dev/null | wc -l)
if [[ "$RPM_COUNT" -eq 0 ]]; then
    die "No RPM packages found in $RPM_SOURCE
The RPM source directory exists but contains no .rpm files.
AL2023 packages must be pre-populated before building a release.
Refresh the RPM cache: ./tools/fetch-al2023-rpms.sh (run on an AL2023 EC2 instance)"
fi
log "Copied $RPM_COUNT RPM packages"

# Sign RPM packages (before createrepo so metadata reflects signed RPMs)
log "Signing RPM packages with rpmsign (key: $RPM_KEY)..."
for rpm_file in "$RPM_DIR"/*.rpm; do
    rpmsign_rpm "$RPM_KEY" "$rpm_file"
done
log "Signed $RPM_COUNT RPM packages"

# Create repository metadata (required for offline dnf repo)
if command -v createrepo_c &>/dev/null; then
    log "Creating repository metadata with createrepo_c..."
    createrepo_c "$RPM_DIR" || die "createrepo_c failed"
elif command -v createrepo &>/dev/null; then
    log "Creating repository metadata with createrepo..."
    createrepo "$RPM_DIR" || die "createrepo failed"
else
    # This shouldn't happen due to upfront check, but be defensive
    die "createrepo_c/createrepo not found. Install with: dnf install createrepo_c"
fi

# Verify repodata was created
if [[ ! -d "$RPM_DIR/repodata" ]]; then
    die "repodata directory not created in $RPM_DIR"
fi
log "RPM repository metadata created"

# Sign repodata/repomd.xml for DNF repo_gpgcheck (detached ASCII-armored signature)
log "Signing repodata/repomd.xml (key: $REPO_KEY)..."
gpg_sign_file "$REPO_KEY" "$RPM_DIR/repodata/repomd.xml" "$RPM_DIR/repodata/repomd.xml.asc"
log "repomd.xml signature created"

#------------------------------------------------------------------------------
# Build Pip Wheelhouse with Lock
#------------------------------------------------------------------------------
log "Building pip wheelhouse..."

# Define required packages with version constraints
# Flask app dependencies with Python 3.9 compatibility constraints
cat > "$PIP_DIR/requirements.in" << 'REQUIREMENTS'
# Flask application dependencies
# Constrained for Python 3.9 compatibility
flask>=3.0,<4.0
pymysql>=1.0,<2.0

# Required for Python < 3.10 (conditional dependency of Flask)
# Must be explicitly included because pip download on Python 3.10+
# won't fetch these conditional dependencies automatically
importlib-metadata>=3.6.0
zipp>=0.5

# Note: Click must be < 8.2 for Python 3.9 compatibility
# MarkupSafe must be a cp39 wheel, not cp313
REQUIREMENTS

# Download wheels (fail-closed: die on pip failure)
log "Downloading wheels..."
python3 -m pip download \
    --python-version 3.9 \
    --only-binary=:all: \
    --platform manylinux2014_x86_64 \
    --platform manylinux_2_17_x86_64 \
    --platform manylinux_2_28_x86_64 \
    --platform linux_x86_64 \
    --platform any \
    --dest "$WHEELS_DIR" \
    flask pymysql importlib-metadata zipp \
    || die "pip download failed (exit $?)"

# Count wheels (fail-closed: must have at least one)
WHEEL_COUNT=$(find "$WHEELS_DIR" -type f -name "*.whl" | wc -l)
if [[ "$WHEEL_COUNT" -eq 0 ]]; then
    die "No wheel packages downloaded to $WHEELS_DIR"
fi
log "Downloaded $WHEEL_COUNT wheel packages"

# Validate MarkupSafe ABI: must have a cp39-compatible wheel.
# Check ALL markupsafe wheels — reject if only incompatible tags exist.
_ms_found=0
_ms_compatible=0
while IFS= read -r -d '' _ms_whl; do
    _ms_found=1
    _ms_base="$(basename "$_ms_whl")"
    # Accept only cp39 ABI wheels. MarkupSafe is a C extension — a pure-python
    # (none-any) wheel would lack the compiled speedups and is unexpected here.
    if [[ "$_ms_base" == *-cp39-* ]]; then
        _ms_compatible=1
        log "MarkupSafe wheel (cp39-ok): $_ms_base"
    else
        error "MarkupSafe wheel (incompatible): $_ms_base"
    fi
done < <(find "$WHEELS_DIR" -type f -iname "markupsafe*.whl" -print0)

if [[ "$_ms_found" -eq 0 ]]; then
    die "MarkupSafe wheel not found in wheelhouse — required for Flask on Python 3.9"
fi
if [[ "$_ms_compatible" -eq 0 ]]; then
    die "No cp39-compatible MarkupSafe wheel found — all wheels have incompatible ABI tags"
fi
unset _ms_found _ms_compatible _ms_base _ms_whl

# Completeness check: required packages for air-gapped Flask install
_missing=()
for _req_pkg in flask click jinja2 itsdangerous werkzeug markupsafe; do
    # Match normalized name: underscores/hyphens/case variations in wheel filenames
    _pattern="$(echo "$_req_pkg" | tr '-' '_')"
    if ! find "$WHEELS_DIR" -type f -iname "${_pattern}-*.whl" -print -quit | grep -q .; then
        # Also try hyphenated form
        _pattern="$(echo "$_req_pkg" | tr '_' '-')"
        if ! find "$WHEELS_DIR" -type f -iname "${_pattern}-*.whl" -print -quit | grep -q .; then
            _missing+=("$_req_pkg")
        fi
    fi
done
if [[ ${#_missing[@]} -gt 0 ]]; then
    die "Missing required wheels for air-gapped install: ${_missing[*]}"
fi
unset _missing _req_pkg _pattern
log "Completeness check passed: all required packages present"

# Generate requirements.lock from shipped wheels (manual method — no pip-compile).
# Extract Name + Version from each wheel's METADATA via Python zipfile (stdlib).
log "Generating requirements.lock with hashes..."

# Collect "name==version hash" entries into a temp file so we can sort
# and detect METADATA extraction failures outside a pipeline (die works).
# Registered with CLEANUP_TMPFILES so cleanup() removes it on any exit path.
_lock_tmp=$(mktemp -t requirements-lock.XXXXXX)
CLEANUP_TMPFILES+=("$_lock_tmp")
while IFS= read -r -d '' _whl_path; do
    # Extract Name and Version from *.dist-info/METADATA inside the wheel
    _meta=$(python3 -c "
import zipfile, sys, re
with zipfile.ZipFile(sys.argv[1]) as zf:
    mdata = [n for n in zf.namelist() if n.endswith('.dist-info/METADATA')]
    if not mdata:
        sys.exit(1)
    text = zf.read(mdata[0]).decode('utf-8')
    name = version = ''
    for line in text.splitlines():
        if line.startswith('Name: '):
            name = line[6:].strip()
        elif line.startswith('Version: '):
            version = line[9:].strip()
        if name and version:
            break
    # PEP 503 normalization: lowercase, runs of [-_.] become single hyphen
    name = re.sub(r'[-_.]+', '-', name).lower()
    print(f'{name}=={version}')
" "$_whl_path") || die "Failed to read METADATA from $_whl_path"

    _hash=$(sha256sum "$_whl_path" | cut -d' ' -f1)
    echo "${_meta} ${_hash}" >> "$_lock_tmp"
done < <(find "$WHEELS_DIR" -type f -name "*.whl" -print0)

# Write header then sorted entries
{
    echo "# Auto-generated requirements.lock with hashes"
    echo "# Release: $RELEASE_ID"
    echo "#"
    echo "# Install with:"
    echo "#   pip install --no-index --find-links ./wheels --require-hashes -r requirements.lock"
    echo ""

    LC_ALL=C sort -t= -k1,1 "$_lock_tmp" | while IFS= read -r _line; do
        _spec="${_line% *}"
        _hash="${_line##* }"
        echo "${_spec} \\"
        echo "    --hash=sha256:${_hash}"
    done
} > "$PIP_DIR/requirements.lock"

# Early cleanup; CLEANUP_TMPFILES registry is the fail-safe on abnormal exit.
rm -f "$_lock_tmp"
unset _lock_tmp _whl_path _meta _hash _line _spec

# Generate SHA256 for requirements.lock
sha256sum "$PIP_DIR/requirements.lock" | cut -d' ' -f1 > "$PIP_DIR/requirements.lock.sha256"

log "Wheelhouse contains $WHEEL_COUNT packages"

#------------------------------------------------------------------------------
# Download CloudWatch Agent
#------------------------------------------------------------------------------
log "Downloading CloudWatch agent..."

if command -v curl &> /dev/null; then
    curl -fsSL -o "$CW_DIR/amazon-cloudwatch-agent.rpm" "$CW_AGENT_URL"
elif command -v wget &> /dev/null; then
    wget -q -O "$CW_DIR/amazon-cloudwatch-agent.rpm" "$CW_AGENT_URL"
else
    # Try to copy from existing deps
    if [[ -f "$PROJECT_DIR/deps/cw-agent/amazon-cloudwatch-agent.rpm" ]]; then
        cp "$PROJECT_DIR/deps/cw-agent/amazon-cloudwatch-agent.rpm" "$CW_DIR/"
        warn "Copied CW agent from existing deps (may be outdated)"
    else
        die "Neither curl nor wget available, and no existing CW agent found"
    fi
fi

CW_SIZE=$(du -h "$CW_DIR/amazon-cloudwatch-agent.rpm" | cut -f1)
log "CloudWatch agent downloaded: $CW_SIZE"

#------------------------------------------------------------------------------
# Generate Manifest (with signing fingerprints)
#------------------------------------------------------------------------------
log "Generating release manifest..."

# Build manifest JSON
cat > "$MANIFEST_DIR/$RELEASE_ID.json" << MANIFEST
{
  "release_id": "$RELEASE_ID",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "arch": "$ARCH",
  "python_version": "$PYTHON_VER",
  "signing": {
    "release_manifest_fpr": "$RELEASE_FPR",
    "repo_metadata_fpr": "$REPO_FPR",
    "rpm_packages_fpr": "$RPM_FPR"
  },
  "rpm": {
    "prefix": "repo/rpm/releases/$RELEASE_ID/$ARCH/",
    "packages": [
$(find "$RPM_DIR" -name "*.rpm" -type f | while read -r file; do
    rel_path="${file#"$OUT_DIR"/}"
    hash=$(sha256sum "$file" | cut -d' ' -f1)
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    echo "      {\"path\": \"$rel_path\", \"sha256\": \"$hash\", \"size\": $size}"
done | paste -sd ',' -)
    ],
    "repodata": [
      {
        "path": "repo/rpm/releases/$RELEASE_ID/$ARCH/repodata/repomd.xml",
        "sha256": "$(sha256sum "$RPM_DIR/repodata/repomd.xml" | cut -d' ' -f1)",
        "size": $(stat -f%z "$RPM_DIR/repodata/repomd.xml" 2>/dev/null || stat -c%s "$RPM_DIR/repodata/repomd.xml" 2>/dev/null || echo 0)
      },
      {
        "path": "repo/rpm/releases/$RELEASE_ID/$ARCH/repodata/repomd.xml.asc",
        "sha256": "$(sha256sum "$RPM_DIR/repodata/repomd.xml.asc" | cut -d' ' -f1)",
        "size": $(stat -f%z "$RPM_DIR/repodata/repomd.xml.asc" 2>/dev/null || stat -c%s "$RPM_DIR/repodata/repomd.xml.asc" 2>/dev/null || echo 0)
      }
    ]
  },
  "pip": {
    "prefix": "repo/pip/releases/$RELEASE_ID/$PYTHON_VER/",
    "wheels": [
$(find "$WHEELS_DIR" -name "*.whl" -type f | while read -r file; do
    rel_path="${file#"$OUT_DIR"/}"
    hash=$(sha256sum "$file" | cut -d' ' -f1)
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    echo "      {\"path\": \"$rel_path\", \"sha256\": \"$hash\", \"size\": $size}"
done | paste -sd ',' -)
    ],
    "requirements_lock": {
      "path": "repo/pip/releases/$RELEASE_ID/$PYTHON_VER/requirements.lock",
      "sha256": "$(cat "$PIP_DIR/requirements.lock.sha256")"
    },
    "requirements_lock_checksum": {
      "path": "repo/pip/releases/$RELEASE_ID/$PYTHON_VER/requirements.lock.sha256",
      "sha256": "$(sha256sum "$PIP_DIR/requirements.lock.sha256" | cut -d' ' -f1)"
    },
    "requirements_in": {
      "path": "repo/pip/releases/$RELEASE_ID/$PYTHON_VER/requirements.in",
      "sha256": "$(sha256sum "$PIP_DIR/requirements.in" | cut -d' ' -f1)"
    }
  },
  "cw_agent": {
    "prefix": "repo/cw-agent/releases/$RELEASE_ID/",
    "rpm": {
      "path": "repo/cw-agent/releases/$RELEASE_ID/amazon-cloudwatch-agent.rpm",
      "sha256": "$(sha256sum "$CW_DIR/amazon-cloudwatch-agent.rpm" | cut -d' ' -f1)",
      "size": $(stat -f%z "$CW_DIR/amazon-cloudwatch-agent.rpm" 2>/dev/null || stat -c%s "$CW_DIR/amazon-cloudwatch-agent.rpm" 2>/dev/null || echo 0)
    }
  }
}
MANIFEST

# Generate SHA256 for manifest
sha256sum "$MANIFEST_DIR/$RELEASE_ID.json" | cut -d' ' -f1 > "$MANIFEST_DIR/$RELEASE_ID.json.sha256"

log "Manifest generated: $MANIFEST_DIR/$RELEASE_ID.json"

#------------------------------------------------------------------------------
# Sign Manifest (with release signing key)
#------------------------------------------------------------------------------
log "Signing manifest (key: $RELEASE_KEY)..."

gpg_sign_file "$RELEASE_KEY" "$MANIFEST_DIR/$RELEASE_ID.json" "$MANIFEST_DIR/$RELEASE_ID.json.sig"

log "Manifest signed"

#------------------------------------------------------------------------------
# Export Public Keys (one per role)
#------------------------------------------------------------------------------
KEYS_DIR="$PROJECT_DIR/keys"
mkdir -p "$KEYS_DIR"

gpg --armor --export "$RELEASE_KEY" > "$KEYS_DIR/release-signing-public.gpg"
log "Release signing key exported: $KEYS_DIR/release-signing-public.gpg"

gpg --armor --export "$REPO_KEY" > "$KEYS_DIR/repo-metadata-signing-public.gpg"
log "Repo metadata signing key exported: $KEYS_DIR/repo-metadata-signing-public.gpg"

gpg --armor --export "$RPM_KEY" > "$KEYS_DIR/rpm-packages-signing-public.gpg"
log "RPM packages signing key exported: $KEYS_DIR/rpm-packages-signing-public.gpg"

#------------------------------------------------------------------------------
# Safety Assertion: verify real ~/.gnupg was not modified
#------------------------------------------------------------------------------
# Mtime + SHA256 check. If GPG somehow wrote through to the real keyring
# (e.g., a code path we didn't anticipate), fail the build so the operator
# knows the isolation was breached.
# - mtime:  always enforced (fast signal)
# - SHA256: enforced when successfully captured (authoritative)
# - empty hash → warning logged + mtime-only fallback (build continues)
log "Verifying real keyring was not modified..."
REAL_GNUPG_MODIFIED=0

if [[ -n "$MTIME_PUBRING_BEFORE" && -f "$REAL_GNUPGHOME/pubring.kbx" ]]; then
    MTIME_PUBRING_AFTER=$(stat -c%Y "$REAL_GNUPGHOME/pubring.kbx" 2>/dev/null \
        || stat -f%m "$REAL_GNUPGHOME/pubring.kbx" 2>/dev/null || echo "")
    if [[ "$MTIME_PUBRING_BEFORE" != "$MTIME_PUBRING_AFTER" ]]; then
        error "ISOLATION BREACH: $REAL_GNUPGHOME/pubring.kbx mtime changed ($MTIME_PUBRING_BEFORE -> $MTIME_PUBRING_AFTER)"
        REAL_GNUPG_MODIFIED=1
    fi
fi
if [[ -n "$SHA256_PUBRING_BEFORE" && -f "$REAL_GNUPGHOME/pubring.kbx" ]]; then
    SHA256_PUBRING_AFTER=$(sha256sum "$REAL_GNUPGHOME/pubring.kbx" 2>/dev/null | awk '{print $1}' || true)
    if [[ -z "$SHA256_PUBRING_AFTER" ]]; then
        warn "Could not recompute SHA256 for $REAL_GNUPGHOME/pubring.kbx; falling back to mtime-only check"
    elif [[ "$SHA256_PUBRING_BEFORE" != "$SHA256_PUBRING_AFTER" ]]; then
        error "ISOLATION BREACH: $REAL_GNUPGHOME/pubring.kbx content changed (sha256 $SHA256_PUBRING_BEFORE -> $SHA256_PUBRING_AFTER)"
        REAL_GNUPG_MODIFIED=1
    fi
fi

if [[ -n "$MTIME_TRUSTDB_BEFORE" && -f "$REAL_GNUPGHOME/trustdb.gpg" ]]; then
    MTIME_TRUSTDB_AFTER=$(stat -c%Y "$REAL_GNUPGHOME/trustdb.gpg" 2>/dev/null \
        || stat -f%m "$REAL_GNUPGHOME/trustdb.gpg" 2>/dev/null || echo "")
    if [[ "$MTIME_TRUSTDB_BEFORE" != "$MTIME_TRUSTDB_AFTER" ]]; then
        error "ISOLATION BREACH: $REAL_GNUPGHOME/trustdb.gpg mtime changed ($MTIME_TRUSTDB_BEFORE -> $MTIME_TRUSTDB_AFTER)"
        REAL_GNUPG_MODIFIED=1
    fi
fi
if [[ -n "$SHA256_TRUSTDB_BEFORE" && -f "$REAL_GNUPGHOME/trustdb.gpg" ]]; then
    SHA256_TRUSTDB_AFTER=$(sha256sum "$REAL_GNUPGHOME/trustdb.gpg" 2>/dev/null | awk '{print $1}' || true)
    if [[ -z "$SHA256_TRUSTDB_AFTER" ]]; then
        warn "Could not recompute SHA256 for $REAL_GNUPGHOME/trustdb.gpg; falling back to mtime-only check"
    elif [[ "$SHA256_TRUSTDB_BEFORE" != "$SHA256_TRUSTDB_AFTER" ]]; then
        error "ISOLATION BREACH: $REAL_GNUPGHOME/trustdb.gpg content changed (sha256 $SHA256_TRUSTDB_BEFORE -> $SHA256_TRUSTDB_AFTER)"
        REAL_GNUPG_MODIFIED=1
    fi
fi

if [[ "$REAL_GNUPG_MODIFIED" -ne 0 ]]; then
    die "Build aborted: real ~/.gnupg was modified. This should not happen with a properly isolated temp GNUPGHOME. Please report this issue."
fi
log "Real keyring integrity verified (mtime + sha256 unchanged)"

#------------------------------------------------------------------------------
# Artifact Self-Check (fail-closed if anything is missing)
#------------------------------------------------------------------------------
log "Running artifact self-check..."
_selfcheck_fail=0
_selfcheck() {
    local desc="$1" path="$2"
    if [[ -e "$path" ]]; then
        log "  OK: $desc"
    else
        error "  MISSING: $desc ($path)"
        _selfcheck_fail=1
    fi
}
_selfcheck "Manifest"          "$MANIFEST_DIR/$RELEASE_ID.json"
_selfcheck "Manifest signature" "$MANIFEST_DIR/$RELEASE_ID.json.sig"
_selfcheck "Manifest SHA256"   "$MANIFEST_DIR/$RELEASE_ID.json.sha256"
_selfcheck "RPM repodata"     "$RPM_DIR/repodata/repomd.xml"
_selfcheck "RPM repo signature" "$RPM_DIR/repodata/repomd.xml.asc"
_selfcheck "requirements.lock" "$PIP_DIR/requirements.lock"
_selfcheck "CW agent RPM"     "$CW_DIR/amazon-cloudwatch-agent.rpm"
_selfcheck "Release GPG key"  "$KEYS_DIR/release-signing-public.gpg"
_selfcheck "Repo GPG key"     "$KEYS_DIR/repo-metadata-signing-public.gpg"
_selfcheck "RPM GPG key"      "$KEYS_DIR/rpm-packages-signing-public.gpg"
if [[ "$_selfcheck_fail" -ne 0 ]]; then
    die "Artifact self-check FAILED — expected files are missing (see above)"
fi
unset _selfcheck_fail _selfcheck
log "Artifact self-check PASSED"

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo ""
log "========================================="
log "Release build complete"
log "========================================="
log "Release ID:    $RELEASE_ID"
log "Output:        $OUT_DIR"
log "RPM packages:  $RPM_COUNT"
log "Pip wheels:    $WHEEL_COUNT"
log "CW agent:      $CW_SIZE"
log ""
log "Files created:"
find "$OUT_DIR" -type f | sort | while read -r f; do
    echo "  ${f#"$OUT_DIR"/}"
done
echo ""
log "Signing keys (3-key model):"
log "  Release manifest:  $RELEASE_FPR"
log "  Repo metadata:     $REPO_FPR"
log "  RPM packages:      $RPM_FPR"
log ""
log "Set in Terraform:"
log "  release_gpg_key_fingerprint = \"$RELEASE_FPR\""
log "  repo_gpg_key_fingerprint    = \"$REPO_FPR\""
log "  rpm_gpg_key_fingerprint     = \"$RPM_FPR\""
log ""
log "Next (day-1_phase-1): Add fingerprints above to terraform.tfvars, then: terraform apply"
log "Then (day-1_phase-2): ./tools/1-upload_release.sh $RELEASE_ID \$BUCKET_NAME"
