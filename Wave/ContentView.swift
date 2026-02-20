import SwiftUI
import AppKit

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

    var body: some View {
        VStack(spacing: 0) {
            queryBar
            if showModelPicker {
                modelDropdown
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
            if showModelPicker {
                showModelPicker = false
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
        .onKeyPress(characters: .init(charactersIn: "aA"), phases: .down) { press in
            guard press.modifiers.contains(.command), inputFocused else { return .ignored }
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard showModelPicker else { return .ignored }
            highlightedModelIndex = max(0, highlightedModelIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard showModelPicker else { return .ignored }
            let models = dropdownModels
            guard !models.isEmpty else { return .handled }
            highlightedModelIndex = min(models.count - 1, highlightedModelIndex + 1)
            return .handled
        }
        .onKeyPress(.return) {
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
