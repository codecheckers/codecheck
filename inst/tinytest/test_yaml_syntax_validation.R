## Test validate_yaml_syntax function

# Test 1: Valid YAML file should return TRUE
valid_yaml <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: 2024-001",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: John Doe"
), valid_yaml)

expect_true(validate_yaml_syntax(valid_yaml, stop_on_error = FALSE))

# Clean up
unlink(valid_yaml)

# Test 2: Invalid YAML syntax should return FALSE when stop_on_error = FALSE
invalid_yaml <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: 2024-001",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: John Doe",
  "  : invalid syntax here"
), invalid_yaml)

expect_false(validate_yaml_syntax(invalid_yaml, stop_on_error = FALSE))

# Clean up
unlink(invalid_yaml)

# Test 3: Invalid YAML should stop execution when stop_on_error = TRUE (default)
invalid_yaml2 <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: 2024-001",
  "paper:",
  "  - invalid: [unclosed bracket"
), invalid_yaml2)

expect_error(validate_yaml_syntax(invalid_yaml2), "Invalid YAML syntax")

# Clean up
unlink(invalid_yaml2)

# Test 4: Non-existent file should throw error
expect_error(validate_yaml_syntax("/nonexistent/file.yml"), "File does not exist")

# Test 5: Empty YAML file should be valid
empty_yaml <- tempfile(fileext = ".yml")
writeLines("", empty_yaml)

expect_true(validate_yaml_syntax(empty_yaml, stop_on_error = FALSE))

# Clean up
unlink(empty_yaml)

# Test 6: YAML with complex structure should be valid
complex_yaml <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: 2024-001",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: John Doe",
  "      ORCID: 0000-0001-2345-6789",
  "    - name: Jane Smith",
  "manifest:",
  "  - file: figure1.png",
  "    comment: Main result",
  "  - file: table1.csv",
  "    comment: Summary data"
), complex_yaml)

expect_true(validate_yaml_syntax(complex_yaml, stop_on_error = FALSE))

# Clean up
unlink(complex_yaml)
