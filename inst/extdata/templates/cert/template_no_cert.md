---
title: $title$
---
The certificate can be found here: $report_link$
<style>
  h1 {
    margin-bottom: 10px; 
  }

  .paper-details, .abstract-section {
    flex: 1;
    max-width: 600px; /* Set a maximum width */
    border: 1px solid #ccc;
    background-color: #f9f9f9;
    padding: 15px;
  }
</style>

<div style="display: flex; align-items: flex-start; gap: 20px;">

  <!-- Paper Details Section -->
  <div class="paper-details">
  <h3 style="color: darkgreen; margin-top: 0;">Paper details</h3>
  <p><strong>Paper title</strong>: $paper_title$</p>  
  <p><strong>Paper authors</strong>: $paper_authors$</p>  
  <p><strong>Codechecker name</strong>: $codechecker_name$</p>  
  <p><strong>Date of codecheck</strong>: $codecheck_date$</p>  
  <p><strong>Codecheck repo</strong>: $codecheck_repo$</p>
  </div>

</div>

<!-- Abstract Section -->
<div class="abstract-section">
<h3 style="color: darkgreen; margin-top: 0;">Abstract</h3>
<p>$abstract$</p> 
</div>
