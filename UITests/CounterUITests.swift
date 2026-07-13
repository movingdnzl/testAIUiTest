import XCTest

/// 页面 2：计数器 UI 测试
final class CounterUITests: UITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        openTab("Counter")
    }

    private var value: String {
        app.staticTexts["counter_value_label"].label
    }

    /// 连续加 3 次，值为 3。
    func testIncrement() {
        let inc = app.buttons["counter_increment_button"]
        inc.tap(); inc.tap(); inc.tap()
        XCTAssertEqual(value, "3", "点「+」3 次后计数应为 3，实际为 \(value)")
    }

    /// 加 2 再减 1，值为 1。
    func testDecrement() {
        app.buttons["counter_increment_button"].tap()
        app.buttons["counter_increment_button"].tap()
        app.buttons["counter_decrement_button"].tap()
        XCTAssertEqual(value, "1", "加 2 减 1 后计数应为 1，实际为 \(value)")
    }

    /// 减到 0 后不能为负。
    func testNoNegative() {
        app.buttons["counter_decrement_button"].tap()
        XCTAssertEqual(value, "0", "计数为 0 时再减不应变负，实际为 \(value)")
    }

    /// 重置归零。
    func testReset() {
        app.buttons["counter_increment_button"].tap()
        app.buttons["counter_increment_button"].tap()
        app.buttons["counter_reset_button"].tap()
        XCTAssertEqual(value, "0", "点重置后计数应归零，实际为 \(value)")
    }
}
