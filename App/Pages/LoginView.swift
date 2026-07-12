import SwiftUI

/// 页面 1：登录
/// 功能：用户名/密码输入、空值校验、账号密码校验、登录成功状态。
/// 正确凭证：admin / 123456
struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoggedIn {
                    Text("Welcome, \(username)!")
                        .font(.title2)
                        .accessibilityIdentifier("login_welcome_label")

                    Button("Logout") {
                        isLoggedIn = false
                        username = ""
                        password = ""
                        message = ""
                    }
                    .accessibilityIdentifier("login_logout_button")
                } else {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("login_username_field")

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("login_password_field")

                    Button("Login", action: login)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("login_submit_button")

                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("login_error_label")
                    }
                }
            }
            .padding()
            .navigationTitle("Login")
        }
    }

    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            message = "Username and password required"
            return
        }
        if username == "admin" && password == "123456" {
            isLoggedIn = true
            message = ""
        } else {
            message = "Invalid credentials"
        }
    }
}

#Preview {
    LoginView()
}
