#!/usr/bin/env bash
#
# 一键：生成工程 -> 跑 UI 自动化测试 -> 输出测试报告
#
# 依赖：
#   - 完整版 Xcode（含 iOS 模拟器、xcodebuild、xcresulttool）
#   - XcodeGen        (brew install xcodegen)
#   - 可选 xcbeautify (brew install xcbeautify) 让日志更好看
#
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SCHEME="UITestDemo"
# 模拟器：可用环境变量覆盖，例如 SIMULATOR="iPhone 15"
SIMULATOR="${SIMULATOR:-iPhone 16}"
RESULT_DIR="$ROOT/build"
XCRESULT="$RESULT_DIR/TestResults.xcresult"
REPORT_MD="$RESULT_DIR/report.md"
REPORT_HTML="$RESULT_DIR/report.html"

echo "==> 0. 环境检查"
command -v xcodebuild >/dev/null || { echo "缺少 xcodebuild：请安装完整版 Xcode 并执行 sudo xcode-select -s /Applications/Xcode.app"; exit 1; }
command -v xcodegen  >/dev/null || { echo "缺少 xcodegen：brew install xcodegen"; exit 1; }

echo "==> 1. 生成 Xcode 工程 (XcodeGen)"
xcodegen generate

echo "==> 2. 清理旧结果"
rm -rf "$XCRESULT"
mkdir -p "$RESULT_DIR"

echo "==> 3. 运行 UI 自动化测试 (模拟器: $SIMULATOR)"
set +e
if command -v xcbeautify >/dev/null; then
  xcodebuild test \
    -project UITestDemo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -resultBundlePath "$XCRESULT" \
    -only-testing:UITestDemoUITests \
    | xcbeautify
  TEST_EXIT=${PIPESTATUS[0]}
else
  xcodebuild test \
    -project UITestDemo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -resultBundlePath "$XCRESULT" \
    -only-testing:UITestDemoUITests
  TEST_EXIT=$?
fi
set -e

echo "==> 4. 生成测试报告"
"$ROOT/scripts/make-report.sh" "$XCRESULT" "$REPORT_MD" "$REPORT_HTML" "$TEST_EXIT"

echo ""
echo "============================================"
echo "  测试完成 (xcodebuild exit=$TEST_EXIT)"
echo "  xcresult : $XCRESULT"
echo "  Markdown : $REPORT_MD"
echo "  HTML     : $REPORT_HTML"
echo "============================================"

exit $TEST_EXIT
