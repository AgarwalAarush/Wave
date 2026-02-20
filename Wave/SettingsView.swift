import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case model = "Model"
    case context = "Context"
    case shortcuts = "Shortcuts"

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .model: return "cpu.fill"
        case .context: return "eye.fill"
        case .shortcuts: return "keyboard.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "API keys and account"
        case .model: return "Choose your AI model"
        case .context: return "Screen capture behavior"
        case .shortcuts: return "Keyboard shortcuts"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $selectedTab)
            DetailView(selectedTab: selectedTab)
        }
        .frame(minWidth: 620, minHeight: 460)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.waveSettingsBackground)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: SettingsTab

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 7) {
                Image(systemName: "wave.3.right")
                    .font(.waveSystem(size: 12, weight: .bold))
                    .foregroundStyle(Color.waveAccent)
                Text("Wave")
                    .font(.waveSystem(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.waveTextPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 52)
            .padding(.bottom, 12)

            ForEach(SettingsTab.allCases, id: \.self) { tab in
                SidebarRow(tab: tab, isSelected: selectedTab == tab)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(width: 170)
        .background(Color.waveSettingsSidebar)
    }
}

struct SidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: tab.icon)
                .font(.waveSystem(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? Color.waveAccent : Color.waveTextSecondary)
                .frame(width: 20)

            Text(tab.rawValue)
                .font(.waveSystem(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.waveTextPrimary : Color.waveTextSecondary)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected
                      ? Color.waveAccent.opacity(0.12)
                      : isHovered ? Color.waveSettingsRowHover.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Detail View

struct DetailView: View {
    let selectedTab: SettingsTab

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedTab.rawValue)
                        .font(.waveSystem(size: 18, weight: .semibold))
                        .foregroundStyle(Color.waveTextPrimary)

                    Text(selectedTab.subtitle)
                        .font(.waveSystem(size: 12))
                        .foregroundStyle(Color.waveTextSecondary)
                }
                .padding(.bottom, 20)

                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .model:
                    ModelSettingsView()
                case .context:
                    ContextSettingsView()
                case .shortcuts:
                    ShortcutsSettingsView()
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.waveSettingsBackground)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @State private var apiKey: String = ""
    @State private var hasStoredKey: Bool = false
    @State private var isEditingKey: Bool = false
    @State private var keySaved: Bool = false

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.waveSystem(size: 16, weight: .medium))
                        .foregroundStyle(Color.waveAccent)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.waveAccent.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenAI API Key")
                            .font(.waveSystem(size: 14, weight: .semibold))
                            .foregroundStyle(Color.waveTextPrimary)
                        Text("Required to connect to OpenAI")
                            .font(.waveSystem(size: 11))
                            .foregroundStyle(Color.waveTextSecondary)
                    }
                }

                Color.waveDivider.frame(height: 1)

                if hasStoredKey && !isEditingKey {
                    // Key is stored - show masked version with replace button
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.waveSystem(size: 12))
                                .foregroundStyle(Color.waveAccent)

                            Text("API key configured")
                                .font(.waveSystem(size: 13))
                                .foregroundStyle(Color.waveTextSecondary)
                        }

                        Spacer()

                        Button(action: {
                            isEditingKey = true
                            apiKey = ""
                        }) {
                            Text("Replace Key")
                                .font(.waveSystem(size: 12, weight: .medium))
                                .foregroundStyle(Color.waveAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.waveAccent, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.waveAccent.opacity(0.1))
                    )
                } else {
                    // No key or editing - show input field
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.plain)
                                .font(.waveSystem(size: 13, design: .monospaced))
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.waveSettingsBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.waveBorder, lineWidth: 1)
                                        )
                                )
                                .onSubmit { saveAPIKey() }
                        }

                        HStack(spacing: 12) {
                            Button(action: saveAPIKey) {
                                HStack(spacing: 6) {
                                    if keySaved {
                                        Image(systemName: "checkmark")
                                            .font(.waveSystem(size: 11, weight: .bold))
                                    }
                                    Text(keySaved ? "Saved" : "Save Key")
                                        .font(.waveSystem(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(keySaved ? Color.green : Color.waveAccent)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(apiKey.isEmpty)
                            .opacity(apiKey.isEmpty ? 0.5 : 1)

                            if isEditingKey {
                                Button(action: {
                                    isEditingKey = false
                                    apiKey = ""
                                }) {
                                    Text("Cancel")
                                        .font(.waveSystem(size: 12, weight: .medium))
                                        .foregroundStyle(Color.waveTextSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.waveBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                        .padding(.top, 1)
                    Text("Your API key is stored securely in the system keychain and never leaves your device.")
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .onAppear { loadAPIKeyStatus() }
    }

    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        KeychainHelper.save(key: "openai_api_key", value: apiKey)
        withAnimation(.easeInOut(duration: 0.2)) {
            keySaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                keySaved = false
                hasStoredKey = true
                isEditingKey = false
                apiKey = ""
            }
        }
    }

    private func loadAPIKeyStatus() {
        let storedKey = KeychainHelper.read(key: "openai_api_key") ?? ""
        hasStoredKey = !storedKey.isEmpty
    }
}

// MARK: - Model Settings

struct ModelSettingsView: View {
    @State private var selectedModel: GPTModel = .default

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "cpu.fill")
                        .font(.waveSystem(size: 16, weight: .medium))
                        .foregroundStyle(Color.waveAccent)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.waveAccent.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("GPT Model")
                            .font(.waveSystem(size: 14, weight: .semibold))
                            .foregroundStyle(Color.waveTextPrimary)
                        Text("Pick the model that fits your workflow")
                            .font(.waveSystem(size: 11))
                            .foregroundStyle(Color.waveTextSecondary)
                    }
                }

                Color.waveDivider.frame(height: 1)

                VStack(spacing: 8) {
                    ForEach(GPTModel.allModels) { model in
                        ModelRow(
                            model: model,
                            isSelected: selectedModel == model,
                            onSelect: {
                                selectedModel = model
                                UserDefaults.standard.set(model.rawValue, forKey: "gpt_model")
                            }
                        )
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                        .padding(.top, 1)
                    Text("More capable models produce better results but may respond slower and cost more per query.")
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .onAppear {
            selectedModel = GPTModel.from(rawValue: UserDefaults.standard.string(forKey: "gpt_model"))
        }
    }
}

struct ModelRow: View {
    let model: GPTModel
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: model.icon)
                    .font(.waveSystem(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Color.waveAccent : Color.waveTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? Color.waveAccent.opacity(0.12) : Color.waveSettingsBackground)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.waveSystem(size: 13, weight: .medium))
                        .foregroundStyle(Color.waveTextPrimary)
                    Text(model.subtitle)
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.waveSystem(size: 16))
                        .foregroundStyle(Color.waveAccent)
                } else {
                    Circle()
                        .stroke(Color.waveBorder, lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected
                          ? Color.waveAccent.opacity(0.08)
                          : isHovered ? Color.waveSettingsRowHover.opacity(0.4) : Color.waveSettingsBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.waveAccent.opacity(0.25) : Color.waveBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - Context Settings

struct ContextSettingsView: View {
    @State private var screenshotEnabled: Bool = true

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.waveSystem(size: 18, weight: .medium))
                        .foregroundStyle(Color.waveAccent)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.waveAccent.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Capture")
                            .font(.waveSystem(size: 14, weight: .semibold))
                            .foregroundStyle(Color.waveTextPrimary)
                        Text("Attach a screenshot with every prompt")
                            .font(.waveSystem(size: 11))
                            .foregroundStyle(Color.waveTextSecondary)
                    }
                }

                Color.waveDivider.frame(height: 1)

                SettingsToggleRow(
                    title: "Capture screenshot automatically",
                    isOn: $screenshotEnabled,
                    onChange: { value in
                        UserDefaults.standard.set(value, forKey: "screenshot_enabled")
                    }
                )

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                        .padding(.top, 1)
                    Text("When enabled, Wave captures your screen before each query to give the model visual context. The screenshot is sent alongside your prompt and is never stored.")
                        .font(.waveSystem(size: 11))
                        .foregroundStyle(Color.waveTextSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .onAppear {
            screenshotEnabled = UserDefaults.standard.object(forKey: "screenshot_enabled") as? Bool ?? true
        }
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        SettingsCard {
            VStack(spacing: 0) {
                ShortcutRow(icon: "rectangle.on.rectangle.angled", action: "Toggle Wave", keys: ["⇧", "⌫"], isLast: false)
                ShortcutRow(icon: "plus.message", action: "New Chat", keys: ["⌘", "N"], isLast: false)
                ShortcutRow(icon: "cpu", action: "Model Selector", keys: ["⌘", "⇧", "M"], isLast: false)
                ShortcutRow(icon: "xmark.circle", action: "Hide", keys: ["esc"], isLast: true)
            }
        }
    }
}

struct ShortcutRow: View {
    let icon: String
    let action: String
    let keys: [String]
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.waveSystem(size: 12, weight: .medium))
                    .foregroundStyle(Color.waveTextSecondary)
                    .frame(width: 20)

                Text(action)
                    .font(.waveSystem(size: 13))
                    .foregroundStyle(Color.waveTextPrimary)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(keys, id: \.self) { key in
                        Text(key)
                            .font(.waveSystem(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.waveTextSecondary)
                            .frame(minWidth: 22, minHeight: 22)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.waveSettingsBackground)
                                    .shadow(color: Color.black.opacity(0.06), radius: 0, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.waveBorder, lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)

            if !isLast {
                Color.waveDivider.frame(height: 1)
                    .padding(.leading, 28)
            }
        }
    }
}

// MARK: - Reusable Components

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.waveSettingsCard)
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.waveBorder, lineWidth: 0.5)
            )
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.waveSystem(size: 13))
                .foregroundStyle(Color.waveTextPrimary)
        }
        .toggleStyle(AccentToggleStyle())
        .onChange(of: isOn) { _, value in
            onChange(value)
        }
    }
}

struct AccentToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.waveAccent : Color.waveTextSecondary.opacity(0.3))
                    .frame(width: 44, height: 26)

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 9 : -9)
            }
            .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}
