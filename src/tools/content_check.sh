#!/usr/bin/env bash
# One-command content pipeline (docs/Phase_5/05, designer workflow steps 2-4):
#   1. schema validation of all catalogs
#   2. seed-2030 fixture regression (via the test suite)
#   3. 20-seed x 3-strategy structural corridor batch
# Usage (from the repo root):  src/tools/content_check.sh [path-to-godot-binary]
set -u
GODOT="${1:-godot/bin/godot.linuxbsd.editor.dev.x86_64}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

echo "== 1/3 validate data =="
"$GODOT" --headless --path "$SRC" --script res://tools/validate_data.gd || FAIL=1

echo "== 2/3 test suite (includes fixture regression) =="
"$GODOT" --headless --path "$SRC" --script res://tests/run_tests.gd || FAIL=1

echo "== 3/3 20-seed structural batch =="
"$GODOT" --headless --path "$SRC" --script res://tools/batch_runs.gd -- \
	--seeds 20 --strategy all --enforce --csv /tmp/drawdown_batch.csv || FAIL=1

if [ "$FAIL" -ne 0 ]; then
	echo "CONTENT CHECK FAILED"
	exit 1
fi
echo "CONTENT CHECK PASSED"
