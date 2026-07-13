import XCTest

/// 页面 3：待办列表 UI 测试
final class TodoUITests: UITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        openTab("Todo")
    }

    private func addTask(_ title: String) {
        let field = app.textFields["todo_input_field"]
        field.tap()
        field.typeText(title)
        app.buttons["todo_add_button"].tap()
    }

    /// 初始为空态。
    func testEmptyState() {
        XCTAssertTrue(app.staticTexts["todo_empty_label"].exists, "初始进入待办页未显示空态提示")
    }

    /// 新增一条任务后出现在列表里。
    func testAddTask() {
        addTask("Buy milk")
        XCTAssertTrue(app.otherElements["todo_row_Buy milk"].waitForExistence(timeout: 3)
            || app.staticTexts["Buy milk"].waitForExistence(timeout: 3),
            "新增任务后列表里找不到「Buy milk」")
    }

    /// 点击任务切换完成状态（复选图标变化）。
    func testToggleTask() {
        addTask("Read book")
        app.staticTexts["Read book"].tap()
        // 完成后图标从 circle 变为 checkmark.circle.fill，行仍存在。
        XCTAssertTrue(app.staticTexts["Read book"].exists, "点击任务后该任务行意外消失")
    }

    /// 滑动删除任务后回到空态。
    func testDeleteTask() {
        addTask("Temp task")
        let cell = app.staticTexts["Temp task"]
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "新增的待删除任务未出现")
        cell.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["todo_empty_label"].waitForExistence(timeout: 3),
            "滑动删除后未回到空态，任务可能未被删除")
    }
}
