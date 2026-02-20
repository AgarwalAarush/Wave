import Foundation

enum MarkdownListKind: Equatable {
    case unordered
    case ordered(ordinal: Int)
}

enum MarkdownRenderedBlock: Equatable {
    case paragraph(content: AttributedString)
    case listItem(kind: MarkdownListKind, depth: Int, content: AttributedString)
}

struct MarkdownBlockRenderer {
    static func renderBlocks(from text: String) -> [MarkdownRenderedBlock] {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)

        guard let attributed = try? AttributedString(markdown: text, options: options) else {
            return fallbackBlocks(from: text)
        }

        var blockByID: [Int: BlockAccumulator] = [:]
        var orderedBlockIDs: [Int] = []
        var nextSyntheticID = -1
        var lastBlockID: Int?

        for run in attributed.runs {
            let fragment = AttributedString(attributed[run.range])
            guard !fragment.characters.isEmpty else { continue }

            let metadata = metadata(from: run.presentationIntent)
            let blockID: Int

            if let paragraphID = metadata.paragraphID {
                blockID = paragraphID
            } else if let existingID = lastBlockID {
                blockID = existingID
            } else {
                blockID = nextSyntheticID
                nextSyntheticID -= 1
            }

            if blockByID[blockID] == nil {
                orderedBlockIDs.append(blockID)
                blockByID[blockID] = BlockAccumulator(
                    content: AttributedString(),
                    listKind: metadata.listKind,
                    depth: metadata.listDepth
                )
            }

            guard var accumulator = blockByID[blockID] else { continue }
            accumulator.content += fragment

            if accumulator.listKind == nil {
                accumulator.listKind = metadata.listKind
                accumulator.depth = metadata.listDepth
            }

            blockByID[blockID] = accumulator
            lastBlockID = blockID
        }

        let blocks: [MarkdownRenderedBlock] = orderedBlockIDs.compactMap { id in
            guard let accumulator = blockByID[id] else { return nil }
            guard !accumulator.content.characters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            if let kind = accumulator.listKind {
                return .listItem(
                    kind: kind,
                    depth: max(accumulator.depth, 1),
                    content: accumulator.content
                )
            } else {
                return .paragraph(content: accumulator.content)
            }
        }

        if blocks.isEmpty {
            return fallbackBlocks(from: text)
        }

        return blocks
    }

    private static func metadata(from intent: PresentationIntent?) -> IntentMetadata {
        guard let intent else {
            return IntentMetadata(paragraphID: nil, listKind: nil, listDepth: 0)
        }

        var paragraphID: Int?
        var listContainerKinds: [ListContainerKind] = []
        var itemOrdinal: Int?

        for component in intent.components {
            switch component.kind {
            case .paragraph:
                paragraphID = component.identity
            case .orderedList:
                listContainerKinds.append(.ordered)
            case .unorderedList:
                listContainerKinds.append(.unordered)
            case .listItem(let ordinal):
                if itemOrdinal == nil {
                    itemOrdinal = ordinal
                }
            default:
                break
            }
        }

        let listDepth = listContainerKinds.count
        let listKind: MarkdownListKind?

        if let closestContainer = listContainerKinds.first {
            switch closestContainer {
            case .unordered:
                listKind = .unordered
            case .ordered:
                listKind = .ordered(ordinal: itemOrdinal ?? 1)
            }
        } else {
            listKind = nil
        }

        return IntentMetadata(
            paragraphID: paragraphID,
            listKind: listKind,
            listDepth: listDepth
        )
    }

    private static func fallbackBlocks(from text: String) -> [MarkdownRenderedBlock] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        return [.paragraph(content: inlineFallback(from: text))]
    }

    private static func inlineFallback(from text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

private struct BlockAccumulator {
    var content: AttributedString
    var listKind: MarkdownListKind?
    var depth: Int
}

private struct IntentMetadata {
    let paragraphID: Int?
    let listKind: MarkdownListKind?
    let listDepth: Int
}

private enum ListContainerKind {
    case unordered
    case ordered
}
