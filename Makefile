.PHONY: setup gen test demo open video result clean

# 安装依赖（需先从 App Store 装好完整 Xcode）
setup:
	brew install xcodegen xcbeautify || true

# 仅生成 Xcode 工程
gen:
	xcodegen generate

# 一键：生成工程 + 启动模拟器录屏 + 跑 UI 测试 + 出报告
test:
	./scripts/run-tests.sh

# 放慢节奏跑，肉眼更好看清每步操作（每步暂停 0.6s）
demo:
	UITEST_SLOWMO=0.6 ./scripts/run-tests.sh

# 在浏览器打开 HTML 报告
open:
	open build/report.html

# 打开自动操作录屏视频
video:
	open build/demo.mp4

# 用 Xcode 打开 xcresult 查看每步截图
result:
	open build/TestResults.xcresult

clean:
	rm -rf build UITestDemo.xcodeproj
