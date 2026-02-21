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
    @State private var highlightedSettingIndex = 0

    // Saved query text when palette is open (to restore on close)
    @State private var savedQueryText = ""

    // Screenshot palette state
    @State private var showScreenshotPalette = false
    @State private var highlightedScreenshotIndex = 0
    @State private var screenshotTargets: [CaptureTarget] = []

    var body: some View {
        VStack(spacing: 0) {
            queryBar
            if showModelPicker {
                modelDropdown
                    .transition(PaletteStyle.transition)
            }
            if showSettingsPalette {
                settingsPaletteDropdown
                    .transition(PaletteStyle.transition)
            }
            if showScreenshotPalette {
                ScreenshotPalette(
                    targets: screenshotTargets,
                    highlightedIndex: highlightedScreenshotIndex,
                    onSelect: { target in selectScreenshotTarget(target) }
                )
                .transition(PaletteStyle.transition)
            }
            if viewModel.hasContent || viewModel.errorMessage != nil {
                Color.waveDivider.frame(height: 1)
                conversationArea
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
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.hasContent)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.errorMessage != nil)
        .onAppear { inputFocused = true }
        .onChange(of: viewModel.queryText) {
            if showSettingsPalette {
                highlightedSettingIndex = 0
            }
        }
        .onKeyPress(.escape) {
            if showScreenshotPalette {
                withAnimation(PaletteStyle.animation) {
                    showScreenshotPalette = false
                }
                return .handled
            }
            if showSettingsPalette {
                withAnimation(PaletteStyle.animation) {
                    if case .settingOptions = settingsPaletteLevel {
                        settingsPaletteLevel = .settingsList
                        highlightedSettingIndex = 0
                    } else {
                        showSettingsPalette = false
                        viewModel.queryText = savedQueryText
                        savedQueryText = ""
                    }
                }
                return .handled
            }
            if showModelPicker {
                withAnimation(PaletteStyle.animation) {
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
        .onKeyPress(characters: .init(charactersIn: "sS"), phases: .down) { press in
            guard press.modifiers.contains(.command) else { return .ignored }
            if press.modifiers.contains(.shift) {
                toggleScreenshotPalette()
            } else {
                captureAndAttachFullScreen()
            }
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "1"), phases: .down) { press in
            guard press.modifiers.contains(.command),
                  press.modifiers.contains(.shift) else { return .ignored }
            captureCurrentFocusedWindow()
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "2"), phases: .down) { press in
            guard press.modifiers.contains(.command),
                  press.modifiers.contains(.shift) else { return .ignored }
            capturePreviousFocusedWindow()
            return .handled
        }
        .onKeyPress(.upArrow) {
            if showScreenshotPalette {
                highlightedScreenshotIndex = max(0, highlightedScreenshotIndex - 1)
                return .handled
            }
            if showSettingsPalette {
                highlightedSettingIndex = max(0, highlightedSettingIndex - 1)
                return .handled
            }
            guard showModelPicker else { return .ignored }
            highlightedModelIndex = max(0, highlightedModelIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            if showScreenshotPalette {
                let maxIndex = screenshotTargets.count - 1
                highlightedScreenshotIndex = min(max(0, maxIndex), highlightedScreenshotIndex + 1)
                return .handled
            }
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
            if showScreenshotPalette {
                selectHighlightedScreenshotTarget()
                return .handled
            }
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

    private var queryBarPlaceholder: String {
        if showSettingsPalette {
            return "Search settings..."
        }
        return "Ask anything..."
    }

    private var queryBar: some View {
        HStack(alignment: .top, spacing: 10) {
            if viewModel.hasManualScreenshot {
                screenshotIndicator
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.waveSystem(size: 14, weight: .medium))
                    .foregroundStyle(Color.waveIcon)
            }

            TextField(queryBarPlaceholder, text: $viewModel.queryText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.waveSystem(size: 15))
                .foregroundStyle(Color.waveTextPrimary)
                .lineLimit(1...4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .focused($inputFocused)
                .onSubmit {
                    guard !showModelPicker, !showSettingsPalette else { return }
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
        withAnimation(PaletteStyle.animation) {
            if showModelPicker {
                showModelPicker = false
            } else {
                // Restore query text if settings palette was open
                if showSettingsPalette {
                    viewModel.queryText = savedQueryText
                    savedQueryText = ""
                    showSettingsPalette = false
                }
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
        withAnimation(PaletteStyle.animation) {
            showModelPicker = false
        }
    }

    // MARK: - Settings Palette

    private var filteredSettings: [SettingItem] {
        SettingItem.allCases.filter { $0.matches(filter: viewModel.queryText) }
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
            withAnimation(PaletteStyle.animation) {
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
        withAnimation(PaletteStyle.animation) {
            if showSettingsPalette {
                showSettingsPalette = false
                settingsPaletteLevel = .settingsList
                // Restore original query text
                viewModel.queryText = savedQueryText
                savedQueryText = ""
            } else {
                // Close model picker if open
                showModelPicker = false
                // Save current query text and clear for filtering
                savedQueryText = viewModel.queryText
                viewModel.queryText = ""
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
            withAnimation(PaletteStyle.animation) {
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

        withAnimation(PaletteStyle.animation) {
            showSettingsPalette = false
            settingsPaletteLevel = .settingsList
            viewModel.queryText = savedQueryText
            savedQueryText = ""
        }
    }

    // MARK: - Screenshot Palette

    private var screenshotIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo.fill")
                .font(.waveSystem(size: 12))
                .foregroundStyle(Color.waveAccent)
            Button {
                viewModel.removeScreenshot()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.waveSystem(size: 12))
                    .foregroundStyle(Color.waveTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.waveAccent.opacity(0.15), in: Capsule())
    }

    private func toggleScreenshotPalette() {
        if showScreenshotPalette {
            withAnimation(PaletteStyle.animation) {
                showScreenshotPalette = false
            }
        } else {
            showModelPicker = false
            // Restore query text if settings palette was open
            if showSettingsPalette {
                viewModel.queryText = savedQueryText
                savedQueryText = ""
            }
            showSettingsPalette = false

            screenshotTargets = []
            highlightedScreenshotIndex = 0

            withAnimation(PaletteStyle.animation) {
                showScreenshotPalette = true
            }

            Task {
                let targets = await ScreenCaptureService.shared.getAvailableTargets()
                await MainActor.run {
                    screenshotTargets = targets
                }
            }
        }
    }

    private func selectHighlightedScreenshotTarget() {
        guard highlightedScreenshotIndex >= 0,
              highlightedScreenshotIndex < screenshotTargets.count else { return }
        selectScreenshotTarget(screenshotTargets[highlightedScreenshotIndex])
    }

    private func selectScreenshotTarget(_ target: CaptureTarget) {
        withAnimation(PaletteStyle.animation) {
            showScreenshotPalette = false
        }

        Task {
            if let data = await ScreenCaptureService.shared.capture(target: target) {
                await MainActor.run {
                    viewModel.attachScreenshot(data)
                }
            }
        }
    }

    private func captureAndAttachFullScreen() {
        Task {
            if let data = await ScreenCaptureService.shared.captureFullScreen() {
                await MainActor.run {
                    viewModel.attachScreenshot(data)
                }
            }
        }
    }

    private func captureCurrentFocusedWindow() {
        guard let bundleId = WindowFocusTracker.shared.currentFocused?.bundleIdentifier else { return }
        Task {
            if let data = await ScreenCaptureService.shared.captureWindow(forBundleIdentifier: bundleId) {
                await MainActor.run {
                    viewModel.attachScreenshot(data)
                }
            }
        }
    }

    private func capturePreviousFocusedWindow() {
        guard let bundleId = WindowFocusTracker.shared.previousFocused?.bundleIdentifier else { return }
        Task {
            if let data = await ScreenCaptureService.shared.captureWindow(forBundleIdentifier: bundleId) {
                await MainActor.run {
                    viewModel.attachScreenshot(data)
                }
            }
        }
    }

    // MARK: - Conversation Area

    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.waveSystem(size: 13))
                            .foregroundStyle(Color.waveError)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    ForEach(viewModel.messages) { message in
                        messageView(for: message)
                    }

                    if viewModel.isStreaming && !viewModel.streamingResponse.isEmpty {
                        assistantMessageView(content: viewModel.streamingResponse)
                    }

                    if viewModel.isStreaming && viewModel.streamingResponse.isEmpty {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking...")
                                .font(.waveSystem(size: 13))
                                .foregroundStyle(Color.waveTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.streamingResponse) {
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .frame(maxHeight: 460)
    }

    @ViewBuilder
    private func messageView(for message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            userMessageView(content: message.content, hasScreenshot: message.screenshot != nil)
        case .assistant:
            assistantMessageView(content: message.content)
        }
    }

    private func userMessageView(content: String, hasScreenshot: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if hasScreenshot {
                Image(systemName: "camera.viewfinder")
                    .font(.waveSystem(size: 12))
                    .foregroundStyle(Color.waveAccent)
            }
            Text(content)
                .font(.waveSystem(size: 14, weight: .medium))
                .foregroundStyle(Color.waveTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.waveModelPill.opacity(0.5))
    }

    private func assistantMessageView(content: String) -> some View {
        MarkdownContentView(text: content)
            .padding(.horizontal, 16)
    }

}
