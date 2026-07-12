.PHONY: setup gen test report open clean

# 安装依赖（需先从 App Store 装好完整 Xcode）
setup:
	brew install xcodegen xcbeautify || true

# 仅生成 Xcode 工程
gen:
	xcodegen generate

# 一键：生成工程 + 跑 UI 测试 + 出报告
test:
	./scripts/run-tests.sh

# 在浏览器打开 HTML 报告
open:
	open build/report.html

# 用 Xcode 打开 xcresult 查看详细录屏/截图
result:
	open build/TestResults.xcresult

clean:
	rm -rf build UITestDemo.xcodeproj
