# Pre-check Scripts

This directory contains scripts used by the GitHub Actions workflow to perform pre-checks on new issues.

## Scripts

### `get_installation_type.R`

R script that retrieves the installation type from the GBIF API using rgbif.

**Usage:**
```bash
Rscript get_installation_type.R <installationKey>
```

**Parameters:**
- `installationKey`: UUID of the GBIF installation

**Output:**
Prints the installation type to stdout (e.g., `IPT_INSTALLATION`, `BIOCASE_INSTALLATION`, etc.)

**Dependencies:**
- R package: `rgbif`

---

### `add_installation_type_label.sh`

Bash script that extracts the installation key from issue labels and adds an installation type label to the issue.

**Usage:**
```bash
bash add_installation_type_label.sh <issue_number>
```

**Parameters:**
- `issue_number`: GitHub issue number to process

**Process:**
1. Extracts installation key from issue labels (format: `inst: <uuid>`)
2. Calls `get_installation_type.R` to retrieve installation type
3. Adds label to issue in format: `installation: <TYPE>`
4. If label already exists, updates it if different

**Dependencies:**
- `gh` CLI (GitHub CLI)
- `jq` (JSON processor)
- `get_installation_type.R` script

---

## GitHub Actions Workflow

The `pre-check.yml` workflow is triggered when:
- A new issue is opened
- An issue is labeled
- Manual workflow dispatch

### Jobs

#### `add-installation-type`

This job:
1. Checks out the repository
2. Sets up R and installs `rgbif`
3. Runs `add_installation_type_label.sh` to add the installation type label
4. Outputs the installation type and whether additional pre-checks should continue

### Outputs

- `installation_type`: The type of installation (e.g., `IPT_INSTALLATION`)
- `should_continue`: Boolean indicating if further pre-checks should run

### Future Extensions

Additional pre-check jobs can be added to the workflow that:
- Depend on the `add-installation-type` job
- Use the `should_continue` output to conditionally run
- Access the `installation_type` output to customize checks

Example:
```yaml
additional-checks:
  name: Additional Pre-checks
  needs: add-installation-type
  if: needs.add-installation-type.outputs.should_continue == 'true'
  runs-on: ubuntu-latest
  steps:
    - name: Run checks
      run: echo "Running checks for ${{ needs.add-installation-type.outputs.installation_type }}"
```
