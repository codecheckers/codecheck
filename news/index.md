# Changelog

## codecheck 0.28.0.9000

### New Features

- The sort state of the register tables is now reflected in the page
  URL, so a particular view can be linked, bookmarked or cited:
  `?sort=-check-date` is the register sorted by check date, newest first
  (a leading `-` means descending, the column name is the header text
  slugified). A page with more than one sortable table numbers them in
  document order, `sort`, `sort2`, …, e.g. a person page as
  `?sort=venue&sort2=-check-date`. The sort is applied on load and the
  URL updated on every header click via `history.replaceState()`, so the
  back button is unaffected; an unknown or unsortable column name is
  ignored and leaves the default order. Entirely in
  `inst/extdata/js/table-sort-init.js`, which is all a static GitHub
  Pages site needs.
- The statistics dashboard now shows the spread of time between a work’s
  publication and its CODECHECK certificate: a bucketed histogram and a
  per-certificate beeswarm plot (each dot linking to its certificate
  page), plus a summary line, computed by
  [`compute_annual_stats()`](http://codecheck.org.uk/codecheck/reference/compute_annual_stats.md)
  from the existing `Work publication date`/`Check date` columns.
  Deliberately framed as a distribution rather than a speed metric -
  checking a decades-old work is as notable as a fast turnaround.
- [`add_openalex_work_fields()`](http://codecheck.org.uk/codecheck/reference/add_openalex_work_fields.md)
  now falls back to reading a work’s publication date straight off its
  own reference URL when OpenAlex has no record for it at all:
  `citation_online_date`/`citation_publication_date`/`citation_date`
  HTML meta tags, schema.org `datePublished` JSON-LD, or - for a
  reference that is itself a PDF - the PDF’s own `Created` metadata via
  [`pdftools::pdf_info()`](https://docs.ropensci.org/pdftools//reference/pdftools.html).
  New
  [`get_page_publication_date_result()`](http://codecheck.org.uk/codecheck/reference/get_page_publication_date_result.md)
  and helpers in `R/utils_paper_publication_date.R`. A partial date (a
  bare year, or year+month) is resolved to its calendar midpoint rather
  than the 1st, so it does not skew interval calculations toward “early
  in the period”. `xml2` moves from Suggests to Imports.
- A render now warns when a certificate’s `paper.reference` is a plain
  (non-archived) PDF link: such links carry no machine-readable
  publication metadata and are prone to rotting (two of the CMMID
  COVID-19 reports already 404). New
  [`warn_if_pdf_reference()`](http://codecheck.org.uk/codecheck/reference/warn_if_pdf_reference.md),
  called from
  [`add_openalex_ids()`](http://codecheck.org.uk/codecheck/reference/add_openalex_ids.md);
  suggests a web.archive.org snapshot instead, matching the guidance
  added to the community workflow config spec.
- A certificate’s “Paper details” box now shows its
  `Work publication date` (when known) below the abstract, and a work’s
  own landing page shows it in the metadata panel directly below the
  DOI. `Work publication date` joins the columns carried through to a
  work page for
  [`generate_work_metadata_html()`](http://codecheck.org.uk/codecheck/reference/generate_work_metadata_html.md)
  (`CONFIG$REGISTER_COLUMNS$works$html`), same as `OpenAlex` already
  was.
- [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  splits a batch that would create more items than Wikidata’s rate limit
  allows per minute into numbered files to paste in turn (register#50).
  A background QuickStatements run pushes as fast as the API accepts, so
  a larger batch stopped at the limit and reported the rest as “No
  success flag set in API result”.
- [`quickstatements_submitted()`](http://codecheck.org.uk/codecheck/reference/quickstatements_submitted.md)
  retires the `.qs` file a batch was pasted from, renaming it with a
  `.submitted` suffix, and
  [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  removes a batch file once nothing is left to create (register#50).
  QuickStatements’ `CREATE` is not idempotent, so a batch file left
  lying around after its run is one paste away from duplicating every
  item in it.
- [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  no longer tells you to run the works batch first when there is no
  works batch to run: certificates left without a `review of` statement
  once every resolvable work exists name a checked work that has no DOI
  (register#50).
- [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  writes the checked works to `wikidata-works.qs` rather than
  `wikidata-papers.qs`, matching the noun the register uses everywhere
  else (register#50).
- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  keeps a register repo’s `.zenodo.json` contributors current with every
  codechecker named in the register (register#58), crediting people
  whose work otherwise only appears on their own person page. New
  [`build_zenodo_contributors()`](http://codecheck.org.uk/codecheck/reference/build_zenodo_contributors.md)
  and
  [`update_zenodo_json()`](http://codecheck.org.uk/codecheck/reference/update_zenodo_json.md).
  Zenodo’s contributor vocabulary has no “reviewer”/“checker” term, so
  every entry is typed `"Other"`; a `.zenodo.json` that does not exist
  is left alone. Only the `contributors` array is touched - the rest of
  the file (title, creators, licence, …) stays hand-maintained.

## codecheck 0.28.0

### New Features

- New
  [`bootstrap_wikibase()`](http://codecheck.org.uk/codecheck/reference/bootstrap_wikibase.md)
  creates the CODECHECK Wikibase’s own properties and class items from
  the data model in `R/wikidata.R`, each carrying a “Wikidata entity”
  statement naming its counterpart (register#50). A Wikibase mints its
  own P-numbers, so that mapping is what lets the two sides line up; it
  is a dry run by default and idempotent, so the instance can be rebuilt
  from empty.
- The bootstrap also creates the properties the model uses as qualifiers
  and references and one item per platform a certificate can be
  published on, without which those statements were dropped for want of
  a target.
- Each statement in the model now names its Wikibase `datatype`,
  validated against `WIKIBASE_DATATYPES` and reported by
  [`wikidata_properties()`](http://codecheck.org.uk/codecheck/reference/wikidata_properties.md) -
  a property created with the wrong datatype cannot be changed
  afterwards.
- The bootstrap writes a generated [Project:Data
  model](https://codecheck.wikibase.cloud/wiki/Project:Data_model) page
  listing every local entity next to its Wikidata counterpart.
- [`bootstrap_wikibase()`](http://codecheck.org.uk/codecheck/reference/bootstrap_wikibase.md)
  also writes
  [Project:About](https://codecheck.wikibase.cloud/wiki/Project:About)
  and
  [Project:Copyrights](https://codecheck.wikibase.cloud/wiki/Project:Copyrights),
  which the [wikibase.cloud hosting
  policy](https://www.wikibase.cloud/hosting-policy) requires of every
  hosted instance (register#50).
- [`bootstrap_wikibase()`](http://codecheck.org.uk/codecheck/reference/bootstrap_wikibase.md)
  brings an entity whose label has drifted from the model back in line,
  so a rerun converges on the model instead of only filling gaps.
- The bootstrap retries a write the server asks it to repeat (`maxlag`,
  `ratelimited`, `readonly`, 429/503) with a capped doubling backoff,
  and names a contact in its User-Agent (`codecheck.contact` option).
- New
  [`load_wikibase_register()`](http://codecheck.org.uk/codecheck/reference/load_wikibase_register.md)
  writes the whole register to the CODECHECK Wikibase as items - people,
  venues, papers, then the certificates that refer to them - and
  generates a
  [Project:Certificates](https://codecheck.wikibase.cloud/wiki/Project:Certificates)
  index (register#50). Dry by default, and a rerun updates what it wrote
  instead of duplicating it.
- New
  [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  shows what an export to Wikidata would do without sending anything,
  writing the QuickStatements batches a person pastes in under their own
  account and publishing [Project:Wikidata
  export](https://codecheck.wikibase.cloud/wiki/Project:Wikidata_export)
  on the Wikibase (register#50).
- The preview page’s table of checked works gained a “Wikidata
  certificate” column, so each row names both the item Wikidata holds
  for the work and the item for the certificate that reviews it
  (register#50).
- [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  resolves against Wikidata through the Action API’s `haswbstatement`
  search rather than the query service, which indexes a new item within
  minutes and sees every graph it might have landed in;
  `method = "sparql"` keeps the old path as a cross-check.
- [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  refuses to write a batch of `CREATE`s the edit log says was already
  submitted while its entities still do not resolve, since a second
  paste would duplicate every item; `force = TRUE` overrides it.
- Checked works are now created on Wikidata as well as mirrored in the
  Wikibase, carrying their DOI, title, OpenAlex ID (`P10283`) and
  authors as `P2093` author name strings (register#50).
- Enriching a work with its OpenAlex ID now also fetches the publication
  it appeared in and its publication date, as new `Paper ISSN` and
  `Work publication date` columns in `register.json`, so an exported
  work states `P1433` published in and `P577` publication date
  (register#50). New
  [`add_openalex_work_fields()`](http://codecheck.org.uk/codecheck/reference/add_openalex_work_fields.md).
- The CODECHECK Wikibase gets an item for every publication the checked
  works appeared in, not only for the venues in `venues.csv` - those
  name the venues that commission checks, and 22 of the 25 publications
  the works name are not among them, so their works’ “published in”
  statements had no target (register#50). Wikidata is unaffected:
  publications are resolved there, never created.
- `register.json` and `register-full.json` carry each checked work’s
  `Paper ISSN`, `Paper venue` and `Work publication date`, and the
  Wikidata export backfills them from cache when the register was
  rendered before those columns existed (register#50).
- New
  [`verify_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/verify_wikidata_export.md)
  checks what actually arrived: whether each certificate item exists,
  whether it is visible in the scholarly graph, and whether it states
  `review of` on the work it checked.
- `verify_wikidata_export(update_register = TRUE)` records each
  certificate’s Wikidata item in a `Wikidata` column of `register.csv`,
  editing the file line by line so its commented-out rows survive
  (register#50). Nothing else can re-derive the item offline, and the
  render needs it to link the exported record.
- Certificate, work and person pages link their Wikidata record, as a
  signposting `describedby` link to `Special:EntityData` in the page
  head, as Schema.org `sameAs` in the JSON-LD, and as a `wikidata` field
  in the page’s JSON (register#50). A certificate’s item comes from
  `register.csv`, a work’s is resolved from its DOI and a person’s from
  their ORCID.
- A certificate page’s CODECHECK details box gained a “Certificate on
  Wikidata” entry linking the exported record, below “Full certificate”;
  the entry is left out entirely for a certificate that has not been
  exported (register#50).
- Person and work landing pages show the Wikidata item in their metadata
  panel, next to ORCID and GitHub on a person page and next to the DOI
  on a work page, rather than only in the page’s head and JSON
  (register#50).
- The people with Wikidata items are recorded in the register’s
  `persons.csv`, read before anything is resolved and written back
  after, so a clone renders the same links without network access.
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_render_cert()`](http://codecheck.org.uk/codecheck/reference/register_render_cert.md)
  gained a `persons_file` argument.
- Wikidata lookups are cached per identifier, a confirmed “no item”
  included, so only an identifier nobody has looked up yet costs a
  request. A failed lookup is not cached, so an outage does not become a
  lasting “no item”.
- New
  [`quickstatements_write()`](http://codecheck.org.uk/codecheck/reference/quickstatements_write.md)
  and
  [`quickstatements_submitted()`](http://codecheck.org.uk/codecheck/reference/quickstatements_submitted.md)
  keep an edit log of both halves of the export, the API writes to the
  Wikibase and the QuickStatements batches pasted into Wikidata by hand
  (register#50).
- New vignette “Export the register to Wikidata”, a step-by-step
  procedure for the whole export, written to be followed literally by a
  person or an assistant (register#50).
- New `/organisations/` pages list the works authored and the checks
  conducted by each research organisation’s people, identified by ROR
  (register#53). An organisation is only credited for a certificate
  where the person’s ORCID profile placed them there at the time, and
  every page says so.
- Organisation pages carry name, type, location and identifiers from
  ror.org and a logo from Wikidata, and cross-link with an institution
  venue that shares their ROR.
- New
  [`orcid_rors()`](http://codecheck.org.uk/codecheck/reference/orcid_rors.md)
  and
  [`register_ror_coverage()`](http://codecheck.org.uk/codecheck/reference/register_ror_coverage.md)
  report which authors and codecheckers have a ROR-identified
  affiliation in their ORCID profile (register#53).
- Every rendered page carries [FAIR
  Signposting](https://signposting.org/FAIR/) typed links, expressed as
  HTML `<link>` elements because GitHub Pages cannot set HTTP `Link`
  headers; certificate pages are Level 1 conformant (register#55). New
  [`generate_page_signposting()`](http://codecheck.org.uk/codecheck/reference/generate_page_signposting.md)
  and one generator per page type.
- Pages with Schema.org metadata now also write it to an `index.jsonld`
  next to the page, so the signposting `describedby` links resolve to a
  machine-readable document.
- Register rendering announces the main register, the full export and
  each filter before rendering them, with a progress bar per page group
  (per-page timings under `verbose = TRUE`).
- The filtered register CSVs are now written under their own log heading
  instead of silently.
- The “all persons” table shows the per-venue-type stacked bar for
  checks conducted again (register#92); `index.json` carries the plain
  counts under `"Check types"`.

### Bug Fixes

- [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  follows a record that Zenodo has superseded with a new version instead
  of failing with “Not found”: the register stores the report DOI as it
  was published, and the id in it stops being the editable one once a
  new version exists (certificate 2023-011).
- [`curate_register_zenodo_records()`](http://codecheck.org.uk/codecheck/reference/curate_register_zenodo_records.md)
  reports records deposited by another Zenodo account as their own
  category rather than as errors, and names the certificates concerned -
  the corrections for those are known and correct, they just have to be
  made by whoever owns the record.
- A work landing page shows its OpenAlex ID again: the column was
  missing from the work pages’ HTML column list, so the metadata panel’s
  OpenAlex row never rendered even though `index.json` carried the ID.
- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  warns when two certificates share a report DOI. The register renders
  both without trouble, so it is invisible there, but the report DOI
  identifies a certificate in the Wikidata export, where two
  certificates naming one archived record become a single item and the
  second silently overwrites the first. New
  [`check_duplicate_reports()`](http://codecheck.org.uk/codecheck/reference/check_duplicate_reports.md).
- [`load_wikibase_register()`](http://codecheck.org.uk/codecheck/reference/load_wikibase_register.md)
  and
  [`preview_wikidata_export()`](http://codecheck.org.uk/codecheck/reference/preview_wikidata_export.md)
  refuse to run when two entities share the identifier the model
  resolves them on, naming the rows that collide, instead of writing one
  item for both. New
  [`check_export_keys()`](http://codecheck.org.uk/codecheck/reference/check_export_keys.md).
- The Wikibase export no longer ends halfway through when a connection
  times out or drops: a request that never completed is now retried like
  a 503, rather than propagating as an error.
- A certificate item’s label includes its number again: mustache cannot
  address a key containing a space, so `` {{`Certificate ID`}} ``
  rendered as “CODECHECK Certificate” alone. Register columns are now
  offered to the model’s templates under an underscored alias.
- A rerun of
  [`bootstrap_wikibase()`](http://codecheck.org.uk/codecheck/reference/bootstrap_wikibase.md)
  no longer relabels the properties it created, having counted each as
  colliding with its own label on the instance and planned `title` as
  `title (P1476)`.

## codecheck 0.27.1

### Bug Fixes

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)’s
  codechecker counts (the main `statistics.json`, every venue’s
  `index.json`, and the statistics dashboard) no longer come back empty:
  [`preprocess_register()`](http://codecheck.org.uk/codecheck/reference/preprocess_register.md)
  only built the underlying `Codechecker` column when
  `"codecheckers" %in% filter_by`, which stopped happening once 0.27.0
  dropped `"codecheckers"` from the default `filter_by`. The column is
  now always built.
- The statistics dashboard’s “Codecheckers” summary card no longer links
  to the retired `/codecheckers/index.html`; it links to
  `/persons/index.html`.

## codecheck 0.27.0

### New Features

- New data model for representing CODECHECK certificates as linked data,
  in the CODECHECK Wikibase and in Wikidata (register#50).
  `R/wikidata.R` holds only the model and its accessors, no HTTP or
  QuickStatements. A certificate carries `P13046` *publication type of
  scholarly work* so it resolves in the query service’s cross-graph
  join, links to the checked paper via `P6977` *review of* rather than
  `P2860`, and gets a venue-derived `P31` (AGILE reproducibility reviews
  are typed separately from CODECHECKs). A checked work whose venue is
  `preprint` is typed Q580922 *preprint* rather than *scholarly
  article*; both values keep it in the scholarly graph beside its
  certificate. The certificate identifier is carried as `P528` *catalog
  code* qualified with `P972` *catalog* → Q141254857 (the register),
  until a dedicated external identifier property exists. Only
  certificates are created on Wikidata; papers, people and venues are
  resolved against existing items and otherwise created only in the
  mirroring CODECHECK Wikibase. New
  [`wikidata_model()`](http://codecheck.org.uk/codecheck/reference/wikidata_model.md),
  [`wikidata_entity_kinds()`](http://codecheck.org.uk/codecheck/reference/wikidata_entity_kinds.md),
  [`wikidata_statements()`](http://codecheck.org.uk/codecheck/reference/wikidata_statements.md),
  [`wikidata_properties()`](http://codecheck.org.uk/codecheck/reference/wikidata_properties.md),
  [`wikidata_endpoint()`](http://codecheck.org.uk/codecheck/reference/wikidata_endpoint.md),
  [`wikidata_creates()`](http://codecheck.org.uk/codecheck/reference/wikidata_creates.md),
  [`validate_wikidata_model()`](http://codecheck.org.uk/codecheck/reference/validate_wikidata_model.md),
  [`wikidata_pending()`](http://codecheck.org.uk/codecheck/reference/wikidata_pending.md).

- Register, venue, person, and work tables gain click-to-sort column
  headers (vendored `stupidtable.js`); columns holding a link/title
  rather than a plain value (Report, Work) are excluded. New
  [`add_sortable_th_attributes()`](http://codecheck.org.uk/codecheck/reference/add_sortable_th_attributes.md).

- New `/works/<DOI>/` landing page for a checked paper (register#150):
  lists every certificate that checked it, a metadata panel (DOI,
  OpenAlex, venues, authors linked to their own person page), Schema.org
  (`ScholarlyArticle` + `Review` graph), and an
  `index.json`/`register.json` API queryable by DOI - a paper with no
  DOI has no page. New
  [`add_work_key()`](http://codecheck.org.uk/codecheck/reference/add_work_key.md),
  [`normalize_work_key()`](http://codecheck.org.uk/codecheck/reference/normalize_work_key.md),
  [`get_work_metadata_fields()`](http://codecheck.org.uk/codecheck/reference/get_work_metadata_fields.md),
  [`generate_work_metadata_html()`](http://codecheck.org.uk/codecheck/reference/generate_work_metadata_html.md)/`_yaml()`,
  [`generate_work_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_work_schema_org.md),
  [`create_all_works_table()`](http://codecheck.org.uk/codecheck/reference/create_all_works_table.md).

- New `/persons/<ORCID>/` landing page (register#123), replacing
  `/codecheckers/`: covers both roles a person can have, showing “Works
  authored” and “Checks conducted” as two separate tables, with role
  counts in `stats.json` and a `Person` + `Review`/`ScholarlyArticle`
  Schema.org graph. Only ORCID-identified people get a page. New
  [`add_person_records()`](http://codecheck.org.uk/codecheck/reference/add_person_records.md),
  [`explode_person_records()`](http://codecheck.org.uk/codecheck/reference/explode_person_records.md),
  [`generate_person_metadata_html()`](http://codecheck.org.uk/codecheck/reference/generate_person_metadata_html.md),
  [`generate_person_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_person_schema_org.md),
  [`create_all_persons_table()`](http://codecheck.org.uk/codecheck/reference/create_all_persons_table.md).
  A new `docs/404.html`
  ([`generate_404_page()`](http://codecheck.org.uk/codecheck/reference/generate_404_page.md))
  redirects a stray `/codecheckers/<X>/` link to `/persons/<X>/` and,
  for an unmatched `/works/<DOI>`, explains that no CODECHECK has been
  registered for that DOI.

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)’s
  default `filter_by` is now `c("venues", "works", "persons")` (was
  `c("venues", "codecheckers")`).

- Certificate pages link each ORCID-bearing paper author to their own
  `/persons/<ORCID>/` page (previously only linked if that author was
  also a codechecker) and link the paper title to its `/works/<DOI>/`
  page when it has one.

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  warns about two certificates that share a paper title but not a
  DOI-normalized work key (a likely same-paper duplicate that would
  otherwise render as two separate `/works/` pages,
  e.g. register#133/#149), and about an ORCID recorded under materially
  different names or a name recorded under different ORCIDs across the
  register. New
  [`check_near_duplicate_works()`](http://codecheck.org.uk/codecheck/reference/check_near_duplicate_works.md),
  [`check_orcid_conflicts()`](http://codecheck.org.uk/codecheck/reference/check_orcid_conflicts.md).

- `register.md` is no longer generated for a person page, since its two
  tables (works authored, checks conducted) can’t be represented as the
  one markdown table every other filter’s `register.md` assumes. New
  `CONFIG$FILTERS_WITHOUT_MD`.

- The “CSV source”/“CSV on GitHub” footer links (formerly “searchable
  CSV”) now show only on the main, unfiltered register page.

- The top navigation menu is now shown on every page, not just overview
  pages; each menu item and the logo gained hover text.

- `.navbar-menu .nav-link` font size reduced from `2rem` to `0.95rem`
  and its breadcrumb counterpart matched to it.

- Added a ResearchEquals collection link to the page footer, next to the
  Zenodo community link.

- Venue landing pages show a metadata panel with website, contact,
  description, identifiers and logo, from new `venues.csv` columns
  (register#84).

- A venue’s `statistics.json` is renamed to `index.json`, since it now
  carries more than statistics (register#183).

- `venues.csv` gained optional `logo_url`, `website_url`, `policy_url`
  and `publisher` columns.

- New statistics dashboard page at `docs/statistics/index.html` with
  charts, a venue grid and a publisher table (addresses register#33,
  register#48). New
  [`render_statistics_page()`](http://codecheck.org.uk/codecheck/reference/render_statistics_page.md).

- Venue type colours are now pinned by name in
  `CONFIG$VENUE_TYPE_COLORS` instead of assigned by the order types
  appear in the data.

- JSON/Markdown export links below register tables are now relative
  rather than absolute `codecheck.org.uk` URLs.

- Venue and codechecker `register.md` exports carry their metadata as
  YAML frontmatter instead of embedded HTML.

- Certificates published on ResearchEquals are now audited against the
  CODECHECK curation policy, including membership in the CODECHECK and
  Reproducible AGILE collections. New
  [`check_researchequals_record()`](http://codecheck.org.uk/codecheck/reference/check_researchequals_record.md)
  and
  [`researchequals_policy_check()`](http://codecheck.org.uk/codecheck/reference/researchequals_policy_check.md).

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  gained `check_researchequals_policy` (default `TRUE`), the
  ResearchEquals counterpart of `check_zenodo_policy`.

- A “Go to random certificate” button on the main register page jumps to
  a random certificate instead of the oldest one (register#188).

- Certificate pages now carry Highwire Press citation metadata, so
  Google Scholar can index a certificate and Zotero saves it as a report
  (register#52).

- Certificate pages describe themselves in their OpenGraph metadata
  instead of describing the register as a whole, and gained an
  `og:image` of the certificate’s first page.

- A certificate’s title is now read from the platform it is published on
  rather than constructed as “CODECHECK Certificate \<ID\>”.

- A certificate’s Schema.org JSON-LD gained `publisher`, `inLanguage`,
  the record DOI as `identifier` and the certificate PDF as `encoding`.

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_render_cert()`](http://codecheck.org.uk/codecheck/reference/register_render_cert.md)
  gained `prune_unavailable_metadata` (default `FALSE`), controlling
  whether an OpenAlex ID or abstract confirmed unavailable is removed
  from the rendered output.

- Codechecker profiles are now looked up in the institutional and
  Reproducible AGILE codechecker lists as well as the volunteer one, so
  those codecheckers’ pages show an avatar and GitHub link
  (register#215). New
  [`get_institutional_codecheckers_data()`](http://codecheck.org.uk/codecheck/reference/get_institutional_codecheckers_data.md)
  and
  [`get_agile_codecheckers_data()`](http://codecheck.org.uk/codecheck/reference/get_agile_codecheckers_data.md).

- A codechecker’s own page shows a metadata panel with their avatar,
  ORCID, GitHub profile and the venues they contributed checks to
  (register#74, register#189, register#83, register#75).

- A codechecker’s `stats.json` gained a `codechecker` field with their
  name, identifiers and contributed venues (register#78).

- The all-codecheckers table gained a “Check types” column with a
  stacked bar per codechecker, and their own page the same breakdown as
  a donut (register#92, register#207).

### Bug Fixes

- A `codecheck.yml` that cannot be retrieved no longer aborts the whole
  register render: the affected entry is rendered without the metadata
  and a warning names the certificate and the error, instead of the
  render stopping at the first rate limited or unreachable repository.
- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  rejects an empty register, or a `from`/`to` selection outside it, up
  front with a message saying so, instead of carrying rows of `NA` into
  the enrichment steps and failing later with an unrelated error.
- The download of a `codecheck.yml` from OSF is now retried like the two
  OSF API calls preceding it, so a rejection from OSF’s file server
  (e.g. `Forbidden (HTTP 403)` when the anonymous quota is exhausted) no
  longer ends the render.
- The Zenodo DOI badge in the page footer no longer renders its raw URL
  as visible link text next to the badge image.
- Codechecker and venue pages’ Schema.org `Review` entities no longer
  embed markdown link syntax in `@id`, `url` and `name`.
- Pages without Schema.org metadata of their own no longer emit an empty
  `<script type="application/ld+json">`; they fall back to the generic
  CODECHECK website metadata as intended.
- A certificate’s OpenAlex ID and abstract are now looked up once per
  certificate instead of three times, and a failed lookup no longer
  drops the field.
- [`researchequals_policy_check()`](http://codecheck.org.uk/codecheck/reference/researchequals_policy_check.md)
  reports a missing reference to the checked paper as a warning, not a
  failure: ResearchEquals references cannot be added after publication.
- ResearchEquals certificates whose main file is a document written in
  that platform’s editor are downloaded correctly again (affects
  certificate 2026-014).
- Codechecker pages’ Schema.org JSON-LD includes each certificate’s
  paper title and URL again.
- [`render_cert_htmls()`](http://codecheck.org.uk/codecheck/reference/render_cert_htmls.md)
  no longer emits a spurious `file("") only supports open = "w+"...`
  warning on every render.
- Poppler’s PDF parsing diagnostics are now captured and classified
  instead of printing raw to the console, and are reported under
  parallel rendering too.
- Removed a duplicate definition of
  [`convert_cert_pdf_to_png()`](http://codecheck.org.uk/codecheck/reference/convert_cert_pdf_to_png.md)
  that existed identically in two files.
- The venue table’s `Report` and `Paper Title` column widths were fixed;
  Paper Title was the narrowest column despite carrying the most
  content.
- The `<meta name="generator">` tag now shows just
  `codecheck <version>`, without the git commit hashes.
- A codechecker’s metadata panel no longer disappears entirely for an
  author-only person with no codecheckers.csv entry; it now falls back
  to showing their ORCID.
- Fixed the navbar’s border colour being silently overridden by a later
  shorthand `border-bottom` declaration at equal specificity, so it
  never actually rendered green.
- Breadcrumbs on a venue type overview page (e.g. `/venues/journals/`)
  no longer collapse to a bare, unlinked “Venues”; they now show “Venues
  \> Journals” like every other venue page.
- [`render_register_json()`](http://codecheck.org.uk/codecheck/reference/render_register_json.md)
  and
  [`register_update_stats()`](http://codecheck.org.uk/codecheck/reference/register_update_stats.md)
  no longer duplicate their venue/codechecker/work/person stats-building
  logic, which could otherwise drift between a full render and a
  stats-only update.

## codecheck 0.26.0

### New Features

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now checks the register newest-first by default (closes
  codecheckers/codecheck#79). Pass `from = 1, to = nrow(register)` for
  the previous oldest-first order.
- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now also checks the checked repository itself: organisation/group
  membership, archived status, CODECHECK badge, license, and `codecheck`
  topic tag (closes codecheckers/codecheck#25,
  [\#75](https://github.com/codecheckers/codecheck/issues/75),
  [\#14](https://github.com/codecheckers/codecheck/issues/14)).
- The allowed GitHub organisations/GitLab groups for
  [`check_repository_org()`](http://codecheck.org.uk/codecheck/reference/check_repository_org.md)
  are now configurable via `CONFIG$ALLOWED_REPO_ORGS`;
  `github.com/reproducible-agile` was added to the default list.
- [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
  now checks that `codecheck.yml` is valid UTF-8, starts with the YAML
  document marker, and has at least one `codechecker` entry;
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now rejects a register containing duplicate certificate IDs (closes
  codecheckers/codecheck#9).
- [`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)
  gained three checks: the certificate ID must appear in the deposit
  title, a non-standard certificate PDF filename is now flagged, and
  deposit membership in the Zenodo `codecheck` community is checked
  (closes codecheckers/codecheck#20).
- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  no longer accumulates stale `header-attrs-*` directories in
  `docs/libs`, and gained
  [`prune_libs()`](http://codecheck.org.uk/codecheck/reference/prune_libs.md)
  to remove other unreferenced library directories (closes
  codecheckers/codecheck#89).
- Zenodo concept DOI checking is extended to also catch an outdated
  version-specific DOI, via new
  [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  (closes codecheckers/codecheck#36).
- Zenodo “concept DOIs” are now rejected in the `report` field of
  `codecheck.yml` (closes codecheckers/codecheck#36).
- A Quarto certificate template (`codecheck.qmd`) is now shipped
  alongside the R Markdown one (closes codecheckers/codecheck#29).
- Licence correction now keeps the licences already on a Zenodo record
  when adding the required CC-BY 4.0.
- Curation findings that need human judgement (e.g. a non-standard title
  or repository) are now surfaced instead of guessed.
- New
  [`curate_register_zenodo_records()`](http://codecheck.org.uk/codecheck/reference/curate_register_zenodo_records.md)
  applies mechanical Zenodo metadata corrections across a whole register
  in one batch.
- [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  gained `creator_overrides` to control how individual creator names are
  split or kept as an organisation.
- Every Zenodo-hosted certificate is now audited against the CODECHECK
  community curation policy during
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md),
  with findings reported as a summary.
- New
  [`check_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/check_zenodo_record.md)
  and
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  audit and correct a single published Zenodo record’s metadata against
  the curation policy.

### Bug Fixes

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  no longer aborts the whole run when Zenodo rate-limits it.
  [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  and
  [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  now query Zenodo’s plain record endpoint directly instead of through
  zen4R’s search-based lookups, which carried a much stricter,
  easily-tripped limit; requests are paced adaptively from Zenodo’s own
  `X-RateLimit-*` response headers rather than a fixed guess, with a
  `cli` message logged whenever a wait is actually applied, and a 429 is
  retried automatically.
- [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  no longer misreports a rate-limited lookup as a concept DOI.
- [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  no longer misreports a record’s own latest version as outdated: it
  compared record IDs against a second, search-based lookup that is not
  reliably ordered by version, and could return a stale record even when
  the checked one was in fact current. It now reads the authoritative
  `is_latest` flag already present on the record itself.
- `rprojroot` is now declared as a package dependency, fixing a
  missing-function error on a clean install.
- The ORCID icon on certificate pages is now clickable and links to the
  ORCID profile.
- The ORCID icon in the PDF certificate no longer silently goes missing
  (closes codecheckers/codecheck#37).
- A creator recorded as an organisation is now reported as information,
  not an error, in the Zenodo curation policy check (raised in
  codecheckers/register#205).
- ORCID name checks no longer fail a fresh, unauthenticated workspace.
- A fresh workspace now passes strict CrossRef and ORCID name validation
  out of the box.
- The register CSS is now written to the output directory rather than
  the working directory.
- [`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
  now reports the correct target folder (closes
  [\#87](https://github.com/codecheckers/codecheck/issues/87)).
- OSF certificate retrieval now survives an OSF outage instead of
  failing with an unrelated parsing error.
- Rendering no longer rewrites `docs/libs/PROVENANCE.csv` on every run
  when nothing changed.
- A failed library download is no longer stored as if it were the
  library file.
- ResearchEquals certificates can be downloaded again after that
  platform’s API change.
- A register in which no codechecker has an ORCID or GitHub identifier
  now renders correctly.
- Zenodo curation no longer truncates titles that need a human’s review.
- A clear error message is now shown when a Zenodo token may not edit a
  record.
- Codecheckers are now recorded as persons, not organisations, in Zenodo
  metadata.
- Alternate identifiers are no longer silently dropped when uploading
  Zenodo metadata.
- Record titles now match the curation policy (“CODECHECK Certificate
  \<ID\>”).
- A missing or non-DOI paper reference now raises a clear warning.

## codecheck 0.25.0

### New Features

- New `register-full.json` and `register-full.csv` exports contain the
  complete certificate metadata, including authors, codecheckers, and
  abstracts (closes codecheckers/register#57).
- New
  [`register_render_cert()`](http://codecheck.org.uk/codecheck/reference/register_render_cert.md)
  renders a single certificate by ID without re-rendering the whole
  register (closes codecheckers/codecheck#84).
- Visiting `/register/certs/` without a certificate ID now redirects to
  the main register page instead of showing a 404 (closes
  codecheckers/register#166).
- Rendering output now uses structured, colored logging with progress
  bars and section headers.
- Warnings raised during rendering are now collected and shown as a
  deduplicated summary at the end of the run.

### Bug Fixes

- Fixed stray `libs/` folders left behind by parallel rendering.
- Fixed broken navigation links on venue type pages.
- Fixed broken navigation and logo paths on venue type pages.
- Removed the redundant venue label column from venue type pages.

### Performance & Scalability

- Log messages during certificate rendering are now prefixed with the
  certificate ID, making parallel-render logs easier to follow.

## codecheck 0.24.0

### Register Enhancements

- Internal navigation links now use relative paths, enabling local
  development and testing.
- The Paper Title column is wider and the Report column narrower, with
  shortened displayed URLs.
- Certificate abstract and summary text now display in full, without a
  scrollable container.
- Certificate preview images now auto-paginate every 5 seconds, pausing
  on user interaction.
- Certificate pages now use the full viewport width.
- All register outputs (HTML, Markdown, JSON) are now consistently
  sorted by certificate ID, except `featured.json`, which stays sorted
  by check date (closes codecheckers/register#160).
- Certificate pages now include an interactive citation generator (APA,
  Vancouver, Harvard, BibTeX, BibLaTeX, RIS) (closes
  codecheckers/register#82).
- JavaScript is now centralized into dedicated files, and the citation
  library is bundled locally instead of loaded from a CDN.
- Navigation and breadcrumb text sizes were increased for readability.

### Performance & Scalability

- Certificate HTML can now be rendered in parallel across CPU cores via
  `register_render(parallel = TRUE)`, roughly 5-6x faster on 8 cores.

### Bug Fixes

- Fixed duplicate certificates appearing on the “no ORCID” codechecker
  page (closes codecheckers/register#153).
- Codecheckers without an ORCID now appear on the “All codecheckers”
  page.
- Fixed a crash from missing check dates in Schema.org metadata.
- Fixed the certificate JSON page generator not being available for
  external use.
- Fixed the citation generator, which previously loaded indefinitely.

## codecheck 0.23.0 (2025-11-12)

### Register Enhancements

- Added a navigation header with the CODECHECK logo, and an overview
  menu on the main register pages.
- Added breadcrumb navigation to all register pages (closes
  codecheckers/register#108).
- Certificate pages now include a machine-readable `index.json` (closes
  codecheckers/register#143).
- Certificate pages now include Schema.org JSON-LD metadata for search
  engines (closes codecheckers/register#182).
- Codechecker profile pages now include Schema.org JSON-LD metadata.
- Column ordering in register tables is now configurable per view
  (addresses
  [\#101](https://github.com/codecheckers/codecheck/issues/101)).
- CSV exports now include all fields available in the JSON output.
- Added `sitemap.xml` and `robots.txt` for search engine discoverability
  (closes codecheckers/register#126).
- Codecheckers without an ORCID now get their own page, keyed by GitHub
  username (closes codecheckers/register#130).
- Overview pages now show build metadata (timestamp, version, commit) in
  the footer (closes
  [\#105](https://github.com/codecheckers/codecheck/issues/105)).
- Replaced inline SVG icons with icon fonts for ORCID, GitHub, and
  Zenodo.
- Codechecker pages now display ORCID and GitHub profile links (closes
  [\#73](https://github.com/codecheckers/codecheck/issues/73)).
- Added a Zenodo community link to the footer.

### Bug Fixes

- Fixed a grouping error in the venue table.
- Fixed a crash from a missing paper title during CSV generation.
- Fixed icon font, JavaScript, CSS, and logo paths on nested pages.

## codecheck (development version)

### Certificate Page Improvements

- Codechecker names on certificate pages now link to their register page
  rather than their ORCID profile (closes
  [\#141](https://github.com/codecheckers/codecheck/issues/141)).
- Certificate pages now link the venue type and venue name (closes
  [\#142](https://github.com/codecheckers/codecheck/issues/142)).
- Certificate pages now include venue-based breadcrumb navigation.

### Visual Improvements

- ORCID icons now use the official ORCID brand color.
- Updated the Zenodo icon to the official logo.
- Improved icon alignment across register pages.

### Infrastructure Improvements

- Temporary HTML section files are now cleaned up after rendering.
- Register CSS moved out of inline styles into a dedicated stylesheet.
- External libraries (Bootstrap, Font Awesome, Academicons) are now
  managed locally instead of via CDN, with provenance tracking.

### Bug Fixes

- Fixed a rendering error from a missing table details name.
- Fixed broken venue type hyperlinks.

### Venue Configuration and Label Integration

- Venue information now loads from `venues.csv` instead of being
  hardcoded.
- Venue pages now link to their open GitHub issues.
- Breaking change:
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  now requires a `venues_file` parameter.

### GitHub Issue Validation

- Certificates are now validated against their GitHub issue: a missing
  issue fails validation, a closed or unassigned issue raises a warning.

### ORCID Validation Improvements

- ORCID validation now handles authentication failures gracefully, with
  a new `skip_on_auth_error` option for CI and offline use.

### Manifest Rendering Enhancements

- Certificates can now render more file formats in the manifest section,
  including TIF, GIF, EPS, SVG, JSON, TSV, and multi-page PDFs.
- A missing or unsupported manifest file no longer fails the whole
  certificate; it now shows an error message in the PDF instead.

## codecheck 0.22.0

### Certificate Automation and Validation

- Certificate IDs can now be retrieved automatically from the matching
  GitHub issue.
- `codecheck.yml` can now be validated for syntax errors and
  auto-completed with missing fields.
- Paper and author/codechecker metadata can now be validated against
  CrossRef and ORCID records.
- Placeholder certificate IDs and report DOIs are now flagged with a
  visible warning in rendered PDFs.

### Lifecycle Journal Integration

- Article metadata can now be retrieved automatically from Lifecycle
  Journal to populate `codecheck.yml` (closes
  [\#82](https://github.com/codecheckers/codecheck/issues/82)).

### Bug Fixes

- Fixed Zenodo certificate upload failing due to an API signature
  change.
- Fixed ORCID icon links in PDF certificates.
- Fixed handling of NULL/empty fields during certificate rendering.
- Fixed Zenodo alternate identifiers not being set per the curation
  policy.

### Enhancements

- Zenodo certificate upload can now include additional files, including
  the certificate source (`.Rmd`/`.qmd`).
- A new Zenodo record’s DOI is now written back to `codecheck.yml`
  automatically, and the record is submitted to the CODECHECK community.
- Zenodo metadata uploads now comply with the CODECHECK curation policy
  (publisher, resource type, identifiers).
- DOI validation is now platform-agnostic (Zenodo, OSF, ResearchEquals,
  …).

## codecheck 0.21.0

- Added a pkgdown documentation site.
- Fixed a typo in abstract text retrieval.
- Fixed repository URL validation to properly check HTTP responses.

## codecheck 0.20.0

- Renamed fields in register output for consistency.
- Updated footer contact information and removed individual maintainer
  references.

## codecheck 0.19.0

- Fixed namespace issues.
- Added support for specifying a from/to range when rendering the
  register.

## codecheck 0.18.0

- Added validation of the certificate identifier format (`NNNN-NNN`,
  e.g. “2024-001”) in
  [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md).

## codecheck 0.17.0

- Added support for downloading certificates from the ResearchEquals
  platform.

## codecheck 0.16.0

- Added support for accessing `codecheck.yml` in a subdirectory of a
  GitHub repository via `github::org/repo|subpath`.
- Added a TL;DR section to the README for template usage.

## codecheck 0.15.0

- Improved handling of PDF import in the certificate template.

## codecheck 0.14.0

- Added TU Delft Data Champion Centre (DCC) and eLife as venues; removed
  unused venue entries.
- Fixed Zenodo hyperlinks in register output.
- Hardened handling of missing ORCIDs in the codechecker field.
- Added venue hyperlinks to register pages.
- Fixed a missing codechecks column.

## codecheck 0.12.0

- Added support for retrieving `codecheck.yml` from Zenodo records via
  `zenodo::1234567` and `zenodo-sandbox::1234567`.

## codecheck 0.11.6

- Fixed JSON output including markdown hyperlinks by mistake.

## codecheck 0.11.5

- Fixed imports to reflect API changes in the zen4R package.

## codecheck 0.11.4

- Replaced a custom URL-check helper with
  [`httr::http_error()`](https://httr.r-lib.org/reference/http_error.html),
  improving URL validation.

## codecheck 0.11.3

- Added logging of cache usage for check and render operations.

## codecheck 0.11.2

- Fixed codechecker hyperlink generation when the ORCID ID is missing.

## codecheck 0.11.1

- Fixed certificate pages that have no certificate preview available.

## codecheck 0.11.0

- Added individual certificate HTML pages.
- Added abstract retrieval from CrossRef and OpenAlex.

## codecheck 0.10.1

- Fixed venue type page hyperlinks.

## codecheck 0.10.0

- Fixed URL links in venue and venue type tables.

## codecheck 0.9.0 / 0.8.0

- Replaced the repository column in the register with platform-prefixed
  specifications (GitHub, OSF, GitLab, Zenodo).

## codecheck 0.7.0

- Added Amsterdam UMC as a venue.

## codecheck 0.6.0

- Split the register by type (journal, conference, community,
  institution).
- Added filtered CSV files by venue and codechecker.

## codecheck 0.5.0

- Added support for multiple output formats (HTML, JSON, Markdown).

## codecheck 0.4.0

- Added codechecker-specific register views.

## codecheck 0.3.0

- Added remote configuration retrieval.

## codecheck 0.2.0

- Added register rendering functionality, supporting multiple venues and
  codecheckers.

## codecheck 0.1.0

- Initial release: basic CODECHECK workspace creation, certificate
  generation, and Zenodo integration.

## codecheck 0.0.0.90xx

- Added a `NEWS.md` file to track changes to the package.
