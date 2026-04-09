# Changelog

All notable changes to **sast-bandit** are documented in this file.

## [Unreleased]

## [1.0.2] — 2026-04-09

### Changed

- Stricter validation of path-related inputs (**`working_directory`**, **`targets`**, **`exclude`**, **`bandit_config`**, **`report_file`**, **`sarif_filename`**) to reject absolute paths and `..` segments.

## [1.0.1] — 2026-04-06

### Added

- **`write_sarif`** / **`sarif_filename`**: optional SARIF report for **GitHub Code Scanning**; output **`sarif_path`** (second Bandit pass when enabled).

## [1.0.0] — (initial)

See git tags and commit history for details.
