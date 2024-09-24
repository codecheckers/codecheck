---
title: $title$
---

<style>
  h1 {
    margin-bottom: 10px; 
  }
</style>

**Paper title**: $paper_title$  
**Paper authors**: $paper_authors$  
**Codechecker name**: $codechecker_name$  
**Date of codecheck**: $codecheck_date$  
**Codecheck repo**: $codecheck_repo$

<div style="display: flex; align-items: flex-start; gap: 20px;">

  <!-- Image Slider Section -->
  <div style="max-width:450px; border: 1px solid #ccc; padding: 5px; text-align: center;">
  
  <!-- Buttons for changing the image -->
  <div style="margin-top: 5px;">
  <button onclick="changeImage(-1)" style="padding: 5px 10px; border-radius: 5px; border: 1px solid #ccc; background-color: #f9f9f9; box-shadow: 0 2px 2px rgba(0, 0, 0, 0.1);">Previous</button>
  <button onclick="changeImage(1)" style="padding: 5px 10px; border-radius: 5px; border: 1px solid #ccc; background-color: #f9f9f9; box-shadow: 0 2px 2px rgba(0, 0, 0, 0.1);">Next</button>
  </div>

  <!-- Slider Image -->
  <img id="slider-image" src="cert_1.png" alt="Image 1" style="width:100%; height:auto;">
  
  </div>

  <!-- Abstract Section -->
  <div style="flex: 1; border: 1px solid #ccc; background-color: #f9f9f9; padding: 15px;">
  <h3 style="color: darkgreen; margin-top: 0;">Abstract</h3>
  <p>$abstract$</p> <!-- You can replace this with actual content or R Markdown variables -->
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
</script>
