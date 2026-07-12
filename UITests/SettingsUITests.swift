import XCTest

/// 页面 5：设置 UI 测试
final class SettingsUITests: UITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        openTab("Settings")
    }

    /// 切换深色模式开关，状态变化。
    func testToggleDarkMode() {
        let toggle = app.switches["settings_dark_toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        let before = toggle.value as? String
        toggle.tap()
        let after = toggle.value as? String
        XCTAssertNotEqual(before, after)
    }

    /// 切换主题分段控件。
    func testChangeAccent() {
        let picker = app.segmentedControls["settings_accent_picker"]
        XCTAssertTrue(picker.buttons["Green"].waitForExistence(timeout: 3))
        picker.buttons["Green"].tap()
        XCTAssertTrue(picker.buttons["Green"].isSelected)
    }

    /// 重置弹窗：取消不改变状态。
    func testResetCancel() {
        app.buttons["settings_reset_button"].tap()
        let cancel = app.alerts.buttons["settings_alert_cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 3))
        cancel.tap()
        XCTAssertEqual(app.staticTexts["settings_status_label"].label, "Ready")
    }

    /// 重置弹窗：确认后状态变为 Reset done。
    func testResetConfirm() {
        app.buttons["settings_reset_button"].tap()
        let confirm = app.alerts.buttons["settings_alert_confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
        XCTAssertEqual(app.staticTexts["settings_status_label"].label, "Reset done")
    }
}
