#!/bin/bash
# build.sh - Claude Desktop Mac Build Script
#
# Usage: ./build.sh [options]
# Options:
#   -c, --configuration   Build configuration (Debug/Release) [default: Release]
#   -s, --scheme          Build scheme [default: ClaudeDesktop]
#   -a, --arch            Architecture (arm64/x86_64/universal) [default: universal]
#   -v, --version         App version [default: from Info.plist or 1.0.0]
#   -b, --build-number    Build number [default: auto-generated]
#   --clean               Clean before build
#   --verbose             Verbose output
#   -h, --help            Show this help message

set -e

# ============================================
# Configuration
# ============================================

APP_NAME="Claude Desktop"
BUNDLE_ID="com.claude.desktop"
SCHEME="ClaudeDesktop"
CONFIGURATION="Release"
ARCH="universal"
CLEAN_BUILD=false
VERBOSE=false

# Version info
VERSION="1.0.0"
BUILD_NUMBER=$(date +%Y%m%d%H%M)

# Directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
Claude Desktop Mac Build Script

Usage: $(basename "$0") [options]

Options:
  -c, --configuration   Build configuration (Debug/Release) [default: Release]
  -s, --scheme          Build scheme [default: ClaudeDesktop]
  -a, --arch            Architecture (arm64/x86_64/universal) [default: universal]
  -v, --version         App version [default: 1.0.0]
  -b, --build-number    Build number [default: auto-generated timestamp]
  --clean               Clean before build
  --verbose             Verbose output
  -h, --help            Show this help message

Examples:
  $(basename "$0")                              # Build Release universal
  $(basename "$0") -c Debug --clean            # Clean and build Debug
  $(basename "$0") -a arm64 -v 1.1.0           # Build arm64 version 1.1.0

EOF
}

# ============================================
# Parse Arguments
# ============================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -s|--scheme)
            SCHEME="$2"
            shift 2
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -b|--build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# ============================================
# Validate Environment
# ============================================

validate_environment() {
    log_info "Validating build environment..."

    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi

    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -n1 | awk '{print $2}')
    log_info "Xcode version: $XCODE_VERSION"

    # Check for Swift
    if ! command -v swift &> /dev/null; then
        log_error "Swift not found. Please install Xcode with Swift."
        exit 1
    fi

    SWIFT_VERSION=$(swift --version | head -n1 | awk '{print $4}')
    log_info "Swift version: $SWIFT_VERSION"

    # Check for Package.swift
    if [[ ! -f "$PROJECT_DIR/Package.swift" ]]; then
        log_error "Package.swift not found in $PROJECT_DIR"
        exit 1
    fi

    log_success "Environment validation passed"
}

# ============================================
# Clean Build
# ============================================

clean_build() {
    if [[ "$CLEAN_BUILD" == true ]]; then
        log_info "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
        log_success "Build directory cleaned"
    fi
}

# ============================================
# Build Project
# ============================================

build_project() {
    log_info "=== Building $APP_NAME v$VERSION ($BUILD_NUMBER) ==="
    log_info "Configuration: $CONFIGURATION"
    log_info "Architecture: $ARCH"

    # Create build directory
    mkdir -p "$BUILD_DIR"

    # Determine destination based on architecture
    case $ARCH in
        arm64)
            DESTINATION="platform=macOS,arch=arm64"
            ;;
        x86_64)
            DESTINATION="platform=macOS,arch=x86_64"
            ;;
        universal)
            DESTINATION="platform=macOS"
            ;;
        *)
            log_error "Unknown architecture: $ARCH"
            exit 1
            ;;
    esac

    # Build command
    BUILD_CMD="xcodebuild build"
    BUILD_CMD="$BUILD_CMD -scheme $SCHEME"
    BUILD_CMD="$BUILD_CMD -configuration $CONFIGURATION"
    BUILD_CMD="$BUILD_CMD -destination '$DESTINATION'"
    BUILD_CMD="$BUILD_CMD -derivedDataPath '$DERIVED_DATA'"
    BUILD_CMD="$BUILD_CMD CURRENT_PROJECT_VERSION=$BUILD_NUMBER"
    BUILD_CMD="$BUILD_CMD MARKETING_VERSION=$VERSION"
    BUILD_CMD="$BUILD_CMD SWIFT_VERSION=5.9"

    if [[ "$VERBOSE" == true ]]; then
        BUILD_CMD="$BUILD_CMD -verbose"
    fi

    log_info "Executing: $BUILD_CMD"

    # Execute build
    eval $BUILD_CMD 2>&1 | tee "$BUILD_DIR/build.log" | while IFS= read -r line; do
        if [[ "$line" == *"error:"* ]]; then
            log_error "$line"
        elif [[ "$line" == *"warning:"* ]]; then
            log_warning "$line"
        elif [[ "$VERBOSE" == true ]]; then
            echo "$line"
        fi
    done

    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [[ $BUILD_EXIT_CODE -ne 0 ]]; then
        log_error "Build failed with exit code $BUILD_EXIT_CODE"
        log_error "Check build log at: $BUILD_DIR/build.log"
        exit $BUILD_EXIT_CODE
    fi

    log_success "Build completed successfully"
}

# ============================================
# Build for Release (Archive)
# ============================================

build_archive() {
    if [[ "$CONFIGURATION" != "Release" ]]; then
        return
    fi

    log_info "Creating archive..."

    ARCHIVE_CMD="xcodebuild archive"
    ARCHIVE_CMD="$ARCHIVE_CMD -scheme $SCHEME"
    ARCHIVE_CMD="$ARCHIVE_CMD -archivePath '$ARCHIVE_PATH'"
    ARCHIVE_CMD="$ARCHIVE_CMD -configuration Release"
    ARCHIVE_CMD="$ARCHIVE_CMD -destination 'platform=macOS'"
    ARCHIVE_CMD="$ARCHIVE_CMD CURRENT_PROJECT_VERSION=$BUILD_NUMBER"
    ARCHIVE_CMD="$ARCHIVE_CMD MARKETING_VERSION=$VERSION"

    eval $ARCHIVE_CMD 2>&1 | tee "$BUILD_DIR/archive.log"

    if [[ $? -ne 0 ]]; then
        log_error "Archive failed"
        exit 1
    fi

    log_success "Archive created at: $ARCHIVE_PATH"
}

# ============================================
# Run Tests
# ============================================

run_tests() {
    log_info "Running tests..."

    TEST_CMD="xcodebuild test"
    TEST_CMD="$TEST_CMD -scheme $SCHEME"
    TEST_CMD="$TEST_CMD -destination 'platform=macOS'"
    TEST_CMD="$TEST_CMD -derivedDataPath '$DERIVED_DATA'"

    if [[ "$VERBOSE" == true ]]; then
        TEST_CMD="$TEST_CMD -verbose"
    fi

    eval $TEST_CMD 2>&1 | tee "$BUILD_DIR/test.log"

    if [[ $? -ne 0 ]]; then
        log_error "Tests failed"
        exit 1
    fi

    log_success "All tests passed"
}

# ============================================
# Copy Resources
# ============================================

copy_resources() {
    log_info "Copying resources..."

    # Find built app in DerivedData
    BUILT_APP=$(find "$DERIVED_DATA" -name "*.app" -type d | head -n1)

    if [[ -z "$BUILT_APP" ]]; then
        log_warning "No built app found in DerivedData"
        return
    fi

    # Create export directory
    mkdir -p "$EXPORT_PATH"

    # Copy app to export path
    cp -R "$BUILT_APP" "$EXPORT_PATH/"

    log_success "App copied to: $EXPORT_PATH/$(basename "$BUILT_APP")"
}

# ============================================
# Generate Build Info
# ============================================

generate_build_info() {
    log_info "Generating build info..."

    cat > "$BUILD_DIR/build-info.json" << EOF
{
    "appName": "$APP_NAME",
    "bundleId": "$BUNDLE_ID",
    "version": "$VERSION",
    "buildNumber": "$BUILD_NUMBER",
    "configuration": "$CONFIGURATION",
    "architecture": "$ARCH",
    "buildDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "xcodeVersion": "$(xcodebuild -version | head -n1 | awk '{print $2}')",
    "swiftVersion": "$(swift --version | head -n1 | awk '{print $4}')",
    "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'N/A')",
    "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
}
EOF

    log_success "Build info generated at: $BUILD_DIR/build-info.json"
}

# ============================================
# Main
# ============================================

main() {
    log_info "============================================"
    log_info "Claude Desktop Mac Build Script"
    log_info "============================================"

    validate_environment
    clean_build
    build_project
    copy_resources
    generate_build_info

    log_info "============================================"
    log_success "Build completed successfully!"
    log_info "============================================"
    log_info "Output: $EXPORT_PATH"
    log_info "Build log: $BUILD_DIR/build.log"
}

# Run main
main "$@"
