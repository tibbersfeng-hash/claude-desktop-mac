#!/bin/bash
# sign.sh - Code Signing Script for Claude Desktop Mac
#
# Usage: ./sign.sh [options] <app-path>
# Options:
#   -i, --identity      Signing identity (Developer ID Application)
#   -e, --entitlements  Path to entitlements file
#   -t, --team-id       Team ID
#   --force             Force re-sign even if already signed
#   -v, --verbose       Verbose output
#   -h, --help          Show this help message

set -e

# ============================================
# Configuration
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
SIGNING_IDENTITY=""
ENTITLEMENTS_PATH="$PROJECT_DIR/Resources/Entitlements.entitlements"
TEAM_ID=""
FORCE_RESIGN=false
VERBOSE=false
APP_PATH=""

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
Code Signing Script for Claude Desktop Mac

Usage: $(basename "$0") [options] <app-path>

Options:
  -i, --identity      Signing identity (Developer ID Application)
                      Can also be set via SIGNING_IDENTITY environment variable
  -e, --entitlements  Path to entitlements file
                      [default: Resources/Entitlements.entitlements]
  -t, --team-id       Team ID for signing
                      Can also be set via APPLE_TEAM_ID environment variable
  --force             Force re-sign even if already signed
  -v, --verbose       Verbose output
  -h, --help          Show this help message

Examples:
  $(basename "$0") build/export/Claude\ Desktop.app
  $(basename "$0") -i "Developer ID Application: Your Name (TEAM_ID)" app.app
  SIGNING_IDENTITY="Developer ID Application: ..." $(basename "$0") app.app

EOF
}

# ============================================
# Parse Arguments
# ============================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--identity)
            SIGNING_IDENTITY="$2"
            shift 2
            ;;
        -e|--entitlements)
            ENTITLEMENTS_PATH="$2"
            shift 2
            ;;
        -t|--team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        --force)
            FORCE_RESIGN=true
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
    log_info "Validating signing environment..."

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

    # Check for signing identity
    if [[ -z "$SIGNING_IDENTITY" ]]; then
        SIGNING_IDENTITY="${SIGNING_IDENTITY:-$SIGNING_IDENTITY}"
    fi

    if [[ -z "$SIGNING_IDENTITY" ]]; then
        log_error "No signing identity specified"
        log_info "Available signing identities:"
        security find-identity -v -p codesigning 2>/dev/null || true
        exit 1
    fi

    # Check for entitlements
    if [[ ! -f "$ENTITLEMENTS_PATH" ]]; then
        log_error "Entitlements file not found at: $ENTITLEMENTS_PATH"
        exit 1
    fi

    log_success "Environment validation passed"
}

# ============================================
# Check Current Signature
# ============================================

check_current_signature() {
    log_info "Checking current signature..."

    if codesign -dv "$APP_PATH" 2>/dev/null; then
        log_warning "App is already signed"

        if [[ "$FORCE_RESIGN" != true ]]; then
            log_warning "Use --force to re-sign"
            read -p "Continue with re-signing? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    else
        log_info "App is not signed"
    fi
}

# ============================================
# Sign Frameworks and Libraries
# ============================================

sign_frameworks() {
    log_info "Signing embedded frameworks and libraries..."

    FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
    LIBRARIES_DIR="$APP_PATH/Contents/Libraries"

    # Sign frameworks
    if [[ -d "$FRAMEWORKS_DIR" ]]; then
        for framework in "$FRAMEWORKS_DIR"/*.framework; do
            if [[ -d "$framework" ]]; then
                log_info "Signing framework: $(basename "$framework")"
                codesign --sign "$SIGNING_IDENTITY" \
                    --options runtime \
                    --timestamp \
                    --force \
                    "$framework"
            fi
        done
    fi

    # Sign dylibs
    if [[ -d "$LIBRARIES_DIR" ]]; then
        for dylib in "$LIBRARIES_DIR"/*.dylib; do
            if [[ -f "$dylib" ]]; then
                log_info "Signing library: $(basename "$dylib")"
                codesign --sign "$SIGNING_IDENTITY" \
                    --options runtime \
                    --timestamp \
                    --force \
                    "$dylib"
            fi
        done
    fi
}

# ============================================
# Sign App Bundle
# ============================================

sign_app() {
    log_info "=== Signing App Bundle ==="
    log_info "App: $APP_PATH"
    log_info "Identity: $SIGNING_IDENTITY"
    log_info "Entitlements: $ENTITLEMENTS_PATH"

    # Build codesign command
    SIGN_CMD="codesign --sign '$SIGNING_IDENTITY'"
    SIGN_CMD="$SIGN_CMD --entitlements '$ENTITLEMENTS_PATH'"
    SIGN_CMD="$SIGN_CMD --options runtime"
    SIGN_CMD="$SIGN_CMD --timestamp"
    SIGN_CMD="$SIGN_CMD --deep"
    SIGN_CMD="$SIGN_CMD --force"

    if [[ "$VERBOSE" == true ]]; then
        SIGN_CMD="$SIGN_CMD --verbose=4"
    else
        SIGN_CMD="$SIGN_CMD --verbose"
    fi

    SIGN_CMD="$SIGN_CMD '$APP_PATH'"

    log_info "Executing: $SIGN_CMD"

    # Execute signing
    eval $SIGN_CMD

    if [[ $? -ne 0 ]]; then
        log_error "Signing failed"
        exit 1
    fi

    log_success "App signed successfully"
}

# ============================================
# Verify Signature
# ============================================

verify_signature() {
    log_info "Verifying signature..."

    # Verify code signature
    if ! codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1; then
        log_error "Signature verification failed"
        exit 1
    fi

    log_success "Signature verification passed"

    # Display signature info
    log_info "Signature details:"
    codesign --display --verbose=4 "$APP_PATH" 2>&1 | while IFS= read -r line; do
        echo "  $line"
    done
}

# ============================================
# Check Gatekeeper
# ============================================

check_gatekeeper() {
    log_info "Checking Gatekeeper assessment..."

    ASSESSMENT=$(spctl --assess --verbose=4 --type execute "$APP_PATH" 2>&1)

    if echo "$ASSESSMENT" | grep -q "accepted"; then
        log_success "Gatekeeper assessment: ACCEPTED"
    else
        log_warning "Gatekeeper assessment: $ASSESSMENT"
        log_warning "App may need notarization for distribution"
    fi
}

# ============================================
# Display Signing Summary
# ============================================

display_summary() {
    log_info "============================================"
    log_info "Signing Summary"
    log_info "============================================"

    # Get signature info
    SIGNER_INFO=$(codesign -dr - "$APP_PATH" 2>&1)

    echo "App Path: $APP_PATH"
    echo ""
    echo "Signature Info:"
    echo "$SIGNER_INFO" | while IFS= read -r line; do
        echo "  $line"
    done

    # Check entitlements
    echo ""
    echo "Entitlements:"
    codesign -d --entitlements - "$APP_PATH" 2>&1 | while IFS= read -r line; do
        echo "  $line"
    done

    log_info "============================================"
}

# ============================================
# Main
# ============================================

main() {
    log_info "============================================"
    log_info "Claude Desktop Mac Code Signing"
    log_info "============================================"

    validate_environment
    check_current_signature
    sign_frameworks
    sign_app
    verify_signature
    check_gatekeeper
    display_summary

    log_success "Code signing completed successfully!"
}

# Run main
main "$@"
