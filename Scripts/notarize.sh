#!/bin/bash
# notarize.sh - Apple Notarization Script for Claude Desktop Mac
#
# Usage: ./notarize.sh [options] <app-path>
# Options:
#   -a, --apple-id      Apple ID for notarization
#   -t, --team-id       Team ID
#   -p, --password      App-specific password (or use keychain profile)
#   -k, --keychain      Keychain profile name (alternative to password)
#   --staple            Staple after notarization
#   --wait              Wait for notarization to complete
#   -v, --verbose       Verbose output
#   -h, --help          Show this help message

set -e

# ============================================
# Configuration
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
APPLE_ID=""
TEAM_ID=""
APP_PASSWORD=""
KEYCHAIN_PROFILE=""
APP_PATH=""
STAPLE=true
WAIT=true
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# Helper Functions
# ============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Apple Notarization Script for Claude Desktop Mac

Usage: $(basename "$0") [options] <app-path>

Options:
  -a, --apple-id      Apple ID for notarization
                      Can also be set via APPLE_ID environment variable
  -t, --team-id       Team ID
                      Can also be set via APPLE_TEAM_ID environment variable
  -p, --password      App-specific password
                      Can also be set via APPLE_APP_PASSWORD environment variable
  -k, --keychain      Keychain profile name (alternative to password)
                      Use 'xcrun notarytool store-credentials' to create
  --no-staple         Don't staple after notarization
  --no-wait           Don't wait for notarization to complete
  -v, --verbose       Verbose output
  -h, --help          Show this help message

Prerequisites:
  1. App must be signed with Developer ID certificate
  2. Create app-specific password at appleid.apple.com
  3. Optionally store credentials with:
     xcrun notarytool store-credentials "profile-name" \
       --apple-id "your@email.com" \
       --team-id "TEAM_ID" \
       --password "xxxx-xxxx-xxxx-xxxx"

Examples:
  $(basename "$0") -a user@email.com -t TEAM_ID -p xxxx-xxxx app.app
  $(basename "$0") -k "notary-profile" app.app

EOF
}

# ============================================
# Parse Arguments
# ============================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--apple-id)
            APPLE_ID="$2"
            shift 2
            ;;
        -t|--team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        -p|--password)
            APP_PASSWORD="$2"
            shift 2
            ;;
        -k|--keychain)
            KEYCHAIN_PROFILE="$2"
            shift 2
            ;;
        --no-staple)
            STAPLE=false
            shift
            ;;
        --no-wait)
            WAIT=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$APP_PATH" ]]; then
                APP_PATH="$1"
            else
                log_error "Multiple app paths specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# ============================================
# Validate Environment
# ============================================

validate_environment() {
    log_info "Validating notarization environment..."

    # Check for app path
    if [[ -z "$APP_PATH" ]]; then
        log_error "No app path specified"
        show_help
        exit 1
    fi

    # Normalize app path
    if [[ "$APP_PATH" != /* ]]; then
        APP_PATH="$PROJECT_DIR/$APP_PATH"
    fi

    # Check if app exists
    if [[ ! -d "$APP_PATH" ]]; then
        log_error "App not found at: $APP_PATH"
        exit 1
    fi

    # Check for credentials
    if [[ -n "$KEYCHAIN_PROFILE" ]]; then
        log_info "Using keychain profile: $KEYCHAIN_PROFILE"
    elif [[ -n "$APPLE_ID" && -n "$TEAM_ID" && -n "$APP_PASSWORD" ]]; then
        log_info "Using credentials: Apple ID, Team ID, and App Password"
    else
        # Try environment variables
        APPLE_ID="${APPLE_ID:-$APPLE_ID}"
        TEAM_ID="${TEAM_ID:-$APPLE_TEAM_ID}"
        APP_PASSWORD="${APP_PASSWORD:-$APPLE_APP_PASSWORD}"

        if [[ -z "$APPLE_ID" || -z "$TEAM_ID" || -z "$APP_PASSWORD" ]]; then
            log_error "Missing notarization credentials"
            log_info "Provide either:"
            log_info "  1. Keychain profile with -k"
            log_info "  2. Apple ID, Team ID, and App Password"
            exit 1
        fi
    fi

    # Check if app is signed
    if ! codesign -dv "$APP_PATH" 2>/dev/null; then
        log_error "App is not signed. Please sign the app first."
        exit 1
    fi

    log_success "Environment validation passed"
}

# ============================================
# Create ZIP Archive
# ============================================

create_zip() {
    log_info "Creating ZIP archive for notarization..."

    ZIP_PATH="${APP_PATH%.app}.zip"

    # Remove existing zip if present
    rm -f "$ZIP_PATH"

    # Create zip with ditto (preserves structure)
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

    if [[ ! -f "$ZIP_PATH" ]]; then
        log_error "Failed to create ZIP archive"
        exit 1
    fi

    log_success "ZIP archive created: $ZIP_PATH"
}

# ============================================
# Submit for Notarization
# ============================================

submit_notarization() {
    log_info "=== Submitting for Notarization ==="

    # Build submit command
    if [[ -n "$KEYCHAIN_PROFILE" ]]; then
        SUBMIT_CMD="xcrun notarytool submit '$ZIP_PATH'"
        SUBMIT_CMD="$SUBMIT_CMD --keychain-profile '$KEYCHAIN_PROFILE'"
    else
        SUBMIT_CMD="xcrun notarytool submit '$ZIP_PATH'"
        SUBMIT_CMD="$SUBMIT_CMD --apple-id '$APPLE_ID'"
        SUBMIT_CMD="$SUBMIT_CMD --team-id '$TEAM_ID'"
        SUBMIT_CMD="$SUBMIT_CMD --password '$APP_PASSWORD'"
    fi

    if [[ "$WAIT" == true ]]; then
        SUBMIT_CMD="$SUBMIT_CMD --wait"
    fi

    if [[ "$VERBOSE" == true ]]; then
        SUBMIT_CMD="$SUBMIT_CMD --verbose"
    fi

    log_info "Submitting..."

    # Execute submission
    SUBMIT_OUTPUT=$(eval $SUBMIT_CMD 2>&1)
    SUBMIT_EXIT_CODE=$?

    echo "$SUBMIT_OUTPUT"

    if [[ $SUBMIT_EXIT_CODE -ne 0 ]]; then
        log_error "Notarization submission failed"
        exit 1
    fi

    # Extract request ID
    REQUEST_ID=$(echo "$SUBMIT_OUTPUT" | grep "id:" | awk '{print $2}' | head -n1)
    log_info "Request ID: $REQUEST_ID"

    # Check result if waited
    if [[ "$WAIT" == true ]]; then
        if echo "$SUBMIT_OUTPUT" | grep -q "status: Accepted"; then
            log_success "Notarization accepted!"
            return 0
        elif echo "$SUBMIT_OUTPUT" | grep -q "status: Invalid"; then
            log_error "Notarization rejected!"
            get_notarization_log "$REQUEST_ID"
            exit 1
        else
            log_warning "Notarization status unknown"
            return 1
        fi
    fi
}

# ============================================
# Check Notarization Status
# ============================================

check_notarization_status() {
    if [[ "$WAIT" == true ]]; then
        return
    fi

    log_info "Checking notarization status..."

    if [[ -n "$KEYCHAIN_PROFILE" ]]; then
        STATUS_CMD="xcrun notarytool info '$REQUEST_ID'"
        STATUS_CMD="$STATUS_CMD --keychain-profile '$KEYCHAIN_PROFILE'"
    else
        STATUS_CMD="xcrun notarytool info '$REQUEST_ID'"
        STATUS_CMD="$STATUS_CMD --apple-id '$APPLE_ID'"
        STATUS_CMD="$STATUS_CMD --team-id '$TEAM_ID'"
        STATUS_CMD="$STATUS_CMD --password '$APP_PASSWORD'"
    fi

    # Poll for status
    for i in {1..60}; do
        STATUS_OUTPUT=$(eval $STATUS_CMD 2>&1)
        STATUS=$(echo "$STATUS_OUTPUT" | grep "status:" | awk '{print $2}')

        log_info "Status: $STATUS (attempt $i/60)"

        case $STATUS in
            Accepted)
                log_success "Notarization accepted!"
                return 0
                ;;
            Invalid)
                log_error "Notarization rejected!"
                get_notarization_log "$REQUEST_ID"
                exit 1
                ;;
            In\ Progress)
                sleep 30
                ;;
            *)
                log_warning "Unknown status: $STATUS"
                sleep 30
                ;;
        esac
    done

    log_error "Notarization timed out"
    exit 1
}

# ============================================
# Get Notarization Log
# ============================================

get_notarization_log() {
    local request_id="$1"

    log_info "Fetching notarization log..."

    LOG_PATH="$PROJECT_DIR/build/notarization-log.json"

    if [[ -n "$KEYCHAIN_PROFILE" ]]; then
        xcrun notarytool log "$request_id" \
            --keychain-profile "$KEYCHAIN_PROFILE" \
            --output "$LOG_PATH"
    else
        xcrun notarytool log "$request_id" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APP_PASSWORD" \
            --output "$LOG_PATH"
    fi

    log_warning "Notarization log saved to: $LOG_PATH"
}

# ============================================
# Staple Notarization
# ============================================

staple_notarization() {
    if [[ "$STAPLE" != true ]]; then
        return
    fi

    log_info "Stapling notarization ticket..."

    xcrun stapler staple "$APP_PATH"

    if [[ $? -ne 0 ]]; then
        log_error "Stapling failed"
        exit 1
    fi

    log_success "Stapling completed"
}

# ============================================
# Verify Staple
# ============================================

verify_staple() {
    log_info "Verifying staple..."

    if xcrun stapler validate "$APP_PATH"; then
        log_success "Staple verification passed"
    else
        log_error "Staple verification failed"
        exit 1
    fi
}

# ============================================
# Cleanup
# ============================================

cleanup() {
    if [[ -f "$ZIP_PATH" ]]; then
        log_info "Cleaning up ZIP archive..."
        rm -f "$ZIP_PATH"
    fi
}

# ============================================
# Main
# ============================================

main() {
    log_info "============================================"
    log_info "Claude Desktop Mac Notarization"
    log_info "============================================"

    validate_environment
    create_zip
    submit_notarization
    check_notarization_status
    staple_notarization
    verify_staple
    cleanup

    log_info "============================================"
    log_success "Notarization completed successfully!"
    log_info "============================================"
    log_info "App is now ready for distribution"
}

# Run main
main "$@"
