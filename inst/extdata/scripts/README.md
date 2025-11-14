# CODECHECK Scripts and Documentation

This directory contains scripts and documentation for managing the CODECHECK register package.

## Contents

### download-js-libraries.sh

Shell script to download all required JavaScript libraries for the CODECHECK register.

**Usage:**
```bash
bash inst/extdata/scripts/download-js-libraries.sh
```

Or from R:
```r
system("bash inst/extdata/scripts/download-js-libraries.sh")
```

This script downloads:
- `citation.min.js` - Citation formatting library (citation-js v0.7.21)

All libraries are stored in `inst/extdata/js/` for local use (no CDN dependencies).

### JAVASCRIPT_LIBRARIES.md

Comprehensive documentation on JavaScript library management, including:
- Current libraries and their versions
- How to download and update libraries
- Testing procedures after updates
- Troubleshooting common issues
- Why we use local storage instead of CDNs

**See this file for:**
- Adding new JavaScript libraries
- Updating existing libraries
- Troubleshooting citation generator issues
- Understanding the citation.js setup (browserify bundle + wrapper)

## Quick Start

If you're setting up the package for the first time or need to refresh the JavaScript libraries:

1. Run the download script:
   ```bash
   bash inst/extdata/scripts/download-js-libraries.sh
   ```

2. Verify downloads:
   ```bash
   ls -lh inst/extdata/js/citation.min.js
   # Should show ~2.7 MB file
   ```

3. Build and test the package:
   ```r
   tinytest::build_install_test(".")
   ```

## For Developers

When working on citation features or JavaScript functionality:

1. **Never** modify `citation.min.js` directly - it's a downloaded library
2. **Do** modify `citation-wrapper.js` if needed to adjust how Cite is exposed globally
3. **Always** update `JAVASCRIPT_LIBRARIES.md` when changing library versions
4. **Always** update `NEWS.md` when making changes that affect users
5. **Test** certificate pages after any changes to JavaScript files

## See Also

- `../js/` - JavaScript library storage directory
- `../templates/cert/` - Certificate page templates that use these libraries
- `../../R/utils_render_cert_htmls.R` - R code for certificate rendering
