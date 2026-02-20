import Foundation

enum GPTModel: String, CaseIterable, Identifiable, Sendable {
    case nano = "gpt-5-nano-2025-08-07"
    case mini = "gpt-5-mini-2025-08-07"
    case full = "gpt-5.2-2025-12-11"
    case codex = "gpt-5.1-codex"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nano:  "5-nano"
        case .mini:  "5-mini"
        case .full:  "5.2"
        case .codex: "5.1-codex"
        }
    }

    static let `default`: GPTModel = .mini

    static let allModels: [GPTModel] = GPTModel.allCases

    static func from(rawValue: String?) -> GPTModel {
        guard let raw = rawValue else { return .default }
        return GPTModel(rawValue: raw) ?? .default
    }
}
