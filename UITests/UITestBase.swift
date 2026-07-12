import XCTest

/// UI 测试基类：统一启动 App、提供 Tab 切换辅助方法。
class UITestBase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// 通过底部 TabBar 切换页面。
    func openTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(label) not found")
        tab.tap()
    }
}
