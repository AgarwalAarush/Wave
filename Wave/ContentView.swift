import SwiftUI

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
    @Bindable var viewModel: ChatViewModel
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
            viewModel.newChat()
            inputFocused = true
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "mM"), phases: .down) { press in
            guard press.modifiers.contains(.command),
                  press.modifiers.contains(.shift) else { return .ignored }
            toggleModelPicker()
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard showModelPicker else { return .ignored }
            highlightedModelIndex = max(0, highlightedModelIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard showModelPicker else { return .ignored }
            highlightedModelIndex = min(GPTModel.allModels.count - 1, highlightedModelIndex + 1)
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
        HStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.waveIcon)

            TextField("Ask anything...", text: $viewModel.queryText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(Color.waveTextPrimary)
                .focused($inputFocused)
                .onSubmit {
                    guard !showModelPicker else { return }
                    viewModel.submit()
                }

            modelPill

            if viewModel.isStreaming {
                Button { viewModel.stopStreaming() } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 16))
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
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.waveTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.waveModelPill, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Model Dropdown

    private var modelDropdown: some View {
        VStack(spacing: 0) {
            Color.waveDivider.frame(height: 1)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(GPTModel.allModels.enumerated()), id: \.element.id) { index, model in
                    Button {
                        viewModel.selectedModel = model
                        showModelPicker = false
                    } label: {
                        HStack {
                            Text(model.displayName)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.waveTextPrimary)
                            Spacer()
                            if model == viewModel.selectedModel {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.waveTextSecondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            index == highlightedModelIndex
                                ? Color.waveModelHighlight
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Model Picker Logic

    private func toggleModelPicker() {
        if showModelPicker {
            showModelPicker = false
        } else {
            highlightedModelIndex = GPTModel.allModels.firstIndex(of: viewModel.selectedModel) ?? 0
            showModelPicker = true
        }
    }

    private func selectHighlightedModel() {
        let models = GPTModel.allModels
        guard highlightedModelIndex >= 0, highlightedModelIndex < models.count else { return }
        viewModel.selectedModel = models[highlightedModelIndex]
        showModelPicker = false
    }

    // MARK: - Response Area

    private var responseArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.waveError)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if !viewModel.responseText.isEmpty {
                        Text(markdownAttributedString(viewModel.responseText))
                            .font(.system(size: 14))
                            .foregroundStyle(Color.waveTextPrimary)
                            .textSelection(.enabled)
                            .padding(.horizontal, 16)
                            .padding(.top, viewModel.errorMessage == nil ? 8 : 0)
                    }

                    if viewModel.isStreaming {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking...")
                                .font(.system(size: 13))
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

    // MARK: - Markdown

    private func markdownAttributedString(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        ))) ?? AttributedString(text)
    }
}
