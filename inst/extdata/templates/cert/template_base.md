---
title: $title$
---

<link href="../../libs/bootstrap/bootstrap.min.css" rel="stylesheet">
<link href="../../assets/codecheck-register.css" rel="stylesheet">

<div class="cert-container container-fluid">
  <div class="row">
  <div class="col-md-6">
  <div class="card mb-3">
  <div class="card-body">
  <!-- Buttons to change cert page -->
  <div class="d-flex justify-content-center">
  <button type="button" onclick="changeImage(-1)" class="btn btn-outline-secondary mx-2" id="prev-btn" title="View previous page">
  <h4>Previous</h4>
  </button>
  <button type="button" onclick="changeImage(1)" class="btn btn-outline-secondary mx-2" id="next-btn" title="View next page">
  <h4>Next</h4>
  </button>
  </div>

  <!-- Cert image -->
  <img class="card-img-top mb-3" src="cert_1.png" id="image-slider">
  </div>
  </div>
  </div>

  <!-- Right Side Content (Paper details + CODECHECK details) -->
  <div class="col-md-6 d-flex flex-column">
  <div class="card mb-3 flex-grow-1">
  <div class="card-header pt-4">
  <h2 class="card-title cert-card-title">Paper details</h2>
  </div>
  <div class="card-body d-flex flex-column">


  <p><strong>Title</strong>: $paper_title$</p>
  <p><strong>$author_names_heading$</strong>: $paper_authors$</p>

  <!-- Abstract section -->
  <div class="text-container" id="abstract-section">
  <p><strong>Abstract</strong>: <i>Obtained from $abstract_source$</i></p>
  <div class="text-box" id="abstract-content">
  <p>$abstract_content$</p>
  </div>
  </div>
  </div>

  </div>

  <div class="card mb-3 flex-grow-1">
  <div class="card-header pt-4">
  <h2 class="card-title cert-card-title">CODECHECK details</h2>
  </div>
  <div class="card-body d-flex flex-column">
  <p><strong>Certificate identifier</strong>: $codecheck_cert$</p>
  <p><strong>$codechecker_names_heading$</strong>: $codechecker_names$</p>
  <p><strong>Time of check</strong>: $codecheck_time$</p>
  <p><strong>Repository</strong>: $codecheck_repo$</p>
  <p><strong>Full certificate</strong>: $codecheck_full_certificate$</p>
  <p><strong>Type</strong>: $codecheck_type$</p>
  <p><strong>Venue</strong>: $codecheck_venue$</p>

  <!-- Summary -->
  <div class="text-container" id="summary-section">
  <p><strong>Summary</strong>:</p>
  <div class="text-box" id="summary-content">
  <p>$codecheck_summary$</p>
  </div>
  </div>

  <!-- Citation Generator -->
  <div class="mt-3" id="citation-section">
  <p>
    <strong>Cite this certificate</strong>:
    <span class="text-muted ms-2" style="font-size: 0.9em;">Citation metadata retrieved from data.crosscite.org</span>
  </p>
  <div class="mb-2">
  <select class="form-select" id="citation-format" aria-label="Citation format" title="Choose citation style">
  <option value="apa">APA</option>
  <option value="vancouver">Vancouver</option>
  <option value="harvard1">Harvard</option>
  <option value="bibtex" selected>BibTeX</option>
  <option value="biblatex">BibLaTeX</option>
  <option value="ris">RIS</option>
  </select>
  </div>
  <div class="citation-preview-wrapper mb-2">
  <div class="border rounded p-2 citation-preview" id="citation-preview">
  <span class="text-muted">Loading citation...</span>
  </div>
  <button class="btn btn-outline-secondary citation-copy-btn" id="copy-citation-btn" type="button" title="Copy citation to clipboard">
  <i class="ai ai-doi ai-2x"></i>
  </button>
  <span class="text-success citation-copy-feedback d-none" id="copy-feedback">Copied!</span>
  </div>
  </div>
  </div>
  </div>
  </div>

  <script src="../../libs/bootstrap/bootstrap.bundle.min.js"></script>
  <script src="../../libs/codecheck/citation.min.js"></script>
  <script src="../../libs/codecheck/citation-wrapper.js"></script>
  <script src="../../libs/codecheck/cert-utils.js"></script>
  <script src="../../libs/codecheck/cert-citation.js"></script>

  <p class="text-muted cert-footer-link">
    <a href="index.json">View certificate data as JSON</a>
  </p>
</div>

<script>
// Dynamically insert the images array
$var_images$
var currentIndex = 0;

// Initialize page on DOM load
document.addEventListener("DOMContentLoaded", function() {
  // Setting the cert page 1 as the display image
  changeImage(0);

  initializeCertificateSections();

  // Initialize auto-pagination
  if (typeof initializeAutoPagination === 'function') {
    initializeAutoPagination();
  }

  // Initialize citation generator
  // The citation-wrapper.js ensures Cite is available globally
  if (typeof initializeCitationGenerator === 'function') {
    initializeCitationGenerator();
  } else {
    console.error('Citation generator function not available');
  }
});

</script>
