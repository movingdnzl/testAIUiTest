#!/usr/bin/env bash
#
# 一键：生成工程 -> 启动模拟器并录屏 -> 跑 UI 自动化测试 -> 输出测试报告 + 操作视频
#
# 依赖：
#   - 完整版 Xcode（含 iOS 模拟器、xcodebuild、xcresulttool、simctl）
#   - XcodeGen        (brew install xcodegen)
#   - 可选 xcbeautify (brew install xcbeautify) 让日志更好看
#
# 环境变量：
#   SIMULATOR   指定模拟器机型名，默认自动选一个可用 iPhone
#   RECORD=0    关闭录屏（默认开启，产出 build/demo.mp4）
#
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SCHEME="UITestDemo"
RECORD="${RECORD:-1}"
RESULT_DIR="$ROOT/build"
XCRESULT="$RESULT_DIR/TestResults.xcresult"
REPORT_MD="$RESULT_DIR/report.md"
REPORT_HTML="$RESULT_DIR/report.html"
VIDEO="$RESULT_DIR/demo.mp4"

echo "==> 0. 环境检查"
command -v xcodebuild >/dev/null || { echo "缺少 xcodebuild：请安装完整版 Xcode 并执行 sudo xcode-select -s /Applications/Xcode.app"; exit 1; }
command -v xcodegen  >/dev/null || { echo "缺少 xcodegen：brew install xcodegen"; exit 1; }

# 选模拟器：优先用 $SIMULATOR，否则自动挑第一个可用 iPhone
if [[ -n "${SIMULATOR:-}" ]]; then
  SIM_NAME="$SIMULATOR"
else
  SIM_NAME="$(xcrun simctl list devices available | grep -oE 'iPhone [0-9]+[^(]*' | head -1 | xargs)"
fi
[[ -n "$SIM_NAME" ]] || { echo "找不到可用 iPhone 模拟器，请用 SIMULATOR=\"iPhone 15\" 指定"; exit 1; }
echo "    使用模拟器: $SIM_NAME"

echo "==> 1. 生成 Xcode 工程 (XcodeGen)"
xcodegen generate

echo "==> 2. 清理旧结果"
rm -rf "$XCRESULT" "$VIDEO"
mkdir -p "$RESULT_DIR"

# 拿到模拟器 UDID 并启动，方便录屏对准同一台设备
UDID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -oE '[0-9A-F-]{36}' | head -1)"
if [[ -n "$UDID" ]]; then
  echo "==> 3. 启动模拟器 ($SIM_NAME / $UDID)"
  xcrun simctl boot "$UDID" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b 2>/dev/null || true
  DEST="platform=iOS Simulator,id=$UDID"
else
  DEST="platform=iOS Simulator,name=$SIM_NAME"
fi

# 开始录屏（后台），把整个自动操作过程录成 MP4
REC_PID=""
if [[ "$RECORD" == "1" && -n "$UDID" ]]; then
  echo "==> 3.1 开始录屏 -> $VIDEO"
  xcrun simctl io "$UDID" recordVideo --codec=h264 -f "$VIDEO" &
  REC_PID=$!
  sleep 1
fi

stop_recording() {
  if [[ -n "$REC_PID" ]]; then
    echo "==> 停止录屏"
    kill -INT "$REC_PID" 2>/dev/null || true
    wait "$REC_PID" 2>/dev/null || true
  fi
}
trap stop_recording EXIT

# 把 UITEST_SLOWMO 通过 simctl 转发给模拟器里的测试进程
# （SIMCTL_CHILD_* 前缀会被 simctl 注入到被测/测试进程环境）
if [[ -n "${UITEST_SLOWMO:-}" ]]; then
  export SIMCTL_CHILD_UITEST_SLOWMO="$UITEST_SLOWMO"
  echo "    放慢节奏: 每步暂停 ${UITEST_SLOWMO}s"
fi

echo "==> 4. 运行 UI 自动化测试（模拟器会真实执行点击/输入/滑动）"
set +e
if command -v xcbeautify >/dev/null; then
  xcodebuild test \
    -project UITestDemo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DEST" \
    -resultBundlePath "$XCRESULT" \
    -only-testing:UITestDemoUITests \
    | xcbeautify
  TEST_EXIT=${PIPESTATUS[0]}
else
  xcodebuild test \
    -project UITestDemo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DEST" \
    -resultBundlePath "$XCRESULT" \
    -only-testing:UITestDemoUITests
  TEST_EXIT=$?
fi
set -e

stop_recording
trap - EXIT

echo "==> 5. 生成测试报告"
"$ROOT/scripts/make-report.sh" "$XCRESULT" "$REPORT_MD" "$REPORT_HTML" "$TEST_EXIT"

echo ""
echo "============================================"
echo "  测试完成 (xcodebuild exit=$TEST_EXIT)"
echo "  操作视频 : $VIDEO"
echo "  xcresult : $XCRESULT  （可用 Xcode 打开看逐步截图）"
echo "  HTML 报告: $REPORT_HTML"
echo "  Markdown : $REPORT_MD"
echo "============================================"

exit $TEST_EXIT
