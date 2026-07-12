#!/usr/bin/env bash
#
# 从 .xcresult 生成 Markdown + HTML 测试报告。
# 用法: make-report.sh <xcresult路径> <report.md> <report.html> <xcodebuild退出码>
#
set -euo pipefail

XCRESULT="$1"
REPORT_MD="$2"
REPORT_HTML="$3"
TEST_EXIT="${4:-0}"

if [[ ! -d "$XCRESULT" ]]; then
  echo "找不到 xcresult: $XCRESULT" >&2
  exit 1
fi

# 优先使用 Xcode 16 的新命令，回退到旧格式；把 JSON 交给 python 解析。
SUMMARY_JSON="$(xcrun xcresulttool get test-results summary --path "$XCRESULT" --format json 2>/dev/null || true)"
TESTS_JSON="$(xcrun xcresulttool get test-results tests --path "$XCRESULT" --format json 2>/dev/null || true)"

export SUMMARY_JSON TESTS_JSON TEST_EXIT XCRESULT REPORT_MD REPORT_HTML

python3 "$(dirname "$0")/report.py"
