/**
 * Certificate Citation Generator
 * Provides citation formatting and management for CODECHECK certificates
 * Requires: citation.js (Cite object must be available)
 */

// Global citation state
var citationData = null;
var currentCitation = '';

/**
 * Fetch certificate metadata from index.json
 * @returns {Promise<Object>} The certificate metadata
 */
async function fetchCertificateMetadata() {
  try {
    const response = await fetch('index.json');
    if (!response.ok) {
      throw new Error('Failed to fetch certificate metadata');
    }
    const metadata = await response.json();
    console.log('Certificate metadata loaded:', metadata);
    return metadata;
  } catch (error) {
    console.error('Error fetching certificate metadata:', error);
    throw error;
  }
}

/**
 * Load citation data from certificate DOI
 * @param {string} certificateDOI - The DOI of the certificate
 */
async function loadCitation(certificateDOI) {
  if (!certificateDOI || certificateDOI.trim() === '') {
    console.log('No certificate DOI provided, hiding citation section');
    document.getElementById('citation-section').style.display = 'none';
    return;
  }

  console.log('Loading citation for DOI:', certificateDOI);

  // Check if Cite library is available
  if (typeof Cite === 'undefined') {
    console.error('Cite library not available');
    document.getElementById('citation-preview').innerHTML =
      '<span class="text-danger">Citation library not loaded. Please refresh the page.</span>';
    return;
  }

  try {
    // Initialize Citation.js with the DOI
    citationData = await Cite.async(certificateDOI);
    console.log('Citation data loaded successfully');

    // Generate initial citation
    updateCitation();
  } catch (error) {
    console.error('Error loading citation:', error);
    document.getElementById('citation-preview').innerHTML =
      '<span class="text-danger">Error loading citation data from ' + certificateDOI + '. Please try again later.</span>';
  }
}

/**
 * Update the citation preview based on selected format
 */
function updateCitation() {
  if (!citationData) {
    console.log('No citation data available');
    return;
  }

  var format = document.getElementById('citation-format').value;
  var previewElement = document.getElementById('citation-preview');

  console.log('Updating citation to format:', format);

  try {
    var citation;

    // Different output formats require different citation.js templates
    switch(format) {
      case 'apa':
        citation = citationData.format('bibliography', {
          format: 'text',
          template: 'apa',
          lang: 'en-US'
        });
        break;
      case 'vancouver':
        citation = citationData.format('bibliography', {
          format: 'text',
          template: 'vancouver',
          lang: 'en-US'
        });
        break;
      case 'harvard1':
        citation = citationData.format('bibliography', {
          format: 'text',
          template: 'harvard1',
          lang: 'en-US'
        });
        break;
      case 'bibtex':
        citation = citationData.format('bibtex');
        break;
      case 'biblatex':
        citation = citationData.format('biblatex');
        break;
      case 'ris':
        citation = citationData.format('ris');
        break;
      default:
        citation = citationData.format('bibliography', {
          format: 'text',
          template: 'apa',
          lang: 'en-US'
        });
    }

    currentCitation = citation.trim();
    previewElement.textContent = currentCitation;
    console.log('Citation updated successfully');
  } catch (error) {
    console.error('Error formatting citation:', error);
    previewElement.innerHTML =
      '<span class="text-danger">Error formatting citation in ' + format + ' format.</span>';
  }
}

/**
 * Copy the current citation to clipboard
 */
function copyCitation() {
  if (!currentCitation) return;

  // Copy to clipboard
  navigator.clipboard.writeText(currentCitation).then(function() {
    // Show feedback
    var feedback = document.getElementById('copy-feedback');
    feedback.classList.remove('d-none');

    // Hide feedback after 2 seconds
    setTimeout(function() {
      feedback.classList.add('d-none');
    }, 2000);
  }).catch(function(error) {
    console.error('Error copying to clipboard:', error);
    alert('Could not copy to clipboard. Please copy manually.');
  });
}

/**
 * Initialize citation generator with event listeners
 * Fetches DOI from index.json instead of using template variable
 */
async function initializeCitationGenerator() {
  console.log('Initializing citation generator');

  // Set up event listeners for citation controls
  var formatSelect = document.getElementById('citation-format');
  if (formatSelect) {
    formatSelect.addEventListener('change', updateCitation);
    console.log('Format selector event listener added');
  } else {
    console.error('Citation format selector not found');
  }

  var copyButton = document.getElementById('copy-citation-btn');
  if (copyButton) {
    copyButton.addEventListener('click', copyCitation);
    console.log('Copy button event listener added');
  } else {
    console.error('Copy button not found');
  }

  // Fetch certificate metadata and load citation
  try {
    const metadata = await fetchCertificateMetadata();

    // Extract DOI from codecheck.report field
    const certificateDOI = metadata.codecheck?.report;

    if (!certificateDOI) {
      console.error('No DOI found in certificate metadata (codecheck.report field)');
      document.getElementById('citation-section').style.display = 'none';
      return;
    }

    console.log('Certificate DOI from JSON:', certificateDOI);

    // Load citation data with the fetched DOI
    await loadCitation(certificateDOI);
  } catch (error) {
    console.error('Error initializing citation generator:', error);
    document.getElementById('citation-preview').innerHTML =
      '<span class="text-danger">Error loading certificate metadata.</span>';
  }
}
