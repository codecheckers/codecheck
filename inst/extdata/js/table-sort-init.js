document.addEventListener("DOMContentLoaded", function () {
  if (typeof jQuery === "undefined" || !jQuery.fn.stupidtable) {
    return;
  }

  jQuery("table").stupidtable();
});
