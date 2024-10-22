---
title: $title$
---

<style>
  h1 {
    margin-bottom: 20px;
    color: darkgreen;
    text-align: center;
  }

  h3 {
    margin-top: 0;
    color: darkgreen;
    padding-bottom: 10px;
    border-bottom: 2px solid green;
  }

  .content-wrapper {
    display: flex;
    gap: 20px; /* Space between the image slider and the right content */
    max-width: 100%; /* Prevents overflow */
  }

  /* Left side (Image slider) */
  .image-slider {
    max-width: calc(68vh * 1.5); /* Fixed width based on viewport height */
    border: 1px solid #ccc;
    padding: 5px;
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    background-color: #fff;
    width: 100%; 
    min-height: 68vh; /* Fixed height */
    background-size: contain;
    background-position: center center;
    background-repeat: no-repeat;
  }

  /* Buttons for image slider */
  .slider-buttons button {
    padding: 5px 10px;
    border-radius: 5px;
    border: 1px solid #ccc;
    background-color: #f9f9f9;
    box-shadow: 0 2px 2px rgba(0, 0, 0, 0.1);
    margin-right: 10px;
    margin-top: -10px;
    margin-bottom: 50px;
    transition: background-color 0.3s ease, box-shadow 0.3s ease;
  }

  /* Effects when hovering over slider buttons */
  .slider-buttons button:hover {
    background-color: #e0e0e0;
    box-shadow: 0 4px 4px rgba(0, 0, 0, 0.2);
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
    padding: 20px;
    max-width: 550px;
    min-width: 450px;
    border: 1px solid #ccc;
    background-color: #f9f9f9;
    flex-grow: 1; /* Allow both sections to grow equally */
  }

  /* Style to handle long abstracts and summaries */
  .scrollable-text-box {
    max-height: 100px;
    overflow-y: auto;
    border: 1px solid #ddd;
    padding: 10px;
    background-color: #fff;
  }

</style>

<div class="content-wrapper">

  <!-- Left Column (Image Slider) -->
  <div class="image-slider" id="image-slider">
  
  <!-- Buttons for changing the image -->
  <div class="slider-buttons" style="margin-top: 5px;">
  <button onclick="changeImage(-1)">Previous</button>
  <button onclick="changeImage(1)">Next</button>
  </div>
  
  </div>

  <!-- Right Side Content (Paper Details + Codecheck details) -->
  <div class="right-content">
    
  <!-- Paper Details Section -->
  <div class="paper-details">
  <h3>Paper details</h3>
  
  <p><strong>Title</strong>: $paper_title$</p>  
  <p><strong>$author_names_heading$</strong>: $paper_authors$</p>  
  
  <!-- Abstract section -->
  <div id="abstract-section">
  <p><strong>Abstract</strong>: <i>Obtained from $abstract_source$</i></p>
  <span id="abstract-content">$abstract_content$</span>
  <div class="scrollable-text-box" id="scrollable-text-box-abstract" style="display: none;">
  <p>$abstract_content$</p>
  </div>
  </div>
  </div>

  <!-- Codecheck Details Section -->
  <div class="codecheck-details">
  <h3 style="color: darkgreen; margin-top: 0;">Codecheck details</h3>
  <p><strong>Certificate identifier</strong>: $codecheck_cert$</p>
  <p><strong>$codechecker_names_heading$</strong>: $codechecker_names$</p>
  <p><strong>Time of codecheck</strong>: $codecheck_time$</p>  
  <p><strong>Repository</strong>: $codecheck_repo$</p>
  <p><strong>Codecheck report</strong>: $codecheck_report$</p>
  
  <!-- Summary -->
  <div id="summary-section">
  <p><strong>Summary</strong>: <span id="summary-content">$codecheck_summary$</span></p>
  <div class="scrollable-text-box" id="scrollable-text-box-summary" style="display: none;">
  <p>$codecheck_summary$</p>
  </div>
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
  // Change the background image of the slider
  document.getElementById('image-slider').style.backgroundImage = `url(${images[currentIndex]})`;
}

// Setting the cert page 1 as the display image
changeImage(0);

function adjustContentDisplay(contentElement, boxElement, minHeight, sectionElement) {

  console.log("Checking content:", contentElement.textContent.trim());
  // Check if the content is empty, in which case we hide the section
  if (!contentElement.textContent.trim()) {
    sectionElement.style.display = 'none';  
    return; 
  }

  // Temporarily set content to block to measure height accurately
  contentElement.style.display = 'block';
  
  // Check the height of the content
  var contentHeight = contentElement.offsetHeight;
  
  // If the content exceeds minHeight, show the box element
  if (contentHeight > minHeight) {
    contentElement.style.display = 'none';  // Hide inline content
    boxElement.style.display = 'block';     // Show box content
  } else {
    contentElement.style.display = 'inline'; // Keep inline content visible
    boxElement.style.display = 'none';       // Hide box
  }
}

document.addEventListener("DOMContentLoaded", function() {
  // Adjust for the summary section
  var summarySection = document.getElementById("summary-section"); // The entire summary section container
  var summaryContent = document.getElementById("summary-content");
  var summaryBox = document.getElementById("scrollable-text-box-summary");
  var minHeightSummary = 100; // Minimum height for summary

  adjustContentDisplay(summaryContent, summaryBox, minHeightSummary, summarySection);

  // Adjust for the abstract section
  var abstractSection = document.getElementById("abstract-section"); // The entire abstract section container
  var abstractContent = document.getElementById("abstract-content");
  var abstractBox = document.getElementById("scrollable-text-box-abstract");
  var minHeightAbstract = 100; // Minimum height for abstract

  adjustContentDisplay(abstractContent, abstractBox, minHeightAbstract, abstractSection);
});

</script>
