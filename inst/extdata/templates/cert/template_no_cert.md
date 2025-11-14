---
title: $title$
---
<p class="fs-3 fw">
The certificate can be found at this $codecheck_report_subtext$
</p>

<link href="../../libs/bootstrap/bootstrap.min.css" rel="stylesheet">
<link href="../../assets/codecheck-register.css" rel="stylesheet">
<div class="cert-container container-fluid">
  <div class="row">

  <!-- Paper details -->
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
  </div>

  <!-- CODECHECK details -->
  <div class="col-md-6 d-flex flex-column">
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
  </div>
  </div>
  </div>
  </div>

  <p class="text-muted cert-footer-link">
    <a href="index.json">View certificate data as JSON</a>
  </p>
</div>

<script src="../../libs/codecheck/cert-utils.js"></script>

<script>
document.addEventListener("DOMContentLoaded", function() {
  initializeCertificateSections();
});
</script>
