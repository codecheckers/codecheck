#' Render the register-wide statistics dashboard page
#'
#' Builds `docs/statistics/index.html` from the already-written
#' `docs/statistics.json` (addresses register#33, register#48): a
#' checks-over-time timeline, a platform-per-year breakdown, a venue grid
#' (grouped by type, with logo/link metadata from `venues.csv` where
#' available) and a publisher summary table. Must run after
#' `docs/statistics.json` has been written (i.e. after
#' [create_register_files()] or [register_update_stats()]), since it only
#' reads that file - it does not recompute statistics itself.
#'
#' @param docs_dir Path to the docs output directory (default: "docs")
#'
#' @author Daniel Nuest
#' @importFrom whisker whisker.render
#' @importFrom jsonlite fromJSON toJSON
#' @export
render_statistics_page <- function(docs_dir = "docs") {
  stats_path <- file.path(docs_dir, "statistics.json")
  if (!file.exists(stats_path)) {
    cli::cli_alert_warning("No {.path {stats_path}} found, skipping statistics page")
    return(invisible(NULL))
  }

  stats <- jsonlite::fromJSON(stats_path, simplifyVector = FALSE)

  output_dir <- file.path(docs_dir, "statistics")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  table_details <- list(is_reg_table = FALSE)
  base_path <- ".."

  # --- header (meta tags) ---
  create_index_header_html(output_dir, schema_org_jsonld = "", include_version_in_meta = TRUE)

  # --- prefix (nav + breadcrumb) ---
  nav_html <- generate_navigation_header("statistics", base_path, table_details)
  breadcrumb_html <- generate_breadcrumb("statistics", table_details, base_path)
  writeLines(
    paste0(nav_html, '<div class="breadcrumb-container">\n', breadcrumb_html, '\n</div>\n'),
    file.path(output_dir, "index_prefix.html")
  )

  # --- postfix (footer, reusing the non-register-table footer template) ---
  postfix_template <- readLines(CONFIG$TEMPLATE_DIR[["non_reg"]][["postfix"]], warn = FALSE)
  build_info <- ""
  if (exists("BUILD_METADATA", envir = CONFIG) && !is.null(CONFIG$BUILD_METADATA)) {
    build_info <- generate_footer_build_info(CONFIG$BUILD_METADATA)
  }
  postfix_output <- whisker.render(postfix_template, list(
    json_href = paste0(base_path, "/statistics.json"),
    build_info = build_info
  ))
  writeLines(postfix_output, file.path(output_dir, "index_postfix.html"))

  generate_html_document_yml(output_dir)

  # --- body content ---
  content_html <- build_statistics_content_html(stats)

  md_template <- readLines(CONFIG$TEMPLATE_DIR[["non_reg"]][["md_template"]], warn = FALSE)
  md_content <- gsub("\\$title\\$", "CODECHECK Statistics", md_template)
  md_content <- gsub("\\$subtitle\\$", "An overview of checks, venues, codecheckers and publishers in the CODECHECK register", md_content)
  md_content <- gsub("\\$profile_links\\$", "", md_content)
  md_content <- gsub("$content$", content_html, md_content, fixed = TRUE)
  md_content <- gsub("\\$extra_text\\$", "", md_content)

  temp_md_path <- file.path(output_dir, "temp.md")
  writeLines(md_content, temp_md_path)

  temp_files <- file.path(output_dir, c("temp.md", "index_header.html", "index_prefix.html", "index_postfix.html", "html_document.yml"))
  on.exit({
    for (f in temp_files) {
      if (file.exists(f)) file.remove(f)
    }
  }, add = TRUE)

  yaml_path <- normalizePath(file.path(getwd(), output_dir, "html_document.yml"))

  # See register.R's register_render() (codecheckers/codecheck#89): without
  # this, rmarkdown injects a header-attrs dependency versioned by
  # packageVersion("rmarkdown") that this page doesn't need (a no-op here,
  # same as elsewhere on the register) but that register_render() otherwise
  # strips from every other page - set independently so this function renders
  # the same page whether called from register_render() or standalone (e.g.
  # from register_update_stats()).
  old_opts <- options(rmarkdown.html_dependency.header_attr = FALSE)
  on.exit(options(old_opts), add = TRUE)

  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path,
    quiet = !isTRUE(CONFIG$VERBOSE)
  )

  html_file_path <- file.path(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)
  unlink(file.path(output_dir, "libs"), recursive = TRUE)

  cli::cli_alert_success("Rendered statistics dashboard to {.path {html_file_path}}")
  invisible(html_file_path)
}

#' Colour for a venue type
#'
#' Named lookup in `CONFIG$VENUE_TYPE_COLORS`, so the statistics page, the
#' codecheckers table (register#92) and the codechecker donut (register#207)
#' all colour a given venue type the same way. Any type not in the map gets
#' `CONFIG$VENUE_TYPE_COLOR_FALLBACK` rather than another type's colour.
#'
#' @param type A venue type, e.g. `"journal"`.
#' @return A hex colour string.
#' @keywords internal
venue_type_color <- function(type) {
  color <- CONFIG$VENUE_TYPE_COLORS[[type]]
  if (is.null(color)) CONFIG$VENUE_TYPE_COLOR_FALLBACK else color
}

#' Build the HTML body content of the statistics dashboard
#'
#' @param stats The parsed contents of `statistics.json` (a list)
#' @return A single HTML string, safe to embed as a pandoc raw-HTML block
#' @keywords internal
build_statistics_content_html <- function(stats, base_path = "..") {
  num <- function(x, default = 0) if (is.null(x)) default else x

  summary_cards <- paste0(
    '<div class="row stats-summary-row">\n',
    stats_summary_card("Certificates", num(stats$cert_count), paste0(base_path, "/index.html")),
    stats_summary_card("Venues", num(stats$venue_count), paste0(base_path, "/venues/index.html")),
    # /codecheckers/ is retired (#123) - the card still counts codecheckers
    # (from the Codechecker column compute_annual_stats() reads), but now
    # links to /persons/, which covers the same people plus paper authors.
    stats_summary_card("Codecheckers", num(stats$codechecker_count), paste0(base_path, "/persons/index.html")),
    '</div>\n'
  )

  checks_labels <- names(stats$checks_cumulative)
  checks_values <- unlist(stats$checks_cumulative, use.names = FALSE)

  # register_update_stats()'s fast path recomputes from docs/register.json,
  # which carries no Codechecker column, so codecheckers_cumulative is simply
  # absent there (only a full register_render() can compute it). Leave every
  # value NA/null in that case rather than a misleading flat line at 0 -
  # Chart.js renders null points as a gap instead of drawing them.
  codecheckers_values <- vapply(checks_labels, function(y) {
    v <- stats$codecheckers_cumulative[[y]]
    if (is.null(v)) NA_integer_ else as.integer(v)
  }, integer(1))
  if (!is.null(stats$codecheckers_cumulative)) {
    # Cumulative counts never decrease - carry the last known value forward
    # into any year gap instead of leaving it NA (which would break the line).
    for (i in seq_along(codecheckers_values)) {
      if (is.na(codecheckers_values[i])) {
        codecheckers_values[i] <- if (i > 1) codecheckers_values[i - 1] else 0L
      }
    }
  }

  platform_years <- names(stats$platform_cumulative)
  platform_names <- unique(unlist(lapply(stats$platform_cumulative, names)))
  platform_datasets <- lapply(platform_names, function(p) {
    vapply(platform_years, function(y) {
      v <- stats$platform_cumulative[[y]][[p]]
      if (is.null(v)) 0L else as.integer(v)
    }, integer(1))
  })
  names(platform_datasets) <- platform_names

  venue_type_years <- names(stats$checks_per_type_per_year)
  venue_type_names <- unique(unlist(lapply(stats$checks_per_type_per_year, names)))
  venue_type_datasets <- lapply(venue_type_names, function(t) {
    vapply(venue_type_years, function(y) {
      v <- stats$checks_per_type_per_year[[y]][[t]]
      if (is.null(v)) 0L else as.integer(v)
    }, integer(1))
  })
  names(venue_type_datasets) <- venue_type_names

  # Keyed by type name (not by position) so the JS looks a colour up rather
  # than indexing into an array whose order depends on the data.
  venue_type_colors <- lapply(venue_type_names, venue_type_color)
  names(venue_type_colors) <- venue_type_names

  charts_html <- paste0(
    '<div class="row stats-charts-row">\n',
    '  <div class="col-md-6"><h3>Checks and codecheckers over time</h3><canvas id="checksChart" height="220"></canvas>',
    '<a href="#" class="chart-reset-link" id="checksChartReset">Show all</a></div>\n',
    '  <div class="col-md-6"><h3>Checks by publication platform</h3><canvas id="platformChart" height="220"></canvas>',
    '<a href="#" class="chart-reset-link" id="platformChartReset">Show all</a></div>\n',
    '</div>\n',
    '<div class="row stats-charts-row">\n',
    '  <div class="col-md-12"><h3>Venues by type</h3><canvas id="venueTypeChart" height="140"></canvas>',
    '<a href="#" class="chart-reset-link" id="venueTypeChartReset">Show all</a></div>\n',
    '</div>\n',
    '<div class="row stats-charts-row">\n',
    '  <div class="col-md-6"><h3>Time from work publication to check</h3><canvas id="intervalChart" height="220"></canvas></div>\n',
    '  <div class="col-md-6"><h3>Every certificate, individually (check time)</h3><div id="intervalBeeswarm" class="interval-beeswarm"></div></div>\n',
    '</div>\n'
  )

  interval_html <- build_interval_summary_html(stats$interval_summary, stats$interval_n, stats$interval_excluded)

  venues_html <- build_venues_grid_html(stats$venues_detail, base_path)
  publishers_html <- build_publishers_table_html(stats$publishers)

  interval_bucket_labels <- c("Before publication", "0-1mo", "1-3mo", "3-6mo", "6-12mo", "1-2y", "2-5y", "5y+")
  interval_bucket_values <- vapply(interval_bucket_labels, function(b) {
    v <- stats$interval_buckets[[b]]
    if (is.null(v)) 0L else as.integer(v)
  }, integer(1))

  chart_data_json <- jsonlite::toJSON(list(
    checks_labels = checks_labels,
    checks_values = checks_values,
    codecheckers_values = unname(codecheckers_values),
    platform_years = platform_years,
    platform_datasets = platform_datasets,
    venue_type_years = venue_type_years,
    venue_type_datasets = venue_type_datasets,
    venue_type_colors = venue_type_colors,
    interval_bucket_labels = unname(interval_bucket_labels),
    interval_bucket_values = unname(interval_bucket_values),
    interval_points = stats$interval_points,
    cert_base_path = paste0(base_path, "/certs/")
  ), auto_unbox = TRUE)

  script_html <- paste0(
    '<script src="../libs/chartjs/chart.umd.min.js"></script>\n',
    '<script id="codecheck-stats-data" type="application/json">', chart_data_json, '</script>\n',
    '<script>\n',
    'document.addEventListener("DOMContentLoaded", function () {\n',
    '  var data = JSON.parse(document.getElementById("codecheck-stats-data").textContent);\n',
    '  var platformNames = { zenodo: "Zenodo", osf: "OSF", researchequals: "ResearchEquals" };\n',
    '  function platformLabel(key) {\n',
    '    return platformNames[key] || (key.charAt(0).toUpperCase() + key.slice(1));\n',
    '  }\n',
    '  // Legend items are canvas-drawn, not real DOM elements, so a native title\n',
    '  // attribute on the canvas is the only way to surface hover text for them.\n',
    '  // Toggling a legend item can leave an axis with no visible dataset on it\n',
    '  // (e.g. the right-hand "Codecheckers" axis once that line is hidden) - hide\n',
    '  // any axis nothing currently visible plots against, and bring it back once\n',
    '  // a dataset using it is shown again.\n',
    '  function updateAxesForVisibility(chart) {\n',
    '    var scales = chart.options.scales || {};\n',
    '    Object.keys(scales).forEach(function (axisId) {\n',
    '      if (axisId === "x") return;\n',
    '      var used = chart.data.datasets.some(function (ds, i) {\n',
    '        return (ds.yAxisID || "y") === axisId && chart.isDatasetVisible(i);\n',
    '      });\n',
    '      scales[axisId].display = used;\n',
    '    });\n',
    '    chart.update();\n',
    '  }\n',
    '  function resetChart(chart) {\n',
    '    chart.data.datasets.forEach(function (ds, i) { chart.show(i); });\n',
    '    updateAxesForVisibility(chart);\n',
    '  }\n',
    '  function addResetLink(id, chart) {\n',
    '    var el = document.getElementById(id);\n',
    '    if (el) el.addEventListener("click", function (e) { e.preventDefault(); resetChart(chart); });\n',
    '  }\n',
    '  function legendHoverPlugin(getTitle) {\n',
    '    return {\n',
    '      onHover: function (event, legendItem, legend) {\n',
    '        legend.chart.canvas.style.cursor = "pointer";\n',
    '        legend.chart.canvas.title = getTitle(legendItem);\n',
    '      },\n',
    '      onLeave: function (event, legendItem, legend) {\n',
    '        legend.chart.canvas.style.cursor = "default";\n',
    '        legend.chart.canvas.title = "";\n',
    '      },\n',
    '      onClick: function (event, legendItem, legend) {\n',
    '        Chart.defaults.plugins.legend.onClick.call(this, event, legendItem, legend);\n',
    '        updateAxesForVisibility(legend.chart);\n',
    '      }\n',
    '    };\n',
    '  }\n',
    '  var checksChart = new Chart(document.getElementById("checksChart"), {\n',
    '    type: "line",\n',
    '    data: { labels: data.checks_labels, datasets: [\n',
    '      { label: "Cumulative certificates", data: data.checks_values, borderColor: "#2c7a4b", backgroundColor: "rgba(44,122,75,0.15)", fill: true, tension: 0.2, yAxisID: "y" },\n',
    '      { label: "Cumulative codecheckers", data: data.codecheckers_values, borderColor: "#8a4fbf", backgroundColor: "rgba(138,79,191,0.15)", fill: false, tension: 0.2, yAxisID: "y1" }\n',
    '    ] },\n',
    '    options: { scales: {\n',
    '      y: { beginAtZero: true, position: "left", title: { display: true, text: "Certificates" } },\n',
    '      y1: { beginAtZero: true, position: "right", title: { display: true, text: "Codecheckers" }, grid: { drawOnChartArea: false } }\n',
    '    }, plugins: { legend: legendHoverPlugin(function (item) { return "Click to show/hide " + item.text; }) } }\n',
    '  });\n',
    '  addResetLink("checksChartReset", checksChart);\n',
    '  var platformColors = ["#2c7a4b", "#3f7fbf", "#c97a2c", "#8a4fbf", "#bf3f5f"];\n',
    '  var platformDatasets = Object.keys(data.platform_datasets).map(function (name, i) {\n',
    '    return { label: platformLabel(name), data: data.platform_datasets[name], borderColor: platformColors[i % platformColors.length], backgroundColor: platformColors[i % platformColors.length], fill: false, tension: 0.2 };\n',
    '  });\n',
    '  var platformChart = new Chart(document.getElementById("platformChart"), {\n',
    '    type: "line",\n',
    '    data: { labels: data.platform_years, datasets: platformDatasets },\n',
    '    options: { scales: { y: { beginAtZero: true, title: { display: true, text: "Certificates" } } }, plugins: { legend: legendHoverPlugin(function (item) { return "Click to show/hide " + item.text; }) } }\n',
    '  });\n',
    '  addResetLink("platformChartReset", platformChart);\n',
    '  var venueTypeNames = { journal: "Journal", conference: "Conference", community: "Community", institution: "Institution" };\n',
    '  function venueTypeLabel(key) {\n',
    '    return venueTypeNames[key] || (key.charAt(0).toUpperCase() + key.slice(1));\n',
    '  }\n',
    '  // Colours are resolved server-side from CONFIG$VENUE_TYPE_COLORS and keyed\n',
    '  // by type name, so they no longer shift when a new type enters the data.\n',
    '  var venueTypeDatasets = Object.keys(data.venue_type_datasets).map(function (name) {\n',
    '    return { label: venueTypeLabel(name), data: data.venue_type_datasets[name], backgroundColor: data.venue_type_colors[name] };\n',
    '  });\n',
    '  var venueTypeChart = new Chart(document.getElementById("venueTypeChart"), {\n',
    '    type: "bar",\n',
    '    data: { labels: data.venue_type_years, datasets: venueTypeDatasets },\n',
    '    options: { scales: { x: { stacked: true }, y: { stacked: true, beginAtZero: true, title: { display: true, text: "Checks" } } }, plugins: { legend: legendHoverPlugin(function (item) { return "Click to show/hide " + item.text; }) } }\n',
    '  });\n',
    '  addResetLink("venueTypeChartReset", venueTypeChart);\n',
    '  var intervalChart = new Chart(document.getElementById("intervalChart"), {\n',
    '    type: "bar",\n',
    '    data: { labels: data.interval_bucket_labels, datasets: [\n',
    '      { label: "Certificates", data: data.interval_bucket_values, backgroundColor: "#2c7a4b" }\n',
    '    ] },\n',
    '    options: { plugins: { legend: { display: false } }, scales: {\n',
    '      y: { beginAtZero: true, title: { display: true, text: "Certificates" } }\n',
    '    } }\n',
    '  });\n',
    '  // Chart.js has no symlog scale, so the beeswarm is a small hand-rolled SVG:\n',
    '  // linear from -1 to 1 year around zero (where most points sit and where sign\n',
    '  // matters most), logarithmic beyond that in either direction. Points are\n',
    '  // bucketed onto a coarse grid and stacked vertically within each bucket so\n',
    '  // nearby certificates fan out instead of overlapping.\n',
    '  (function renderBeeswarm() {\n',
    '    var el = document.getElementById("intervalBeeswarm");\n',
    '    if (!el || !data.interval_points || data.interval_points.length === 0) return;\n',
    '    var width = el.clientWidth || 480, height = 220;\n',
    '    var margin = { top: 10, right: 16, bottom: 34, left: 16 };\n',
    '    var plotW = width - margin.left - margin.right;\n',
    '    var yearDays = 365.25;\n',
    '    function scaleX(days) {\n',
    '      var sign = days < 0 ? -1 : 1;\n',
    '      var a = Math.abs(days);\n',
    '      var t; // 0..1 position within the [-domainMax, domainMax] symlog domain\n',
    '      if (a <= yearDays) {\n',
    '        t = 0.5 * (a / yearDays);\n',
    '      } else {\n',
    '        var maxDays = Math.max.apply(null, data.interval_points.map(function (p) { return Math.abs(p.days); }));\n',
    '        var logSpan = Math.log(Math.max(maxDays, yearDays * 2)) - Math.log(yearDays);\n',
    '        t = 0.5 + 0.5 * ((Math.log(a) - Math.log(yearDays)) / logSpan);\n',
    '      }\n',
    '      return margin.left + plotW / 2 + sign * t * (plotW / 2);\n',
    '    }\n',
    '    var radius = 3.5, rowHeight = radius * 2 + 1;\n',
    '    var maxRows = Math.floor((height - margin.top - margin.bottom) / rowHeight);\n',
    '    var binPx = radius * 2;\n',
    '    var binCounts = {};\n',
    '    var svgns = "http://www.w3.org/2000/svg";\n',
    '    var svg = document.createElementNS(svgns, "svg");\n',
    '    svg.setAttribute("viewBox", "0 0 " + width + " " + height);\n',
    '    svg.setAttribute("width", "100%");\n',
    '    svg.setAttribute("height", height);\n',
    '    var zeroX = scaleX(0);\n',
    '    var axisY = height - margin.bottom;\n',
    '    var axis = document.createElementNS(svgns, "line");\n',
    '    axis.setAttribute("x1", margin.left); axis.setAttribute("x2", width - margin.right);\n',
    '    axis.setAttribute("y1", axisY); axis.setAttribute("y2", axisY);\n',
    '    axis.setAttribute("stroke", "#ccc");\n',
    '    svg.appendChild(axis);\n',
    '    [0, yearDays, yearDays * 10].forEach(function (d, i) {\n',
    '      [d, -d].forEach(function (dd) {\n',
    '        if (dd !== 0 && d === 0) return;\n',
    '        var x = scaleX(dd);\n',
    '        var tick = document.createElementNS(svgns, "text");\n',
    '        tick.setAttribute("x", x); tick.setAttribute("y", axisY + 14);\n',
    '        tick.setAttribute("text-anchor", "middle"); tick.setAttribute("font-size", "10"); tick.setAttribute("fill", "#888");\n',
    '        tick.textContent = dd === 0 ? "publication" : (dd < 0 ? "-" : "+") + (i === 1 ? "1yr" : "10yr");\n',
    '        svg.appendChild(tick);\n',
    '      });\n',
    '    });\n',
    '    data.interval_points.forEach(function (p) {\n',
    '      var x = scaleX(p.days);\n',
    '      var bin = Math.round(x / binPx);\n',
    '      var row = binCounts[bin] || 0;\n',
    '      binCounts[bin] = row + 1;\n',
    '      if (row >= maxRows) return; // silently drop overflow beyond the plot height\n',
    '      var y = axisY - radius - 2 - row * rowHeight;\n',
      # Each dot links to its certificate landing page - a real <a> around the
      # <circle> (not a click handler) so it behaves like any other link
      # (middle-click/open-in-new-tab, status bar preview, no-JS fallback).
    '      var link = document.createElementNS(svgns, "a");\n',
    '      link.setAttribute("href", data.cert_base_path + encodeURIComponent(p.id) + "/");\n',
    '      var c = document.createElementNS(svgns, "circle");\n',
    '      c.setAttribute("cx", x); c.setAttribute("cy", y); c.setAttribute("r", radius);\n',
    '      c.setAttribute("fill", p.days < 0 ? "#8a4fbf" : "#2c7a4b");\n',
    '      c.setAttribute("fill-opacity", "0.75");\n',
    '      var title = document.createElementNS(svgns, "title");\n',
    '      var years = Math.abs(p.days / yearDays);\n',
    '      title.textContent = p.id + ": " + (p.days < 0 ? "checked " + Math.round(-p.days) + " days before publication" : Math.round(p.days) + " days (" + years.toFixed(1) + " yr) after publication");\n',
    '      c.appendChild(title);\n',
    '      link.appendChild(c);\n',
    '      svg.appendChild(link);\n',
    '    });\n',
    '    el.appendChild(svg);\n',
    '  })();\n',
    '});\n',
    '</script>\n'
  )

  style_html <- paste0(
    '<style>\n',
    '.stats-summary-row { display: flex; gap: 1rem; margin-bottom: 2rem; }\n',
    '.stats-summary-card { text-align: center; padding: 1.5rem 1rem; border: 1px solid #ddd; border-radius: 6px; }\n',
    '.stats-summary-card .stats-value { font-size: 2.5rem; font-weight: bold; color: #2c7a4b; }\n',
    '.stats-charts-row { margin-bottom: 2rem; }\n',
    '.venues-grid { display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 2rem; }\n',
    '.venue-card { border: 1px solid #ddd; border-radius: 6px; padding: 1rem; width: 220px; text-align: center; }\n',
    '.venue-card img { max-height: 40px; max-width: 100%; margin-bottom: 0.5rem; }\n',
    '.venue-card .venue-badge { display: flex; align-items: center; justify-content: center; min-height: 40px; margin-bottom: 0.5rem; padding: 0 0.25rem; font-weight: bold; font-size: 0.85rem; letter-spacing: 0.05em; line-height: 1.2; word-break: break-all; color: #999; }\n',
    '.venue-card .venue-count { color: #2c7a4b; font-size: 1.3rem; font-weight: bold; }\n',
    '.venue-card .venue-years { color: #888; font-size: 0.8rem; margin-top: 0.15rem; }\n',
    '.stats-summary-card-link { flex: 1; display: block; color: inherit; text-decoration: none; }\n',
    '.stats-summary-card-link:hover { text-decoration: none; }\n',
    '.stats-summary-card-link:hover .stats-summary-card { border-color: #2c7a4b; }\n',
    '.chart-reset-link { display: inline-block; margin-top: 0.5rem; font-size: 0.85rem; cursor: pointer; }\n',
    '.interval-summary { margin: 1.5rem 0; }\n',
    '.interval-note { color: #888; font-size: 0.85rem; }\n',
    '.interval-beeswarm { width: 100%; }\n',
    '.interval-beeswarm svg a circle { cursor: pointer; }\n',
    '</style>\n'
  )

  paste0(style_html, summary_cards, charts_html, interval_html, venues_html, publishers_html, script_html)
}

#' Build the "time from work publication to check" summary stat line
#'
#' Deliberately not framed as a speed metric: a fast turnaround and a check
#' of a decades-old work are both notable, not "good vs. bad" - so this
#' describes the spread, never phrasing it as something "completed within" a
#' target time.
#'
#' @param interval_summary The `interval_summary` list from statistics.json
#'   (`pct_before_publication`, `pct_within_6mo`, `max_years`), or NULL
#' @param n Number of certificates the summary covers
#' @param excluded Number of certificates excluded (missing a date)
#' @return An HTML string, or "" if no summary is available
#' @keywords internal
build_interval_summary_html <- function(interval_summary, n, excluded) {
  if (is.null(interval_summary)) {
    return("")
  }
  note <- if (!is.null(excluded) && excluded > 0) {
    sprintf(' <span class="interval-note">(%d certificate%s excluded for missing a date)</span>', excluded, if (excluded != 1) "s" else "")
  } else {
    ""
  }
  paste0(
    '<p class="interval-summary">Checks span from preprints reviewed before formal publication to works checked ',
    'decades after: <strong>', interval_summary$pct_before_publication, '%</strong> precede formal publication, ',
    '<strong>', interval_summary$pct_within_6mo, '%</strong> follow within 6 months, and some reproduce work ',
    'published over <strong>', interval_summary$max_years, ' years</strong> earlier.', note, '</p>\n'
  )
}

#' @keywords internal
stats_summary_card <- function(label, value, href = NULL) {
  card <- paste0(
    '<div class="stats-summary-card"><div class="stats-value">', value, '</div><div class="stats-label">', label, '</div></div>\n'
  )
  if (is.null(href)) {
    return(paste0('  ', card))
  }
  paste0('  <a class="stats-summary-card-link" href="', href, '">', card, '</a>\n')
}

#' Fallback venue badge text when no logo is available
#'
#' All-caps consonants-only abbreviation of the venue's long name (vowels,
#' spaces and punctuation stripped), e.g. "Preprint" -> "PRPRNT", "In press"
#' -> "NPRSS".
#'
#' @param longname The venue's display name
#' @return A short uppercase consonant string
#' @keywords internal
venue_fallback_badge <- function(longname) {
  gsub("[^BCDFGHJKLMNPQRSTVWXYZ]", "", toupper(longname))
}

#' @keywords internal
build_venues_grid_html <- function(venues_detail, base_path = "..") {
  if (is.null(venues_detail) || length(venues_detail) == 0) {
    return("")
  }

  # A missing field comes back from fromJSON(simplifyVector = FALSE) either as
  # NULL (JSON null) or as an empty list() (JSON `{}`, which is how jsonlite
  # serializes an R NULL inside a list) - both must be treated as "no value".
  has_value <- function(x) !is.null(x) && is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)

  # Group by the venue's actual Type (community/journal/conference/institution,
  # from register.csv - resolved server-side into page_type), the same
  # grouping the rest of the site uses under docs/venues/. venues.csv's `label`
  # is not it: it can carry other values (e.g. "check-nl", "lifecycle journal")
  # meant only for GitHub issue labels, which would otherwise fragment venues
  # of the same real type into their own one-venue groups.
  group_key <- function(v) if (has_value(v$page_type)) v$page_type else v$label
  groups <- unique(vapply(venues_detail, group_key, character(1)))
  html <- ""
  for (grp in groups) {
    group_venues <- Filter(function(v) identical(group_key(v), grp), venues_detail)
    heading <- if (length(group_venues) > 1) {
      plural <- if (!is.null(CONFIG$VENUE_SUBCAT_PLURAL[[grp]])) CONFIG$VENUE_SUBCAT_PLURAL[[grp]] else paste0(grp, "s")
      paste0(tools::toTitleCase(plural), " (", length(group_venues), ")")
    } else {
      tools::toTitleCase(grp)
    }
    html <- paste0(html, '<h3>', heading, '</h3>\n<div class="venues-grid">\n')
    for (v in group_venues) {
      logo_html <- if (has_value(v$logo_url)) {
        paste0('<img src="', v$logo_url, '" alt="', v$longname, ' logo">')
      } else {
        paste0('<div class="venue-badge">', venue_fallback_badge(v$longname), '</div>')
      }
      # Link to the venue's own page in the register rather than an external
      # site - it needs the page's Type (community/journal/conference/institution)
      # and slug, resolved server-side in compute_annual_stats() since that is
      # what determines the actual rendered path under docs/venues/.
      link_url <- if (has_value(v$page_type_plural) && has_value(v$page_slug)) {
        paste0(base_path, "/venues/", v$page_type_plural, "/", v$page_slug, "/")
      } else {
        NULL
      }
      name_html <- if (!is.null(link_url)) {
        paste0('<a href="', link_url, '">', v$longname, '</a>')
      } else {
        v$longname
      }
      years_html <- if (has_value(v$year_range)) {
        paste0('<div class="venue-years">', v$year_range, '</div>')
      } else {
        ""
      }
      html <- paste0(
        html,
        '  <div class="venue-card">', logo_html, '<div class="venue-name">', name_html, '</div>',
        '<div class="venue-count">', v$cert_count, ' check', if (v$cert_count != 1) "s" else "", '</div>',
        years_html, '</div>\n'
      )
    }
    html <- paste0(html, '</div>\n')
  }
  html
}

#' @keywords internal
build_publishers_table_html <- function(publishers) {
  if (is.null(publishers) || length(publishers) == 0) {
    return("")
  }

  rows <- vapply(publishers, function(p) {
    sprintf('  <tr><td>%s</td><td>%d</td><td>%d</td></tr>', p$name, p$venue_count, p$cert_count)
  }, character(1))

  paste0(
    '<h3>Publishers</h3>\n',
    '<table class="table"><thead><tr><th>Publisher</th><th>Venues</th><th>Certificates</th></tr></thead><tbody>\n',
    paste(rows, collapse = "\n"),
    '\n</tbody></table>\n'
  )
}
