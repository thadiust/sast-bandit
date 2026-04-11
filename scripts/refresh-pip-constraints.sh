#!/usr/bin/env bash
# Regenerate constraints/bandit-sarif-<version>.txt after changing the default bandit_version in action.yml.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_VER="${1:-1.9.4}"
VENV="${TMPDIR:-/tmp}/bandit-constr-$$"
python3.11 -m venv "$VENV"
# shellcheck disable=SC1090
source "$VENV/bin/activate"
pip install -q pip-tools
REQ="${ROOT}/constraints/bandit-sarif-${DEFAULT_VER}.txt"
echo "bandit[sarif]==${DEFAULT_VER}" > /tmp/bandit-sarif.in
pip-compile --allow-unsafe --generate-hashes /tmp/bandit-sarif.in -o "$REQ" --strip-extras
rm -rf "$VENV"
echo "Wrote $REQ"
