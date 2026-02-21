import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let screenshot: Data?
    let screenshotSourceName: String?
    let timestamp: Date

    enum Role: String {
        case user
        case assistant
    }

    init(role: Role, content: String, screenshot: Data? = nil, screenshotSourceName: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.screenshot = screenshot
        self.screenshotSourceName = screenshotSourceName
        self.timestamp = Date()
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
