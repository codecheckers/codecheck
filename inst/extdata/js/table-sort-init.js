// Click-to-sort for the register tables (stupidtable.js), with the sort state
// of every sortable table kept in the URL query string so a particular view can
// be linked, bookmarked or cited: "?sort=-check-date" is the register sorted by
// check date, newest first. A page with more than one sortable table numbers
// them in document order: "sort", "sort2", "sort3", ...
document.addEventListener("DOMContentLoaded", function () {
  if (typeof jQuery === "undefined" || !jQuery.fn.stupidtable) {
    return;
  }

  jQuery("table").stupidtable();

  var $sortable = jQuery("table").filter(function () {
    return jQuery(this).find("thead th[data-sort]").length > 0;
  });

  if ($sortable.length === 0) {
    return;
  }

  // The parameter for the n-th sortable table on the page: sort, sort2, sort3.
  function paramName(index) {
    return index === 0 ? "sort" : "sort" + (index + 1);
  }

  // "Check date" -> "check-date", "No. of codechecks" -> "no-of-codechecks";
  // any non-alphanumeric run collapses to "-", including the non-breaking
  // space pandoc's abbreviations extension puts after "No.".
  function slugify(text) {
    return text
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
  }

  function findHeader($table, slug) {
    var $match = null;
    $table.find("thead th[data-sort]").each(function () {
      if (!$match && slugify(jQuery(this).text()) === slug) {
        $match = jQuery(this);
      }
    });
    return $match;
  }

  // Rebuild the whole query string from the live state of all sortable tables,
  // keeping any unrelated parameters, and write it without a history entry.
  function updateUrl() {
    var params = new URLSearchParams(window.location.search);

    $sortable.each(function (index) {
      var $active = jQuery(this).find("thead th.sorting-asc, thead th.sorting-desc").eq(0);
      if ($active.length === 0) {
        params.delete(paramName(index));
        return;
      }
      var prefix = $active.hasClass("sorting-desc") ? "-" : "";
      params.set(paramName(index), prefix + slugify($active.text()));
    });

    var query = params.toString();
    var url = window.location.pathname + (query ? "?" + query : "") + window.location.hash;
    window.history.replaceState(null, "", url);
  }

  var initial = new URLSearchParams(window.location.search);

  $sortable.each(function (index) {
    var $table = jQuery(this);
    $table.on("aftertablesort", updateUrl);

    var value = initial.get(paramName(index));
    if (!value) {
      return;
    }

    var direction = value.charAt(0) === "-" ? "desc" : "asc";
    var slug = value.replace(/^-/, "");
    var $th = findHeader($table, slug);
    // An unknown or unsortable column name leaves the default order alone.
    if ($th) {
      $th.stupidsort(direction);
    }
  });
});
