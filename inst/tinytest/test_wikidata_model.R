tinytest::using(ttdo)

# The model is data, so a mistake in it is not a syntax error anywhere - these
# tests are what turns one into a failure instead of a wrong statement on a
# public Wikidata item. No network, no fixtures needed.

# Model invariants ----

expect_true(codecheck::validate_wikidata_model())

expect_equal(
  codecheck::wikidata_entity_kinds(),
  c("certificate", "paper", "person", "venue")
)

# The two decisions the model exists to record ----

certificate_properties <- vapply(
  codecheck::wikidata_statements("certificate"),
  function(s) s$property,
  character(1)
)

# P13046 is what puts a certificate in the scholarly graph, next to the paper it
# reviews; without it a query cannot join the two at all.
expect_true("P13046" %in% certificate_properties)

# The link to the checked paper is "review of", never "cites work".
expect_true("P6977" %in% certificate_properties)
expect_false("P2860" %in% certificate_properties)

# P6977 points at the paper entity, and at nothing else on a certificate.
review_of <- Filter(function(s) s$property == "P6977", codecheck::wikidata_statements("certificate"))
expect_equal(length(review_of), 1)
expect_equal(review_of[[1]]$value$kind, "entity")
expect_equal(review_of[[1]]$value$entity, "paper")

# The certificate identifier, carried until a dedicated property exists ----

catalog <- Filter(function(s) s$property == "P528", codecheck::wikidata_statements("certificate"))
expect_equal(length(catalog), 1)
expect_equal(catalog[[1]]$value$field, "Certificate ID")

# P528 says nothing without naming its catalog.
expect_equal(vapply(catalog[[1]]$qualifiers, function(q) q$property, character(1)), "P972")

# The catalog item does not exist yet, so the statement is marked pending and no
# export may emit it - the marker is what keeps that visible.
pending <- codecheck::wikidata_pending()
expect_equal(nrow(pending), 1)
expect_equal(pending$property, "P528")
expect_true(nzchar(pending$pending))

missing_catalog <- codecheck::wikidata_model()
missing_catalog$certificate$statements <- lapply(
  missing_catalog$certificate$statements,
  function(s) { if (s$property == "P528") s$qualifiers <- NULL; s }
)
expect_true(any(grepl("P972", codecheck::validate_wikidata_model(missing_catalog))))

# A pending marker has to say what is missing, rather than just being present.
empty_marker <- codecheck::wikidata_model()
empty_marker$certificate$statements <- lapply(
  empty_marker$certificate$statements,
  function(s) {
    if (s$property == "P528") s$qualifiers[[1]]$value$pending <- ""
    s
  }
)
expect_true(any(grepl("pending marker", codecheck::validate_wikidata_model(empty_marker))))

# Two venues, on two different items ----

# Where the certificate itself was published (Zenodo, OSF, ResearchEquals) and
# where the checked paper appeared are different facts; both are in the model.
cert_venue <- Filter(function(s) s$property == "P1433", codecheck::wikidata_statements("certificate"))
expect_equal(length(cert_venue), 1)
expect_equal(cert_venue[[1]]$value$kind, "mapped")
expect_equal(cert_venue[[1]]$value$field, "Report")

paper_venue <- Filter(function(s) s$property == "P1433", codecheck::wikidata_statements("paper"))
expect_equal(length(paper_venue), 1)
expect_equal(paper_venue[[1]]$value$entity, "venue")
# Resolved from the paper's own record, not from the register's Venue column:
# one register venue can span several publications over the years - AGILE papers
# are in AGILE: GIScience Series today and were in Springer LNCS earlier - so a
# venue-derived value would be wrong for the older ones.
expect_equal(paper_venue[[1]]$value$field, "Paper reference")
expect_true(is.null(paper_venue[[1]]$venue_types))
expect_equal(codecheck::wikidata_model()$venue$resolve$property, "P236")
expect_equal(codecheck::wikidata_model()$venue$resolve$field, "issn")

# Dropping either one is a modelling regression.
no_paper_venue <- codecheck::wikidata_model()
no_paper_venue$paper$statements <- Filter(function(s) s$property != "P1433",
                                          no_paper_venue$paper$statements)
expect_true(any(grepl("venue of the checked article",
                      codecheck::validate_wikidata_model(no_paper_venue))))

swapped <- codecheck::wikidata_model()
swapped$certificate$statements <- lapply(swapped$certificate$statements, function(s) {
  if (s$property == "P1433") s$value <- list(kind = "entity", entity = "venue", field = "Venue")
  s
})
expect_true(any(grepl("platform the certificate is published on",
                      codecheck::validate_wikidata_model(swapped))))

# AGILE reproducibility reviews are not branded CODECHECKs ----

instance_of <- Filter(function(s) s$property == "P31", codecheck::wikidata_statements("certificate"))[[1]]
expect_equal(instance_of$value$kind, "switch")
expect_equal(instance_of$value$field, "Venue")
expect_equal(instance_of$value$cases$AGILEGIS, "Q116740071")
expect_equal(instance_of$value$default, "Q116740091")

bad_switch <- codecheck::wikidata_model()
bad_switch$certificate$statements[[1]]$value$default <- "P116740091"
expect_true(any(grepl("switch cases and default",
                      codecheck::validate_wikidata_model(bad_switch))))

unknown_map <- codecheck::wikidata_model()
unknown_map$certificate$statements <- lapply(unknown_map$certificate$statements, function(s) {
  if (s$property == "P1433") s$value$map <- "repositories"
  s
})
expect_true(any(grepl("no known map", codecheck::validate_wikidata_model(unknown_map))))

# A checked preprint is typed as one ----

paper_type <- Filter(function(s) s$property == "P31", codecheck::wikidata_statements("paper"))[[1]]
expect_equal(paper_type$value$kind, "switch")
expect_equal(paper_type$value$cases$preprint, "Q580922")
expect_equal(paper_type$value$default, "Q13442814")

# Both values keep the paper in the scholarly graph, beside its certificate;
# a type that moved it to the main graph would break the link.
expect_true(all(c(paper_type$value$cases$preprint, paper_type$value$default) %in%
                  c("Q580922", "Q13442814")))

# Endpoints follow the query service graph split ----

# Papers live in the scholarly graph, people and venues in the main one;
# querying the wrong endpoint returns no match rather than an error, which is
# why this is asserted rather than left to the caller.
expect_equal(codecheck::wikidata_endpoint("paper"), "https://query-scholarly.wikidata.org/sparql")
expect_equal(codecheck::wikidata_endpoint("certificate"), "https://query-scholarly.wikidata.org/sparql")
expect_equal(codecheck::wikidata_endpoint("person"), "https://query.wikidata.org/sparql")
expect_equal(codecheck::wikidata_endpoint("venue"), "https://query.wikidata.org/sparql")

# The CODECHECK Wikibase is unsplit, so one endpoint serves every kind.
expect_equal(
  codecheck::wikidata_endpoint("paper", target = "wikibase"),
  codecheck::wikidata_endpoint("person", target = "wikibase")
)

expect_error(codecheck::wikidata_endpoint("nonesuch"), pattern = "Unknown entity kind")
expect_error(codecheck::wikidata_statements("nonesuch"), pattern = "Unknown entity kind")

# What may be created where ----

# Only certificates are created on Wikidata; the papers, people and venues they
# refer to belong to the communities that maintain them.
expect_true(codecheck::wikidata_creates("certificate", "wikidata"))
expect_false(codecheck::wikidata_creates("paper", "wikidata"))
expect_false(codecheck::wikidata_creates("person", "wikidata"))
expect_false(codecheck::wikidata_creates("venue", "wikidata"))

# Our own Wikibase mirrors everything, having no notability rules to respect.
for (kind in codecheck::wikidata_entity_kinds()) {
  expect_true(codecheck::wikidata_creates(kind, "wikibase"))
}

# The flat property table ----

properties <- codecheck::wikidata_properties()
expect_true(is.data.frame(properties))
expect_equal(
  colnames(properties),
  c("entity", "key", "property", "label", "value_kind", "required", "note")
)
expect_equal(
  nrow(properties),
  sum(vapply(codecheck::wikidata_entity_kinds(),
             function(k) length(codecheck::wikidata_statements(k)), integer(1)))
)
expect_true(all(grepl("^P[0-9]+$", properties$property)))
expect_true(all(properties$value_kind %in% c("constant", "field", "entity", "render_date", "switch", "mapped")))

# The DOI is the dedup key for a certificate: it is required, and it is what
# resolution looks an existing item up by.
doi <- properties[properties$entity == "certificate" & properties$key == "doi", ]
expect_equal(nrow(doi), 1)
expect_true(doi$required)
expect_equal(codecheck::wikidata_model()$certificate$resolve$property, "P356")
expect_equal(codecheck::wikidata_model()$certificate$resolve$field, "Report")

# Register columns the model reads ----

# Every "field" value must name a column the register table actually carries,
# or the export would silently emit nothing for that statement.
register_columns <- c(
  "Certificate ID", "Certificate Link", "Certificate PDF", "Report", "Check date",
  "Title", "Paper reference", "Repository Link", "Venue", "Codechecker",
  # venue and person entities are built from venues.csv / codecheck.yml rather
  # than from a register row
  "orcid", "name", "issn", "identifiers", "website_url", "longname"
)
field_values <- unlist(lapply(codecheck::wikidata_entity_kinds(), function(kind) {
  vapply(
    Filter(function(s) s$value$kind == "field", codecheck::wikidata_statements(kind)),
    function(s) s$value$field,
    character(1)
  )
}))
expect_true(all(field_values %in% register_columns))

# Detecting a broken model ----

# The validator takes a model so a deliberately corrupted copy can be checked:
# these are the mistakes that would otherwise first show up as wrong statements
# on public Wikidata items.

without_graph_property <- codecheck::wikidata_model()
without_graph_property$certificate$statements <- Filter(
  function(s) s$property != "P13046",
  without_graph_property$certificate$statements
)
problems <- codecheck::validate_wikidata_model(without_graph_property)
expect_true(is.character(problems))
expect_true(any(grepl("P13046", problems)))

without_review_of <- codecheck::wikidata_model()
without_review_of$certificate$statements <- Filter(
  function(s) s$property != "P6977",
  without_review_of$certificate$statements
)
expect_true(any(grepl("P6977", codecheck::validate_wikidata_model(without_review_of))))

# Reintroducing "cites work" on a certificate is a modelling regression, not a
# harmless addition.
with_cites_work <- codecheck::wikidata_model()
with_cites_work$certificate$statements <- c(
  with_cites_work$certificate$statements,
  list(list(key = "cites_work", property = "P2860", label = "cites work",
            value = list(kind = "entity", entity = "paper", field = "Paper reference"),
            required = FALSE))
)
expect_true(any(grepl("P2860", codecheck::validate_wikidata_model(with_cites_work))))

bad_property <- codecheck::wikidata_model()
bad_property$certificate$statements[[1]]$property <- "Q31"
expect_true(any(grepl("not a property id", codecheck::validate_wikidata_model(bad_property))))

bad_reference <- codecheck::wikidata_model()
bad_reference$certificate$statements[[1]]$value <- list(kind = "entity", entity = "publisher")
expect_true(any(grepl("unknown entity kind", codecheck::validate_wikidata_model(bad_reference))))

bad_endpoint <- codecheck::wikidata_model()
bad_endpoint$person$resolve$endpoint <- "legacy_full"
expect_true(any(grepl("unknown endpoint", codecheck::validate_wikidata_model(bad_endpoint))))

duplicate_keys <- codecheck::wikidata_model()
duplicate_keys$paper$statements <- c(duplicate_keys$paper$statements,
                                     duplicate_keys$paper$statements[1])
expect_true(any(grepl("duplicate statement key", codecheck::validate_wikidata_model(duplicate_keys))))
