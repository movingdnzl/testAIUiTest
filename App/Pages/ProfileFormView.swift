import SwiftUI

/// 页面 4：表单
/// 功能：姓名/邮箱输入、年龄滑块、通知开关、保存后展示确认信息。
struct ProfileFormView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var age = 18.0
    @State private var notificationsOn = true
    @State private var savedSummary = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("form_name_field")
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("form_email_field")
                }

                Section("Age: \(Int(age))") {
                    Slider(value: $age, in: 18...80, step: 1)
                        .accessibilityIdentifier("form_age_slider")
                }

                Section {
                    Toggle("Enable notifications", isOn: $notificationsOn)
                        .accessibilityIdentifier("form_notifications_toggle")
                }

                Section {
                    Button("Save", action: save)
                        .accessibilityIdentifier("form_save_button")
                }

                if !savedSummary.isEmpty {
                    Section("Saved") {
                        Text(savedSummary)
                            .accessibilityIdentifier("form_summary_label")
                    }
                }
            }
            .navigationTitle("Form")
        }
    }

    private func save() {
        let notif = notificationsOn ? "on" : "off"
        savedSummary = "\(name.isEmpty ? "N/A" : name) | \(email.isEmpty ? "N/A" : email) | age \(Int(age)) | notif \(notif)"
    }
}

#Preview {
    ProfileFormView()
}
