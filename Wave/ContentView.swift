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

    var body: some View {
        VStack(spacing: 0) {
            queryBar
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
            dismissPanel()
            return .handled
        }
        .onKeyPress(characters: .init(charactersIn: "n"), phases: .down) { press in
            guard press.modifiers.contains(.command) else { return .ignored }
            viewModel.newChat()
            inputFocused = true
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
                .onSubmit { viewModel.submit() }

            if viewModel.isStreaming {
                Button { viewModel.stopStreaming() } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.waveIcon)
                }
                .buttonStyle(.plain)
            } else {
                Text("**\u{2318}`**")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.waveHint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
                                .font(.system(size: 12))
                                .foregroundStyle(Color.waveTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .opacity(viewModel.responseText.isEmpty ? 1 : 0)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.bottom, 12)
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
