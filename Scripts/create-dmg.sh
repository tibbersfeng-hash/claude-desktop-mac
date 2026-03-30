#!/bin/bash
# create-dmg.sh - DMG Creation Script for Claude Desktop Mac
#
# Usage: ./create-dmg.sh [options] <app-path>
# Options:
#   -o, --output        Output DMG path
#   -n, --name          Volume name
#   -s, --size          DMG size (e.g., 500m) [default: auto]
#   --sign              Sign the DMG
#   -i, --identity      Signing identity for DMG
#   --background        Background image path
#   --icon              App icon size [default: 128]
#   --no-applications   Don't include Applications link
#   -v, --verbose       Verbose output
#   -h, --help          Show this help message

set -e

# ============================================
# Configuration
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
APP_PATH=""
OUTPUT_PATH=""
VOLUME_NAME="Claude Desktop"
DMG_SIZE=""
SIGN_DMG=false
SIGNING_IDENTITY=""
BACKGROUND_IMAGE=""
ICON_SIZE=128
INCLUDE_APPLICATIONS=true
VERBOSE=false

# DMG Layout settings
WINDOW_WIDTH=660
WINDOW_HEIGHT=400
ICON_ROW_SPACING=100
APP_ICON_X=180
APP_ICON_Y=180
APPLICATIONS_X=480
APPLICATIONS_Y=180

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
DMG Creation Script for Claude Desktop Mac

Usage: $(basename "$0") [options] <app-path>

Options:
  -o, --output        Output DMG path [default: build/ClaudeDesktop-{version}.dmg]
  -n, --name          Volume name [default: Claude Desktop]
  -s, --size          DMG size (e.g., 500m) [default: auto-calculated]
  --sign              Sign the DMG after creation
  -i, --identity      Signing identity for DMG
  --background        Background image path (PNG)
  --icon              App icon size [default: 128]
  --no-applications   Don't include Applications link
  -v, --verbose       Verbose output
  -h, --help          Show this help message

Examples:
  $(basename "$0") build/export/Claude\ Desktop.app
  $(basename "$0") --sign -i "Developer ID Application: ..." app.app
  $(basename "$0") -o release.dmg --background background.png app.app

EOF
}

# ============================================
# Parse Arguments
# ============================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -n|--name)
            VOLUME_NAME="$2"
            shift 2
            ;;
        -s|--size)
            DMG_SIZE="$2"
            shift 2
            ;;
        --sign)
            SIGN_DMG=true
            shift
            ;;
        -i|--identity)
            SIGNING_IDENTITY="$2"
            shift 2
            ;;
        --background)
            BACKGROUND_IMAGE="$2"
            shift 2
            ;;
        --icon)
            ICON_SIZE="$2"
            shift 2
            ;;
        --no-applications)
            INCLUDE_APPLICATIONS=false
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
    log_info "Validating environment..."

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

    # Get app version
    APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")

    # Set default output path
    if [[ -z "$OUTPUT_PATH" ]]; then
        OUTPUT_PATH="$PROJECT_DIR/build/ClaudeDesktop-$APP_VERSION.dmg"
    fi

    # Normalize output path
    if [[ "$OUTPUT_PATH" != /* ]]; then
        OUTPUT_PATH="$PROJECT_DIR/$OUTPUT_PATH"
    fi

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_PATH")"

    # Check background image if specified
    if [[ -n "$BACKGROUND_IMAGE" && ! -f "$BACKGROUND_IMAGE" ]]; then
        log_warning "Background image not found: $BACKGROUND_IMAGE"
        BACKGROUND_IMAGE=""
    fi

    # Check signing identity if signing
    if [[ "$SIGN_DMG" == true && -z "$SIGNING_IDENTITY" ]]; then
        # Try to find a Developer ID
        SIGNING_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -n1 | sed 's/.*\"\(.*\)\".*/\1/')
        if [[ -z "$SIGNING_IDENTITY" ]]; then
            log_warning "No signing identity found, DMG will not be signed"
            SIGN_DMG=false
        fi
    fi

    log_success "Environment validation passed"
}

# ============================================
# Calculate DMG Size
# ============================================

calculate_dmg_size() {
    if [[ -n "$DMG_SIZE" ]]; then
        return
    fi

    log_info "Calculating DMG size..."

    # Get app size in bytes
    APP_SIZE=$(du -s "$APP_PATH" | awk '{print $1}')
    APP_SIZE_BYTES=$((APP_SIZE * 512))

    # Add 20% buffer and convert to MB
    SIZE_WITH_BUFFER=$((APP_SIZE_BYTES * 120 / 100))
    SIZE_MB=$((SIZE_WITH_BUFFER / 1024 / 1024))

    # Minimum 100MB
    if [[ $SIZE_MB -lt 100 ]]; then
        SIZE_MB=100
    fi

    DMG_SIZE="${SIZE_MB}m"
    log_info "DMG size: $DMG_SIZE"
}

# ============================================
# Create DMG
# ============================================

create_dmg() {
    log_info "=== Creating DMG ==="
    log_info "App: $APP_PATH"
    log_info "Output: $OUTPUT_PATH"
    log_info "Volume Name: $VOLUME_NAME"
    log_info "Size: $DMG_SIZE"

    # Remove existing DMG
    rm -f "$OUTPUT_PATH"

    # Create temporary directory for DMG contents
    TMP_DIR=$(mktemp -d)
    DMG_CONTENTS="$TMP_DIR/contents"
    mkdir -p "$DMG_CONTENTS"

    # Copy app to temp directory
    log_info "Copying app..."
    cp -R "$APP_PATH" "$DMG_CONTENTS/"

    # Create Applications link
    if [[ "$INCLUDE_APPLICATIONS" == true ]]; then
        log_info "Creating Applications link..."
        ln -s /Applications "$DMG_CONTENTS/Applications"
    fi

    # Copy background image if specified
    if [[ -n "$BACKGROUND_IMAGE" ]]; then
        mkdir -p "$DMG_CONTENTS/.background"
        cp "$BACKGROUND_IMAGE" "$DMG_CONTENTS/.background/background.png"
    fi

    # Create DMG
    log_info "Creating DMG file..."
    hdiutil create \
        -volname "$VOLUME_NAME" \
        -srcfolder "$DMG_CONTENTS" \
        -ov -format UDZO \
        -imagekey zlib-level=9 \
        "$OUTPUT_PATH"

    if [[ $? -ne 0 ]]; then
        log_error "Failed to create DMG"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Cleanup temp directory
    rm -rf "$TMP_DIR"

    log_success "DMG created: $OUTPUT_PATH"
}

# ============================================
# Configure DMG Appearance
# ============================================

configure_appearance() {
    log_info "Configuring DMG appearance..."

    # Mount DMG
    MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$OUTPUT_PATH" | \
        grep "/Volumes/$VOLUME_NAME" | awk '{print $3}')

    if [[ -z "$MOUNT_DIR" ]]; then
        log_warning "Could not mount DMG for appearance configuration"
        return
    fi

    # Use AppleScript to configure window appearance
    osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, $((100 + WINDOW_WIDTH)), $((100 + WINDOW_HEIGHT))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set background picture of viewOptions to file ".background:background.png"

        -- Position app icon
        set position of item "$(basename "$APP_PATH")" of container window to {$APP_ICON_X, $APP_ICON_Y}

        -- Position Applications link
        $(if [[ "$INCLUDE_APPLICATIONS" == true ]]; then
            echo "set position of item \"Applications\" of container window to {$APPLICATIONS_X, $APPLICATIONS_Y}"
        fi)

        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

    # Sync and unmount
    sync
    hdiutil detach "$MOUNT_DIR"

    log_success "DMG appearance configured"
}

# ============================================
# Sign DMG
# ============================================

sign_dmg() {
    if [[ "$SIGN_DMG" != true ]]; then
        return
    fi

    log_info "Signing DMG..."
    log_info "Identity: $SIGNING_IDENTITY"

    codesign --sign "$SIGNING_IDENTITY" \
        --timestamp \
        "$OUTPUT_PATH"

    if [[ $? -ne 0 ]]; then
        log_error "DMG signing failed"
        exit 1
    fi

    log_success "DMG signed"
}

# ============================================
# Verify DMG
# ============================================

verify_dmg() {
    log_info "Verifying DMG..."

    # Verify DMG structure
    if ! hdiutil verify "$OUTPUT_PATH"; then
        log_error "DMG verification failed"
        exit 1
    fi

    log_success "DMG verification passed"

    # Check signature if signed
    if [[ "$SIGN_DMG" == true ]]; then
        if codesign --verify --verbose=2 "$OUTPUT_PATH"; then
            log_success "DMG signature valid"
        else
            log_error "DMG signature invalid"
            exit 1
        fi
    fi
}

# ============================================
# Display Summary
# ============================================

display_summary() {
    log_info "============================================"
    log_info "DMG Creation Summary"
    log_info "============================================"

    # Get DMG size
    DMG_SIZE_BYTES=$(stat -f%z "$OUTPUT_PATH")
    DMG_SIZE_MB=$((DMG_SIZE_BYTES / 1024 / 1024))

    echo "Output: $OUTPUT_PATH"
    echo "Size: ${DMG_SIZE_MB} MB"
    echo "Volume Name: $VOLUME_NAME"
    echo "Signed: $SIGN_DMG"

    if [[ "$SIGN_DMG" == true ]]; then
        echo "Signing Identity: $SIGNING_IDENTITY"
    fi

    log_info "============================================"
}

# ============================================
# Main
# ============================================

main() {
    log_info "============================================"
    log_info "Claude Desktop Mac DMG Creator"
    log_info "============================================"

    validate_environment
    calculate_dmg_size
    create_dmg

    # Only configure appearance on macOS
    if [[ "$(uname)" == "Darwin" ]]; then
        configure_appearance
    fi

    sign_dmg
    verify_dmg
    display_summary

    log_success "DMG creation completed successfully!"
}

# Run main
main "$@"
