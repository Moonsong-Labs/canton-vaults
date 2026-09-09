#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"
canton_version="${CANTON_VERSION:-3.5.6}"
canton_jar="${CANTON_JAR:-${DPM_HOME:-$HOME/.dpm}/cache/components/canton-open-source/$canton_version/lib/canton-open-source-$canton_version.jar}"

if ! command -v java >/dev/null 2>&1; then
  echo "Java is required. Install JDK 17 or newer." >&2
  exit 1
fi

if [[ ! -f "$canton_jar" ]]; then
  echo "Set CANTON_JAR to a Canton 3.5 runtime JAR (tested with 3.5.6)." >&2
  exit 1
fi
canton_jar="$(cd "$(dirname "$canton_jar")" && pwd)/$(basename "$canton_jar")"

log_root="${SANDBOX_LOG_DIR:-${TMPDIR:-/tmp}}"
mkdir -p "$log_root"
log_root="$(cd "$log_root" && pwd)"
sandbox_dir="$(mktemp -d "$log_root/canton-sandbox.XXXXXX")"
echo "Sandbox log: $sandbox_dir/canton.log"
cd "$repo_root"
exec java -Xmx2g -jar "$canton_jar" run "$script_dir/demo.canton" \
  --manual-start \
  --log-level-stdout WARN \
  --log-file-name "$sandbox_dir/canton.log" \
  -c "$script_dir/canton.conf"
