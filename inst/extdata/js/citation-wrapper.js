/**
 * Citation.js Global Wrapper
 *
 * The citation.min.js file from npm is a browserify bundle that uses CommonJS
 * (module.exports) instead of exposing a global Cite object. This wrapper
 * extracts Cite from the require system and makes it available globally.
 *
 * Usage: Load this script immediately after citation.min.js
 */

(function() {
  'use strict';

  try {
    // The browserify bundle creates a require function and registers modules
    // The main module (732 in current version) exports Cite via module.exports
    // We need to require it and assign to window

    if (typeof require === 'function') {
      // Try common entry point module IDs used by citation-js
      var Cite = null;

      // Citation.js typically uses module ID 732 or 737 as entry points
      // Try to require the main module
      try {
        Cite = require('citation-js');
      } catch (e) {
        // If named require doesn't work, the browserify bundle might use numeric IDs
        // The bundle ends with require calls like: },{},[732,737]);
        // These are the entry points - try them
        try {
          Cite = require(732);
        } catch (e2) {
          try {
            Cite = require(737);
          } catch (e3) {
            console.error('Could not load Cite from browserify bundle:', e, e2, e3);
          }
        }
      }

      if (Cite) {
        // Export to global scope
        window.Cite = Cite;
        console.log('Citation.js loaded successfully - Cite object is now global');
      } else {
        console.error('Failed to extract Cite from browserify bundle');
      }
    } else {
      console.error('require function not found - citation.min.js may not have loaded');
    }
  } catch (error) {
    console.error('Error in citation-wrapper:', error);
  }
})();
