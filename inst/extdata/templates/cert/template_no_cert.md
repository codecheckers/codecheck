---
title: $title$
---
<p class="fs-3 fw">
The certificate can be found at this $codecheck_report_subtext$
</p>

<link href="../../libs/bootstrap/bootstrap.min.css" rel="stylesheet">


<style>
  body {
    font-family: "PT Sans", Helvetica, Arial, sans-serif;
  }

  h1 {
    margin-top: 2rem;
  }

  /* Add minimum height to cards when screen less than md */
  @media (max-width: 768px) {
    .card {
      min-height: 270px;
    }
  }

  .scrollable-container {
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  .scrollable-text-box {
    flex: 1 1 auto;
    height: 0; /*Adding a height of 0 so that the text box fills remainder of card*/
    overflow-y: auto;
    border: 1px solid #ddd;
    padding: 10px;
    background-color: #fff;
  }
  
</style>
<div class="container">
  <div class="row">

  <!-- Paper details -->
  <div class="col-md-6 d-flex flex-column">
  <div class="card mb-3 flex-grow-1">
  <div class="card-header pt-4">
  <h2 class="card-title" style="color: darkgreen; margin-top: 0;">Paper details</h2>
  </div>

  <div class="card-body d-flex flex-column">
  <p><strong>Title</strong>: $paper_title$</p>
  <p><strong>$author_names_heading$</strong>: $paper_authors$</p>

  <!-- Abstract section -->
  <div class="scrollable-container" id="abstract-section">
  <p><strong>Abstract</strong>: <i>Obtained from $abstract_source$</i></p>
  <div class="scrollable-text-box" id="abstract-content">
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
  <h2 class="card-title" style="color: darkgreen; margin-top: 0;">CODECHECK details</h2>
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
  <div class="scrollable-container" id="summary-section">
  <p><strong>Summary</strong>:</p>
  <div class="scrollable-text-box" id="summary-content">
  <p>$codecheck_summary$</p>
  </div>
  </div>
  </div>
  </div>
  </div>
  </div>
</div>

<script>

// Toggling display of the summary and abstract section on and off depending on if text is available
function adjustContentDisplay(contentElement, sectionElement) {
  // Check if the content is empty, in which case we hide the section
  if (!contentElement.textContent.trim()) {
    sectionElement.style.display = 'none';  
    return; 
  }

  // Set the min-height for elements with the "card" class
  else {
    const cardElements = document.querySelectorAll('.card');
    cardElements.forEach(card => {
      card.style.minHeight = '320px'; // Adjust this value as needed
    });
  }
}

document.addEventListener("DOMContentLoaded", function() {
  // Adjust for the summary section
  var summarySection = document.getElementById("summary-section"); 
  var summaryContent = document.getElementById("summary-content");

  adjustContentDisplay(summaryContent, summarySection);

  // Adjust for the abstract section
  var abstractSection = document.getElementById("abstract-section"); 
  var abstractContent = document.getElementById("abstract-content");

  adjustContentDisplay(abstractContent, abstractSection);
});
</script>
