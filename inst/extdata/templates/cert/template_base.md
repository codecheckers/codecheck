---
title: $title$
---

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

  .img-background {
    background-position: center;
    background-repeat: no-repeat;
    background-size: contain;
    height: 100%;
  }
  .wrapper {
    height: 80vh;
    padding: 0px;
  }
  .row {
    margin: 5px;
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
  <div class="col-md-6">
  <div class="card mb-3">
  <div class="card-body">
  <!-- Buttons to change cert page -->
  <div class="d-flex justify-content-center">
  <button type="button" onclick="changeImage(-1)" class="btn btn-outline-secondary mx-2">
  <h4>Previous</h4>
  </button>
  <button type="button" onclick="changeImage(1)" class="btn btn-outline-secondary mx-2">
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

  <script src="../../libs/bootstrap/bootstrap.bundle.min.js"></script>
</div>

<script>
// Dynamically insert the images array
$var_images$
var currentIndex = 0;

function changeImage(direction) {
  currentIndex += direction;
  if (currentIndex < 0) {
    currentIndex = images.length - 1;
  } else if (currentIndex >= images.length) {
    currentIndex = 0;
  }
  // Change the src image on click
  document.getElementById('image-slider').src= images[currentIndex];
}

// Setting the cert page 1 as the display image
changeImage(0);

// Toggling display of the summary and abstract section on and off depending on if text is available
function adjustContentDisplay(contentElement, sectionElement) {
  // Check if the content is empty, in which case we hide the section
  if (!contentElement.textContent.trim()) {
    sectionElement.style.display = 'none';  
    return; 
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
