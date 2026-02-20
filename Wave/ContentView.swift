import SwiftUI
import AppKit

// MARK: - Notification Names

extension Notification.Name {
    static let appearanceChanged = Notification.Name("appearanceChanged")
}

// MARK: - Settings Palette Types

enum SettingsPaletteLevel: Equatable {
    case settingsList
    case settingOptions(SettingItem)
}

enum SettingItem: CaseIterable, Equatable {
    case appearance
    case screenshot

    var displayName: String {
        switch self {
        case .appearance: "Appearance"
        case .screenshot: "Screenshot"
        }
    }

    var options: [SettingOption] {
        switch self {
        case .appearance:
            let current = UserDefaults.standard.string(forKey: "appearance") ?? "system"
            return [
                SettingOption(label: "Light", value: "light", isSelected: current == "light"),
                SettingOption(label: "Dark", value: "dark", isSelected: current == "dark"),
                SettingOption(label: "System", value: "system", isSelected: current == "system")
            ]
        case .screenshot:
            let current = UserDefaults.standard.object(forKey: "screenshot_enabled") as? Bool ?? true
            return [
                SettingOption(label: "On", value: true, isSelected: current),
                SettingOption(label: "Off", value: false, isSelected: !current)
            ]
        }
    }

    var currentValueLabel: String {
        options.first { $0.isSelected }?.label ?? ""
    }

    func matches(filter: String) -> Bool {
        filter.isEmpty || displayName.localizedCaseInsensitiveContains(filter)
    }
}

struct SettingOption {
    let label: String
    let value: Any
    let isSelected: Bool
}

struct DismissPanelKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissPanel: () -> Void {
        get { self[DismissPanelKey.self] }
        set { self[DismissPanelKey.self] = newValue }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismissPanel) private var dismissPanel
    @FocusState private var inputFocused: Bool
    @State private var showModelPicker = false
    @State private var highlightedModelIndex: Int = 0

    // Settings palette state
    @State private var showSettingsPalette = false
    @State private var settingsPaletteLevel: SettingsPaletteLevel = .settingsList
    @State private var settingsFilterText = ""
    @State private var highlightedSettingIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            queryBar
            if showModelPicker {
                modelDropdown
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if showSettingsPalette {
                settingsPaletteDropdown
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if viewModel.hasResponse || viewModel.errorMessage != nil {
                Color.waveDivider.frame(height: 1)
                responseArea
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 560)
        .fixedSize(horizontal: true, vertical: true)
        .background(Color.wavePanelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.waveBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.waveShadow, radius: 20, y: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.hasResponse)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.errorMessage != nil)
        .onAppear { inputFocused = true }
        .onKeyPress(.escape) {
            if showSettingsPalette {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    if case .settingOptions = settingsPaletteLevel {
                        settingsPaletteLevel = .settingsList
                        highlightedSettingIndex = 0
                    } else {
                        showSettingsPalette = false
                        settingsFilterText = ""
                    }
                }
                return .handled
            }
            if showModelPicker {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    showModelPicker = false
                }
                return .handled
            }
            dismissPanel()
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "n"), phases: .down) { press in
            guard press.modifiers.contains(.command), !showModelPicker else { return .ignored }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                viewModel.newChat()
            }
            inputFocused = true
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "mM"), phases: .down) { press in
            guard press.modifiers.contains(.command),
                  press.modifiers.contains(.shift) else { return .ignored }
            toggleModelPicker()
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "pP"), phases: .down) { press in
            guard press.modifiers.contains(.command),
                  press.modifiers.contains(.shift) else { return .ignored }
            toggleSettingsPalette()
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "aA"), phases: .down) { press in
            guard press.modifiers.contains(.command), inputFocused else { return .ignored }
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            return .handled
        }
        .onKeyPress(.upArrow) {
            if showSettingsPalette {
                highlightedSettingIndex = max(0, highlightedSettingIndex - 1)
                return .handled
            }
            guard showModelPicker else { return .ignored }
            highlightedModelIndex = max(0, highlightedModelIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            if showSettingsPalette {
                let maxIndex = currentSettingsItemCount - 1
                highlightedSettingIndex = min(max(0, maxIndex), highlightedSettingIndex + 1)
                return .handled
            }
            guard showModelPicker else { return .ignored }
            let models = dropdownModels
            guard !models.isEmpty else { return .handled }
            highlightedModelIndex = min(models.count - 1, highlightedModelIndex + 1)
            return .handled
        }
        .onKeyPress(.return) {
            if showSettingsPalette {
                selectHighlightedSetting()
                return .handled
            }
            guard showModelPicker else { return .ignored }
            selectHighlightedModel()
            return .handled
        }
    }

    // MARK: - Query Bar

    private var queryBar: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.waveSystem(size: 14, weight: .medium))
                .foregroundStyle(Color.waveIcon)

            TextField("Ask anything...", text: $viewModel.queryText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.waveSystem(size: 15))
                .foregroundStyle(Color.waveTextPrimary)
                .lineLimit(1...4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .focused($inputFocused)
                .onSubmit {
                    guard !showModelPicker else { return }
                    viewModel.submit()
                }

            modelPill

            if viewModel.isStreaming {
                Button { viewModel.stopStreaming() } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.waveSystem(size: 16))
                        .foregroundStyle(Color.waveIcon)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Model Pill

    private var modelPill: some View {
        Button { toggleModelPicker() } label: {
            Text(viewModel.selectedModel.displayName)
                .font(.waveSystem(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.waveTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.waveModelPill, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Model Dropdown

    private var dropdownProviders: [AIProvider] {
        [.openai, .anthropic]
    }

    private var dropdownModels: [AIModel] {
        dropdownProviders.flatMap { AIModel.models(for: $0) }
    }

    private var modelDropdown: some View {
        return VStack(spacing: 0) {
            Color.waveDivider.frame(height: 1)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(dropdownProviders) { provider in
                    HStack(spacing: 6) {
                        Image(provider.brandAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)

                        Text(provider.rawValue)
                            .font(.waveSystem(size: 11, weight: .semibold))
                            .foregroundStyle(Color.waveTextSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                    ForEach(AIModel.models(for: provider), id: \.id) { model in
                        let globalIndex = dropdownModels.firstIndex(of: model) ?? 0
                        Button {
                            viewModel.selectedModel = model
                            showModelPicker = false
                        } label: {
                            HStack {
                                Text(model.displayName)
                                    .font(.waveSystem(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.waveTextPrimary)
                                Spacer()
                                if model == viewModel.selectedModel {
                                    Image(systemName: "checkmark")
                                        .font(.waveSystem(size: 10, weight: .semibold))
                                        .foregroundStyle(Color.waveTextSecondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                globalIndex == highlightedModelIndex
                                    ? Color.waveModelHighlight
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Model Picker Logic

    private func toggleModelPicker() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            if showModelPicker {
                showModelPicker = false
            } else {
                let models = dropdownModels
                highlightedModelIndex = models.firstIndex(of: viewModel.selectedModel) ?? 0
                showModelPicker = true
            }
        }
    }

    private func selectHighlightedModel() {
        let models = dropdownModels
        guard highlightedModelIndex >= 0, highlightedModelIndex < models.count else { return }
        viewModel.selectedModel = models[highlightedModelIndex]
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showModelPicker = false
        }
    }

    // MARK: - Settings Palette

    private var filteredSettings: [SettingItem] {
        SettingItem.allCases.filter { $0.matches(filter: settingsFilterText) }
    }

    private var currentSettingsItemCount: Int {
        switch settingsPaletteLevel {
        case .settingsList:
            return filteredSettings.count
        case .settingOptions(let setting):
            return setting.options.count
        }
    }

    private var settingsPaletteDropdown: some View {
        VStack(spacing: 0) {
            Color.waveDivider.frame(height: 1)

            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.waveSystem(size: 12))
                    .foregroundStyle(Color.waveTextSecondary)
                TextField("Search settings...", text: $settingsFilterText)
                    .textFieldStyle(.plain)
                    .font(.waveSystem(size: 13))
                    .foregroundStyle(Color.waveTextPrimary)
                    .onChange(of: settingsFilterText) {
                        highlightedSettingIndex = 0
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Color.waveDivider.frame(height: 1)

            VStack(alignment: .leading, spacing: 2) {
                switch settingsPaletteLevel {
                case .settingsList:
                    ForEach(Array(filteredSettings.enumerated()), id: \.element) { index, setting in
                        settingRow(setting, highlighted: index == highlightedSettingIndex)
                    }
                case .settingOptions(let setting):
                    // Back button / header
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.waveSystem(size: 10, weight: .semibold))
                        Text(setting.displayName)
                            .font(.waveSystem(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.waveTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    ForEach(Array(setting.options.enumerated()), id: \.offset) { index, option in
                        optionRow(option, highlighted: index == highlightedSettingIndex)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func settingRow(_ setting: SettingItem, highlighted: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                settingsPaletteLevel = .settingOptions(setting)
                highlightedSettingIndex = 0
            }
        } label: {
            HStack {
                Text(setting.displayName)
                    .font(.waveSystem(size: 13, weight: .medium))
                    .foregroundStyle(Color.waveTextPrimary)
                Spacer()
                Text(setting.currentValueLabel)
                    .font(.waveSystem(size: 12))
                    .foregroundStyle(Color.waveTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.waveSystem(size: 10, weight: .semibold))
                    .foregroundStyle(Color.waveTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                highlighted ? Color.waveModelHighlight : Color.clear,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func optionRow(_ option: SettingOption, highlighted: Bool) -> some View {
        Button {
            if case .settingOptions(let setting) = settingsPaletteLevel {
                applySettingOption(setting, option)
            }
        } label: {
            HStack {
                Text(option.label)
                    .font(.waveSystem(size: 13, weight: .medium))
                    .foregroundStyle(Color.waveTextPrimary)
                Spacer()
                if option.isSelected {
                    Image(systemName: "checkmark")
                        .font(.waveSystem(size: 10, weight: .semibold))
                        .foregroundStyle(Color.waveAccent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                highlighted ? Color.waveModelHighlight : Color.clear,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleSettingsPalette() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            if showSettingsPalette {
                showSettingsPalette = false
                settingsFilterText = ""
                settingsPaletteLevel = .settingsList
            } else {
                // Close model picker if open
                showModelPicker = false
                showSettingsPalette = true
                settingsPaletteLevel = .settingsList
                highlightedSettingIndex = 0
            }
        }
    }

    private func selectHighlightedSetting() {
        switch settingsPaletteLevel {
        case .settingsList:
            let settings = filteredSettings
            guard highlightedSettingIndex >= 0, highlightedSettingIndex < settings.count else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                settingsPaletteLevel = .settingOptions(settings[highlightedSettingIndex])
                highlightedSettingIndex = 0
            }
        case .settingOptions(let setting):
            let options = setting.options
            guard highlightedSettingIndex >= 0, highlightedSettingIndex < options.count else { return }
            applySettingOption(setting, options[highlightedSettingIndex])
        }
    }

    private func applySettingOption(_ setting: SettingItem, _ option: SettingOption) {
        switch setting {
        case .appearance:
            if let value = option.value as? String {
                UserDefaults.standard.set(value, forKey: "appearance")
                NotificationCenter.default.post(name: .appearanceChanged, object: nil)
            }
        case .screenshot:
            if let value = option.value as? Bool {
                UserDefaults.standard.set(value, forKey: "screenshot_enabled")
            }
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showSettingsPalette = false
            settingsPaletteLevel = .settingsList
            settingsFilterText = ""
        }
    }

    // MARK: - Response Area

    private var responseArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.waveSystem(size: 13))
                            .foregroundStyle(Color.waveError)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if !viewModel.responseText.isEmpty {
                        MarkdownContentView(text: viewModel.responseText)
                            .padding(.horizontal, 16)
                            .padding(.top, viewModel.errorMessage == nil ? 8 : 0)
                    }

                    if viewModel.isStreaming {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking...")
                                .font(.waveSystem(size: 13))
                                .foregroundStyle(Color.waveTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .opacity(viewModel.responseText.isEmpty ? 1 : 0)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.responseText) {
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .frame(maxHeight: 460)
    }

}
