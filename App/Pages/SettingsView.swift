import SwiftUI

/// 页面 5：设置
/// 功能：深色模式开关、主题分段控件、带二次确认弹窗的重置按钮。
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var accent = 0
    @State private var showResetAlert = false
    @State private var statusText = "Ready"

    private let accents = ["Blue", "Green", "Orange"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .accessibilityIdentifier("settings_dark_toggle")

                    Picker("Accent", selection: $accent) {
                        ForEach(0..<accents.count, id: \.self) { i in
                            Text(accents[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings_accent_picker")
                }

                Section("Status") {
                    Text(statusText)
                        .accessibilityIdentifier("settings_status_label")
                }

                Section {
                    Button("Reset", role: .destructive) {
                        showResetAlert = true
                    }
                    .accessibilityIdentifier("settings_reset_button")
                }
            }
            .navigationTitle("Settings")
            .alert("Reset all settings?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                    .accessibilityIdentifier("settings_alert_cancel")
                Button("Confirm", role: .destructive) {
                    isDarkMode = false
                    accent = 0
                    statusText = "Reset done"
                }
                .accessibilityIdentifier("settings_alert_confirm")
            }
        }
    }
}

#Preview {
    SettingsView()
}
