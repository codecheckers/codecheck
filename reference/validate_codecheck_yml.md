# Validate a CODECHECK configuration

Checks the \`MUST\`-contents of the configuration file specification,
see \<https://codecheck.org.uk/spec/config/latest/\>.

## Usage

``` r
validate_codecheck_yml(configuration, spec_version = NULL)
```

## Arguments

- configuration:

  R object of class \`list\`, or a path to a file

- spec_version:

  Specification version to validate against, defaulting to the version
  the file declares, see \[codecheck_spec_version()\].

## Value

\`TRUE\` if the provided configuration is valid, otherwise the function
stops with an error

## Details

The structural checks are the rules of the specification version the
file declares, run by \[validate_codecheck_yml_rules()\] - this function
does not implement them a second time. It stops at the first failure, as
it always has, whereas \[validate_codecheck_yml_rules()\] reports every
rule.

Which rules are enforced here is deliberately the set this function has
always enforced, see \`VALIDATE_YML_RULES\`: it gates the register
rendering, so widening it rejects certificates that are recorded and
published today. Use \[validate_codecheck_yml_rules()\] for the full
picture of a file.

## See also

\[validate_codecheck_yml_rules()\] for all rules and their severities

## Author

Daniel Nuest
