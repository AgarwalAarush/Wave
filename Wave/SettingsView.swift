import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var selectedModel: GPTModel = .default
    @State private var screenshotEnabled: Bool = true
    @State private var keySaved: Bool = false

    var body: some View {
        Form {
            Section("OpenAI API Key") {
                SecureField("sk-...", text: $apiKey)
                    .onSubmit { saveAPIKey() }

                HStack {
                    Button("Save Key") { saveAPIKey() }
                    if keySaved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .transition(.opacity)
                    }
                }
            }

            Section("Model") {
                Picker("GPT Model", selection: $selectedModel) {
                    ForEach(GPTModel.allModels) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .onChange(of: selectedModel) { _, value in
                    UserDefaults.standard.set(value.rawValue, forKey: "gpt_model")
                }
            }

            Section("Context") {
                Toggle("Capture screenshot automatically", isOn: $screenshotEnabled)
                    .onChange(of: screenshotEnabled) { _, value in
                        UserDefaults.standard.set(value, forKey: "screenshot_enabled")
                    }
                Text("When enabled, Wave captures your screen before each query to give the model visual context.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Keyboard Shortcuts") {
                LabeledContent("Toggle Wave") { Text("**\u{2318}`**").foregroundStyle(.secondary) }
                LabeledContent("New Chat") { Text("**\u{2318}N**").foregroundStyle(.secondary) }
                LabeledContent("Model Selector") { Text("**\u{2318}\u{21E7}M**").foregroundStyle(.secondary) }
                LabeledContent("Hide") { Text("**Esc**").foregroundStyle(.secondary) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 400)
        .onAppear(perform: loadSettings)
    }

    private func saveAPIKey() {
        KeychainHelper.save(key: "openai_api_key", value: apiKey)
        withAnimation { keySaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { keySaved = false }
        }
    }

    private func loadSettings() {
        apiKey = KeychainHelper.read(key: "openai_api_key") ?? ""
        selectedModel = GPTModel.from(rawValue: UserDefaults.standard.string(forKey: "gpt_model"))
        screenshotEnabled = UserDefaults.standard.object(forKey: "screenshot_enabled") as? Bool ?? true
    }
}
