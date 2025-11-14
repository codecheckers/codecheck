/**
 * Certificate Page Utilities
 * Shared JavaScript functions for CODECHECK certificate pages
 */

// Auto-pagination state
var autoPaginationInterval = null;
var autoPaginationEnabled = true;

/**
 * Adjust content display - hide empty sections and set card heights
 * @param {HTMLElement} contentElement - The element containing the content to check
 * @param {HTMLElement} sectionElement - The section element to show/hide
 */
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
      card.style.minHeight = '320px';
    });
  }
}

/**
 * Update button titles with current page information
 */
function updateButtonTitles() {
  var totalPages = images.length;
  var nextPage = (currentIndex + 1) % totalPages + 1;
  var prevPage = (currentIndex - 1 + totalPages) % totalPages + 1;
  var currentPage = currentIndex + 1;

  var prevBtn = document.getElementById('prev-btn');
  var nextBtn = document.getElementById('next-btn');

  if (prevBtn) {
    prevBtn.title = 'View previous page ' + prevPage + '/' + totalPages + ' of the certificate';
  }

  if (nextBtn) {
    nextBtn.title = 'View next page ' + nextPage + '/' + totalPages + ' of the certificate';
  }
}

/**
 * Image slider for certificate pages
 * @param {number} direction - Direction to move (-1 for previous, 1 for next)
 */
function changeImage(direction) {
  currentIndex += direction;
  if (currentIndex < 0) {
    currentIndex = images.length - 1;
  } else if (currentIndex >= images.length) {
    currentIndex = 0;
  }
  // Change the src image on click
  document.getElementById('image-slider').src = images[currentIndex];

  // Update button titles with new page numbers
  updateButtonTitles();
}

/**
 * Stop auto-pagination
 */
function stopAutoPagination() {
  if (autoPaginationInterval) {
    clearInterval(autoPaginationInterval);
    autoPaginationInterval = null;
    autoPaginationEnabled = false;
    console.log('Auto-pagination stopped');
  }
}

/**
 * Start auto-pagination (advances to next page every 5 seconds)
 */
function startAutoPagination() {
  if (!autoPaginationEnabled) {
    return;
  }

  console.log('Starting auto-pagination');

  autoPaginationInterval = setInterval(function() {
    if (!autoPaginationEnabled) {
      stopAutoPagination();
      return;
    }

    // Call changeImage directly to avoid triggering click event listeners
    changeImage(1);
    console.log('Auto-pagination: advanced to next page');
  }, 5000); // 5 seconds
}

/**
 * Initialize certificate page sections on DOM load
 * Adjusts display for summary and abstract sections
 */
function initializeCertificateSections() {
  // Adjust for the summary section
  var summarySection = document.getElementById("summary-section");
  var summaryContent = document.getElementById("summary-content");
  if (summarySection && summaryContent) {
    adjustContentDisplay(summaryContent, summarySection);
  }

  // Adjust for the abstract section
  var abstractSection = document.getElementById("abstract-section");
  var abstractContent = document.getElementById("abstract-content");
  if (abstractSection && abstractContent) {
    adjustContentDisplay(abstractContent, abstractSection);
  }

  // Initialize button titles
  if (typeof images !== 'undefined' && images.length > 0) {
    updateButtonTitles();
  }
}

/**
 * Initialize auto-pagination and stop handlers
 */
function initializeAutoPagination() {
  // Only start auto-pagination if there are multiple pages
  if (typeof images === 'undefined' || images.length <= 1) {
    console.log('Single page certificate, auto-pagination not needed');
    return;
  }

  // Add event listeners to stop auto-pagination on user interaction
  var prevBtn = document.getElementById('prev-btn');
  var nextBtn = document.getElementById('next-btn');
  var imageSlider = document.getElementById('image-slider');

  if (prevBtn) {
    prevBtn.addEventListener('click', stopAutoPagination);
  }

  if (nextBtn) {
    nextBtn.addEventListener('click', stopAutoPagination);
  }

  if (imageSlider) {
    imageSlider.addEventListener('click', stopAutoPagination);
  }

  // Start auto-pagination after page is fully loaded
  window.addEventListener('load', function() {
    console.log('Page fully loaded, starting auto-pagination in 1 second');
    // Wait 1 second before starting to give user a moment to see the first page
    setTimeout(startAutoPagination, 1000);
  });
}
