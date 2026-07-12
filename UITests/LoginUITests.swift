import XCTest

/// 页面 1：登录 UI 测试
final class LoginUITests: UITestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        openTab("Login")
    }

    /// 空值校验：直接点登录应提示必填。
    func testEmptyValidation() {
        app.buttons["login_submit_button"].tap()
        let error = app.staticTexts["login_error_label"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "Username and password required")
    }

    /// 错误凭证：应提示 Invalid credentials。
    func testInvalidCredentials() {
        app.textFields["login_username_field"].tap()
        app.textFields["login_username_field"].typeText("admin")
        app.secureTextFields["login_password_field"].tap()
        app.secureTextFields["login_password_field"].typeText("wrong")
        app.buttons["login_submit_button"].tap()

        let error = app.staticTexts["login_error_label"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "Invalid credentials")
    }

    /// 正确凭证：登录成功后展示欢迎语。
    func testSuccessfulLogin() {
        app.textFields["login_username_field"].tap()
        app.textFields["login_username_field"].typeText("admin")
        app.secureTextFields["login_password_field"].tap()
        app.secureTextFields["login_password_field"].typeText("123456")
        app.buttons["login_submit_button"].tap()

        let welcome = app.staticTexts["login_welcome_label"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 3))
        XCTAssertEqual(welcome.label, "Welcome, admin!")
    }
}
