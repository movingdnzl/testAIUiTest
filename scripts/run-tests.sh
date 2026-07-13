#!/usr/bin/env bash
#
# 一键：生成工程 -> 启动模拟器 -> 逐个页面(Tab)分别录屏并跑对应 UI 用例 -> 输出测试报告 + 每页操作视频
#
# 与旧版区别：不再录一整段 demo.mp4，而是「按 Tab 分别录屏」：
#   每个页面单独启一段录屏，只跑该页面的用例，产出 build/videos/<页面>.mp4，
#   看某个功能怎么被自动操作时，直接点对应页面的视频即可。
#
# 依赖：
#   - 完整版 Xcode（含 iOS 模拟器、xcodebuild、xcresulttool、simctl）
#   - XcodeGen        (brew install xcodegen)
#   - 可选 xcbeautify (brew install xcbeautify) 让日志更好看
#
# 环境变量：
#   SIMULATOR   指定模拟器机型名，默认自动选一个可用 iPhone
#   RECORD=0    关闭录屏（默认开启，产出 build/videos/*.mp4）
#   UITEST_SLOWMO=0.6  每步暂停秒数，肉眼更好看清操作
#
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

SCHEME="UITestDemo"
TEST_TARGET="UITestDemoUITests"
RECORD="${RECORD:-1}"
RESULT_DIR="$ROOT/build"
XCRESULT="$RESULT_DIR/TestResults.xcresult"     # 合并后的总结果（供报告使用）
REPORT_MD="$RESULT_DIR/report.md"
REPORT_HTML="$RESULT_DIR/report.html"
VIDEO_DIR="$RESULT_DIR/videos"                   # 每个页面一段视频
PARTS_DIR="$RESULT_DIR/parts"                    # 每个页面一个 xcresult（后续合并）

# 页面(Tab) -> 测试类 映射；顺序即录屏与报告顺序。
# 每行 "序号|页面名|测试类名"
PLAN=(
  "1|Login|LoginUITests"
  "2|Counter|CounterUITests"
  "3|Todo|TodoUITests"
  "4|Form|ProfileFormUITests"
  "5|Settings|SettingsUITests"
)

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
rm -rf "$XCRESULT" "$VIDEO_DIR" "$PARTS_DIR"
mkdir -p "$RESULT_DIR" "$VIDEO_DIR" "$PARTS_DIR"

# 拿到模拟器 UDID 并启动，方便按同一台设备分别录屏
UDID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -oE '[0-9A-F-]{36}' | head -1)"
if [[ -n "$UDID" ]]; then
  echo "==> 3. 启动模拟器 ($SIM_NAME / $UDID)"
  xcrun simctl boot "$UDID" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b 2>/dev/null || true
  DEST="platform=iOS Simulator,id=$UDID"
else
  DEST="platform=iOS Simulator,name=$SIM_NAME"
  echo "    ⚠️ 未取到 UDID，将不分页录屏（仅跑测试）。建议用 SIMULATOR 指定确切机型以启用录屏。"
fi

# 把 UITEST_SLOWMO 通过 simctl 转发给模拟器里的测试进程
if [[ -n "${UITEST_SLOWMO:-}" ]]; then
  export SIMCTL_CHILD_UITEST_SLOWMO="$UITEST_SLOWMO"
  echo "    放慢节奏: 每步暂停 ${UITEST_SLOWMO}s"
fi

REC_PID=""
start_recording() {   # $1=视频文件路径
  REC_PID=""
  if [[ "$RECORD" == "1" && -n "$UDID" ]]; then
    xcrun simctl io "$UDID" recordVideo --codec=h264 -f "$1" >/dev/null 2>&1 &
    REC_PID=$!
    sleep 1
  fi
}
stop_recording() {
  if [[ -n "$REC_PID" ]]; then
    kill -INT "$REC_PID" 2>/dev/null || true
    wait "$REC_PID" 2>/dev/null || true
    REC_PID=""
  fi
}
trap stop_recording EXIT

echo "==> 4. 按页面(Tab)分别录屏并运行对应 UI 用例"
OVERALL_EXIT=0
PART_RESULTS=()
for row in "${PLAN[@]}"; do
  IFS='|' read -r idx page cls <<< "$row"
  video="$VIDEO_DIR/${idx}-${page}.mp4"
  part="$PARTS_DIR/${page}.xcresult"
  rm -rf "$part"

  echo ""
  echo "----> 页面 ${idx}/${#PLAN[@]}: ${page}  (类 ${cls})"
  [[ "$RECORD" == "1" && -n "$UDID" ]] && echo "      录屏 -> $video"

  start_recording "$video"

  set +e
  if command -v xcbeautify >/dev/null; then
    xcodebuild test \
      -project UITestDemo.xcodeproj \
      -scheme "$SCHEME" \
      -destination "$DEST" \
      -resultBundlePath "$part" \
      -only-testing:"${TEST_TARGET}/${cls}" \
      | xcbeautify
    rc=${PIPESTATUS[0]}
  else
    xcodebuild test \
      -project UITestDemo.xcodeproj \
      -scheme "$SCHEME" \
      -destination "$DEST" \
      -resultBundlePath "$part" \
      -only-testing:"${TEST_TARGET}/${cls}"
    rc=$?
  fi
  set -e

  stop_recording
  [[ "$rc" != "0" ]] && OVERALL_EXIT="$rc"
  [[ -d "$part" ]] && PART_RESULTS+=("$part")
done

trap - EXIT

echo ""
echo "==> 5. 合并各页面结果 -> 总 xcresult"
if [[ "${#PART_RESULTS[@]}" -gt 1 ]]; then
  xcrun xcresulttool merge "${PART_RESULTS[@]}" --output-path "$XCRESULT" 2>/dev/null \
    || cp -R "${PART_RESULTS[0]}" "$XCRESULT"
elif [[ "${#PART_RESULTS[@]}" -eq 1 ]]; then
  cp -R "${PART_RESULTS[0]}" "$XCRESULT"
fi

echo "==> 6. 生成测试报告"
"$ROOT/scripts/make-report.sh" "$XCRESULT" "$REPORT_MD" "$REPORT_HTML" "$OVERALL_EXIT"

echo ""
echo "============================================"
echo "  测试完成 (xcodebuild exit=$OVERALL_EXIT)"
echo "  每页视频 : $VIDEO_DIR/  （1-Login.mp4 / 2-Counter.mp4 ...）"
echo "  xcresult : $XCRESULT  （可用 Xcode 打开看逐步截图）"
echo "  HTML 报告: $REPORT_HTML"
echo "  Markdown : $REPORT_MD"
echo "============================================"

exit $OVERALL_EXIT
