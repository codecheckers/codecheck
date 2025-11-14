# JavaScript Libraries

This document describes the JavaScript libraries used in the CODECHECK register and how to manage them.

## Overview

The CODECHECK register uses JavaScript libraries for interactive features on certificate pages. All libraries are stored locally in `inst/extdata/js/` to avoid dependencies on external CDNs.

## Current Libraries

### Citation.js (citation.min.js + citation-wrapper.js)

**Purpose**: Generates formatted citations from DOIs in multiple formats (APA, Vancouver, Harvard, BibTeX, BibLaTeX, RIS).

**Files**:
- `citation.min.js` (2.7 MB) - The main citation-js library (browserify bundle)
- `citation-wrapper.js` (2 KB) - Wrapper to expose Cite as a global object

**Version**: 0.7.21

**Source**: https://www.npmjs.com/package/citation-js

**Download URL**: https://cdn.jsdelivr.net/npm/citation-js@0.7.21/build/citation.min.js

**Notes**:
- The npm distribution of citation-js is a browserify bundle that uses CommonJS modules (`require`, `module.exports`)
- It does NOT expose a global `Cite` object by default
- The `citation-wrapper.js` file extracts Cite from the browserify bundle and makes it available as `window.Cite`
- The wrapper must be loaded immediately after `citation.min.js`

**Usage in templates**:
```html
<script src="../../libs/codecheck/citation.min.js"></script>
<script src="../../libs/codecheck/citation-wrapper.js"></script>
```

After these scripts load, `Cite` is available globally and can be used to format citations:
```javascript
const citationData = await Cite.async(doi);
const citation = citationData.format('bibliography', {
  format: 'text',
  template: 'apa',
  lang: 'en-US'
});
```

## Downloading Libraries

### Using the Download Script

Run the provided shell script to download all libraries:

```bash
# From the package root directory
bash inst/extdata/scripts/download-js-libraries.sh
```

Or from R:
```r
system("bash inst/extdata/scripts/download-js-libraries.sh")
```

### Manual Download

If you need to manually download a library:

1. Identify the library version and download URL (see above)
2. Download the file:
   ```bash
   curl -L "DOWNLOAD_URL" -o inst/extdata/js/FILENAME.js
   ```
3. Verify the file size matches the expected size
4. Test on a certificate page to ensure it works

## Updating Libraries

To update to a new version of a library:

1. **Check for breaking changes**: Review the library's changelog for API changes
2. **Update the download script**: Edit `download-js-libraries.sh` with the new version number
3. **Download the new version**: Run the download script
4. **Test thoroughly**: Test citation generation on multiple certificate pages
5. **Update this documentation**: Update version numbers and notes in this file
6. **Update NEWS.md**: Document the library update in the package changelog

### Testing After Updates

After updating a library, test the following:

1. **Certificate page rendering**: Visit a certificate page (e.g., `/certs/2021-009/index.html`)
2. **Citation generation**:
   - Check that citations load (no "Loading citation..." stuck state)
   - Test all citation formats (APA, Vancouver, Harvard, BibTeX, BibLaTeX, RIS)
   - Verify the "Copy" button works
3. **Browser console**: Check for JavaScript errors
4. **Cross-browser testing**: Test in Chrome, Firefox, and Safari if possible

## Library Maintenance Checklist

When adding a new library:

- [ ] Add download command to `download-js-libraries.sh`
- [ ] Document the library in this file (purpose, version, source, usage)
- [ ] Add the library to relevant templates
- [ ] Test functionality
- [ ] Update `NEWS.md`

When removing a library:

- [ ] Remove from `download-js-libraries.sh`
- [ ] Remove documentation from this file
- [ ] Remove from all templates
- [ ] Delete the file from `inst/extdata/js/`
- [ ] Update `NEWS.md`

## Why Local Storage?

We store libraries locally rather than using CDNs for several reasons:

1. **Reliability**: No dependency on external services
2. **Reproducibility**: Exact versions are locked and committed
3. **Performance**: Files are served from the same domain (no additional DNS lookups)
4. **Privacy**: No third-party tracking via CDN requests
5. **Offline access**: Register can be built and served without internet access

## Troubleshooting

### Citation.js Not Loading

**Symptoms**: Certificate page shows "Loading citation..." indefinitely

**Checks**:
1. Verify `citation.min.js` is present and non-empty:
   ```bash
   ls -lh inst/extdata/js/citation.min.js
   ```
   Expected size: ~2.7 MB

2. Verify `citation-wrapper.js` is present:
   ```bash
   ls -lh inst/extdata/js/citation-wrapper.js
   ```

3. Check browser console for errors (F12 in most browsers)

4. Verify script order in template:
   ```html
   <script src="citation.min.js"></script>
   <script src="citation-wrapper.js"></script>  <!-- Must be after citation.min.js -->
   ```

5. Test the wrapper in browser console:
   ```javascript
   console.log(typeof Cite);  // Should be "function"
   ```

**Solutions**:
- Re-download citation.min.js using the download script
- Ensure citation-wrapper.js matches the version in the repository
- Check that the template includes both scripts in the correct order

### Library Version Conflicts

If multiple versions of a library exist:

1. Check which version is loaded in the browser (Network tab in DevTools)
2. Search for duplicate script tags in templates
3. Verify `inst/extdata/js/` contains only one version of each library
4. Clear browser cache and test again

## Related Files

- `inst/extdata/js/` - JavaScript library storage
- `inst/extdata/templates/cert/template_base.md` - Main certificate template
- `inst/extdata/js/cert-citation.js` - Citation generator logic
- `inst/extdata/js/cert-utils.js` - Certificate page utilities
- `R/utils_render_cert_htmls.R` - R functions for certificate rendering
