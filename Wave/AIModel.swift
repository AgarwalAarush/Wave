import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"

    var id: String { rawValue }

    var apiKeyKey: String {
        switch self {
        case .openai: return "openai_api_key"
        case .anthropic: return "anthropic_api_key"
        }
    }

    var brandAssetName: String {
        switch self {
        case .openai: return "ChatGPT"
        case .anthropic: return "Claude"
        }
    }
}

enum AIModel: String, CaseIterable, Identifiable, Sendable {
    // OpenAI
    case gptNano = "gpt-5-nano-2025-08-07"
    case gptMini = "gpt-5-mini-2025-08-07"
    case gptFull = "gpt-5.2-2025-12-11"
    case gptCodex = "gpt-5.1-codex"

    // Anthropic
    case claudeOpus = "claude-opus-4-5-20251101"
    case claudeSonnet = "claude-sonnet-4-5"
    case claudeHaiku = "claude-haiku-4-5-20251001"

    var id: String { rawValue }

    var provider: AIProvider {
        switch self {
        case .gptNano, .gptMini, .gptFull, .gptCodex: return .openai
        case .claudeOpus, .claudeSonnet, .claudeHaiku: return .anthropic
        }
    }

    var displayName: String {
        switch self {
        case .gptNano: return "5-nano"
        case .gptMini: return "5-mini"
        case .gptFull: return "5.2"
        case .gptCodex: return "5.1-codex"
        case .claudeOpus: return "Opus 4.5"
        case .claudeSonnet: return "Sonnet 4.5"
        case .claudeHaiku: return "Haiku 4.5"
        }
    }

    static let `default`: AIModel = .gptMini

    static var openAIModels: [AIModel] {
        [.gptNano, .gptMini, .gptFull, .gptCodex]
    }

    static var anthropicModels: [AIModel] {
        [.claudeOpus, .claudeSonnet, .claudeHaiku]
    }

    static func models(for provider: AIProvider) -> [AIModel] {
        switch provider {
        case .openai: return openAIModels
        case .anthropic: return anthropicModels
        }
    }

    static func from(rawValue: String?) -> AIModel {
        guard let raw = rawValue else { return .default }
        return AIModel(rawValue: raw) ?? .default
    }

    /// Backward compatibility: map legacy GPTModel raw values
    static func fromStored(_ value: String?) -> AIModel {
        guard let raw = value else { return .default }
        if let model = AIModel(rawValue: raw) { return model }
        return GPTModel.from(rawValue: raw).toAIModel
    }
}

extension GPTModel {
    var toAIModel: AIModel {
        switch self {
        case .nano: return .gptNano
        case .mini: return .gptMini
        case .full: return .gptFull
        case .codex: return .gptCodex
        }
    }
}
