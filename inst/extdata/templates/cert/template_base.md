---
title: $title$
---

<style>
  h1 {
    margin-bottom: 10px; 
  }

  .content-wrapper {
    display: flex;
    gap: 20px; /* Space between the image slider and the right content */
    align-items: stretch; /* Make both sides (left and right) stretch to the same height */
  }

  /* Left side (Image slider) */
  .image-slider {
    /* max-width: 550px; */
    border: 1px solid #ccc;
    padding: 5px;
    text-align: center;
    display: flex;
    flex-direction: column;
  }

  .slider-buttons {
    margin-top: 5px;
  }

  /* Right content container */
  .right-content {
    display: flex;
    flex-direction: column; /* Stack paper details and codecheck details vertically */
    gap: 20px; /* Space between paper details and codecheck details */
    flex-grow: 1; /* Take all available space */
  }

  /* Paper details and Codecheck details */
  .paper-details, .codecheck-details {
    max-width: 550px;
    border: 1px solid #ccc;
    background-color: #f9f9f9;
    padding: 15px;
    flex-grow: 1; /* Allow both sections to grow equally */
  }

  /* Style to handle long abstracts */
  .abstract-box {
    max-height: 100px; /* Set a maximum height */
    overflow-y: auto; /* Enable vertical scrolling if content exceeds max-height */
    border: 1px solid #ddd;
    padding: 10px;
    background-color: #fff;
  }

  /* Style to handle long summaries */
  .summary-box {
    max-height: 100px;
    overflow-y: auto;
    border: 1px solid #ddd;
    padding: 10px;
    background-color: #fff;
  }

  /* Style to define when we need a scrollable box*/
  .scrollable {
    max-height: 100px;
    overflow-y: auto;
  }
</style>

<div class="content-wrapper">

  <div class="image-slider">
  <!-- Image Slider Section -->
  <div style="max-width: 450px; padding: 5px; text-align: center;">
  
  <!-- Buttons for changing the image -->
  <div style="margin-top: 5px;">
  <button onclick="changeImage(-1)" style="padding: 5px 10px; border-radius: 5px; border: 1px solid #ccc; background-color: #f9f9f9; box-shadow: 0 2px 2px rgba(0, 0, 0, 0.1);">Previous</button>
  <button onclick="changeImage(1)" style="padding: 5px 10px; border-radius: 5px; border: 1px solid #ccc; background-color: #f9f9f9; box-shadow: 0 2px 2px rgba(0, 0, 0, 0.1);">Next</button>
  </div>

  <!-- Slider Image -->
  <img id="slider-image" src="cert_1.png" alt="Image 1" style="width: 100%; height: auto;">
  </div>
  </div>

  <!-- Right Side Content (Paper Details + Codecheck details) -->
  <div class="right-content">
    
  <!-- Paper Details Section -->
  <div class="paper-details">
  <h3 style="color: darkgreen; margin-top: 0;">Paper details</h3>
  <p><strong>Paper title</strong>: $paper_title$</p>  
  <p><strong>Paper authors</strong>: $paper_authors$</p>  
  
  <!-- Abstract section if available -->
  $abstract$
  </div>

  <!-- Codecheck Details Section -->
  <div class="codecheck-details">
  <h3 style="color: darkgreen; margin-top: 0;">Codecheck details</h3>
  <p><strong>Codecheck certificate</strong>: $codecheck_cert$</p>
  <p><strong>$codechecker_names_heading$</strong>: $codechecker_names$</p>
  <p><strong>Codecheck time</strong>: $codecheck_time$</p>  
  <p><strong>Codecheck repo</strong>: $codecheck_repo$</p>
  <p><strong>Codecheck report</strong>: $codecheck_report$</p>
  
  <!-- Summary -->
  <p><strong>Summary</strong>: <span id="summary-content">$codecheck_summary$</span></p>
  <div class="summary-box" id="summary-box" style="display: none;">
  <p id="summary-content-div">$codecheck_summary$</p>
  </div>

  </div>

  </div>

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
  document.getElementById('slider-image').src = images[currentIndex];
}

// Dynamically adjusting the summary section
document.addEventListener("DOMContentLoaded", function() {
  var summaryContent = document.getElementById("summary-content");
  var summaryBox = document.getElementById("summary-box");
  var summaryContentDiv = document.getElementById("summary-content-div");
  
  var minHeight = 100; // Set your minimum height

  // Temporarily set to block to measure height accurately
  summaryContent.style.display = 'block';
  
  // Check the height of the inline content
  var contentHeight = summaryContent.offsetHeight;
  
  // If the content exceeds minHeight, use the summary-box div
  if (contentHeight > minHeight) {
    summaryContent.style.display = 'none';
    summaryBox.style.display = 'block';
  } 
  
  // If the content is less than or equal to minHeight, keep it inline
  else {
    summaryContent.style.display = 'inline';
    summaryBox.style.display = 'none';
  }
});
</script>