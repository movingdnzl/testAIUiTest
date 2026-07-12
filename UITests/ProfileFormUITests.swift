import XCTest

/// 页面 4：表单 UI 测试
final class ProfileFormUITests: UITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        openTab("Form")
    }

    /// 填写姓名邮箱并保存，摘要展示输入内容。
    func testFillAndSave() {
        let name = app.textFields["form_name_field"]
        name.tap()
        name.typeText("Alice")

        let email = app.textFields["form_email_field"]
        email.tap()
        email.typeText("alice@example.com")

        app.buttons["form_save_button"].tap()

        let summary = app.staticTexts["form_summary_label"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.label.contains("Alice"))
        XCTAssertTrue(summary.label.contains("alice@example.com"))
    }

    /// 关闭通知开关并保存，摘要显示 notif off。
    func testToggleNotifications() {
        app.switches["form_notifications_toggle"].tap()
        app.buttons["form_save_button"].tap()

        let summary = app.staticTexts["form_summary_label"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.label.contains("notif off"))
    }

    /// 拖动年龄滑块后保存，摘要包含年龄字段。
    func testAdjustAgeSlider() {
        app.sliders["form_age_slider"].adjust(toNormalizedSliderPosition: 0.5)
        app.buttons["form_save_button"].tap()

        let summary = app.staticTexts["form_summary_label"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.label.contains("age"))
    }
}
