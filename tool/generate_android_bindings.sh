#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart run jnigen --config jnigen.yaml
