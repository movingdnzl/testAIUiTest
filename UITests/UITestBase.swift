import XCTest

/// UI 测试基类：统一启动 App、提供 Tab 切换与截图辅助。
///
/// - 支持通过环境变量 UITEST_SLOWMO 放慢每步节奏（秒），便于肉眼观看，例如 UITEST_SLOWMO=0.6
/// - 每个用例结束自动截图并附到 xcresult，失败时也会带最终界面
class UITestBase: XCTestCase {
    var app: XCUIApplication!

    /// 每步暂停秒数，读自环境变量 UITEST_SLOWMO（默认 0=不暂停）。
    private var slowmo: TimeInterval {
        TimeInterval(ProcessInfo.processInfo.environment["UITEST_SLOWMO"] ?? "0") ?? 0
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        // 用例结束截图，附进报告（含失败时的最终界面）
        snapshot("最终界面")
        app = nil
    }

    /// 通过底部 TabBar 切换页面。
    func openTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "找不到底部 Tab：\(label)")
        tab.tap()
        pause()
    }

    /// 放慢节奏：按 UITEST_SLOWMO 暂停，让操作肉眼可见。
    func pause() {
        if slowmo > 0 { Thread.sleep(forTimeInterval: slowmo) }
    }

    /// 截图并附到测试结果，命名后可在 xcresult / 报告里查看。
    func snapshot(_ name: String) {
        guard let app else { return }
        let shot = app.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
