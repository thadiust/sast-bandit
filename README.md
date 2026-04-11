# sast-bandit

Composite GitHub Action that runs **[Bandit](https://github.com/pycqa/bandit)** static analysis on Python source under **`working_directory`**, counts **issues** (SAST findings) from a **JSON** report, and optionally writes a human-readable report. Output uses **`issue_count`**.

## Behavior

- **`issue_count = 0` and the scan finishes successfully** → `scan_status=clean`, step succeeds.
- **`issue_count > 0`** → `scan_status=findings_found`. If **`fail_on_findings`** is **`true`** (the default), the step exits **1**; if **`false`**, the step exits **0** after logging the count (reporting-only).
- **Missing or unparseable JSON, missing targets, or Bandit configuration errors** → `scan_status=scanner_error`, step fails with Bandit’s exit code.

**`issue_count`** is the length of Bandit’s **`results`** array in the JSON output, after applying **`minimum_severity`**, **`minimum_confidence`**, **`bandit_config`**, and **`exclude`** — so it matches what your thresholds would show in the rendered report.

The action runs Bandit once with **`-f json`** to compute **`issue_count`**. If **`report_format`** is **`json`**, it reuses that file for the log or **`report_file`**; otherwise it runs Bandit again with **`report_format`** (for example **`txt`**) so logs stay readable. With **`-q`**, Bandit may produce an **empty** **`.txt`** file on a clean scan; the action treats that as success when the tool exits **0**.

**`write_sarif: true` (Code Scanning):** Bandit runs **again** with **`-f sarif`** so **`upload-sarif`** gets a proper SARIF document while the **JSON** pass remains the source of **`issue_count`** and fail logic. That is **intentional** but costs roughly **another full Bandit traversal** on large repos; set **`write_sarif: false`** if you only need exit status and human-readable output.

## Caller responsibilities

- Use a **Linux** runner; **`actions/setup-python`** runs inside the action. Inputs are **validated before** Python/Bandit are installed so bad configuration fails fast without installing packages.
- Every path in **`targets`** must exist under **`working_directory`** (validated before the scan).
- If **`bandit_config`** is set, that file must exist (validated).
- Pin **`bandit_version`** if you want reproducible CI as Bandit rules change.

## Severity and confidence

| Input | Effect (Bandit flags) |
|--------|------------------------|
| `minimum_severity` `all` | *(no extra flag)* |
| `minimum_severity` `low` | `-l` |
| `minimum_severity` `medium` | `-ll` |
| `minimum_severity` `high` | `-lll` |
| `minimum_confidence` `all` | *(no extra flag)* |
| `minimum_confidence` `low` | `-i` |
| `minimum_confidence` `medium` | `-ii` |
| `minimum_confidence` `high` | `-iii` |

Higher minimums **filter out** lower-severity or lower-confidence issues from both the count and the rendered report.

## Inputs

| Input | Default | Description |
|--------|---------|-------------|
| `python_version` | `3.11` | Python version for `actions/setup-python`. |
| `bandit_version` | `1.9.4` | Exact Bandit version installed with `pip install bandit==…`. |
| `working_directory` | `.` | Directory from which Bandit runs (repo-root relative). |
| `targets` | `.` | Space-separated paths to scan, passed to **`bandit -r`** (relative to **`working_directory`**). |
| `bandit_config` | *(empty)* | Optional Bandit config path (for example **`bandit.yaml`**) relative to **`working_directory`**. |
| `exclude` | *(empty)* | Optional comma-separated paths passed to **`bandit --exclude`**. |
| `minimum_severity` | `all` | Floor for severity: **`all`**, **`low`**, **`medium`**, or **`high`**. |
| `minimum_confidence` | `all` | Floor for confidence: **`all`**, **`low`**, **`medium`**, or **`high`**. |
| `report_format` | `txt` | Human-oriented format when not using JSON-only output: **`txt`**, **`json`**, **`yaml`**, or **`csv`**. |
| `report_file` | *(empty)* | If set, copy the report to this path relative to **`working_directory`**. |
| `fail_on_findings` | `true` | If **`true`**, exit **1** when **`issue_count > 0`**. |
| `write_sarif` | `false` | If **`true`**, run a second **Bandit** pass and write **SARIF** to **`sarif_filename`** (for **`github/codeql-action/upload-sarif`**). |
| `sarif_filename` | `bandit-results.sarif` | Path relative to **`working_directory`** when **`write_sarif`** is **`true`**. |

## Outputs

| Output | Description |
|--------|-------------|
| `issue_count` | Number of Bandit results after severity/confidence/config filters. |
| `scan_status` | `clean`, `findings_found`, or `scanner_error`. |
| `sarif_path` | Repo-relative path to the SARIF file when **`write_sarif`** is **`true`**; empty otherwise. |

## Example

```yaml
jobs:
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: thadiust/sast-bandit@main
        with:
          working_directory: "."
          targets: "src"
          minimum_severity: "medium"
          report_format: "txt"
          fail_on_findings: true
```

With a config file and artifact report:

```yaml
      - uses: thadiust/sast-bandit@main
        with:
          targets: "."
          bandit_config: "bandit.yaml"
          exclude: ".venv,tests/fixtures"
          report_format: "json"
          report_file: "bandit-report.json"
          fail_on_findings: true
```

## Scope and limits

- Bandit is **pattern-based SAST** and often emits **false positives**; use **`bandit.yaml`**, **`exclude`**, and **`minimum_severity` / `minimum_confidence`** to tune signal quality instead of turning the job off. It does not replace code review, dependency scanning, or secret detection.

For a full Python security pipeline (Gitleaks, Bandit, pip-audit), see [`thadiust/workflow-python`](https://github.com/thadiust/workflow-python).
