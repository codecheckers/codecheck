#!/bin/bash
#
# Download JavaScript Libraries for CODECHECK Register
#
# This script downloads all required JavaScript libraries for the CODECHECK
# register certificate pages. All libraries are stored locally to avoid
# dependency on external CDNs.
#
# Usage:
#   bash inst/extdata/scripts/download-js-libraries.sh
#
# Or from R:
#   system("bash inst/extdata/scripts/download-js-libraries.sh")
#

set -e  # Exit on error

# Determine script directory and package root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JS_DIR="$PACKAGE_ROOT/inst/extdata/js"

echo "=== CODECHECK JavaScript Library Downloader ==="
echo ""
echo "Package root: $PACKAGE_ROOT"
echo "JavaScript directory: $JS_DIR"
echo ""

# Create JS directory if it doesn't exist
mkdir -p "$JS_DIR"

# Citation.js - For citation formatting
# Version 0.7.21 is the latest stable version as of 2024
# This is a browserify bundle that requires a wrapper to expose Cite globally
CITATION_VERSION="0.7.21"
CITATION_URL="https://cdn.jsdelivr.net/npm/citation-js@${CITATION_VERSION}/build/citation.min.js"
CITATION_FILE="$JS_DIR/citation.min.js"

echo "Downloading Citation.js ${CITATION_VERSION}..."
curl -L "$CITATION_URL" -o "$CITATION_FILE"
echo "✓ Downloaded citation.min.js ($(du -h "$CITATION_FILE" | cut -f1))"
echo ""

# Note about citation-wrapper.js
echo "Note: citation-wrapper.js is maintained in the package repository"
echo "      (inst/extdata/js/citation-wrapper.js) and does not need downloading."
echo ""

# Future libraries can be added here
# Example:
# echo "Downloading Library X..."
# curl -L "https://example.com/library.js" -o "$JS_DIR/library.js"
# echo "✓ Downloaded library.js"

echo "=== Download complete ==="
echo ""
echo "Downloaded files:"
ls -lh "$JS_DIR"/*.min.js 2>/dev/null || echo "(no minified files found)"
echo ""
echo "To verify the download, check the file sizes against the expected values:"
echo "  - citation.min.js: ~2.7 MB"
echo ""
