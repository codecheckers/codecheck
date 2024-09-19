---
title: $Title$
---

# Certificate Details

<div style="max-width:200px; float:left;">
  <img id="slider-image" src="image1.jpg" alt="Image 1" style="width:100%; height:auto;">
  <div style="text-align:center; margin-top:10px;">
    <button onclick="changeImage(-1)">Previous</button>
    <button onclick="changeImage(1)">Next</button>
  </div>
</div>

<script>
// Dynamically insert the images array
var images = [{{ images | join(', ') }}]; // e.g., ["image1.jpg", "image2.jpg", "image3.jpg"]
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

More details about the certificate can be added here.

## Abstract

abstract: $abstract$