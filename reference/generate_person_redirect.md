# Generate HTML redirect page for a person's GitHub handle

The person-page analogue of \[generate_codechecker_redirect()\]: a
person with a GitHub handle on record gets a redirect stub at
\`docs/persons/\<handle\>/\` pointing at their canonical
\`docs/persons/\<ORCID\>/\` page, so a handle-based link (or bookmark
from before \#123) still resolves. Reuses the exact same template -
"redirect to a person" is the same shape of page whether the person is a
codechecker or an author.

## Usage

``` r
generate_person_redirect(github_handle, orcid, name)
```

## Arguments

- github_handle:

  The GitHub handle (without @ prefix)

- orcid:

  The person's ORCID

- name:

  The person's name

## Value

Invisibly returns TRUE if successful, FALSE otherwise
